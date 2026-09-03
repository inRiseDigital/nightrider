#!/usr/bin/env node
// seed.mjs
//
// Fills the local Firebase emulator (Auth + Firestore + Storage) with
// realistic Night Ride / Night Rite data matching docs/FIRESTORE_SCHEMA.md
// exactly, so the Flutter app and the webpanel have something real to
// develop against.
//
// This uses the Admin SDK, which bypasses Firestore/Storage security rules
// entirely — that is exactly why it is the right tool for seed data, and
// exactly why this script must never run anywhere but the local emulator.
// It is not a rules test; nothing here asserts on permissions.
//
// Usage:
//   node seed.mjs             seed (idempotent — safe to run repeatedly)
//   node seed.mjs --wipe      clear the collections this script owns, then seed
//   node seed.mjs --force     seed even if no *_EMULATOR_HOST env var is set
//
// See README.md for the full explanation.

import admin from "firebase-admin";
import { seedOrganizerAnalytics } from "./seed-organizer-analytics.mjs";

// ── Safety rails ─────────────────────────────────────────────────────────────
// This script must never be pointed at production by accident. If nothing in
// the environment says "emulator", refuse to run unless the caller explicitly
// overrides with --force.

const args = process.argv.slice(2);
const FLAG_WIPE = args.includes("--wipe");
const FLAG_FORCE = args.includes("--force");

const PROJECT_ID = "nightride-a9173";

const DEFAULT_FIRESTORE_HOST = "127.0.0.1:8080";
const DEFAULT_AUTH_HOST = "127.0.0.1:9099";
const DEFAULT_STORAGE_HOST = "http://127.0.0.1:9199";

if (!process.env.FIRESTORE_EMULATOR_HOST && !FLAG_FORCE) {
  console.error(
    [
      "Refusing to run: FIRESTORE_EMULATOR_HOST is not set and --force was not passed.",
      "",
      "This script writes with the Admin SDK, which bypasses every security rule —",
      "it must only ever run against the local Firebase emulator, never production.",
      "",
      "Start the emulator suite first, or export FIRESTORE_EMULATOR_HOST yourself, e.g.:",
      `  export FIRESTORE_EMULATOR_HOST=${DEFAULT_FIRESTORE_HOST}`,
      `  export FIREBASE_AUTH_EMULATOR_HOST=${DEFAULT_AUTH_HOST}`,
      `  export STORAGE_EMULATOR_HOST=${DEFAULT_STORAGE_HOST}`,
      "",
      "Or, if you are certain the environment is already pointed at an emulator",
      "some other way, re-run with --force.",
    ].join("\n")
  );
  process.exit(1);
}

process.env.FIRESTORE_EMULATOR_HOST ??= DEFAULT_FIRESTORE_HOST;
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= DEFAULT_AUTH_HOST;
process.env.STORAGE_EMULATOR_HOST ??= DEFAULT_STORAGE_HOST;

console.log("Seeding Night Ride emulator data");
console.log(`  project:   ${PROJECT_ID}`);
console.log(`  firestore: ${process.env.FIRESTORE_EMULATOR_HOST}`);
console.log(`  auth:      ${process.env.FIREBASE_AUTH_EMULATOR_HOST}`);
console.log(`  storage:   ${process.env.STORAGE_EMULATOR_HOST}`);
console.log(`  wipe:      ${FLAG_WIPE}`);
console.log("");

const BUCKET_NAME = `${PROJECT_ID}.firebasestorage.app`;

admin.initializeApp({
  projectId: PROJECT_ID,
  storageBucket: BUCKET_NAME,
});

const db = admin.firestore();
const auth = admin.auth();
const bucket = admin.storage().bucket();

const { Timestamp, GeoPoint } = admin.firestore;

// ── Small helpers ────────────────────────────────────────────────────────────

/** Fixed, deterministic Timestamp from an ISO string — used for anything that
 * should stay byte-identical across reruns regardless of what day it is. */
function T(iso) {
  return Timestamp.fromDate(new Date(iso));
}

function geo(lat, lng) {
  return new GeoPoint(lat, lng);
}

// Standard 5-bit-per-character geohash encoder (base32), written inline so
// this script has no dependency beyond firebase-admin.
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

/** Build the emulator's local download URL for a Storage object — the same
 * shape the client SDK would get back from getDownloadURL(). No network
 * round-trip needed: the emulator serves any object at this URL by path. */
function emulatorDownloadUrl(objectPath) {
  return `${process.env.STORAGE_EMULATOR_HOST}/v0/b/${BUCKET_NAME}/o/${encodeURIComponent(
    objectPath
  )}?alt=media`;
}

// Anchor for the handful of fields that are deliberately relative to "now"
// (event startAt/endAt), so date-range queries in the app/webpanel have
// something to bite on regardless of which day this script actually runs.
// Everything else uses fixed ISO timestamps so reruns are byte-identical.
const RUN_TIME = new Date();

function daysFromNow(n, hourUTC = 20, minuteUTC = 0) {
  const d = new Date(RUN_TIME);
  d.setUTCDate(d.getUTCDate() + n);
  d.setUTCHours(hourUTC, minuteUTC, 0, 0);
  return Timestamp.fromDate(d);
}

function todayYMD() {
  return RUN_TIME.toISOString().slice(0, 10);
}

// A minimal, genuinely decodable 1x1 pixel baseline JPEG, hardcoded so this
// script never reaches out to the network for placeholder images.
const TINY_JPEG = Buffer.from(
  "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0a" +
    "HBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIy" +
    "MjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIA" +
    "AhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAj/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEB" +
    "AQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX" +
    "/9k=",
  "base64"
);

// ── Deterministic identities ─────────────────────────────────────────────────

const UID = {
  admin: "seed-admin-uid",
  rider: "seed-rider-uid",
  applicant: "seed-applicant-uid",
  organizer: "seed-organizer-uid",
  rejected: "seed-rejected-uid",
};

// Non-Auth teammate uids for the organizer dashboard's venue team — these
// don't need real Auth accounts for seed purposes, only stable ids that
// editorUids/editors/team can agree on.
const TEAM_UID = {
  manager: "seed-team-manager-uid",
  door: "seed-team-door-uid",
};

const ACCOUNTS = [
  {
    key: "admin",
    uid: UID.admin,
    email: "admin@nightride.test",
    password: "AdminSeed!123",
    displayName: "Admin Seed",
  },
  {
    key: "rider",
    uid: UID.rider,
    email: "rider@nightride.test",
    password: "RiderSeed!123",
    displayName: "Rider Seed",
  },
  {
    key: "applicant",
    uid: UID.applicant,
    email: "applicant@nightride.test",
    password: "ApplicantSeed!123",
    displayName: "Applicant Seed",
  },
  {
    key: "organizer",
    uid: UID.organizer,
    email: "organizer@nightride.test",
    password: "OrganizerSeed!123",
    displayName: "Organizer Seed",
  },
  {
    key: "rejected",
    uid: UID.rejected,
    email: "rejected@nightride.test",
    password: "RejectedSeed!123",
    displayName: "Rejected Seed",
  },
];

// Avatar URLs are pure functions of (uid, path) — no need to wait for the
// actual upload to know what they'll be, so user docs and Storage uploads
// can be written independently of one another.
const RIDER_AVATAR_PATH = `avatars/${UID.rider}.jpg`;
const ORGANIZER_AVATAR_PATH = `avatars/${UID.organizer}.jpg`;
const RIDER_AVATAR_URL = emulatorDownloadUrl(RIDER_AVATAR_PATH);
const ORGANIZER_AVATAR_URL = emulatorDownloadUrl(ORGANIZER_AVATAR_PATH);

// ── Venues (8) ────────────────────────────────────────────────────────────────
// Six OSM-seeded, two admin-added (one of which the organizer owns).

const VENUE_GEO = {
  baseDubai: [25.1972, 55.2744],
  sohoGardenDxb: [25.1552, 55.302],
  wombTokyo: [35.6567, 139.6993],
  contactTokyo: [35.6578, 139.6982],
  fabricLondon: [51.5203, -0.1027],
  ministryOfSound: [51.4959, -0.098],
  revolverUpstairs: [-37.8477, 144.9944],
  sunsetRooftopMelbourne: [-37.8226, 144.9648],
};

function venueGeo(key) {
  const [lat, lng] = VENUE_GEO[key];
  return { geo: geo(lat, lng), geohash: encodeGeohash(lat, lng, 9) };
}

function venueGeoLatLng(lat, lng) {
  return { geo: geo(lat, lng), geohash: encodeGeohash(lat, lng, 9) };
}

const MOCK_DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

/** Mirrors mock-data.ts's hours() helper: every day gets the same open/close,
 * closedDays get closed:true. */
function mockHours(closedDays, open, close) {
  return MOCK_DAYS.map((day) => ({ day, closed: closedDays.includes(day), open, close }));
}

const VENUE_CREATED = T("2026-01-10T08:00:00Z");
const VENUE_UPDATED = T("2026-08-10T21:00:00Z");

// IANA zone per city — small, hand-rolled, only covers the cities this seed
// data actually uses (matches migrate.mjs's backfill logic in spirit).
const CITY_TZ = {
  Dubai: "Asia/Dubai",
  Tokyo: "Asia/Tokyo",
  London: "Europe/London",
  Melbourne: "Australia/Melbourne",
};

/** Backfills editorUids/editors/capacity/timeZone on a venue fixture that
 * doesn't already set them, mirroring migrate.mjs's production backfill so
 * seed data is never a step behind what the migration guarantees. */
function withVenueAuth(v) {
  const ownerUid = typeof v.ownerUid === "string" && v.ownerUid ? v.ownerUid : null;
  return {
    ...v,
    editorUids: v.editorUids ?? (ownerUid ? [ownerUid] : []),
    editors: v.editors ?? (ownerUid ? { [ownerUid]: "owner" } : {}),
    capacity: v.capacity ?? 0,
    timeZone: v.timeZone ?? CITY_TZ[v.city] ?? "UTC",
  };
}

const RAW_VENUES = [
  {
    id: "osm_374829102",
    name: "Base Dubai",
    ...venueGeo("baseDubai"),
    type: "nightclub",
    typeLabel: "Night Club",
    city: "Dubai",
    countryCode: "AE",
    address: "The Address Downtown, Sheikh Mohammed Bin Rashid Blvd, Dubai",
    openingHours: "Th-Sa 22:00-04:00",
    phone: "+971 4 888 3444",
    website: "https://www.thebase.ae",
    photos: [
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/venues/osm_374829102/photo1.jpg",
    ],
    source: "osm",
    osmId: "374829102",
    ownerUid: null,
    verified: true,
    status: "active",
    live: {
      status: "open",
      crowdLevel: "busy",
      queueStatus: "moderate",
      ticketsAvailable: true,
      tablesAvailable: true,
      tonightDj: "DJ Khalid Live",
      offer: "",
      updatedAt: VENUE_UPDATED,
    },
  },
  {
    id: "osm_374829188",
    name: "Soho Garden DXB",
    ...venueGeo("sohoGardenDxb"),
    type: "nightclub",
    typeLabel: "Night Club",
    city: "Dubai",
    countryCode: "AE",
    address: "Meydan Racecourse, Nad Al Sheba, Dubai",
    openingHours: "We-Sa 21:00-03:00",
    phone: "+971 4 327 9922",
    website: "https://sohogardendxb.com",
    photos: [],
    source: "osm",
    osmId: "374829188",
    ownerUid: null,
    verified: true,
    status: "active",
    live: {
      status: "vipOnly",
      crowdLevel: "packed",
      queueStatus: "long",
      ticketsAvailable: false,
      tablesAvailable: true,
      tonightDj: "",
      offer: "Ladies free before 11pm",
      updatedAt: VENUE_UPDATED,
    },
  },
  {
    id: "osm_559011234",
    name: "Womb Tokyo",
    ...venueGeo("wombTokyo"),
    type: "nightclub",
    typeLabel: "Night Club",
    city: "Tokyo",
    countryCode: "JP",
    address: "2-16 Maruyamacho, Shibuya City, Tokyo",
    openingHours: "Fr-Sa 23:00-05:00",
    phone: "+81 3-5459-0039",
    website: "https://www.womb.co.jp",
    photos: [],
    source: "osm",
    osmId: "559011234",
    ownerUid: null,
    verified: true,
    status: "active",
    live: {
      status: "open",
      crowdLevel: "moderate",
      queueStatus: "short",
      ticketsAvailable: true,
      tablesAvailable: false,
      tonightDj: "",
      offer: "",
      updatedAt: VENUE_UPDATED,
    },
  },
  {
    id: "osm_559011356",
    name: "Contact Tokyo",
    ...venueGeo("contactTokyo"),
    type: "nightclub",
    typeLabel: "Night Club",
    city: "Tokyo",
    countryCode: "JP",
    address: "2-10-12 Dogenzaka, Shibuya City, Tokyo",
    openingHours: "Fr-Sa 23:00-04:30",
    phone: "+81 3-6427-8107",
    website: "https://www.contacttokyo.com",
    photos: [],
    source: "osm",
    osmId: "559011356",
    ownerUid: null,
    verified: false,
    status: "active",
    // No live map — this venue has never had its door status set.
  },
  {
    id: "osm_812345671",
    name: "Fabric London",
    ...venueGeo("fabricLondon"),
    type: "nightclub",
    typeLabel: "Night Club",
    city: "London",
    countryCode: "GB",
    address: "77a Charterhouse St, Farringdon, London",
    openingHours: "Fr-Sa 23:00-06:00",
    phone: "+44 20 7336 8898",
    website: "https://www.fabriclondon.com",
    photos: [],
    source: "osm",
    osmId: "812345671",
    ownerUid: null,
    verified: true,
    status: "active",
    live: {
      status: "closed",
      crowdLevel: "empty",
      queueStatus: "noQueue",
      ticketsAvailable: false,
      tablesAvailable: false,
      tonightDj: "",
      offer: "Reopening after refurbishment",
      updatedAt: VENUE_UPDATED,
    },
  },
  {
    id: "osm_812345842",
    name: "Ministry of Sound",
    ...venueGeo("ministryOfSound"),
    type: "nightclub",
    typeLabel: "Night Club",
    city: "London",
    countryCode: "GB",
    address: "103 Gaunt St, Elephant & Castle, London",
    openingHours: "Fr-Sa 23:00-06:00",
    phone: "+44 20 7740 8600",
    website: "https://www.ministryofsound.com",
    photos: [],
    source: "osm",
    osmId: "812345842",
    ownerUid: null,
    verified: false,
    status: "closed",
    // No live map — venue is currently marked closed in the seed data.
  },
  {
    id: "admin-revolver-upstairs",
    name: "Revolver Upstairs",
    ...venueGeo("revolverUpstairs"),
    type: "nightclub",
    typeLabel: "Night Club",
    city: "Melbourne",
    countryCode: "AU",
    address: "229 Chapel St, Prahran, Melbourne",
    openingHours: "Th-Su 22:00-07:00",
    phone: "+61 3 9521 5985",
    website: "https://www.revolverupstairs.com.au",
    photos: [],
    source: "admin",
    osmId: null,
    ownerUid: null,
    verified: true,
    status: "active",
    live: {
      status: "open",
      crowdLevel: "quiet",
      queueStatus: "noQueue",
      ticketsAvailable: true,
      tablesAvailable: true,
      tonightDj: "",
      offer: "",
      updatedAt: VENUE_UPDATED,
    },
  },
  {
    id: "admin-sunset-rooftop-melbourne",
    name: "Sunset Rooftop Melbourne",
    ...venueGeo("sunsetRooftopMelbourne"),
    type: "bar",
    typeLabel: "Rooftop Bar",
    city: "Melbourne",
    countryCode: "AU",
    address: "1 Southbank Promenade, Southbank, Melbourne",
    openingHours: "We-Su 17:00-01:00",
    phone: "+61 3 9000 1234",
    website: "https://sunsetrooftop.example.com",
    photos: [],
    source: "admin",
    osmId: null,
    ownerUid: UID.organizer,
    verified: true,
    status: "active",
    // No live map yet — the organizer hasn't set a door status.
  },

  // ── Organizer dashboard fixtures ─────────────────────────────────────────
  // Mirrors nightride-webpanel/lib/organizer/dashboard/mock-data.ts's
  // MOCK_VENUES verbatim (names, numbers, strings) so the wired dashboard
  // renders identically to the mock it replaces. `sirens` and `warehouse9`
  // are MOCK_VENUE_ORDER; the third is a fresh, unverified organizer venue
  // with no mock counterpart.
  {
    id: "sirens",
    name: "Sirens Dubai",
    ...venueGeoLatLng(25.0805, 55.1403),
    type: "nightclub",
    typeLabel: "Night Club",
    city: "Dubai",
    countryCode: "AE",
    address: "Marina Walk, Dubai Marina, Dubai, UAE",
    openingHours: "Th-Sa 22:00-04:00",
    phone: "",
    website: "",
    photos: [
      emulatorDownloadUrl("venuePhotos/sirens/hero.jpg"),
      emulatorDownloadUrl("venuePhotos/sirens/gallery/0.jpg"),
      emulatorDownloadUrl("venuePhotos/sirens/gallery/1.jpg"),
      emulatorDownloadUrl("venuePhotos/sirens/gallery/2.jpg"),
      emulatorDownloadUrl("venuePhotos/sirens/gallery/3.jpg"),
    ],
    source: "organizer",
    osmId: null,
    ownerUid: UID.organizer,
    verified: true,
    status: "active",
    about:
      "Rooftop techno and house on the Marina skyline. Open-air terrace, resident DJs Thu–Sat, and a strict door policy after 23:00.",
    socialLinks: [
      { network: "instagram", value: "@sirensdubai" },
      { network: "tiktok", value: "@sirensdubai" },
    ],
    genres: ["Techno", "House"],
    dressCode: "Smart Casual",
    agePolicy: "21+",
    cover: { min: 50, max: 150, currency: "AED" },
    capacity: 450,
    amenities: ["Rooftop", "Cloakroom"],
    hours: mockHours(["Mon", "Tue"], "22:00", "04:00"),
    exceptions: [{ label: "Eid Al Adha — Private Hire", date: "2026-08-19", closed: true }],
    tableLink: "https://booking.sirensdubai.com/reserve",
    editorUids: [UID.organizer, TEAM_UID.manager, TEAM_UID.door],
    editors: { [UID.organizer]: "owner", [TEAM_UID.manager]: "manager", [TEAM_UID.door]: "door" },
    verification: {
      license: { status: "done", attempt: 1, note: "", reviewedAt: VENUE_UPDATED, reviewedBy: UID.admin },
      gps: { status: "done", attempt: 1, note: "", reviewedAt: VENUE_UPDATED, reviewedBy: UID.admin },
      video: { status: "done", attempt: 1, note: "", reviewedAt: VENUE_UPDATED, reviewedBy: UID.admin },
    },
    live: {
      status: "open", // filling→open, capacity→soldOut, guestlist→vipOnly, open→open, closed→closed
      doorStatus: "open",
      crowdLevel: "packed", // 412/450 = 0.915 >= 0.90
      queueStatus: "moderate", // 15 min is 11-30
      ticketsAvailable: true,
      tablesAvailable: true,
      tonightDj: "DJ Kalima",
      offer: "",
      inVenue: 412,
      queueMinutes: 15,
      emergencyActive: false,
      flash: { active: false, text: "Free entry before midnight", until: "23:59" },
      updatedAt: VENUE_UPDATED,
    },
  },
  {
    id: "warehouse9",
    name: "Warehouse 9",
    ...venueGeoLatLng(35.6595, 139.7005),
    type: "nightclub",
    typeLabel: "Night Club",
    city: "Tokyo",
    countryCode: "JP",
    address: "9 Chome, Shibuya, Tokyo, Japan",
    openingHours: "Tu-Su 21:00-05:00",
    phone: "",
    website: "",
    photos: [
      emulatorDownloadUrl("venuePhotos/warehouse9/hero.jpg"),
      emulatorDownloadUrl("venuePhotos/warehouse9/gallery/0.jpg"),
      emulatorDownloadUrl("venuePhotos/warehouse9/gallery/1.jpg"),
      emulatorDownloadUrl("venuePhotos/warehouse9/gallery/2.jpg"),
      emulatorDownloadUrl("venuePhotos/warehouse9/gallery/3.jpg"),
    ],
    source: "organizer",
    osmId: null,
    ownerUid: UID.organizer,
    verified: true,
    status: "active",
    about:
      "Industrial main room built for deep house and techno. Outdoor terrace for smoke breaks, VIP tables on request.",
    socialLinks: [{ network: "instagram", value: "@warehouse9tokyo" }],
    genres: ["Deep House", "Techno", "Commercial"],
    dressCode: "Casual",
    agePolicy: "18+",
    cover: { min: 2000, max: 4000, currency: "JPY" },
    capacity: 600,
    amenities: ["Smoking Area", "VIP Tables", "Outdoor Terrace"],
    hours: mockHours(["Mon"], "21:00", "05:00"),
    exceptions: [{ label: "Closed for Renovation", date: "2026-09-01", closed: true }],
    tableLink: "",
    editorUids: [UID.organizer, TEAM_UID.manager, TEAM_UID.door],
    editors: { [UID.organizer]: "owner", [TEAM_UID.manager]: "manager", [TEAM_UID.door]: "door" },
    verification: {
      license: { status: "done", attempt: 1, note: "", reviewedAt: VENUE_UPDATED, reviewedBy: UID.admin },
      gps: { status: "done", attempt: 1, note: "", reviewedAt: VENUE_UPDATED, reviewedBy: UID.admin },
      video: { status: "done", attempt: 1, note: "", reviewedAt: VENUE_UPDATED, reviewedBy: UID.admin },
    },
    live: {
      status: "open",
      doorStatus: "open",
      crowdLevel: "moderate", // 180/600 = 0.30
      queueStatus: "short", // 5 min is 1-10
      ticketsAvailable: true,
      tablesAvailable: false,
      tonightDj: "Resident Crew",
      offer: "",
      inVenue: 180,
      queueMinutes: 5,
      emergencyActive: false,
      flash: null,
      updatedAt: VENUE_UPDATED,
    },
  },
  {
    id: "neon-annex",
    name: "Neon Fox Annex",
    ...venueGeoLatLng(25.0879, 55.1494),
    type: "bar",
    typeLabel: "Lounge",
    city: "Dubai",
    countryCode: "AE",
    address: "Business Bay, Dubai, UAE",
    openingHours: "",
    phone: "",
    website: "",
    photos: [],
    source: "organizer",
    osmId: null,
    ownerUid: UID.organizer,
    verified: false,
    status: "active",
    about: "",
    socialLinks: [],
    genres: [],
    dressCode: "",
    agePolicy: "",
    cover: { min: 0, max: 0, currency: "AED" },
    capacity: 0,
    amenities: [],
    hours: mockHours([], "20:00", "03:00"),
    exceptions: [],
    tableLink: "",
    editorUids: [UID.organizer],
    editors: { [UID.organizer]: "owner" },
    verification: {
      license: { status: "active", attempt: 0, note: "", reviewedAt: null, reviewedBy: null },
      gps: { status: "active", attempt: 0, note: "", reviewedAt: null, reviewedBy: null },
      video: { status: "active", attempt: 0, note: "", reviewedAt: null, reviewedBy: null },
    },
    // Deliberately no `live` map — this venue has never gone through admin
    // verification, so the organizer's editor unlocks but the app preview
    // and door-status controls do not.
  },
];

const VENUE_ID = {
  baseDubai: "osm_374829102",
  sohoGardenDxb: "osm_374829188",
  wombTokyo: "osm_559011234",
  contactTokyo: "osm_559011356",
  fabricLondon: "osm_812345671",
  ministryOfSound: "osm_812345842",
  revolverUpstairs: "admin-revolver-upstairs",
  sunsetRooftopMelbourne: "admin-sunset-rooftop-melbourne",
  sirens: "sirens",
  warehouse9: "warehouse9",
  neonAnnex: "neon-annex",
};

const VENUES = RAW_VENUES.map(withVenueAuth);

// ── Users ────────────────────────────────────────────────────────────────────

const USER_CREATED = T("2026-01-15T09:00:00Z");
const USER_UPDATED = T("2026-08-10T09:00:00Z");

function defaultOrganizerApplication(submittedAt) {
  return {
    submitted: false,
    submittedAt,
    profile: {
      orgName: "",
      venueName: "",
      instagram: "",
      website: "",
      bio: "",
      eventTypes: [],
      eventsPerMonth: 0,
    },
    steps: {
      venueAddress: null,
      nic: { uploaded: false },
      selfie: { uploaded: false },
      video: { uploaded: false },
      gps: { attempts: [] },
    },
  };
}

function baseUser(overrides) {
  return {
    email: "",
    displayName: "",
    username: "",
    pronouns: "",
    bio: "",
    city: "",
    countryCode: "",
    ageRange: "",
    avatarUrl: "",
    instagram: "",
    facebook: "",
    phone: "",
    interests: [],
    genres: [],
    vibes: [],
    features: [],
    rank: 0,
    streakDays: 0,
    partiesAttended: 0,
    friendsCount: 0,
    lastActiveDate: todayYMD(),
    isAdmin: false,
    organizerStatus: "none",
    organizerApplication: defaultOrganizerApplication(USER_CREATED),
    createdAt: USER_CREATED,
    updatedAt: USER_UPDATED,
    ...overrides,
  };
}

const APPLICANT_SUBMITTED_AT = T("2026-07-20T14:30:00Z");
const ORGANIZER_SUBMITTED_AT = T("2026-05-10T10:00:00Z");
const ORGANIZER_DECIDED_AT = T("2026-05-18T09:15:00Z");
const ORGANIZER_GPS_CAPTURED_AT = T("2026-05-17T18:00:00Z");
const REJECTED_SUBMITTED_AT = T("2026-06-01T11:00:00Z");
const REJECTED_DECIDED_AT = T("2026-06-10T16:45:00Z");
const REJECTED_NIC_REVIEWED_AT = T("2026-06-05T10:00:00Z");
const APPLICANT_SCRIPT_SENT_AT = T("2026-07-22T09:20:00Z");
const ORGANIZER_SCRIPT_SENT_AT = T("2026-05-14T09:20:00Z");

const USERS = {
  [UID.admin]: baseUser({
    email: "admin@nightride.test",
    displayName: "Admin Seed",
    username: "admin_seed",
    city: "Dubai",
    countryCode: "AE",
    ageRange: "25-34",
    isAdmin: true,
    organizerStatus: "none",
  }),

  [UID.rider]: baseUser({
    email: "rider@nightride.test",
    displayName: "Rider Seed",
    username: "rider_seed",
    pronouns: "she/her",
    bio: "Always chasing the next rooftop set.",
    city: "London",
    countryCode: "GB",
    ageRange: "25-34",
    avatarUrl: RIDER_AVATAR_URL,
    instagram: "@rider.nights",
    phone: "+44 7700 900123",
    interests: ["live music", "rooftop bars"],
    genres: ["House", "Techno"],
    vibes: ["upscale", "underground"],
    features: ["outdoorSeating"],
    rank: 120,
    streakDays: 6,
    partiesAttended: 14,
    friendsCount: 9,
    organizerStatus: "none",
  }),

  // Application submitted, awaiting an admin's first pass — see the
  // matching private/organizerReview doc below for the review-side shape.
  [UID.applicant]: baseUser({
    email: "applicant@nightride.test",
    displayName: "Applicant Seed",
    username: "applicant_seed",
    bio: "Running boutique lounge nights across Dubai.",
    city: "Dubai",
    countryCode: "AE",
    ageRange: "35-44",
    instagram: "@dunelounge",
    organizerStatus: "none",
    organizerApplication: {
      submitted: true,
      submittedAt: APPLICANT_SUBMITTED_AT,
      profile: {
        orgName: "Desert Nights Collective",
        venueName: "Dune Lounge Dubai",
        instagram: "@dunelounge",
        website: "https://dunelounge.ae",
        bio: "Boutique lounge collective running monthly desert-themed nights.",
        eventTypes: ["Lounge", "Live Music"],
        eventsPerMonth: 4,
      },
      steps: {
        venueAddress: {
          address: "Al Wasl Road, Jumeirah 1",
          city: "Dubai",
          countryCode: "AE",
          geo: geo(25.21, 55.253),
          placeId: "",
        },
        nic: { uploaded: true },
        selfie: { uploaded: true },
        video: { uploaded: true },
        gps: { attempts: [] },
      },
    },
  }),

  // Approved, owns admin-sunset-rooftop-melbourne.
  [UID.organizer]: baseUser({
    email: "organizer@nightride.test",
    displayName: "Organizer Seed",
    username: "organizer_seed",
    bio: "Golden-hour rooftop sessions in Melbourne CBD.",
    city: "Melbourne",
    countryCode: "AU",
    ageRange: "25-34",
    avatarUrl: ORGANIZER_AVATAR_URL,
    instagram: "@sunsetrooftopmel",
    phone: "+61 400 111 222",
    organizerStatus: "approved",
    organizerApplication: {
      submitted: true,
      submittedAt: ORGANIZER_SUBMITTED_AT,
      profile: {
        orgName: "Sunset Collective",
        venueName: "Sunset Rooftop Melbourne",
        instagram: "@sunsetrooftopmel",
        website: "https://sunsetrooftop.example.com",
        bio: "Rooftop party collective bringing golden-hour sessions to the CBD.",
        eventTypes: ["Rooftop", "House", "Live DJ"],
        eventsPerMonth: 6,
      },
      steps: {
        venueAddress: {
          address: "1 Southbank Promenade",
          city: "Melbourne",
          countryCode: "AU",
          geo: geo(-37.8226, 144.9648),
          placeId: "ChIJseed0000000000000001",
        },
        nic: { uploaded: true },
        selfie: { uploaded: true },
        video: { uploaded: true },
        gps: {
          attempts: [
            {
              point: geo(-37.8226, 144.9648),
              accuracyM: 8,
              mocked: false,
              capturedAt: ORGANIZER_GPS_CAPTURED_AT,
              attempt: 0,
            },
          ],
        },
      },
    },
  }),

  // Rejected after a failed NIC retry.
  [UID.rejected]: baseUser({
    email: "rejected@nightride.test",
    displayName: "Rejected Seed",
    username: "rejected_seed",
    bio: "Pop-up neon-themed bar nights.",
    city: "Tokyo",
    countryCode: "JP",
    ageRange: "18-24",
    instagram: "@neoncircuit",
    organizerStatus: "rejected",
    organizerApplication: {
      submitted: true,
      submittedAt: REJECTED_SUBMITTED_AT,
      profile: {
        orgName: "Neon Circuit",
        venueName: "Neon Circuit Bar",
        instagram: "@neoncircuit",
        website: "",
        bio: "Pop-up neon-themed bar nights.",
        eventTypes: ["Pop-up", "Electronic"],
        eventsPerMonth: 2,
      },
      steps: {
        venueAddress: {
          address: "Dogenzaka, Shibuya",
          city: "Tokyo",
          countryCode: "JP",
          geo: geo(35.6578, 139.6982),
          placeId: "",
        },
        nic: { uploaded: true },
        selfie: { uploaded: true },
        video: { uploaded: false },
        gps: { attempts: [] },
      },
    },
  }),
};

// ── users/{uid}/private/organizerReview ──────────────────────────────────────

function reviewStep(overrides) {
  return {
    status: "pending",
    attempt: 0,
    note: "",
    reviewedAt: null,
    reviewedBy: null,
    venueId: null,
    mediaDeletedAt: null,
    // video only — the walkthrough script an admin publishes to unlock it.
    script: null,
    ...overrides,
  };
}

/** A published walkthrough script — the thing that unlocks the video step. */
function walkthroughScript(sentAt) {
  return {
    format: "list",
    lines: [
      "Start outside: the street entrance with the venue name visible.",
      "Walk in through the main door and show the ID check position.",
      "Pan across the main floor.",
      "Show the bar, including the POS terminal.",
      "Walk to a fire exit and show that it is unobstructed.",
    ],
    revision: 0,
    updatedAt: sentAt,
    updatedBy: UID.admin,
  };
}

const ORGANIZER_REVIEWS = {
  // Exact required initial shape, except nic/selfie/video have moved to
  // 'submitted' because the applicant has uploaded evidence and it is
  // sitting in the admin's queue. gps is still 'pending' — it only starts
  // once an admin has accepted the venue address to measure a fix against.
  // video only got as far as 'submitted' because an admin had already sent a
  // walkthrough script; with no script it would still be 'pending'.
  [UID.applicant]: {
    status: "none",
    appliedAt: APPLICANT_SUBMITTED_AT,
    decidedAt: null,
    decidedBy: "",
    rejectionReason: "",
    phoneVerified: false,
    steps: {
      venueAddress: reviewStep({ status: "active" }),
      nic: reviewStep({ status: "submitted" }),
      selfie: reviewStep({ status: "submitted" }),
      video: reviewStep({
        status: "submitted",
        script: walkthroughScript(APPLICANT_SCRIPT_SENT_AT),
      }),
      gps: reviewStep({ status: "pending" }),
    },
    updatedAt: APPLICANT_SUBMITTED_AT,
  },

  [UID.organizer]: {
    status: "approved",
    appliedAt: ORGANIZER_SUBMITTED_AT,
    decidedAt: ORGANIZER_DECIDED_AT,
    decidedBy: UID.admin,
    rejectionReason: "",
    phoneVerified: true,
    steps: {
      venueAddress: reviewStep({
        status: "accepted",
        reviewedAt: ORGANIZER_DECIDED_AT,
        reviewedBy: UID.admin,
        venueId: VENUE_ID.sunsetRooftopMelbourne,
      }),
      nic: reviewStep({
        status: "accepted",
        reviewedAt: ORGANIZER_DECIDED_AT,
        reviewedBy: UID.admin,
      }),
      selfie: reviewStep({
        status: "accepted",
        reviewedAt: ORGANIZER_DECIDED_AT,
        reviewedBy: UID.admin,
      }),
      video: reviewStep({
        status: "accepted",
        reviewedAt: ORGANIZER_DECIDED_AT,
        reviewedBy: UID.admin,
        script: walkthroughScript(ORGANIZER_SCRIPT_SENT_AT),
      }),
      gps: reviewStep({
        status: "accepted",
        reviewedAt: ORGANIZER_DECIDED_AT,
        reviewedBy: UID.admin,
      }),
    },
    updatedAt: ORGANIZER_DECIDED_AT,
  },

  [UID.rejected]: {
    status: "rejected",
    appliedAt: REJECTED_SUBMITTED_AT,
    decidedAt: REJECTED_DECIDED_AT,
    decidedBy: UID.admin,
    rejectionReason:
      "Unable to verify identity after repeated invalid document submissions.",
    phoneVerified: false,
    steps: {
      venueAddress: reviewStep({ status: "active" }),
      // The needs_info history: the admin asked for a clearer resubmission
      // and advanced the attempt counter to open a fresh Storage path.
      nic: reviewStep({
        status: "needs_info",
        attempt: 1,
        note: "ID photo blurry — please resubmit clear photos of both sides of your NIC.",
        reviewedAt: REJECTED_NIC_REVIEWED_AT,
        reviewedBy: UID.admin,
      }),
      selfie: reviewStep({ status: "active" }),
      // Still 'pending' with no script: this application died on identity, and
      // never reaching the walkthrough is exactly the point of the gate.
      video: reviewStep({ status: "pending" }),
      gps: reviewStep({ status: "pending" }),
    },
    updatedAt: REJECTED_DECIDED_AT,
  },
};

// ── Rider subcollections: favourites + chat_sessions/messages ───────────────

const RIDER_FAVOURITES = [
  {
    // events/evt-07 — Fabric Presents: Bassline
    eventId: "evt-07",
    name: "Fabric Presents: Bassline",
    venueName: "Fabric London",
    city: "London",
    countryCode: "GB",
    coverImage:
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/events/evt-07/cover.jpg",
    genre: "Drum & Bass",
    startAt: daysFromNow(18, 23, 0),
    savedAt: T("2026-08-05T12:00:00Z"),
  },
  {
    // events/evt-11 — London Warehouse Rave
    eventId: "evt-11",
    name: "London Warehouse Rave",
    venueName: "Fabric London",
    city: "London",
    countryCode: "GB",
    coverImage:
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/events/evt-11/cover.jpg",
    genre: "Techno",
    startAt: daysFromNow(40, 23, 0),
    savedAt: T("2026-08-06T09:30:00Z"),
  },
];

const RIDER_CHAT_SESSION_ID = "seed-session-1";
const RIDER_CHAT_SESSION = {
  title: "Best spots for tonight?",
  createdAt: T("2026-08-09T20:00:00Z"),
  updatedAt: T("2026-08-09T20:04:00Z"),
};
const RIDER_CHAT_MESSAGES = [
  {
    id: "msg-1",
    role: "user",
    text: "What's a good techno night in London this weekend?",
    at: T("2026-08-09T20:00:00Z"),
  },
  {
    id: "msg-2",
    role: "assistant",
    text: "Fabric has a Bassline night coming up, and there's a warehouse rave listed too — want details on either?",
    at: T("2026-08-09T20:02:00Z"),
  },
  {
    id: "msg-3",
    role: "user",
    text: "Send me the warehouse rave one.",
    at: T("2026-08-09T20:04:00Z"),
  },
];

// ── Events (12) ───────────────────────────────────────────────────────────────

const EVENT_CREATED = T("2026-07-01T08:00:00Z");
const EVENT_UPDATED = T("2026-08-01T08:00:00Z");

function defaultPolicies() {
  return {
    ageRestriction: 0,
    refundPolicy: "",
    reEntryAllowed: false,
    wheelchairAccessible: false,
    allowPets: false,
  };
}

function venueFields(key) {
  const v = VENUES.find((venue) => venue.id === VENUE_ID[key]);
  return {
    venueId: v.id,
    venueName: v.name,
    city: v.city,
    countryCode: v.countryCode,
    geo: v.geo,
  };
}

function baseEvent(overrides) {
  return {
    name: "",
    description: "",
    venueId: null,
    venueName: "",
    city: "",
    countryCode: "",
    geo: null,
    startAt: null,
    endAt: null,
    price: { min: 0, max: 0, currency: "USD", isFree: false },
    ticketUrl: "",
    coverImage: "",
    genre: "",
    category: "",
    vibe: "",
    language: "en",
    performers: [],
    policies: defaultPolicies(),
    interestedCount: 0,
    popularityScore: 0,
    status: "published",
    source: "admin",
    organizerUid: null,
    // `live` is never stored — derived at render from status/startAt/endAt.
    scheduledPublish: null, // required non-null iff status == 'scheduled'
    cancelReason: "", // required non-empty iff status == 'cancelled'
    notifyOnChange: true,
    recurring: false,
    recurrenceLabel: "",
    posterImage: "", // coverImage stays the card hero
    tickets: { currency: "USD", tiers: [] },
    moderation: { flag: "", requestedAt: null, eta: null, reviewedBy: null, note: "" },
    sales: { sold: 0, gross: 0, currency: "USD", updatedAt: null }, // null == no producer has run
    createdAt: EVENT_CREATED,
    updatedAt: EVENT_UPDATED,
    ...overrides,
  };
}

const EVENTS = [
  // ── Organizer-owned (Sunset Rooftop Melbourne) ───────────────────────────
  baseEvent({
    id: "evt-01",
    name: "Sunset Sessions Vol. 1",
    description: "Golden-hour house set on the Southbank rooftop.",
    ...venueFields("sunsetRooftopMelbourne"),
    startAt: daysFromNow(10, 19, 0),
    endAt: daysFromNow(11, 1, 0),
    price: { min: 80, max: 80, currency: "AUD", isFree: false },
    ticketUrl: "https://tickets.example.com/sunset-sessions-1",
    coverImage:
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/events/evt-01/cover.jpg",
    genre: "House",
    category: "rooftop",
    vibe: "chill",
    status: "draft",
    source: "organizer",
    organizerUid: UID.organizer,
  }),
  baseEvent({
    id: "evt-02",
    name: "Sunset Sessions Vol. 2",
    description: "Second edition of the rooftop's signature sunset-to-midnight run.",
    ...venueFields("sunsetRooftopMelbourne"),
    startAt: daysFromNow(24, 19, 0),
    endAt: daysFromNow(25, 0, 0),
    price: { min: 90, max: 120, currency: "AUD", isFree: false },
    ticketUrl: "https://tickets.example.com/sunset-sessions-2",
    coverImage:
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/events/evt-02/cover.jpg",
    genre: "House",
    category: "rooftop",
    vibe: "upscale",
    performers: [
      {
        name: "Ari Nova",
        type: "DJ",
        bio: "Melbourne-based house selector known for sunset-to-midnight sets.",
      },
    ],
    policies: {
      ageRestriction: 18,
      refundPolicy: "Refundable up to 48 hours before the event.",
      reEntryAllowed: true,
      wheelchairAccessible: true,
      allowPets: false,
    },
    status: "published",
    source: "organizer",
    organizerUid: UID.organizer,
  }),
  baseEvent({
    id: "evt-03",
    name: "NYE Rooftop Countdown",
    description: "Ring in the new year with a Southbank skyline countdown set.",
    ...venueFields("sunsetRooftopMelbourne"),
    startAt: daysFromNow(42, 20, 0),
    endAt: daysFromNow(43, 2, 0),
    price: { min: 150, max: 250, currency: "AUD", isFree: false },
    ticketUrl: "https://tickets.example.com/nye-rooftop",
    coverImage:
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/events/evt-03/cover.jpg",
    genre: "House",
    category: "rooftop",
    vibe: "festive",
    status: "published",
    source: "organizer",
    organizerUid: UID.organizer,
  }),

  // ── Admin-entered ─────────────────────────────────────────────────────────
  baseEvent({
    id: "evt-04",
    name: "Dubai Nightlife Expo Afterparty",
    description: "Official afterparty for the Dubai Nightlife Expo.",
    ...venueFields("baseDubai"),
    startAt: daysFromNow(-2, 22, 0),
    endAt: daysFromNow(-1, 4, 0),
    price: { min: 150, max: 400, currency: "AED", isFree: false },
    ticketUrl: "https://tickets.example.com/dubai-expo-afterparty",
    coverImage:
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/events/evt-04/cover.jpg",
    genre: "House",
    category: "nightclub",
    vibe: "upscale",
    performers: [
      {
        name: "DJ Khalid Live",
        type: "DJ",
        bio: "Resident DJ known for Arabic house fusion sets.",
      },
    ],
    policies: {
      ageRestriction: 21,
      refundPolicy: "No refunds within 48 hours of the event.",
      reEntryAllowed: false,
      wheelchairAccessible: true,
      allowPets: false,
    },
    interestedCount: 3,
    status: "published",
    source: "admin",
  }),
  baseEvent({
    id: "evt-05",
    name: "Neon Nights Warehouse",
    description: "Free-entry warehouse night in Meydan.",
    ...venueFields("sohoGardenDxb"),
    startAt: daysFromNow(12, 22, 0),
    endAt: daysFromNow(13, 3, 0),
    price: { min: 0, max: 0, currency: "AED", isFree: true },
    ticketUrl: "",
    coverImage:
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/events/evt-05/cover.jpg",
    genre: "Techno",
    category: "nightclub",
    vibe: "underground",
    policies: {
      ageRestriction: 21,
      refundPolicy: "",
      reEntryAllowed: true,
      wheelchairAccessible: false,
      allowPets: false,
    },
    status: "published",
    source: "admin",
  }),
  baseEvent({
    id: "evt-06",
    name: "Shibuya Underground",
    description: "Late-night underground techno at Womb.",
    ...venueFields("wombTokyo"),
    startAt: daysFromNow(-1, 23, 0),
    endAt: daysFromNow(0, 5, 0),
    price: { min: 3000, max: 6000, currency: "JPY", isFree: false },
    ticketUrl: "https://tickets.example.com/shibuya-underground",
    coverImage:
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/events/evt-06/cover.jpg",
    genre: "Techno",
    category: "nightclub",
    vibe: "underground",
    status: "published",
    source: "admin",
  }),
  baseEvent({
    id: "evt-07",
    name: "Fabric Presents: Bassline",
    description: "A drum & bass and jungle double bill at fabric.",
    ...venueFields("fabricLondon"),
    startAt: daysFromNow(18, 23, 0),
    endAt: daysFromNow(19, 6, 0),
    price: { min: 20, max: 35, currency: "GBP", isFree: false },
    ticketUrl: "https://tickets.example.com/fabric-bassline",
    coverImage:
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/events/evt-07/cover.jpg",
    genre: "Drum & Bass",
    category: "nightclub",
    vibe: "underground",
    performers: [
      {
        name: "Sub Motive",
        type: "DJ",
        bio: "Bass-heavy drum & bass producer and touring DJ.",
      },
      {
        name: "Echo Ward",
        type: "DJ",
        bio: "Jungle revivalist known for vinyl-only sets.",
      },
    ],
    policies: {
      ageRestriction: 18,
      refundPolicy: "Non-refundable.",
      reEntryAllowed: false,
      wheelchairAccessible: true,
      allowPets: false,
    },
    status: "published",
    source: "admin",
  }),
  baseEvent({
    id: "evt-08",
    name: "Ministry Reopening Gala",
    description: "Invite-only preview ahead of the public reopening.",
    ...venueFields("ministryOfSound"),
    startAt: daysFromNow(30, 21, 0),
    endAt: daysFromNow(31, 4, 0),
    price: { min: 40, max: 75, currency: "GBP", isFree: false },
    ticketUrl: "https://tickets.example.com/ministry-reopening",
    coverImage:
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/events/evt-08/cover.jpg",
    genre: "House",
    category: "nightclub",
    vibe: "upscale",
    status: "draft",
    source: "admin",
  }),

  // ── Scraped (non-zero popularityScore) ───────────────────────────────────
  baseEvent({
    id: "evt-09",
    name: "Late Night Sessions - Contact",
    description: "Weekly late-night session scraped from Contact Tokyo's listings.",
    ...venueFields("contactTokyo"),
    startAt: daysFromNow(3, 23, 0),
    endAt: daysFromNow(4, 5, 0),
    price: { min: 2500, max: 4500, currency: "JPY", isFree: false },
    ticketUrl: "https://tickets.example.com/contact-late-night",
    coverImage:
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/events/evt-09/cover.jpg",
    genre: "Techno",
    category: "nightclub",
    vibe: "underground",
    policies: {
      ageRestriction: 20,
      refundPolicy: "",
      reEntryAllowed: true,
      wheelchairAccessible: false,
      allowPets: false,
    },
    popularityScore: 55,
    status: "published",
    source: "scraped",
  }),
  baseEvent({
    id: "evt-10",
    name: "Melbourne Laneway Afterdark",
    description: "Laneway-to-club crawl finishing at Revolver Upstairs.",
    ...venueFields("revolverUpstairs"),
    startAt: daysFromNow(9, 22, 0),
    endAt: daysFromNow(10, 5, 0),
    price: { min: 25, max: 45, currency: "AUD", isFree: false },
    ticketUrl: "https://tickets.example.com/laneway-afterdark",
    coverImage:
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/events/evt-10/cover.jpg",
    genre: "Indie Dance",
    category: "nightclub",
    vibe: "underground",
    interestedCount: 5,
    popularityScore: 63,
    status: "published",
    source: "scraped",
  }),
  baseEvent({
    id: "evt-11",
    name: "London Warehouse Rave",
    description: "Unlicensed-feel warehouse techno night, scraped listing.",
    ...venueFields("fabricLondon"),
    startAt: daysFromNow(40, 23, 0),
    endAt: daysFromNow(41, 6, 0),
    price: { min: 15, max: 30, currency: "GBP", isFree: false },
    ticketUrl: "https://tickets.example.com/london-warehouse-rave",
    coverImage:
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/events/evt-11/cover.jpg",
    genre: "Techno",
    category: "warehouse",
    vibe: "underground",
    performers: [
      {
        name: "Nyx Larsen",
        type: "DJ",
        bio: "Warehouse techno mainstay with releases on several UK labels.",
      },
    ],
    interestedCount: 4,
    popularityScore: 91,
    status: "published",
    source: "scraped",
  }),
  baseEvent({
    id: "evt-12",
    name: "Dubai Desert Sunrise Set",
    description: "Sunrise closing set on the edge of the desert, scraped listing.",
    ...venueFields("baseDubai"),
    startAt: daysFromNow(41, 3, 0),
    endAt: daysFromNow(41, 7, 0),
    price: { min: 100, max: 250, currency: "AED", isFree: false },
    ticketUrl: "https://tickets.example.com/dubai-sunrise",
    coverImage:
      "https://storage.googleapis.com/nightride-a9173.firebasestorage.app/events/evt-12/cover.jpg",
    genre: "Melodic Techno",
    category: "outdoor",
    vibe: "chill",
    popularityScore: 40,
    status: "published",
    source: "scraped",
  }),

  // ── Organizer dashboard fixtures (sirens / warehouse9) ───────────────────
  // Mirror nightride-webpanel's MOCK_EVENTS verbatim (e1-e4), plus one
  // cancelled event with a reason (not in the mock — exercises the new
  // status). `price` is the client-derived min/max/isFree over `tickets.tiers`.
  baseEvent({
    id: "e1",
    name: "Full Moon Rooftop",
    description: "",
    ...venueFields("sirens"),
    startAt: T("2026-08-08T22:00:00+04:00"),
    endAt: T("2026-08-09T04:00:00+04:00"),
    price: { min: 80, max: 120, currency: "AED", isFree: false },
    performers: [
      { name: "DJ Kalima", type: "DJ", bio: "" },
      { name: "Nyx", type: "DJ", bio: "" },
    ],
    tickets: {
      currency: "AED",
      tiers: [
        { name: "Early Bird", price: 80, qty: 100 },
        { name: "General", price: 120, qty: 300 },
      ],
    },
    sales: { sold: 268, gross: 21440, currency: "AED", updatedAt: EVENT_UPDATED },
    moderation: { flag: "clean", requestedAt: EVENT_CREATED, eta: null, reviewedBy: UID.admin, note: "" },
    notifyOnChange: true,
    status: "published",
    source: "organizer",
    organizerUid: UID.organizer,
  }),
  baseEvent({
    id: "e2",
    name: "Techno Fridays",
    description: "",
    ...venueFields("warehouse9"),
    startAt: T("2026-08-14T23:00:00+09:00"),
    endAt: T("2026-08-15T05:00:00+09:00"),
    price: { min: 3000, max: 3000, currency: "JPY", isFree: false },
    performers: [{ name: "Resident Crew", type: "DJ", bio: "" }],
    tickets: { currency: "JPY", tiers: [{ name: "Door", price: 3000, qty: 400 }] },
    sales: { sold: 112, gross: 336000, currency: "JPY", updatedAt: EVENT_UPDATED },
    moderation: { flag: "clean", requestedAt: EVENT_CREATED, eta: null, reviewedBy: UID.admin, note: "" },
    recurring: true,
    recurrenceLabel: "Every Friday",
    notifyOnChange: true,
    status: "published",
    source: "organizer",
    organizerUid: UID.organizer,
  }),
  baseEvent({
    id: "e3",
    name: "Sunset to Sunrise",
    description: "",
    ...venueFields("sirens"),
    startAt: T("2026-08-16T20:00:00+04:00"),
    endAt: T("2026-08-17T06:00:00+04:00"),
    price: { min: 100, max: 100, currency: "AED", isFree: false },
    performers: [{ name: "Anya Frost", type: "DJ", bio: "" }],
    tickets: { currency: "AED", tiers: [{ name: "General", price: 100, qty: 250 }] },
    moderation: {
      flag: "pending",
      requestedAt: T("2026-08-05T12:00:00Z"),
      eta: T("2026-08-05T14:00:00Z"),
      reviewedBy: null,
      note: "",
    },
    notifyOnChange: true,
    status: "in_review",
    source: "organizer",
    organizerUid: UID.organizer,
  }),
  baseEvent({
    id: "e4",
    name: "Members Only: Vol. 3",
    description: "",
    ...venueFields("warehouse9"),
    startAt: T("2026-08-22T22:00:00+09:00"),
    endAt: T("2026-08-23T05:00:00+09:00"),
    scheduledPublish: T("2026-08-19T18:00:00+09:00"),
    notifyOnChange: true,
    status: "scheduled",
    source: "organizer",
    organizerUid: UID.organizer,
  }),
  baseEvent({
    id: "e5",
    name: "Ladies Night Vol. 4",
    description: "",
    ...venueFields("sirens"),
    startAt: T("2026-08-21T22:00:00+04:00"),
    endAt: T("2026-08-22T04:00:00+04:00"),
    cancelReason: "Venue double-booked for a private buyout.",
    notifyOnChange: true,
    status: "cancelled",
    source: "organizer",
    organizerUid: UID.organizer,
  }),
];

// Fake "fan" uids used only to populate interested/upvote marker
// subcollections so counters aren't lies. These are not real Auth accounts —
// the schema only requires the marker doc to exist at events/{id}/interested/{uid}.
const FAN_UIDS = [
  "seed-fan-01",
  "seed-fan-02",
  "seed-fan-03",
  "seed-fan-04",
  "seed-fan-05",
];

const EVENT_INTERESTED = {
  "evt-04": FAN_UIDS.slice(0, 3),
  "evt-10": FAN_UIDS.slice(0, 5),
  "evt-11": FAN_UIDS.slice(0, 4),
};

// ── Venue reports (20) ────────────────────────────────────────────────────────

const REPORT_AUTHORS = [
  { uid: UID.rider, username: "Rider Seed", avatarUrl: RIDER_AVATAR_URL },
  { uid: UID.organizer, username: "Organizer Seed", avatarUrl: ORGANIZER_AVATAR_URL },
  { uid: "seed-fan-01", username: "nightowl_01", avatarUrl: "" },
  { uid: "seed-fan-02", username: "nightowl_02", avatarUrl: "" },
  { uid: "seed-fan-03", username: "nightowl_03", avatarUrl: "" },
  { uid: "seed-fan-04", username: "nightowl_04", avatarUrl: "" },
  { uid: "seed-fan-05", username: "nightowl_05", avatarUrl: "" },
  { uid: "seed-fan-06", username: "nightowl_06", avatarUrl: "" },
];

const REPORT_VENUES = [
  "baseDubai",
  "sohoGardenDxb",
  "wombTokyo",
  "contactTokyo",
  "fabricLondon",
  "ministryOfSound",
  "revolverUpstairs",
  "sunsetRooftopMelbourne",
];

const REPORT_TAGS = ["crowd", "music", "service", "value", "vibe", "safety", "queue", "drinks"];

const REPORT_COMMENTS = [
  "",
  "Line moved fast tonight, worth it.",
  "",
  "Music was a bit too commercial for my taste.",
  "Bar staff were slammed, 20 min for a drink.",
  "",
  "Best sound system in the city, hands down.",
  "Great vibe but pricey drinks.",
  "",
  "Bouncers were strict about dress code, be warned.",
  "Packed by midnight, get there early.",
  "",
  "Rooftop view alone is worth the cover charge.",
  "Decent but nothing special this time.",
  "",
  "Loved the DJ selection tonight.",
  "A bit empty for a Friday, might've been the weather.",
  "",
  "Smooth entry, friendly staff.",
  "Would come back, solid all-round night.",
];

const REPORT_UPVOTES = {
  "report-01": ["seed-fan-01", "seed-fan-02"],
  "report-04": ["seed-fan-03"],
  "report-07": ["seed-fan-01", "seed-fan-04", "seed-fan-05"],
  "report-10": ["seed-fan-02"],
  "report-13": ["seed-fan-01", "seed-fan-03"],
  "report-16": ["seed-fan-06"],
  "report-19": ["seed-fan-02", "seed-fan-04"],
};

const REPORT_CREATED_BASE = new Date("2026-08-01T18:00:00Z").getTime();

const VENUE_REPORTS = Array.from({ length: 20 }, (_, i) => {
  const n = i + 1;
  const id = `report-${String(n).padStart(2, "0")}`;
  const venueKey = REPORT_VENUES[i % REPORT_VENUES.length];
  const venue = VENUES.find((v) => v.id === VENUE_ID[venueKey]);
  const author = REPORT_AUTHORS[i % REPORT_AUTHORS.length];
  const vibeRating = (i % 5) + 1;
  const upvoters = REPORT_UPVOTES[id] ?? [];
  return {
    id,
    venueId: venue.id,
    uid: author.uid,
    username: author.username,
    avatarUrl: author.avatarUrl,
    city: venue.city,
    countryCode: venue.countryCode,
    tag: REPORT_TAGS[i % REPORT_TAGS.length],
    vibeRating,
    comment: REPORT_COMMENTS[i % REPORT_COMMENTS.length],
    upvoteCount: upvoters.length,
    upvoters,
    createdAt: Timestamp.fromMillis(REPORT_CREATED_BASE + i * 3600_000),
  };
});

// Two extra reports on the organizer's own venue exercising the new reply /
// flaggedByOwner fields from the appended spec (A3 venueReports).
const EXTRA_VENUE_REPORTS = [
  {
    id: "report-21",
    venueId: VENUE_ID.sirens,
    uid: "seed-fan-01",
    username: "@mira_k",
    avatarUrl: "",
    city: "Dubai",
    countryCode: "AE",
    tag: "vibe",
    vibeRating: 5,
    comment: "Best rooftop set of the summer. Door was quick even at 1am.",
    reply: { text: "Thank you! Kalima is back the first Friday of every month.", byUid: UID.organizer, byName: "Rana Aziz", at: T("2026-08-06T10:00:00Z") },
    flaggedByOwner: false,
    upvoteCount: 3,
    upvoters: ["seed-fan-02", "seed-fan-03", "seed-fan-04"],
    createdAt: T("2026-08-05T20:00:00Z"),
  },
  {
    id: "report-22",
    venueId: VENUE_ID.sirens,
    uid: "seed-fan-02",
    username: "@johndoe22",
    avatarUrl: "",
    city: "Dubai",
    countryCode: "AE",
    tag: "safety",
    vibeRating: 1,
    comment: "Obvious spam review with a promo link.",
    reply: null,
    flaggedByOwner: true,
    upvoteCount: 0,
    upvoters: [],
    createdAt: T("2026-08-06T09:00:00Z"),
  },
];

const ALL_VENUE_REPORTS = [...VENUE_REPORTS, ...EXTRA_VENUE_REPORTS];

// ── Organizer dashboard: venueEdits, subcollections, inbox, analytics ────────

const VENUE_EDITS = [
  {
    // Document id IS the venue id — the reviewable listing draft.
    venueId: VENUE_ID.sirens,
    status: "pending",
    listing: {
      about:
        "Rooftop techno and house on the Marina skyline. Open-air terrace, resident DJs Thu–Sat, and a strict door policy after 23:00. Now serving a late-night tapas menu.",
      socialLinks: [
        { network: "instagram", value: "@sirensdubai" },
        { network: "tiktok", value: "@sirensdubai" },
      ],
      genres: ["Techno", "House"],
      dressCode: "Smart Casual",
      agePolicy: "21+",
      cover: { min: 50, max: 150, currency: "AED" },
      capacity: 450,
      amenities: ["Rooftop", "Cloakroom", "Late-night kitchen"],
      hours: mockHours(["Mon", "Tue"], "22:00", "04:00"),
      exceptions: [{ label: "Eid Al Adha — Private Hire", date: "2026-08-19", closed: true }],
      photos: [
        emulatorDownloadUrl("venuePhotos/sirens/hero.jpg"),
        emulatorDownloadUrl("venuePhotos/sirens/gallery/0.jpg"),
        emulatorDownloadUrl("venuePhotos/sirens/gallery/1.jpg"),
        emulatorDownloadUrl("venuePhotos/sirens/gallery/2.jpg"),
        emulatorDownloadUrl("venuePhotos/sirens/gallery/3.jpg"),
      ],
      timeZone: "Asia/Dubai",
    },
    submittedBy: TEAM_UID.manager,
    submittedAt: T("2026-08-10T09:00:00Z"),
    reviewedBy: null,
    reviewedAt: null,
    note: "",
  },
];

const MENU_SECTIONS = {
  sirens: [
    {
      id: "ms1",
      name: "Bottle service & tables",
      order: 0,
      items: [
        { id: "mi1", name: "Skyline table — Grey Goose", price: 3200, desc: "Reserved terrace table with skyline view, two mixers per bottle.", size: "1.5L magnum", serves: "6", tags: ["Signature"], nights: [4, 5], soldOut: false, image: emulatorDownloadUrl("venuePhotos/sirens/menu/0.jpg") },
        { id: "mi2", name: "Dom Pérignon 2013", price: 2900, desc: "Served with sparklers on request.", size: "75cl", serves: "4", tags: [], nights: [], soldOut: false, image: "" },
        { id: "mi3", name: "Booth minimum — main deck", price: 1500, desc: "Minimum spend, redeemable against anything on the menu.", size: "", serves: "8", tags: [], nights: [3, 4, 5], soldOut: true, image: "" },
      ],
      updatedAt: VENUE_UPDATED,
    },
    {
      id: "ms2",
      name: "Cocktails",
      order: 1,
      items: [
        { id: "mi4", name: "Marasi Spritz", price: 75, desc: "Aperol, cava, blood orange, rosemary smoke.", size: "", serves: "", tags: ["Signature"], nights: [], soldOut: false, image: "" },
        { id: "mi5", name: "Sober Sunset", price: 45, desc: "Seedlip, passionfruit, lime, soda.", size: "", serves: "", tags: ["Alcohol-free", "New"], nights: [], soldOut: false, image: "" },
      ],
      updatedAt: VENUE_UPDATED,
    },
    {
      id: "ms3",
      name: "Food",
      order: 2,
      items: [
        { id: "mi6", name: "Wagyu sliders (3)", price: 95, desc: "Truffle mayo, aged cheddar, brioche.", size: "", serves: "2", tags: ["Halal"], nights: [], soldOut: false, image: "" },
        { id: "mi7", name: "Charred padrón peppers", price: 40, desc: "Sea salt, lemon.", size: "", serves: "", tags: ["Vegan"], nights: [], soldOut: false, image: "" },
      ],
      updatedAt: VENUE_UPDATED,
    },
    {
      id: "ms4",
      name: "Happy hour",
      order: 3,
      items: [
        { id: "mi8", name: "Two-for-one house pours", price: 55, desc: "House spirits and wines by the glass.", size: "", serves: "", tags: [], nights: [3, 4], soldOut: false, image: "" },
      ],
      updatedAt: VENUE_UPDATED,
    },
  ],
  warehouse9: [
    {
      id: "mw1",
      name: "Bar",
      order: 0,
      items: [
        { id: "mwi1", name: "Beer bucket", price: 4500, desc: "Five bottles on ice.", size: "5 × 33cl", serves: "3", tags: [], nights: [5, 6], soldOut: false, image: emulatorDownloadUrl("venuePhotos/warehouse9/menu/0.jpg") },
        { id: "mwi2", name: "Espresso martini", price: 1800, desc: "Double shot, house cold brew.", size: "", serves: "", tags: ["Signature"], nights: [], soldOut: false, image: "" },
      ],
      updatedAt: VENUE_UPDATED,
    },
    {
      id: "mw2",
      name: "Late food",
      order: 1,
      items: [
        { id: "mwi3", name: "Loaded fries", price: 1200, desc: "Served until 04:00 from the yard hatch.", size: "", serves: "2", tags: ["Vegan"], nights: [], soldOut: false, image: "" },
      ],
      updatedAt: VENUE_UPDATED,
    },
  ],
};

const ACTIVITY = {
  sirens: [
    { actorUid: UID.organizer, actorName: "Rana Aziz", what: "Set live status to Filling Up (Sirens Dubai)", targetType: "venue", targetId: VENUE_ID.sirens, at: T("2026-08-04T23:10:00Z") },
    { actorUid: TEAM_UID.manager, actorName: "Marco Reyes", what: "Changed Sunset to Sunrise price tier", targetType: "event", targetId: "e3", at: T("2026-08-05T14:02:00Z") },
    { actorUid: TEAM_UID.door, actorName: "Leila Haddad", what: "Marked Booth minimum sold out", targetType: "menuItem", targetId: "mi3", at: T("2026-08-05T21:30:00Z") },
    { actorUid: UID.organizer, actorName: "Rana Aziz", what: "Replied to a review from @mira_k", targetType: "venueReport", targetId: "report-21", at: T("2026-08-06T10:00:00Z") },
  ],
  warehouse9: [
    { actorUid: TEAM_UID.manager, actorName: "Marco Reyes", what: "Published Techno Fridays (Aug 14)", targetType: "event", targetId: "e2", at: T("2026-08-02T09:44:00Z") },
    { actorUid: TEAM_UID.door, actorName: "Leila Haddad", what: "Scheduled Members Only: Vol. 3 for Aug 19 publish", targetType: "event", targetId: "e4", at: T("2026-08-03T11:00:00Z") },
  ],
};

const TEAM = {
  sirens: [
    { id: "tm1", uid: UID.organizer, name: "Rana Aziz", email: "rana@sirensdubai.com", role: "owner", invitedBy: null, invitedAt: T("2026-01-10T08:00:00Z"), acceptedAt: T("2026-01-10T08:00:00Z") },
    { id: "tm2", uid: TEAM_UID.manager, name: "Marco Reyes", email: "marco@sirensdubai.com", role: "manager", invitedBy: UID.organizer, invitedAt: T("2026-02-01T08:00:00Z"), acceptedAt: T("2026-02-02T09:00:00Z") },
    { id: "tm3", uid: TEAM_UID.door, name: "Leila Haddad", email: "leila@sirensdubai.com", role: "door", invitedBy: UID.organizer, invitedAt: T("2026-02-10T08:00:00Z"), acceptedAt: T("2026-02-11T10:00:00Z") },
  ],
};

const VENUE_INVITES = [
  {
    id: "invite-01",
    venueId: VENUE_ID.warehouse9,
    venueName: "Warehouse 9",
    email: "kenji@warehouse9tokyo.jp",
    role: "door",
    invitedBy: UID.organizer,
    invitedAt: T("2026-08-09T08:00:00Z"),
    expiresAt: T("2026-08-23T08:00:00Z"),
    acceptedAt: null,
    acceptedByUid: null,
  },
];

const ORGANIZER_INBOX = [
  {
    id: "m1",
    subject: "Photo policy reminder",
    from: "Trust & Safety",
    type: "policy",
    body: "Hero images must show the actual venue interior or entrance — stock photos will be removed.",
    venueId: VENUE_ID.sirens,
    at: T("2026-08-03T09:00:00Z"),
    readAt: T("2026-08-03T10:00:00Z"),
  },
  {
    id: "m2",
    subject: "Event flagged for review: Sunset to Sunrise",
    from: "Content Review",
    type: "violation",
    body: "Automated scan flagged the lineup name for duplicate-event review. ETA ~2h.",
    venueId: VENUE_ID.sirens,
    at: T("2026-08-05T12:00:00Z"),
    readAt: null, // the one unread message
  },
  {
    id: "m3",
    subject: "Appeal decision: Warehouse 9 listing",
    from: "Trust & Safety",
    type: "appeal",
    body: "Your appeal was upheld — the listing has been reinstated.",
    venueId: VENUE_ID.warehouse9,
    at: T("2026-07-29T09:00:00Z"),
    readAt: T("2026-07-29T15:00:00Z"),
  },
];

// Metrics, aiVisibility, and the promotion trio (promotions/boosts/
// pushCampaigns/promoState/rankPerks) live in seed-organizer-analytics.mjs —
// see seedOrganizerAnalytics() below, called from main().

// ── Logs (6) ──────────────────────────────────────────────────────────────────

const LOGS = [
  {
    id: "log-01",
    action: "organizer.approve",
    actorUid: UID.admin,
    targetType: "user",
    targetId: UID.organizer,
    summary: "Approved organizer application for Sunset Rooftop Melbourne.",
    at: ORGANIZER_DECIDED_AT,
  },
  {
    id: "log-02",
    action: "kyc.accept",
    actorUid: UID.admin,
    targetType: "user",
    targetId: UID.organizer,
    summary: "Accepted NIC, selfie, video, and GPS evidence.",
    at: ORGANIZER_DECIDED_AT,
  },
  {
    id: "log-03",
    action: "venue.create",
    actorUid: UID.admin,
    targetType: "venue",
    targetId: VENUE_ID.sunsetRooftopMelbourne,
    summary: "Created Sunset Rooftop Melbourne from the accepted venue address.",
    at: ORGANIZER_DECIDED_AT,
  },
  {
    id: "log-04",
    action: "kyc.needsInfo",
    actorUid: UID.admin,
    targetType: "user",
    targetId: UID.rejected,
    summary: "Requested clearer NIC photos (attempt 1).",
    at: REJECTED_NIC_REVIEWED_AT,
  },
  {
    id: "log-05",
    action: "organizer.reject",
    actorUid: UID.admin,
    targetType: "user",
    targetId: UID.rejected,
    summary: "Rejected organizer application: repeated invalid ID uploads.",
    at: REJECTED_DECIDED_AT,
  },
  {
    id: "log-06",
    action: "report.delete",
    actorUid: UID.admin,
    targetType: "report",
    targetId: "report-05",
    summary: "Removed report for containing contact information spam.",
    at: T("2026-08-11T12:00:00Z"),
  },
];

// ── Wipe ──────────────────────────────────────────────────────────────────────

const WIPED_COLLECTIONS = [
  "users",
  "venues",
  "events",
  "venueReports",
  "logs",
  "venueEdits",
  "venueInvites",
];

async function wipeAll() {
  console.log(`Wiping collections this script owns (${WIPED_COLLECTIONS.join(", ")})...`);
  for (const name of WIPED_COLLECTIONS) {
    await db.recursiveDelete(db.collection(name));
  }
  // recursiveDelete already handles venue subcollections (menuSections,
  // activity, team, promotions, pushCampaigns, promoState, boosts,
  // rankPerks, aiVisibility, metrics) for free — nothing new to add there.
  await bucket
    .deleteFiles({ prefix: "avatars/" })
    .catch(() => {});
  await bucket
    .deleteFiles({ prefix: "kyc/" })
    .catch(() => {});
  await bucket
    .deleteFiles({ prefix: "venuePhotos/" })
    .catch(() => {});
  await bucket
    .deleteFiles({ prefix: "eventMedia/" })
    .catch(() => {});
  await bucket
    .deleteFiles({ prefix: "venueKyc/" })
    .catch(() => {});
  console.log("Wipe complete.\n");
}

// ── Seed steps ────────────────────────────────────────────────────────────────

async function seedAuthUsers() {
  console.log("Creating/updating Auth users...");
  for (const acc of ACCOUNTS) {
    const payload = {
      uid: acc.uid,
      email: acc.email,
      password: acc.password,
      displayName: acc.displayName,
      emailVerified: true, // chat writes require this; the emulator defaults to false
    };
    try {
      await auth.createUser(payload);
    } catch (err) {
      if (err.code === "auth/uid-already-exists" || err.code === "auth/email-already-exists") {
        await auth.updateUser(acc.uid, payload);
      } else {
        throw err;
      }
    }
  }
}

async function seedVenues() {
  console.log(`Writing ${VENUES.length} venues...`);
  const batch = db.batch();
  for (const v of VENUES) {
    const { id, ...data } = v;
    batch.set(db.collection("venues").doc(id), {
      ...data,
      createdAt: VENUE_CREATED,
      updatedAt: VENUE_UPDATED,
    });
  }
  await batch.commit();
}

async function seedUsers() {
  console.log(`Writing ${Object.keys(USERS).length} user documents...`);
  const batch = db.batch();
  for (const [uid, data] of Object.entries(USERS)) {
    batch.set(db.collection("users").doc(uid), data);
  }
  await batch.commit();

  console.log("Writing private/organizerReview verdict documents...");
  const reviewBatch = db.batch();
  for (const [uid, data] of Object.entries(ORGANIZER_REVIEWS)) {
    reviewBatch.set(
      db.collection("users").doc(uid).collection("private").doc("organizerReview"),
      data
    );
  }
  await reviewBatch.commit();

  console.log("Writing rider favourites + chat session...");
  const riderBatch = db.batch();
  for (const fav of RIDER_FAVOURITES) {
    const { eventId, ...data } = fav;
    riderBatch.set(
      db.collection("users").doc(UID.rider).collection("favourites").doc(eventId),
      data
    );
  }
  riderBatch.set(
    db
      .collection("users")
      .doc(UID.rider)
      .collection("chat_sessions")
      .doc(RIDER_CHAT_SESSION_ID),
    RIDER_CHAT_SESSION
  );
  for (const msg of RIDER_CHAT_MESSAGES) {
    const { id, ...data } = msg;
    riderBatch.set(
      db
        .collection("users")
        .doc(UID.rider)
        .collection("chat_sessions")
        .doc(RIDER_CHAT_SESSION_ID)
        .collection("messages")
        .doc(id),
      data
    );
  }
  riderBatch.set(
    db.collection("users").doc(UID.rider).collection("settings").doc("privacy"),
    { publicProfile: true, showLocation: true, showActivity: true, twoFactor: false }
  );
  await riderBatch.commit();
}

async function seedEvents() {
  console.log(`Writing ${EVENTS.length} events...`);
  const batch = db.batch();
  for (const e of EVENTS) {
    const { id, ...data } = e;
    batch.set(db.collection("events").doc(id), data);
  }
  await batch.commit();

  console.log("Writing events/{id}/interested marker docs...");
  const markerBatch = db.batch();
  for (const [eventId, uids] of Object.entries(EVENT_INTERESTED)) {
    for (const uid of uids) {
      markerBatch.set(
        db.collection("events").doc(eventId).collection("interested").doc(uid),
        { at: EVENT_UPDATED }
      );
    }
  }
  await markerBatch.commit();
}

async function seedVenueReports() {
  console.log(`Writing ${ALL_VENUE_REPORTS.length} venue reports...`);
  const batch = db.batch();
  for (const r of ALL_VENUE_REPORTS) {
    const { id, upvoters, ...data } = r;
    batch.set(db.collection("venueReports").doc(id), { reply: null, flaggedByOwner: false, ...data });
  }
  await batch.commit();

  console.log("Writing venueReports/{id}/upvotes marker docs...");
  const upvoteBatch = db.batch();
  for (const r of ALL_VENUE_REPORTS) {
    for (const voterUid of r.upvoters) {
      upvoteBatch.set(
        db.collection("venueReports").doc(r.id).collection("upvotes").doc(voterUid),
        { at: r.createdAt }
      );
    }
  }
  await upvoteBatch.commit();
}

// ── Organizer dashboard fixtures ─────────────────────────────────────────────

async function seedVenueEdits() {
  console.log(`Writing ${VENUE_EDITS.length} venueEdits draft(s)...`);
  const batch = db.batch();
  for (const e of VENUE_EDITS) {
    const { venueId, ...data } = e;
    batch.set(db.collection("venueEdits").doc(venueId), { venueId, ...data });
  }
  await batch.commit();
}

async function seedVenueInvites() {
  console.log(`Writing ${VENUE_INVITES.length} venue invite(s)...`);
  const batch = db.batch();
  for (const inv of VENUE_INVITES) {
    const { id, ...data } = inv;
    batch.set(db.collection("venueInvites").doc(id), data);
  }
  await batch.commit();
}

async function seedOrganizerInbox() {
  console.log(`Writing ${ORGANIZER_INBOX.length} organizer inbox message(s)...`);
  const batch = db.batch();
  for (const msg of ORGANIZER_INBOX) {
    const { id, ...data } = msg;
    batch.set(db.collection("users").doc(UID.organizer).collection("inbox").doc(id), data);
  }
  await batch.commit();
}

/** menuSections/activity/team under `venues/{venueId}/...` — the aiVisibility,
 * metrics, and promotion-trio subcollections are seeded separately by
 * seedOrganizerAnalytics() (seed-organizer-analytics.mjs), called from main(). */
async function seedVenueSubcollections() {
  let menuSectionCount = 0;
  let activityCount = 0;
  let teamCount = 0;

  const batch = db.batch();

  for (const [venueKey, sections] of Object.entries(MENU_SECTIONS)) {
    const venueId = VENUE_ID[venueKey];
    for (const section of sections) {
      const { id, ...data } = section;
      batch.set(db.collection("venues").doc(venueId).collection("menuSections").doc(id), data);
      menuSectionCount++;
    }
  }

  for (const [venueKey, entries] of Object.entries(ACTIVITY)) {
    const venueId = VENUE_ID[venueKey];
    entries.forEach((entry, i) => {
      const id = `activity-${String(i + 1).padStart(2, "0")}`;
      batch.set(db.collection("venues").doc(venueId).collection("activity").doc(id), entry);
      activityCount++;
    });
  }

  for (const [venueKey, members] of Object.entries(TEAM)) {
    const venueId = VENUE_ID[venueKey];
    for (const m of members) {
      const { id, ...data } = m;
      batch.set(db.collection("venues").doc(venueId).collection("team").doc(id), data);
      teamCount++;
    }
  }

  console.log(
    `Writing venue subcollections: menuSections=${menuSectionCount} activity=${activityCount} team=${teamCount}...`
  );
  await batch.commit();
}

async function seedLogs() {
  console.log(`Writing ${LOGS.length} log entries...`);
  const batch = db.batch();
  for (const l of LOGS) {
    const { id, ...data } = l;
    batch.set(db.collection("logs").doc(id), data);
  }
  await batch.commit();
}

async function seedStorage() {
  console.log("Uploading placeholder Storage objects...");

  await bucket.file(RIDER_AVATAR_PATH).save(TINY_JPEG, {
    contentType: "image/jpeg",
    resumable: false,
  });
  await bucket.file(ORGANIZER_AVATAR_PATH).save(TINY_JPEG, {
    contentType: "image/jpeg",
    resumable: false,
  });

  const kycBase = `kyc/${UID.applicant}/nic/0`;
  await bucket.file(`${kycBase}/front.jpg`).save(TINY_JPEG, {
    contentType: "image/jpeg",
    resumable: false,
  });
  await bucket.file(`${kycBase}/back.jpg`).save(TINY_JPEG, {
    contentType: "image/jpeg",
    resumable: false,
  });
  await bucket.file(`kyc/${UID.applicant}/selfie/0/capture.jpg`).save(TINY_JPEG, {
    contentType: "image/jpeg",
    resumable: false,
  });

  // venuePhotos: hero + 4 gallery per organizer venue, plus one shared menu
  // photo per venue (referenced from MENU_SECTIONS above).
  for (const venueId of [VENUE_ID.sirens, VENUE_ID.warehouse9]) {
    const paths = [
      `venuePhotos/${venueId}/hero.jpg`,
      `venuePhotos/${venueId}/gallery/0.jpg`,
      `venuePhotos/${venueId}/gallery/1.jpg`,
      `venuePhotos/${venueId}/gallery/2.jpg`,
      `venuePhotos/${venueId}/gallery/3.jpg`,
      `venuePhotos/${venueId}/menu/0.jpg`,
    ];
    for (const p of paths) {
      await bucket.file(p).save(TINY_JPEG, { contentType: "image/jpeg", resumable: false });
    }
  }

  // eventMedia: cover art for the two published organizer events.
  for (const eventId of ["e1", "e2"]) {
    await bucket.file(`eventMedia/${eventId}/cover.jpg`).save(TINY_JPEG, {
      contentType: "image/jpeg",
      resumable: false,
    });
  }

  // venueKyc: license front page for the unverified organizer venue.
  await bucket.file(`venueKyc/${VENUE_ID.neonAnnex}/license/0/front.jpg`).save(TINY_JPEG, {
    contentType: "image/jpeg",
    resumable: false,
  });
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  if (FLAG_WIPE) {
    await wipeAll();
  }

  await seedAuthUsers();
  await seedVenues();
  await seedUsers();
  await seedEvents();
  await seedVenueReports();
  await seedLogs();
  await seedVenueEdits();
  await seedVenueInvites();
  await seedOrganizerInbox();
  await seedVenueSubcollections();
  await seedOrganizerAnalytics(db, { venueId: VENUE_ID.sirens });
  await seedStorage();

  console.log("\nDone.\n");
  console.log("Counts:");
  console.log(`  users:         ${Object.keys(USERS).length}`);
  console.log(`  venues:        ${VENUES.length}`);
  console.log(`  events:        ${EVENTS.length}`);
  console.log(`  venueReports:  ${ALL_VENUE_REPORTS.length}`);
  console.log(`  logs:          ${LOGS.length}`);
  console.log(`  venueEdits:    ${VENUE_EDITS.length}`);
  console.log(`  venueInvites:  ${VENUE_INVITES.length}`);
  console.log(`  organizer inbox: ${ORGANIZER_INBOX.length}`);

  console.log("\nSeeded accounts (copy/paste-friendly — email / password / uid):\n");
  const emailWidth = Math.max(...ACCOUNTS.map((a) => a.email.length)) + 2;
  const passWidth = Math.max(...ACCOUNTS.map((a) => a.password.length)) + 2;
  for (const a of ACCOUNTS) {
    console.log(`  ${a.email.padEnd(emailWidth)}${a.password.padEnd(passWidth)}${a.uid}`);
  }
  console.log("");
}

main().catch((err) => {
  console.error("Seeding failed:", err);
  process.exit(1);
});
