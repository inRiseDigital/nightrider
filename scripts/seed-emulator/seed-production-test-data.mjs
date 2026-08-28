#!/usr/bin/env node
// seed-production-test-data.mjs
//
// Adds a small, clearly-namespaced set of TEST accounts/venues/events to the
// REAL production Firebase project (nightride-a9173) -- organizers at
// several verification stages, an admin account, and a plain test account,
// plus a handful of events so there's something to look at in the app and
// the admin panel.
//
// This is deliberately NOT the emulator seed script (seed.mjs) -- that one
// refuses to run anywhere but the emulator by design. This one is the
// opposite: it only ever runs against production, using a real service
// account, and every document/uid it creates is prefixed "test-" so it can
// never collide with real data and is trivially identifiable for later
// cleanup.
//
// Known gap: this writes no Storage objects. The organizers' `steps.nic
// .uploaded` etc. are the applicant's *claim* that they uploaded something
// (see docs/FIRESTORE_SCHEMA.md) -- the admin review UI derives the real
// object paths from kyc/{uid}/{stepId}/{attempt}/ and reads them directly, so
// the KYC panes will render as missing files for these accounts. Fine for
// exercising the queue and the verdict states; not enough to review an image.
//
// Usage:
//   node seed-production-test-data.mjs --i-know-this-is-production
//   node unseed-production-test-data.mjs --i-know-this-is-production   # undo

import admin from "firebase-admin";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const args = process.argv.slice(2);
if (!args.includes("--i-know-this-is-production")) {
  console.error(
    [
      "Refusing to run without --i-know-this-is-production.",
      "",
      "This script writes real Auth users and Firestore documents to the",
      "live nightride-a9173 project with the Admin SDK -- it bypasses every",
      "security rule. Re-run with the flag once you're sure.",
    ].join("\n")
  );
  process.exit(1);
}

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SERVICE_ACCOUNT_PATH = path.resolve(__dirname, "../../firebase_service_account.json");
const serviceAccount = JSON.parse(readFileSync(SERVICE_ACCOUNT_PATH, "utf8"));

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const db = admin.firestore();
const auth = admin.auth();
const { Timestamp, GeoPoint } = admin.firestore;

console.log(`Seeding TEST data into PRODUCTION project: ${serviceAccount.project_id}`);
console.log("");

function geo(lat, lng) {
  return new GeoPoint(lat, lng);
}

// Standard 5-bit-per-character geohash encoder (base32), copied from seed.mjs so
// this script has no dependency beyond firebase-admin. venues.geohash is what
// firestore.indexes.json's radius queries order by -- a venue without it is
// invisible to the app's map/Live Hub queries.
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

const NOW = Timestamp.now();

function daysFromNow(n, hourUTC = 20) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + n);
  d.setUTCHours(hourUTC, 0, 0, 0);
  return Timestamp.fromDate(d);
}

function reviewStep(overrides) {
  return {
    status: "pending",
    attempt: 0,
    note: "",
    reviewedAt: null,
    reviewedBy: null,
    venueId: null,
    mediaDeletedAt: null,
    // video only -- the walkthrough script an admin publishes to unlock it.
    script: null,
    ...overrides,
  };
}

/** A published walkthrough script -- the thing that unlocks the video step. */
function walkthroughScript(sentAt) {
  return {
    format: "list",
    lines: [
      "Start outside: the street entrance with the venue name visible.",
      "Walk in and show the ID check position.",
      "Show the bar, including the POS terminal.",
      "Walk to a fire exit and show that it is unobstructed.",
    ],
    revision: 0,
    updatedAt: sentAt,
    updatedBy: UID.admin,
  };
}

function defaultOrganizerApplication() {
  return {
    submitted: false,
    submittedAt: NOW,
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
    lastActiveDate: new Date().toISOString().slice(0, 10),
    isAdmin: false,
    organizerStatus: "none",
    organizerApplication: defaultOrganizerApplication(),
    createdAt: NOW,
    updatedAt: NOW,
    ...overrides,
  };
}

// -- Identities ---------------------------------------------------------------

const UID = {
  admin: "test-admin-uid",
  rider: "test-rider-uid",
  orgVerified: "test-organizer-verified-uid",
  orgPending: "test-organizer-pending-uid",
  orgRejected: "test-organizer-rejected-uid",
};

const ACCOUNTS = [
  { uid: UID.admin, email: "test-admin@nightride.test", password: "TestAdmin!2026", displayName: "Test Admin" },
  { uid: UID.rider, email: "test-rider@nightride.test", password: "TestRider!2026", displayName: "Test Rider" },
  { uid: UID.orgVerified, email: "test-organizer-verified@nightride.test", password: "TestOrgVerified!2026", displayName: "Test Organizer (Verified)" },
  { uid: UID.orgPending, email: "test-organizer-pending@nightride.test", password: "TestOrgPending!2026", displayName: "Test Organizer (Pending)" },
  { uid: UID.orgRejected, email: "test-organizer-rejected@nightride.test", password: "TestOrgRejected!2026", displayName: "Test Organizer (Rejected)" },
];

const VENUE_ID = "test-venue-verified-dubai";

const VENUE_LAT = 25.2048;
const VENUE_LNG = 55.2708;

const VENUE = {
  name: "Test Venue — Verified Organizer",
  geo: geo(VENUE_LAT, VENUE_LNG),
  geohash: encodeGeohash(VENUE_LAT, VENUE_LNG, 9),
  type: "nightclub",
  typeLabel: "Night Club",
  city: "Dubai",
  countryCode: "AE",
  address: "Sheikh Zayed Rd, Dubai (test data)",
  openingHours: "Th-Sa 22:00-04:00",
  phone: "",
  website: "",
  photos: [],
  source: "admin",
  osmId: null,
  ownerUid: UID.orgVerified,
  verified: true,
  status: "active",
  live: {
    status: "open",
    crowdLevel: "moderate",
    queueStatus: "short",
    ticketsAvailable: true,
    tablesAvailable: true,
    tonightDj: "",
    offer: "",
    updatedAt: NOW,
  },
  createdAt: NOW,
  updatedAt: NOW,
};

const SUBMITTED_AT = Timestamp.fromDate(new Date(Date.now() - 10 * 24 * 3600_000));
const DECIDED_AT = Timestamp.fromDate(new Date(Date.now() - 3 * 24 * 3600_000));

const USERS = {
  [UID.admin]: baseUser({
    email: "test-admin@nightride.test",
    displayName: "Test Admin",
    username: "test_admin",
    isAdmin: true,
  }),

  [UID.rider]: baseUser({
    email: "test-rider@nightride.test",
    displayName: "Test Rider",
    username: "test_rider",
    city: "Dubai",
    countryCode: "AE",
    ageRange: "25-34",
  }),

  // Fully approved -- owns the test venue, every step accepted.
  [UID.orgVerified]: baseUser({
    email: "test-organizer-verified@nightride.test",
    displayName: "Test Organizer (Verified)",
    username: "test_organizer_verified",
    city: "Dubai",
    countryCode: "AE",
    organizerStatus: "approved",
    organizerApplication: {
      submitted: true,
      submittedAt: SUBMITTED_AT,
      profile: {
        orgName: "Test Nightlife Co",
        venueName: VENUE.name,
        instagram: "",
        website: "",
        bio: "Test organizer account -- verified/approved.",
        eventTypes: ["Nightclub"],
        eventsPerMonth: 4,
      },
      steps: {
        venueAddress: {
          address: VENUE.address,
          city: VENUE.city,
          countryCode: VENUE.countryCode,
          geo: VENUE.geo,
          placeId: "",
        },
        nic: { uploaded: true },
        selfie: { uploaded: true },
        video: { uploaded: true },
        gps: { attempts: [{ point: VENUE.geo, accuracyM: 6, mocked: false, capturedAt: DECIDED_AT, attempt: 0 }] },
      },
    },
  }),

  // Mid-checklist -- venue address submitted (awaiting review), ID + selfie
  // done, gps still to do and video still locked behind an admin's walkthrough
  // script. Untriaged (organizerStatus stays 'none' until an admin picks it up
  // -- see docs/FIRESTORE_SCHEMA.md).
  [UID.orgPending]: baseUser({
    email: "test-organizer-pending@nightride.test",
    displayName: "Test Organizer (Pending)",
    username: "test_organizer_pending",
    city: "Dubai",
    countryCode: "AE",
    organizerStatus: "none",
    organizerApplication: {
      submitted: true,
      submittedAt: SUBMITTED_AT,
      profile: {
        orgName: "Test Pending Nights",
        venueName: "Test Pending Venue",
        instagram: "",
        website: "",
        bio: "Test organizer account -- still mid-verification.",
        eventTypes: ["Bar"],
        eventsPerMonth: 2,
      },
      steps: {
        venueAddress: {
          address: "Al Wasl Road (test data)",
          city: "Dubai",
          countryCode: "AE",
          geo: geo(25.21, 55.253),
          placeId: "",
        },
        nic: { uploaded: true },
        selfie: { uploaded: true },
        video: { uploaded: false },
        gps: { attempts: [] },
      },
    },
  }),

  // Rejected after review.
  [UID.orgRejected]: baseUser({
    email: "test-organizer-rejected@nightride.test",
    displayName: "Test Organizer (Rejected)",
    username: "test_organizer_rejected",
    city: "Dubai",
    countryCode: "AE",
    organizerStatus: "rejected",
    organizerApplication: {
      submitted: true,
      submittedAt: SUBMITTED_AT,
      profile: {
        orgName: "Test Rejected Nights",
        venueName: "Test Rejected Venue",
        instagram: "",
        website: "",
        bio: "Test organizer account -- rejected.",
        eventTypes: ["Pop-up"],
        eventsPerMonth: 1,
      },
      steps: {
        venueAddress: {
          address: "Jumeirah Beach Rd (test data)",
          city: "Dubai",
          countryCode: "AE",
          geo: geo(25.2, 55.27),
          placeId: "",
        },
        nic: { uploaded: true },
        selfie: { uploaded: false },
        video: { uploaded: false },
        gps: { attempts: [] },
      },
    },
  }),
};

const ORGANIZER_REVIEWS = {
  [UID.orgVerified]: {
    status: "approved",
    appliedAt: SUBMITTED_AT,
    decidedAt: DECIDED_AT,
    decidedBy: UID.admin,
    rejectionReason: "",
    phoneVerified: true,
    steps: {
      venueAddress: reviewStep({ status: "accepted", reviewedAt: DECIDED_AT, reviewedBy: UID.admin, venueId: VENUE_ID }),
      nic: reviewStep({ status: "accepted", reviewedAt: DECIDED_AT, reviewedBy: UID.admin }),
      selfie: reviewStep({ status: "accepted", reviewedAt: DECIDED_AT, reviewedBy: UID.admin }),
      video: reviewStep({ status: "accepted", reviewedAt: DECIDED_AT, reviewedBy: UID.admin, script: walkthroughScript(SUBMITTED_AT) }),
      gps: reviewStep({ status: "accepted", reviewedAt: DECIDED_AT, reviewedBy: UID.admin }),
    },
    updatedAt: DECIDED_AT,
  },
  [UID.orgPending]: {
    status: "none",
    appliedAt: SUBMITTED_AT,
    decidedAt: null,
    decidedBy: "",
    rejectionReason: "",
    phoneVerified: false,
    steps: {
      venueAddress: reviewStep({ status: "active" }),
      nic: reviewStep({ status: "submitted" }),
      selfie: reviewStep({ status: "submitted" }),
      // No script sent yet, so the video step is locked -- the applicant sees
      // "waiting for an admin" rather than an upload they cannot usefully make.
      video: reviewStep({ status: "pending" }),
      gps: reviewStep({ status: "pending" }),
    },
    updatedAt: SUBMITTED_AT,
  },
  [UID.orgRejected]: {
    status: "rejected",
    appliedAt: SUBMITTED_AT,
    decidedAt: DECIDED_AT,
    decidedBy: UID.admin,
    rejectionReason: "Test rejection reason -- could not verify identity.",
    phoneVerified: false,
    steps: {
      venueAddress: reviewStep({ status: "active" }),
      nic: reviewStep({ status: "submitted" }),
      selfie: reviewStep({ status: "active" }),
      video: reviewStep({ status: "pending" }),
      gps: reviewStep({ status: "pending" }),
    },
    updatedAt: DECIDED_AT,
  },
};

const EVENTS = [
  {
    id: "test-evt-01",
    name: "[TEST] Opening Night",
    description: "Test event data.",
    venueId: VENUE_ID,
    venueName: VENUE.name,
    city: VENUE.city,
    countryCode: VENUE.countryCode,
    geo: VENUE.geo,
    startAt: daysFromNow(7, 22),
    endAt: daysFromNow(8, 4),
    price: { min: 50, max: 100, currency: "AED", isFree: false },
    ticketUrl: "",
    coverImage: "",
    genre: "House",
    category: "nightclub",
    vibe: "upscale",
    language: "en",
    performers: [],
    policies: { ageRestriction: 21, refundPolicy: "", reEntryAllowed: false, wheelchairAccessible: false, allowPets: false },
    interestedCount: 0,
    popularityScore: 0,
    status: "published",
    source: "organizer",
    organizerUid: UID.orgVerified,
    createdAt: NOW,
    updatedAt: NOW,
  },
  {
    id: "test-evt-02",
    name: "[TEST] Draft Event",
    description: "Test event data -- draft, not yet published.",
    venueId: VENUE_ID,
    venueName: VENUE.name,
    city: VENUE.city,
    countryCode: VENUE.countryCode,
    geo: VENUE.geo,
    startAt: daysFromNow(21, 22),
    endAt: daysFromNow(22, 4),
    price: { min: 0, max: 0, currency: "AED", isFree: true },
    ticketUrl: "",
    coverImage: "",
    genre: "Techno",
    category: "nightclub",
    vibe: "underground",
    language: "en",
    performers: [],
    policies: { ageRestriction: 21, refundPolicy: "", reEntryAllowed: false, wheelchairAccessible: false, allowPets: false },
    interestedCount: 0,
    popularityScore: 0,
    status: "draft",
    source: "organizer",
    organizerUid: UID.orgVerified,
    createdAt: NOW,
    updatedAt: NOW,
  },
  {
    id: "test-evt-03",
    name: "[TEST] Admin-Entered Event",
    description: "Test event data -- entered by admin, no organizer.",
    venueId: VENUE_ID,
    venueName: VENUE.name,
    city: VENUE.city,
    countryCode: VENUE.countryCode,
    geo: VENUE.geo,
    startAt: daysFromNow(14, 21),
    endAt: daysFromNow(15, 3),
    price: { min: 20, max: 40, currency: "AED", isFree: false },
    ticketUrl: "",
    coverImage: "",
    genre: "Live Music",
    category: "bar",
    vibe: "chill",
    language: "en",
    performers: [],
    policies: { ageRestriction: 18, refundPolicy: "", reEntryAllowed: true, wheelchairAccessible: true, allowPets: false },
    interestedCount: 0,
    popularityScore: 0,
    status: "published",
    source: "admin",
    organizerUid: null,
    createdAt: NOW,
    updatedAt: NOW,
  },
];

// -- Run ------------------------------------------------------------------

async function main() {
  console.log("Creating/updating Auth users...");
  for (const acc of ACCOUNTS) {
    const payload = {
      uid: acc.uid,
      email: acc.email,
      password: acc.password,
      displayName: acc.displayName,
      emailVerified: true,
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

  console.log("Writing test venue...");
  await db.collection("venues").doc(VENUE_ID).set(VENUE);

  console.log(`Writing ${Object.keys(USERS).length} user documents...`);
  const userBatch = db.batch();
  for (const [uid, data] of Object.entries(USERS)) {
    userBatch.set(db.collection("users").doc(uid), data);
  }
  await userBatch.commit();

  console.log("Writing organizerReview verdict documents...");
  const reviewBatch = db.batch();
  for (const [uid, data] of Object.entries(ORGANIZER_REVIEWS)) {
    reviewBatch.set(db.collection("users").doc(uid).collection("private").doc("organizerReview"), data);
  }
  await reviewBatch.commit();

  console.log(`Writing ${EVENTS.length} events...`);
  const eventBatch = db.batch();
  for (const e of EVENTS) {
    const { id, ...data } = e;
    eventBatch.set(db.collection("events").doc(id), data);
  }
  await eventBatch.commit();

  console.log("\nDone.\n");
  console.log("Accounts (email / password / uid):\n");
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
