#!/usr/bin/env node
// seed-organizer-analytics.mjs
//
// Seeds the organizer dashboard's read-mostly analytics surfaces:
//   venues/{venueId}/aiVisibility/current
//   venues/{venueId}/metrics/{periodId}          ("last30" and "YYYY-Www")
//   venues/{venueId}/promotions/{promoId}
//   venues/{venueId}/boosts/{boostId}
//   venues/{venueId}/pushCampaigns/{campaignId}
//   venues/{venueId}/promoState/current
//   venues/{venueId}/rankPerks/current
//
// Split out of seed.mjs so that file doesn't have to carry every analytics
// number inline — this module can run standalone against the emulator, or be
// imported and invoked by seed.mjs against its own already-initialized
// Admin SDK instance.
//
// Values mirror nightride-webpanel/lib/organizer/dashboard/mock-data.ts and
// mock-analytics.ts verbatim (MOCK_PROMOS, MOCK_BOOST, MOCK_PERKS,
// MOCK_ATTENDANCE, MOCK_DISCOVERY_FUNNEL, MOCK_TOP_NIGHTS, MOCK_AI_SCORE,
// MOCK_AI_PROMPTS, MOCK_AI_TIPS), with two conversions the mock's UI shapes
// don't need but the stored documents must have: FunnelStage.value/width
// become an absolute `value` number (no formatted string, no bar-width
// percentage — the panel derives both), and TopNight.date ("Aug 8") becomes
// `at: Timestamp`. Likewise AiPrompt.rank ("#1" / "Not shown") becomes
// `rank: number | null`.
//
// Usage:
//   node seed-organizer-analytics.mjs             seed (emulator required)
//   node seed-organizer-analytics.mjs --force     seed even with no
//                                                  *_EMULATOR_HOST env var
//
// This uses the Admin SDK, which bypasses every security rule — like
// seed.mjs, it must only ever run against the local Firebase emulator.

import admin from "firebase-admin";

const args = process.argv.slice(2);
const FLAG_FORCE = args.includes("--force");

// True only when this file is the process entry point (`node
// seed-organizer-analytics.mjs`), not when it's imported by seed.mjs — the
// importer already did its own safety check and Admin SDK bootstrap, and
// re-running admin.initializeApp() would throw.
const isMain = process.argv[1] && import.meta.url === `file://${process.argv[1]}`;

const PROJECT_ID = "nightride-a9173";
const DEFAULT_FIRESTORE_HOST = "127.0.0.1:8080";

if (isMain) {
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
        "",
        "Or, if you are certain the environment is already pointed at an emulator",
        "some other way, re-run with --force.",
      ].join("\n")
    );
    process.exit(1);
  }
  process.env.FIRESTORE_EMULATOR_HOST ??= DEFAULT_FIRESTORE_HOST;
  admin.initializeApp({ projectId: PROJECT_ID });
}

function T(iso) {
  return admin.firestore.Timestamp.fromDate(new Date(iso));
}

const VENUE_UPDATED = T("2026-08-10T21:00:00Z");

// ── Fixtures (keyed by the venue id they belong to — "sirens" by default,
// the same fixture the seed.mjs organizer-dashboard venues use) ────────────

function fixturesFor() {
  return {
    aiVisibility: {
      score: 74,
      prompts: [
        { prompt: "rooftop with house music tonight", weeklyAsks: 2400, rank: 1 },
        { prompt: "best view bar in Business Bay", weeklyAsks: 1150, rank: 3 },
        { prompt: "afrobeats night Dubai", weeklyAsks: 980, rank: 8 },
        { prompt: "late night after 3am", weeklyAsks: 640, rank: null },
      ],
      tips: [
        "Publish next week's lineup at least 5 days ahead — early listings get recommended more often.",
        'Add "Amapiano" if you programme it; you rank for it organically but it is missing from your genres.',
        "Reply to reviews within 48 hours; response rate feeds directly into your score.",
      ],
      updatedAt: VENUE_UPDATED,
    },

    metrics: {
      last30: {
        // Absolute counts only — FunnelStage.width ("64%") and value
        // ("14,300") are presentation the panel derives from these numbers.
        funnel: [
          { label: "Surfaced by the assistant", value: 14300, tone: "primary" },
          { label: "Profile opened", value: 9120, tone: "primary" },
          { label: "Added to a plan", value: 2410, tone: "tertiary" },
          { label: "Checked in at the door", value: 1865, tone: "tertiary" },
        ],
        ageBands: [
          { label: "18–24", pct: 38 },
          { label: "25–34", pct: 44 },
          { label: "35–44", pct: 14 },
          { label: "45+", pct: 4 },
        ],
        localSplit: [
          { label: "Local", pct: 61 },
          { label: "Tourist", pct: 39 },
        ],
        genreFollows: [
          { label: "Techno", pct: 52 },
          { label: "House", pct: 31 },
          { label: "Afrobeats", pct: 17 },
        ],
        updatedAt: VENUE_UPDATED,
      },
      "2026-W32": {
        attendance: [
          { label: "Mon", value: 0 },
          { label: "Tue", value: 0 },
          { label: "Wed", value: 180 },
          { label: "Thu", value: 340 },
          { label: "Fri", value: 520 },
          { label: "Sat", value: 585 },
          { label: "Sun", value: 240 },
        ],
        attendanceCeiling: 600,
        // TopNight.date ("Aug 8") becomes `at: Timestamp`.
        topNights: [
          { rank: 1, name: "Full Moon Rooftop", at: T("2026-08-08T22:00:00+04:00"), value: 585 },
          { rank: 2, name: "Techno Fridays", at: T("2026-08-01T23:00:00+09:00"), value: 540 },
          { rank: 3, name: "Sunset to Sunrise", at: T("2026-07-26T20:00:00+04:00"), value: 498 },
          { rank: 4, name: "Members Only: Vol. 2", at: T("2026-07-18T22:00:00+09:00"), value: 312 },
        ],
        updatedAt: VENUE_UPDATED,
      },
    },

    promotions: [
      {
        id: "promo-01",
        code: "VIP-AUG-08",
        desc: "Guest list — Full Moon Rooftop",
        maxUses: 50,
        used: 31,
        createdAt: T("2026-08-01T08:00:00Z"),
      },
      {
        id: "promo-02",
        code: "LADIES2FOR1",
        desc: "2-for-1 before 11pm",
        maxUses: 200,
        used: 88,
        createdAt: T("2026-07-20T08:00:00Z"),
      },
    ],

    boosts: [{ id: "boost-01", active: false, night: "2026-08-15", price: 40 }],

    // status: 'queued' is all that's ever shape-validated at create time —
    // the real weekly rate limit is enforced by the FCM fanout function, not
    // by rules (rules can't count documents or mandate a promoState update
    // alongside a create).
    pushCampaigns: [
      {
        id: "push-01",
        message: "Free entry before midnight — see you on the terrace.",
        status: "sent",
        createdAt: T("2026-08-04T18:00:00Z"),
      },
      {
        id: "push-02",
        message: "Guest list for Full Moon Rooftop closes at 9pm tonight.",
        status: "queued",
        createdAt: T("2026-08-08T15:00:00Z"),
      },
    ],

    // Display state only — the organizer cannot write this document at all.
    promoState: { used: 2, max: 4, updatedAt: T("2026-08-08T15:00:00Z") },

    rankPerks: {
      perks: [
        { tier: "Gold", perk: "Skip-the-line + welcome shot" },
        { tier: "Silver", perk: "Priority guest list" },
        { tier: "Bronze", perk: "Early-bird ticket alerts" },
      ],
      updatedAt: VENUE_UPDATED,
    },
  };
}

/** Writes every fixture above under `venues/{venueId}/...`. `db` is the
 * caller's already-initialized Firestore instance (or this module's own, in
 * standalone mode). Returns per-collection counts for the caller to log. */
export async function seedOrganizerAnalytics(db, { venueId = "sirens" } = {}) {
  const f = fixturesFor();
  const venueRef = db.collection("venues").doc(venueId);
  const batch = db.batch();

  batch.set(venueRef.collection("aiVisibility").doc("current"), f.aiVisibility);

  for (const [periodId, data] of Object.entries(f.metrics)) {
    batch.set(venueRef.collection("metrics").doc(periodId), data);
  }

  for (const p of f.promotions) {
    const { id, ...data } = p;
    batch.set(venueRef.collection("promotions").doc(id), data);
  }

  for (const b of f.boosts) {
    const { id, ...data } = b;
    batch.set(venueRef.collection("boosts").doc(id), data);
  }

  for (const c of f.pushCampaigns) {
    const { id, ...data } = c;
    batch.set(venueRef.collection("pushCampaigns").doc(id), data);
  }

  batch.set(venueRef.collection("promoState").doc("current"), f.promoState);
  batch.set(venueRef.collection("rankPerks").doc("current"), f.rankPerks);

  await batch.commit();

  const counts = {
    aiVisibility: 1,
    metrics: Object.keys(f.metrics).length,
    promotions: f.promotions.length,
    boosts: f.boosts.length,
    pushCampaigns: f.pushCampaigns.length,
    promoState: 1,
    rankPerks: 1,
  };
  console.log(`Seeded organizer analytics for venues/${venueId}:`, counts);
  return counts;
}

if (isMain) {
  const db = admin.firestore();
  seedOrganizerAnalytics(db)
    .then(() => process.exit(0))
    .catch((err) => {
      console.error("Seeding organizer analytics failed:", err);
      process.exit(1);
    });
}
