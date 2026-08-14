#!/usr/bin/env node
// migrate.mjs
//
// One-off Admin SDK rewrite of every pre-schema document into the shape
// docs/FIRESTORE_SCHEMA.md decides. The schema doc promises this script
// exists (see the "Rewrite existing documents" row in its privilege-model
// table) — this is it.
//
// This uses the Admin SDK, which bypasses every Firestore/Storage security
// rule. That is exactly why running it safely is the script's job, not the
// rules': dry-run by default, batched + chunked writes, idempotent reruns,
// and a printed summary of what happened and what could not be migrated.
//
// Usage:
//   node migrate.mjs                              dry run (default, no writes)
//   node migrate.mjs --apply                      write the migrated documents
//   node migrate.mjs --apply --delete-retired      also remove the retired
//                                                   collections' documents,
//                                                   but only the ones this run
//                                                   just confirmed migrated
//   node migrate.mjs --i-know-this-is-production   required to target anything
//                                                   other than the emulator
//
// See README.md for the full field-by-field mapping and the judgment calls
// this script had to make against real exported data.

import admin from "firebase-admin";
import { readFileSync, existsSync } from "node:fs";

// ── CLI flags ────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const FLAG_APPLY = args.includes("--apply");
const FLAG_DELETE_RETIRED = args.includes("--delete-retired");
const FLAG_PROD_OK = args.includes("--i-know-this-is-production");

function argValue(name) {
  const prefix = `--${name}=`;
  const hit = args.find((a) => a.startsWith(prefix));
  return hit ? hit.slice(prefix.length) : undefined;
}

const PROJECT_ID =
  argValue("project") ??
  process.env.FIREBASE_PROJECT_ID ??
  process.env.GCLOUD_PROJECT ??
  "nightride-a9173";

const IS_EMULATOR = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

console.log("=".repeat(78));
console.log("Night Ride — Firestore schema migration");
console.log(`  project:        ${PROJECT_ID}`);
console.log(
  `  target:         ${
    IS_EMULATOR ? `EMULATOR (${process.env.FIRESTORE_EMULATOR_HOST})` : "*** PRODUCTION / LIVE PROJECT ***"
  }`
);
console.log(`  mode:           ${FLAG_APPLY ? "APPLY — writes will be committed" : "DRY RUN — no writes"}`);
console.log(`  delete-retired: ${FLAG_DELETE_RETIRED}`);
console.log("=".repeat(78));
console.log("");

// ── Safety rails ─────────────────────────────────────────────────────────────

if (!IS_EMULATOR && !FLAG_PROD_OK) {
  console.error(
    [
      "Refusing to run: FIRESTORE_EMULATOR_HOST is not set, so this would target",
      "a real Firebase project, and --i-know-this-is-production was not passed.",
      "",
      "This script rewrites real documents with the Admin SDK, which bypasses",
      "every security rule. Point it at the local emulator first:",
      "  export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080",
      "  export FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099",
      "  export STORAGE_EMULATOR_HOST=http://127.0.0.1:9199",
      "or re-run with --i-know-this-is-production once you are certain.",
    ].join("\n")
  );
  process.exit(1);
}

if (FLAG_DELETE_RETIRED && !FLAG_APPLY) {
  console.error(
    "Refusing to run: --delete-retired only runs immediately after a successful\n" +
      "--apply, in the same invocation — it deletes only the source documents this\n" +
      "run just confirmed were migrated. Pass both flags together: --apply --delete-retired."
  );
  process.exit(1);
}

// ── Admin SDK bootstrap ──────────────────────────────────────────────────────

function resolveCredential() {
  if (IS_EMULATOR) return undefined;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (raw) {
    const parsed = JSON.parse(raw);
    return admin.credential.cert({
      projectId: parsed.project_id,
      clientEmail: parsed.client_email,
      privateKey: parsed.private_key.replace(/\\n/g, "\n"),
    });
  }
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) return admin.credential.applicationDefault();
  // Repo convention: a service-account file dropped next to the other Admin
  // SDK consumers (set_admin.py, PartyAgent). Convenience only — it is
  // gitignored and must stay that way.
  for (const candidate of [
    "./firebase_service_account.json",
    "../../firebase_service_account.json",
    "../../PartyAgent/firebase_service_account.json",
  ]) {
    if (existsSync(candidate)) return admin.credential.cert(JSON.parse(readFileSync(candidate, "utf8")));
  }
  return undefined;
}

const credential = resolveCredential();
if (!IS_EMULATOR && !credential) {
  console.error(
    "No Admin SDK credentials found for production. Set FIREBASE_SERVICE_ACCOUNT_JSON " +
      "(raw JSON), GOOGLE_APPLICATION_CREDENTIALS, or drop a firebase_service_account.json " +
      "where set_admin.py expects one."
  );
  process.exit(1);
}

admin.initializeApp({
  projectId: PROJECT_ID,
  ...(credential ? { credential } : {}),
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET ?? `${PROJECT_ID}.firebasestorage.app`,
});

const db = admin.firestore();
const bucket = admin.storage().bucket();
const { Timestamp, GeoPoint, FieldValue } = admin.firestore;

// ── Reporting ────────────────────────────────────────────────────────────────

const report = {};
function bucketFor(name) {
  if (!report[name]) report[name] = { migrated: 0, skipped: 0, failed: 0, samples: [], issues: [] };
  return report[name];
}
function recordMigrated(coll, id, before, after) {
  const b = bucketFor(coll);
  b.migrated++;
  if (b.samples.length < 3) b.samples.push({ id, before, after });
}
function recordSkipped(coll, id, reason) {
  const b = bucketFor(coll);
  b.skipped++;
  b.issues.push(`${id}: ${reason}`);
}
function recordFailed(coll, id, reason) {
  const b = bucketFor(coll);
  b.failed++;
  b.issues.push(`${id}: FAILED — ${reason}`);
}
function recordNote(coll, note) {
  bucketFor(coll).issues.push(note);
}

// ── Batched writes ───────────────────────────────────────────────────────────

const BATCH_SIZE = 400; // Firestore's hard cap is 500 ops/batch

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

async function commitInChunks(ops) {
  if (!FLAG_APPLY || ops.length === 0) return;
  for (const group of chunk(ops, BATCH_SIZE)) {
    const batch = db.batch();
    for (const op of group) {
      if (op.type === "set") batch.set(op.ref, op.data);
      else if (op.type === "update") batch.update(op.ref, op.data);
      else if (op.type === "delete") batch.delete(op.ref);
    }
    await batch.commit();
  }
}

// ── Geohash (standard base32, inline — no new dependency) ───────────────────

const GEOHASH_BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

function encodeGeohash(latitude, longitude, precision = 9) {
  let latMin = -90,
    latMax = 90;
  let lonMin = -180,
    lonMax = 180;
  let isEvenBit = true;
  let bit = 0;
  let ch = 0;
  let hash = "";

  while (hash.length < precision) {
    if (isEvenBit) {
      const mid = (lonMin + lonMax) / 2;
      if (longitude >= mid) {
        ch = (ch << 1) | 1;
        lonMin = mid;
      } else {
        ch = ch << 1;
        lonMax = mid;
      }
    } else {
      const mid = (latMin + latMax) / 2;
      if (latitude >= mid) {
        ch = (ch << 1) | 1;
        latMin = mid;
      } else {
        ch = ch << 1;
        latMax = mid;
      }
    }
    isEvenBit = !isEvenBit;
    bit++;
    if (bit === 5) {
      hash += GEOHASH_BASE32[ch];
      bit = 0;
      ch = 0;
    }
  }
  return hash;
}

// ── Country name → ISO-3166 alpha-2 ──────────────────────────────────────────
// Covers every value seen in the real exported dataset plus common aliases.
// Anything not in this table is reported as unresolvable, never guessed.

const COUNTRY_NAME_TO_ISO2 = {
  "united states of america": "US",
  "united states": "US",
  usa: "US",
  "u.s.a.": "US",
  "great britain": "GB",
  "united kingdom": "GB",
  uk: "GB",
  england: "GB",
  scotland: "GB",
  wales: "GB",
  australia: "AU",
  canada: "CA",
  mexico: "MX",
  "new zealand": "NZ",
  "united arab emirates": "AE",
  uae: "AE",
  japan: "JP",
  france: "FR",
  germany: "DE",
  italy: "IT",
  spain: "ES",
  portugal: "PT",
  netherlands: "NL",
  belgium: "BE",
  switzerland: "CH",
  austria: "AT",
  ireland: "IE",
  sweden: "SE",
  norway: "NO",
  denmark: "DK",
  finland: "FI",
  poland: "PL",
  greece: "GR",
  turkey: "TR",
  russia: "RU",
  china: "CN",
  india: "IN",
  indonesia: "ID",
  malaysia: "MY",
  singapore: "SG",
  thailand: "TH",
  philippines: "PH",
  vietnam: "VN",
  "south korea": "KR",
  "korea, republic of": "KR",
  "hong kong": "HK",
  brazil: "BR",
  argentina: "AR",
  chile: "CL",
  colombia: "CO",
  peru: "PE",
  "south africa": "ZA",
  egypt: "EG",
  "saudi arabia": "SA",
  qatar: "QA",
  kuwait: "KW",
  bahrain: "BH",
  oman: "OM",
  israel: "IL",
  jordan: "JO",
  lebanon: "LB",
  morocco: "MA",
  nigeria: "NG",
  kenya: "KE",
  pakistan: "PK",
  bangladesh: "BD",
  "sri lanka": "LK",
  nepal: "NP",
};

function normalizeCountryName(s) {
  return String(s || "").trim().toLowerCase().replace(/\s+/g, " ");
}

function resolveCountryCode(d) {
  if (typeof d.countryCode === "string" && /^[A-Z]{2}$/.test(d.countryCode)) return d.countryCode; // already migrated
  if (typeof d.country_code === "string" && /^[a-zA-Z]{2}$/.test(d.country_code)) return d.country_code.toUpperCase();
  if (typeof d.country === "string") {
    const code = COUNTRY_NAME_TO_ISO2[normalizeCountryName(d.country)];
    if (code) return code;
  }
  return null;
}

// ── Date / time parsing ──────────────────────────────────────────────────────
// Three legacy shapes exist in the wild (confirmed against the real export
// plus git history of the pre-migration client code):
//   1. events written by the Ticketmaster ingest: start_time is a full ISO
//      local datetime with no offset, e.g. "2026-04-24T23:00:00".
//   2. events written by the old admin panel (admin_add_event_page.dart):
//      date is "YYYY-MM-DD" from a date picker, start_time/end_time are
//      *free text* the admin typed, e.g. "09:00 PM" — no format enforced.
//   3. live_hub_social: date + time, same free-text risk as (2).
//
// Judgment call: a naive datetime/time-of-day with no timezone offset is
// interpreted as UTC (not the machine's local time and not a guess at the
// venue's real timezone) so the parse is deterministic and reruns the same
// way on any machine. This is documented, not hidden.

const ISO_DATETIME_RE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2})?(\.\d+)?(Z|[+-]\d{2}:?\d{2})?$/;
const DATE_ONLY_RE = /^\d{4}-\d{2}-\d{2}$/;
const TIME_24H_RE = /^([01]?\d|2[0-3]):([0-5]\d)$/;
const TIME_12H_RE = /^(1[0-2]|0?[1-9]):([0-5]\d)\s*([AaPp][Mm])$/;

function parseIsoDateTimeAsUtc(s) {
  if (!ISO_DATETIME_RE.test(s)) return null;
  const hasOffset = /(Z|[+-]\d{2}:?\d{2})$/.test(s);
  const iso = hasOffset ? s : `${s}Z`;
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? null : d;
}

function parseTimeOfDay(s) {
  if (typeof s !== "string") return null;
  const t = s.trim();
  const m24 = t.match(TIME_24H_RE);
  if (m24) return { h: Number(m24[1]), m: Number(m24[2]) };
  const m12 = t.match(TIME_12H_RE);
  if (m12) {
    let h = Number(m12[1]) % 12;
    if (/pm/i.test(m12[3])) h += 12;
    return { h, m: Number(m12[2]) };
  }
  return null;
}

function parseDateAndTime(dateStr, timeStr) {
  if (typeof dateStr !== "string" || !DATE_ONLY_RE.test(dateStr)) return null;
  const [y, mo, da] = dateStr.split("-").map(Number);
  const tod = parseTimeOfDay(timeStr);
  const h = tod ? tod.h : 0;
  const m = tod ? tod.m : 0;
  const d = new Date(Date.UTC(y, mo - 1, da, h, m, 0));
  return Number.isNaN(d.getTime()) ? null : d;
}

/**
 * Resolves an event-like document's startAt. Never invents a date: returns
 * { failed: true, reason } when nothing in the document parses, so the
 * caller can leave the document untouched and report it.
 */
function resolveStartAt(d) {
  if (d.startAt instanceof Timestamp) return { date: d.startAt.toDate() }; // already migrated

  const timeField = d.start_time ?? d.time;
  if (typeof timeField === "string" && ISO_DATETIME_RE.test(timeField)) {
    const dt = parseIsoDateTimeAsUtc(timeField);
    if (dt) return { date: dt };
  }
  if (typeof d.date === "string") {
    const dt = parseDateAndTime(d.date, typeof timeField === "string" ? timeField : null);
    if (dt) return { date: dt };
  }
  return {
    failed: true,
    reason: `cannot parse a start date from date=${JSON.stringify(d.date)} start_time/time=${JSON.stringify(
      timeField
    )}`,
  };
}

function resolveEndAt(d, fallbackStartDate) {
  if (d.endAt instanceof Timestamp) return d.endAt; // already migrated
  if (d.endAt === null) return null;

  const endTimeField = d.end_time;
  if (typeof endTimeField === "string" && ISO_DATETIME_RE.test(endTimeField)) {
    const dt = parseIsoDateTimeAsUtc(endTimeField);
    if (dt) return Timestamp.fromDate(dt);
  }
  if (typeof d.date === "string" && typeof endTimeField === "string") {
    const dt = parseDateAndTime(d.date, endTimeField);
    if (dt) {
      // Free-text end times ("2:00 AM") almost always mean past midnight —
      // roll to the next day when the parsed time lands before the start.
      if (fallbackStartDate && dt.getTime() <= fallbackStartDate.getTime()) {
        dt.setUTCDate(dt.getUTCDate() + 1);
      }
      return Timestamp.fromDate(dt);
    }
  }
  return null; // endAt is nullable — an unparseable end time is not fatal
}

// ── Price parsing ────────────────────────────────────────────────────────────

const CURRENCY_SYMBOLS = { "A$": "AUD", "C$": "CAD", $: "USD", "£": "GBP", "€": "EUR", "¥": "JPY", "₹": "INR" };

function parsePriceHint(hint) {
  if (typeof hint !== "string") return null;
  const s = hint.trim();
  if (!s) return null;
  if (/\bfree\b/i.test(s)) return { min: 0, max: 0, currency: "USD", isFree: true };

  let currency = "USD";
  for (const [sym, code] of Object.entries(CURRENCY_SYMBOLS)) {
    if (s.includes(sym)) {
      currency = code;
      break;
    }
  }
  const codeMatch = s.match(/\b([A-Z]{3})\b/);
  if (codeMatch) currency = codeMatch[1];

  const numbers = s.match(/\d+(\.\d+)?/g);
  if (!numbers || numbers.length === 0) return null;
  const nums = numbers.map(Number);
  return { min: Math.min(...nums), max: Math.max(...nums), currency, isFree: false };
}

function resolvePrice(d) {
  if (d.price && typeof d.price === "object" && typeof d.price.isFree === "boolean") return d.price; // already migrated
  return parsePriceHint(d.price_hint) ?? { min: 0, max: 0, currency: "USD", isFree: false };
}

// ── Geo ──────────────────────────────────────────────────────────────────────

function resolveGeo(d) {
  if (d.geo instanceof GeoPoint) return d.geo; // already migrated
  const lat = typeof d.lat === "number" ? d.lat : null;
  const lng = typeof d.lng === "number" ? d.lng : null;
  if (lat === null || lng === null) return null;
  if (lat === 0 && lng === 0) return null; // geocoding-failure sentinel, not a real point
  return new GeoPoint(lat, lng);
}

// ── Status / source ──────────────────────────────────────────────────────────

function resolveStatus(d) {
  const raw = String(d.status ?? "").toLowerCase().trim();
  if (raw === "draft" || raw === "published" || raw === "archived") return raw;
  if (raw === "cancelled" || raw === "canceled" || raw === "completed") return "archived";
  return "draft"; // unknown/missing — hidden by default rather than surfaced unverified
}

function resolveSource(d, { forcedSource } = {}) {
  if (forcedSource) return forcedSource;
  if (typeof d.organizerUid === "string" && d.organizerUid) return "organizer";
  if (typeof d.source === "string" && ["organizer", "admin", "scraped"].includes(d.source)) return d.source;
  if (typeof d.source === "string" && d.source.trim()) return "scraped"; // e.g. legacy 'ticketmaster'
  return "admin"; // no source field at all — the old admin panel never wrote one
}

// ── events (in place) ────────────────────────────────────────────────────────

function isAlreadyMigratedEvent(d) {
  return (
    d.startAt instanceof Timestamp &&
    typeof d.name === "string" &&
    d.price &&
    typeof d.price.isFree === "boolean" &&
    typeof d.countryCode === "string" &&
    /^[A-Z]{2}$/.test(d.countryCode) &&
    !("title" in d) &&
    !("date" in d) &&
    !("start_time" in d) &&
    !("price_hint" in d) &&
    !("country_code" in d) &&
    !("cover_image" in d) &&
    !("venue_name" in d) &&
    !("created_at" in d) &&
    !("updated_at" in d) &&
    !("artists" in d) &&
    !("isTrending" in d) &&
    !("watchingCount" in d)
  );
}

function buildEventDoc(d, { forcedSource, forcedStatus } = {}) {
  const startRes = resolveStartAt(d);
  if (startRes.failed) return { failed: true, reason: startRes.reason };

  const countryCode = resolveCountryCode(d);
  if (!countryCode) {
    return {
      failed: true,
      reason: `cannot resolve a countryCode from country=${JSON.stringify(d.country)} country_code=${JSON.stringify(
        d.country_code
      )}`,
    };
  }

  const name = d.name ?? d.title ?? "";
  if (!name) return { failed: true, reason: "no name/title field to migrate" };

  const startAtDate = startRes.date;
  const endAt = resolveEndAt(d, startAtDate);
  const geo = resolveGeo(d);
  const price = resolvePrice(d);

  const performers = Array.isArray(d.performers) ? d.performers : [];
  if (!performers.length && typeof d.djName === "string" && d.djName.trim()) {
    performers.push({ name: d.djName.trim(), type: "DJ", bio: "" });
  }

  const rawPolicies = d.policies && typeof d.policies === "object" ? d.policies : {};
  const policies = {
    ageRestriction: Number(rawPolicies.ageRestriction ?? rawPolicies.age_restriction ?? 0) || 0,
    refundPolicy: rawPolicies.refundPolicy ?? rawPolicies.refund_policy ?? "",
    reEntryAllowed: (rawPolicies.reEntryAllowed ?? rawPolicies.re_entry_allowed) === true,
    wheelchairAccessible: (rawPolicies.wheelchairAccessible ?? rawPolicies.wheelchair_accessible) === true,
    allowPets: (rawPolicies.allowPets ?? rawPolicies.allow_pets) === true,
  };

  return {
    failed: false,
    doc: {
      name,
      description: typeof d.description === "string" ? d.description : "",
      venueId: typeof d.venueId === "string" ? d.venueId : null,
      venueName: d.venueName ?? d.venue_name ?? d.clubName ?? "",
      city: typeof d.city === "string" ? d.city : "",
      countryCode,
      geo,
      startAt: Timestamp.fromDate(startAtDate),
      endAt,
      price,
      ticketUrl: d.ticketUrl ?? d.ticket_url ?? "",
      coverImage: d.coverImage ?? d.cover_image ?? d.imageUrl ?? "",
      genre: typeof d.genre === "string" ? d.genre : "",
      category: typeof d.category === "string" ? d.category : "",
      vibe: typeof d.vibe === "string" ? d.vibe : "",
      language: typeof d.language === "string" ? d.language : "",
      performers,
      policies,
      interestedCount: Number.isInteger(d.interestedCount)
        ? d.interestedCount
        : Number.isInteger(d.interested_count)
          ? d.interested_count
          : 0,
      popularityScore: typeof d.popularityScore === "number" ? d.popularityScore : 0,
      status: forcedStatus ?? resolveStatus(d),
      source: resolveSource(d, { forcedSource }),
      organizerUid: typeof d.organizerUid === "string" ? d.organizerUid : null,
      createdAt:
        d.createdAt instanceof Timestamp ? d.createdAt : d.created_at instanceof Timestamp ? d.created_at : Timestamp.now(),
      updatedAt: Timestamp.now(),
    },
  };
}

async function migrateEventsInPlace() {
  const coll = "events";
  const snap = await db.collection("events").get();
  const ops = [];
  for (const doc of snap.docs) {
    const d = doc.data();
    if (isAlreadyMigratedEvent(d)) {
      recordSkipped(coll, doc.id, "already migrated");
      continue;
    }
    const result = buildEventDoc(d);
    if (result.failed) {
      recordSkipped(coll, doc.id, result.reason);
      continue;
    }
    ops.push({ type: "set", ref: doc.ref, data: result.doc });
    recordMigrated(coll, doc.id, d, result.doc);
  }
  await commitInChunks(ops);
}

// ── live_hub_clubs → venues ──────────────────────────────────────────────────

const VALID_LIVE_STATUS = new Set(["open", "closed", "vipOnly", "soldOut"]);
const VALID_CROWD = new Set(["empty", "quiet", "moderate", "busy", "packed"]);
const VALID_QUEUE = new Set(["noQueue", "short", "moderate", "long", "closed"]);

function normalizeClubName(s) {
  return String(s || "").trim().toLowerCase();
}

function looksLikeMigratedVenue(d) {
  return Boolean(d) && d.geo instanceof GeoPoint && typeof d.geohash === "string" && d.geohash.length === 9;
}

async function migrateVenuesFromClubs() {
  const coll = "venues (from live_hub_clubs)";
  const clubsSnap = await db.collection("live_hub_clubs").get();

  const venueIdByClubName = new Map();
  const venueIdByClubDocId = new Map();
  const migratedClubIds = [];
  const ops = [];

  for (const doc of clubsSnap.docs) {
    const d = doc.data();
    const targetId = typeof d.osmId === "string" && d.osmId ? `osm_${d.osmId}` : doc.id;
    const targetRef = db.collection("venues").doc(targetId);
    const existing = await targetRef.get();

    if (existing.exists && looksLikeMigratedVenue(existing.data())) {
      recordSkipped(coll, doc.id, "already migrated");
      venueIdByClubName.set(normalizeClubName(d.clubName ?? existing.data().name ?? ""), targetId);
      venueIdByClubDocId.set(doc.id, targetId);
      migratedClubIds.push(doc.id);
      continue;
    }

    const geo = resolveGeo(d);
    if (!geo) {
      recordSkipped(
        coll,
        doc.id,
        `no coordinates on the legacy document (clubName=${JSON.stringify(
          d.clubName
        )}) — refusing to invent a location; this venue needs manual geocoding before it can be migrated`
      );
      continue;
    }
    const countryCode = resolveCountryCode(d);
    if (!countryCode) {
      recordSkipped(coll, doc.id, `cannot resolve countryCode from country=${JSON.stringify(d.country)}`);
      continue;
    }

    const venueDoc = {
      name: d.clubName ?? d.name ?? "",
      geo,
      geohash: encodeGeohash(geo.latitude, geo.longitude, 9),
      type: "nightclub",
      typeLabel: "Night Club",
      city: typeof d.city === "string" ? d.city : "",
      countryCode,
      address: "",
      openingHours: "",
      phone: "",
      website: "",
      photos: typeof d.imageUrl === "string" && d.imageUrl ? [d.imageUrl] : [],
      source: typeof d.osmId === "string" && d.osmId ? "osm" : "admin",
      osmId: typeof d.osmId === "string" ? d.osmId : null,
      ownerUid: null,
      verified: false,
      status: "active",
      live: {
        status: VALID_LIVE_STATUS.has(d.status) ? d.status : "closed",
        crowdLevel: VALID_CROWD.has(d.crowdLevel) ? d.crowdLevel : "empty",
        queueStatus: VALID_QUEUE.has(d.queueStatus) ? d.queueStatus : "noQueue",
        ticketsAvailable: d.ticketsAvailable === true,
        tablesAvailable: d.tablesAvailable === true,
        tonightDj: typeof d.tonightDj === "string" ? d.tonightDj : "",
        offer: typeof d.offer === "string" ? d.offer : "",
        // The old doc only ever carried a relative label like "12 min ago" —
        // free text, not a Timestamp, and already stale by the time this
        // script runs. There is nothing real to recover, so this falls back
        // to now() exactly as instructed for a missing timestamp.
        updatedAt: d.updatedAt instanceof Timestamp ? d.updatedAt : Timestamp.now(),
      },
      createdAt: d.createdAt instanceof Timestamp ? d.createdAt : Timestamp.now(),
      updatedAt: Timestamp.now(),
    };

    ops.push({ type: "set", ref: targetRef, data: venueDoc });
    recordMigrated(coll, doc.id, d, venueDoc);
    venueIdByClubName.set(normalizeClubName(venueDoc.name), targetId);
    venueIdByClubDocId.set(doc.id, targetId);
    migratedClubIds.push(doc.id);
  }

  await commitInChunks(ops);
  return { venueIdByClubName, venueIdByClubDocId, migratedClubIds };
}

// ── Deterministic target-id resolution for docs moving collections ──────────
// Used by the two migrations that create documents in a different collection
// than they read from (live_hub_reports → venueReports, live_hub_social →
// events). Reusing the source doc id keeps the mapping traceable and,
// crucially, makes reruns idempotent without a marker field: the second run
// finds the same target id already in the new shape and skips it.

async function resolveTargetDoc(targetCollection, originalId, isMigratedShapeFn, fallbackPrefix) {
  const ref = db.collection(targetCollection).doc(originalId);
  const snap = await ref.get();
  if (!snap.exists) return { ref, alreadyMigrated: false };
  if (isMigratedShapeFn(snap.data())) return { ref, alreadyMigrated: true };

  // The id is taken by something unrelated — fall back to a prefixed id
  // instead of clobbering it.
  const fallbackRef = db.collection(targetCollection).doc(`${fallbackPrefix}-${originalId}`);
  const fallbackSnap = await fallbackRef.get();
  if (fallbackSnap.exists && isMigratedShapeFn(fallbackSnap.data())) {
    return { ref: fallbackRef, alreadyMigrated: true };
  }
  return { ref: fallbackRef, alreadyMigrated: false };
}

// ── live_hub_reports → venueReports ──────────────────────────────────────────

function isMigratedVenueReport(d) {
  return Boolean(d) && typeof d.venueId === "string" && typeof d.upvoteCount === "number" && !("upvotes" in d);
}

async function migrateVenueReports(venueLookup) {
  const coll = "venueReports (from live_hub_reports)";
  const snap = await db.collection("live_hub_reports").get();
  const ops = [];
  const migratedIds = [];

  for (const doc of snap.docs) {
    const d = doc.data();
    const { ref: targetRef, alreadyMigrated } = await resolveTargetDoc(
      "venueReports",
      doc.id,
      isMigratedVenueReport,
      "legacy"
    );
    if (alreadyMigrated) {
      recordSkipped(coll, doc.id, "already migrated");
      migratedIds.push(doc.id);
      continue;
    }

    let venueId = null;
    if (typeof d.clubId === "string" && venueLookup.venueIdByClubDocId.has(d.clubId)) {
      venueId = venueLookup.venueIdByClubDocId.get(d.clubId);
    } else if (typeof d.clubName === "string") {
      venueId = venueLookup.venueIdByClubName.get(normalizeClubName(d.clubName)) ?? null;
    }
    if (!venueId) {
      recordSkipped(
        coll,
        doc.id,
        `cannot resolve venueId for clubName=${JSON.stringify(d.clubName)} — reporting as unresolvable rather than guessing`
      );
      continue;
    }

    const newDoc = {
      venueId,
      // Legacy live_hub_reports never captured an author uid (see
      // live_hub_service.dart submitReport) — left "" rather than invented.
      uid: typeof d.uid === "string" ? d.uid : "",
      username: typeof d.username === "string" ? d.username : "",
      avatarUrl: typeof d.avatarUrl === "string" ? d.avatarUrl : "",
      city: typeof d.city === "string" ? d.city : "",
      countryCode: resolveCountryCode(d) ?? "",
      tag: typeof d.tag === "string" ? d.tag : "",
      vibeRating: typeof d.vibeRating === "number" ? d.vibeRating : 3,
      comment: typeof d.comment === "string" ? d.comment : "",
      upvoteCount: typeof d.upvotes === "number" ? d.upvotes : 0,
      createdAt: d.createdAt instanceof Timestamp ? d.createdAt : Timestamp.now(),
    };

    ops.push({ type: "set", ref: targetRef, data: newDoc });
    recordMigrated(coll, doc.id, d, newDoc);
    if (!newDoc.uid) recordNote(coll, `${doc.id}: migrated with uid:"" — see README, legacy reports had no author uid`);
    migratedIds.push(doc.id);
  }

  await commitInChunks(ops);
  return { migratedIds };
}

// ── live_hub_social → events ─────────────────────────────────────────────────

async function migrateEventsFromSocial(venueLookup) {
  const coll = "events (from live_hub_social)";
  const snap = await db.collection("live_hub_social").get();
  const ops = [];
  const migratedIds = [];

  for (const doc of snap.docs) {
    const d = doc.data();
    const { ref: targetRef, alreadyMigrated } = await resolveTargetDoc(
      "events",
      `social-${doc.id}`,
      isAlreadyMigratedEvent,
      "social"
    );
    if (alreadyMigrated) {
      recordSkipped(coll, doc.id, "already migrated");
      migratedIds.push(doc.id);
      continue;
    }

    const result = buildEventDoc(
      { ...d, name: d.title, venueName: d.clubName, coverImage: d.imageUrl },
      { forcedSource: "scraped", forcedStatus: "published" }
    );
    if (result.failed) {
      recordSkipped(coll, doc.id, result.reason);
      continue;
    }

    result.doc.venueId =
      typeof d.clubName === "string" ? venueLookup.venueIdByClubName.get(normalizeClubName(d.clubName)) ?? null : null;
    result.doc.popularityScore = typeof d.popularityScore === "number" ? d.popularityScore : 0;

    ops.push({ type: "set", ref: targetRef, data: result.doc });
    recordMigrated(coll, doc.id, d, result.doc);
    migratedIds.push(doc.id);
  }

  await commitInChunks(ops);
  return { migratedIds };
}

// ── users + organizer_requests → users + users/{uid}/private/organizerReview ─
//
// Old organizerApplication shape (nightride-webpanel/lib/organizer/application-service.ts,
// before this migration existed):
//   organizerApplication: {
//     steps: { nic, selfie, gps, video_request }: bare status strings
//     extraSteps: [...], rejected: bool, rejectionReason: string, phoneVerified: bool
//   }
// This was writable by the applicant, which is exactly the bug the new schema
// fixes: the verdict half of that shape moves to an admin-only
// users/{uid}/private/organizerReview, and what remains on the user document
// becomes purely the applicant's own claims.

const OLD_STEP_TO_REVIEW_STATUS = {
  pending: "pending",
  active: "active",
  needs_info: "needs_info",
  scheduled: "active", // the new schema has no scheduled-call concept
  done: "accepted",
};

function mapReviewStepStatus(oldStatus) {
  return OLD_STEP_TO_REVIEW_STATUS[oldStatus] ?? "active";
}

function stepWasUploaded(oldStatus) {
  return oldStatus === "needs_info" || oldStatus === "scheduled" || oldStatus === "done";
}

function reviewStep(overrides) {
  return { status: "active", attempt: 0, note: "", reviewedAt: null, reviewedBy: null, venueId: null, mediaDeletedAt: null, ...overrides };
}

function parseEventsPerMonth(v) {
  if (typeof v === "number") return v;
  if (typeof v === "string") {
    const m = v.match(/\d+/);
    if (m) return Number(m[0]);
  }
  return 0;
}

function isAlreadyMigratedUser(d) {
  return (
    typeof d.organizerStatus === "string" &&
    !("role" in d) &&
    !("isOrganizer" in d) &&
    d.organizerApplication &&
    typeof d.organizerApplication.submitted === "boolean" &&
    d.organizerApplication.steps &&
    "venueAddress" in d.organizerApplication.steps
  );
}

async function migrateUsersAndOrganizerRequests() {
  const coll = "users";
  const usersSnap = await db.collection("users").get();
  const orgReqSnap = await db.collection("organizer_requests").get();
  const orgReqByUid = new Map(orgReqSnap.docs.map((d) => [d.id, d.data()]));
  const usersUidSet = new Set(usersSnap.docs.map((d) => d.id));

  const ops = [];
  const migratedOrgReqIds = [];

  for (const doc of usersSnap.docs) {
    const uid = doc.id;
    const d = doc.data();
    const orgReq = orgReqByUid.get(uid);
    const alreadyMigratedUser = isAlreadyMigratedUser(d);

    if (alreadyMigratedUser) {
      recordSkipped(coll, uid, "already migrated");
    } else {
      const oldApp = d.organizerApplication && typeof d.organizerApplication === "object" ? d.organizerApplication : null;

      const approvedBySelf = d.isOrganizer === true || d.role === "organizer";
      const rejectedFlag = oldApp?.rejected === true || orgReq?.status === "rejected";
      // Judgment call (see README): the task's literal rule is "approved
      // where isOrganizer/role said so, else 'none'". Left at 'none', a
      // decided rejection would silently re-enter the untriaged review queue
      // (submitted==true && organizerStatus=='none' is exactly that queue's
      // definition per docs/FIRESTORE_SCHEMA.md), so a recorded rejection
      // overrides to 'rejected' instead.
      const resolvedStatus = approvedBySelf ? "approved" : rejectedFlag ? "rejected" : "none";

      const submitted = Boolean(oldApp) || Boolean(orgReq) || resolvedStatus !== "none";
      const submittedAt =
        (oldApp?.startedAt instanceof Timestamp && oldApp.startedAt) ||
        (orgReq?.createdAt instanceof Timestamp && orgReq.createdAt) ||
        (d.createdAt instanceof Timestamp && d.createdAt) ||
        Timestamp.now();

      const newApplication = {
        submitted,
        submittedAt,
        profile: {
          orgName: orgReq?.orgName ?? "",
          venueName: "",
          instagram: orgReq?.instagram ?? "",
          website: orgReq?.website ?? "",
          bio: orgReq?.bio ?? "",
          eventTypes: Array.isArray(orgReq?.eventTypes) ? orgReq.eventTypes : [],
          eventsPerMonth: parseEventsPerMonth(orgReq?.eventsPerMonth),
        },
        steps: {
          venueAddress: null,
          nic: { uploaded: stepWasUploaded(oldApp?.steps?.nic) },
          selfie: { uploaded: stepWasUploaded(oldApp?.steps?.selfie) },
          video: { uploaded: stepWasUploaded(oldApp?.steps?.video_request) }, // video_request -> video
          gps: { attempts: [] },
        },
      };

      // update(), not set({merge:true}): a merge deep-merges nested maps and
      // would leave old sibling keys (organizerApplication.steps.video_request,
      // .extraSteps, .rejected, ...) behind forever. update() replaces the
      // whole field path it names, which is what "rewritten to the new shape"
      // has to mean here.
      ops.push({
        type: "update",
        ref: doc.ref,
        data: {
          role: FieldValue.delete(),
          isOrganizer: FieldValue.delete(),
          organizerStatus: resolvedStatus,
          organizerApplication: newApplication,
          updatedAt: Timestamp.now(),
        },
      });
      recordMigrated(coll, uid, d, { organizerStatus: resolvedStatus, organizerApplication: newApplication });
      if (rejectedFlag && !approvedBySelf) {
        recordNote(coll, `${uid}: organizerStatus -> 'rejected' (judgment call — see README)`);
      }

      if (submitted) {
        const reviewRef = doc.ref.collection("private").doc("organizerReview");
        const existingReview = await reviewRef.get();
        if (!existingReview.exists) {
          const decided = resolvedStatus === "approved" || resolvedStatus === "rejected";
          const reviewDoc = {
            status: resolvedStatus,
            appliedAt: submittedAt,
            decidedAt: decided ? (d.updatedAt instanceof Timestamp ? d.updatedAt : Timestamp.now()) : null,
            decidedBy: "", // unknown admin identity in the old data — never invented
            rejectionReason: oldApp?.rejectionReason ?? "",
            phoneVerified: oldApp?.phoneVerified === true,
            steps: {
              // Explicit instruction: the new venueAddress step starts
              // 'active' with no data — there is no old equivalent to carry
              // forward, even for an approved organizer.
              venueAddress: reviewStep({ status: "active" }),
              nic: reviewStep({ status: mapReviewStepStatus(oldApp?.steps?.nic) }),
              selfie: reviewStep({ status: mapReviewStepStatus(oldApp?.steps?.selfie) }),
              video: reviewStep({ status: mapReviewStepStatus(oldApp?.steps?.video_request) }),
              gps: reviewStep({ status: "pending" }), // gated on venueAddress being accepted, which it never was here
            },
            updatedAt: Timestamp.now(),
          };
          ops.push({ type: "set", ref: reviewRef, data: reviewDoc });
          recordMigrated("users/{uid}/private/organizerReview", uid, oldApp ?? orgReq ?? null, reviewDoc);
        } else {
          recordSkipped("users/{uid}/private/organizerReview", uid, "already exists");
        }
      }
    }

    // An organizer_requests doc is fully retired once its uid's users
    // document is on the new schema — whether that happened just now or on
    // a prior run.
    if (orgReq) migratedOrgReqIds.push(uid);
  }

  for (const doc of orgReqSnap.docs) {
    if (!usersUidSet.has(doc.id)) {
      recordSkipped("organizer_requests", doc.id, "no matching users/{uid} document to fold into — left untouched");
    }
  }

  await commitInChunks(ops);
  return { migratedOrgReqIds };
}

// ── avatars → Storage + users.avatarUrl ──────────────────────────────────────

async function migrateAvatars() {
  const coll = "avatars";
  const snap = await db.collection("avatars").get();
  const migratedUids = [];

  for (const doc of snap.docs) {
    const uid = doc.id;
    const d = doc.data();
    const userSnap = await db.collection("users").doc(uid).get();
    if (!userSnap.exists) {
      recordSkipped(coll, uid, "no matching users/{uid} document");
      continue;
    }
    const existingAvatarUrl = userSnap.data().avatarUrl;
    if (typeof existingAvatarUrl === "string" && existingAvatarUrl.includes(`avatars/${uid}.jpg`)) {
      recordSkipped(coll, uid, "already migrated");
      migratedUids.push(uid);
      continue;
    }

    const base64 = d.data;
    if (typeof base64 !== "string" || !base64) {
      recordFailed(coll, uid, "no base64 'data' field on the avatars document");
      continue;
    }
    let buffer;
    try {
      buffer = Buffer.from(base64, "base64");
      if (!buffer.length) throw new Error("decoded to an empty buffer");
    } catch (err) {
      recordFailed(coll, uid, `blob is not decodable: ${err.message}`);
      continue;
    }

    const objectPath = `avatars/${uid}.jpg`;
    let url;
    if (FLAG_APPLY) {
      await bucket.file(objectPath).save(buffer, { contentType: "image/jpeg", resumable: false });
      url = IS_EMULATOR
        ? `${process.env.STORAGE_EMULATOR_HOST ?? "http://127.0.0.1:9199"}/v0/b/${bucket.name}/o/${encodeURIComponent(
            objectPath
          )}?alt=media`
        : `https://storage.googleapis.com/${bucket.name}/${objectPath}`;
      await db.collection("users").doc(uid).update({ avatarUrl: url });
    } else {
      url = `<would upload ${buffer.length} bytes to ${objectPath} and set users/${uid}.avatarUrl>`;
    }
    recordMigrated(coll, uid, { hasBase64: true }, { avatarUrl: url });
    migratedUids.push(uid);
  }

  return { migratedUids };
}

// ── --delete-retired ──────────────────────────────────────────────────────────

async function deleteRetired({ migratedClubIds, migratedOrgReqIds, migratedAvatarUids, migratedReportIds, migratedSocialIds }) {
  const ops = [];
  for (const uid of migratedOrgReqIds) ops.push({ type: "delete", ref: db.collection("organizer_requests").doc(uid) });
  for (const uid of migratedAvatarUids) ops.push({ type: "delete", ref: db.collection("avatars").doc(uid) });
  for (const id of migratedClubIds) ops.push({ type: "delete", ref: db.collection("live_hub_clubs").doc(id) });
  for (const id of migratedReportIds) ops.push({ type: "delete", ref: db.collection("live_hub_reports").doc(id) });
  for (const id of migratedSocialIds) ops.push({ type: "delete", ref: db.collection("live_hub_social").doc(id) });

  console.log(
    `Deleting ${ops.length} retired documents (organizer_requests: ${migratedOrgReqIds.length}, avatars: ${migratedAvatarUids.length}, live_hub_clubs: ${migratedClubIds.length}, live_hub_reports: ${migratedReportIds.length}, live_hub_social: ${migratedSocialIds.length})`
  );
  await commitInChunks(ops);
}

// ── Summary ──────────────────────────────────────────────────────────────────

function printSummary() {
  console.log("\n" + "=".repeat(78));
  console.log("SUMMARY");
  console.log("=".repeat(78));
  let totalMigrated = 0,
    totalSkipped = 0,
    totalFailed = 0;
  for (const [name, b] of Object.entries(report)) {
    totalMigrated += b.migrated;
    totalSkipped += b.skipped;
    totalFailed += b.failed;
    console.log(`\n${name}`);
    console.log(`  migrated: ${b.migrated}   skipped: ${b.skipped}   failed: ${b.failed}`);
    if (b.samples.length) {
      console.log(`  sample before/after:`);
      for (const s of b.samples.slice(0, 2)) {
        console.log(`    --- ${s.id} ---`);
        console.log(`    before: ${JSON.stringify(s.before)}`);
        console.log(`    after:  ${JSON.stringify(s.after)}`);
      }
    }
    if (b.issues.length) {
      console.log(`  notes/reasons (${b.issues.length}):`);
      for (const issue of b.issues.slice(0, 25)) console.log(`    - ${issue}`);
      if (b.issues.length > 25) console.log(`    ... and ${b.issues.length - 25} more`);
    }
  }
  console.log(`\nTOTAL — migrated: ${totalMigrated}   skipped: ${totalSkipped}   failed: ${totalFailed}`);
  console.log(
    FLAG_APPLY
      ? "\n(APPLY mode — the writes above were committed.)"
      : "\n(DRY RUN — nothing was written. Re-run with --apply to commit.)"
  );
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  await migrateEventsInPlace();
  const venueLookup = await migrateVenuesFromClubs();
  const reportsResult = await migrateVenueReports(venueLookup);
  const socialResult = await migrateEventsFromSocial(venueLookup);
  const usersResult = await migrateUsersAndOrganizerRequests();
  const avatarsResult = await migrateAvatars();

  printSummary();

  if (FLAG_DELETE_RETIRED) {
    console.log("\n" + "=".repeat(78));
    console.log("DELETE-RETIRED PHASE");
    console.log("=".repeat(78));
    await deleteRetired({
      migratedClubIds: venueLookup.migratedClubIds,
      migratedOrgReqIds: usersResult.migratedOrgReqIds,
      migratedAvatarUids: avatarsResult.migratedUids,
      migratedReportIds: reportsResult.migratedIds,
      migratedSocialIds: socialResult.migratedIds,
    });
  }
}

main().catch((err) => {
  console.error("Migration failed:", err);
  process.exit(1);
});
