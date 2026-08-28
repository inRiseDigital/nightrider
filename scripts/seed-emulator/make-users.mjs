#!/usr/bin/env node
// make-users.mjs
//
// Creates one fresh user of each kind against the local Firebase emulator:
// plain rider, admin, applicant (submitted, awaiting review), organizer
// (approved), rejected applicant, and an applicant mid-review with a
// needs_info step. Unlike seed.mjs, every run generates new accounts with a
// unique email suffix, so it never collides with seed.mjs's fixed dataset
// and can be run repeatedly to pile up more test users.
//
// Usage:
//   node make-users.mjs             create one of each kind
//   node make-users.mjs --force     create even if no *_EMULATOR_HOST env var is set
//
// Same Admin-SDK / emulator-only safety rail as seed.mjs.

import admin from "firebase-admin";

const args = process.argv.slice(2);
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

admin.initializeApp({ projectId: PROJECT_ID });
const auth = admin.auth();
const db = admin.firestore();

const RUN_ID = Date.now().toString(36);
const T = (iso) => admin.firestore.Timestamp.fromDate(new Date(iso));
const geo = (lat, lng) => new admin.firestore.GeoPoint(lat, lng);
const today = () => new Date().toISOString().slice(0, 10);

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
    lastActiveDate: today(),
    isAdmin: false,
    organizerStatus: "none",
    organizerApplication: {
      submitted: false,
      submittedAt: null,
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
    },
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    ...overrides,
  };
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
    script: null,
    ...overrides,
  };
}

/**
 * Creates one Auth user + matching users/{uid} doc (+ private/organizerReview
 * when given). `profile` overrides baseUser(); `review` is the full
 * organizerReview shape, omitted for kinds that don't have one yet.
 */
async function makeUser({ label, email, password, profile, review, adminUid }) {
  const user = await auth.createUser({
    email,
    password,
    emailVerified: true,
    displayName: profile.displayName,
  });

  await db.collection("users").doc(user.uid).set(baseUser(profile));

  if (review) {
    await db
      .collection("users")
      .doc(user.uid)
      .collection("private")
      .doc("organizerReview")
      .set(review(user.uid, adminUid));
  }

  console.log(`  ${label.padEnd(22)} ${email.padEnd(34)} uid=${user.uid}`);
  return user.uid;
}

async function main() {
  console.log(`Creating one user of each kind (run ${RUN_ID})...\n`);

  const adminUid = await makeUser({
    label: "admin",
    email: `admin.${RUN_ID}@nightride.test`,
    password: "Password123!",
    profile: {
      email: `admin.${RUN_ID}@nightride.test`,
      displayName: `Admin ${RUN_ID}`,
      username: `admin_${RUN_ID}`,
      city: "Dubai",
      countryCode: "AE",
      isAdmin: true,
    },
  });

  await makeUser({
    label: "rider (plain)",
    email: `rider.${RUN_ID}@nightride.test`,
    password: "Password123!",
    profile: {
      email: `rider.${RUN_ID}@nightride.test`,
      displayName: `Rider ${RUN_ID}`,
      username: `rider_${RUN_ID}`,
      city: "Tokyo",
      countryCode: "JP",
      ageRange: "25-34",
    },
  });

  const appliedAt = T(new Date().toISOString());
  await makeUser({
    label: "applicant (submitted)",
    email: `applicant.${RUN_ID}@nightride.test`,
    password: "Password123!",
    profile: {
      email: `applicant.${RUN_ID}@nightride.test`,
      displayName: `Applicant ${RUN_ID}`,
      username: `applicant_${RUN_ID}`,
      city: "London",
      countryCode: "GB",
      organizerStatus: "none",
      organizerApplication: {
        submitted: true,
        submittedAt: appliedAt,
        profile: {
          orgName: `Applicant Org ${RUN_ID}`,
          venueName: `Applicant Venue ${RUN_ID}`,
          instagram: "",
          website: "",
          bio: "Freshly submitted application awaiting first review.",
          eventTypes: ["Club"],
          eventsPerMonth: 3,
        },
        steps: {
          venueAddress: {
            address: "1 Shoreditch High St",
            city: "London",
            countryCode: "GB",
            geo: geo(51.5253, -0.0786),
            placeId: "",
          },
          nic: { uploaded: true },
          selfie: { uploaded: true },
          video: { uploaded: false },
          gps: { attempts: [] },
        },
      },
    },
    review: () => ({
      status: "pending",
      appliedAt,
      decidedAt: null,
      decidedBy: "",
      rejectionReason: "",
      phoneVerified: false,
      steps: {
        venueAddress: reviewStep({ status: "active" }),
        nic: reviewStep({ status: "submitted" }),
        selfie: reviewStep({ status: "submitted" }),
        video: reviewStep({ status: "pending" }),
        gps: reviewStep({ status: "pending" }),
      },
      updatedAt: appliedAt,
    }),
  });

  const orgAppliedAt = T("2026-05-10T10:00:00Z");
  const orgDecidedAt = T(new Date().toISOString());
  await makeUser({
    label: "organizer (approved)",
    email: `organizer.${RUN_ID}@nightride.test`,
    password: "Password123!",
    profile: {
      email: `organizer.${RUN_ID}@nightride.test`,
      displayName: `Organizer ${RUN_ID}`,
      username: `organizer_${RUN_ID}`,
      city: "Melbourne",
      countryCode: "AU",
      organizerStatus: "approved",
      organizerApplication: {
        submitted: true,
        submittedAt: orgAppliedAt,
        profile: {
          orgName: `Organizer Collective ${RUN_ID}`,
          venueName: `Organizer Venue ${RUN_ID}`,
          instagram: "",
          website: "",
          bio: "Approved organizer, ready to publish events.",
          eventTypes: ["Rooftop", "House"],
          eventsPerMonth: 6,
        },
        steps: {
          venueAddress: {
            address: "1 Southbank Promenade",
            city: "Melbourne",
            countryCode: "AU",
            geo: geo(-37.8226, 144.9648),
            placeId: "",
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
                capturedAt: orgDecidedAt,
                attempt: 0,
              },
            ],
          },
        },
      },
    },
    review: (uid, admUid) => ({
      status: "approved",
      appliedAt: orgAppliedAt,
      decidedAt: orgDecidedAt,
      decidedBy: admUid,
      rejectionReason: "",
      phoneVerified: true,
      steps: {
        venueAddress: reviewStep({
          status: "accepted",
          reviewedAt: orgDecidedAt,
          reviewedBy: admUid,
          venueId: null,
        }),
        nic: reviewStep({ status: "accepted", reviewedAt: orgDecidedAt, reviewedBy: admUid }),
        selfie: reviewStep({ status: "accepted", reviewedAt: orgDecidedAt, reviewedBy: admUid }),
        video: reviewStep({ status: "accepted", reviewedAt: orgDecidedAt, reviewedBy: admUid }),
        gps: reviewStep({ status: "accepted", reviewedAt: orgDecidedAt, reviewedBy: admUid }),
      },
      updatedAt: orgDecidedAt,
    }),
    adminUid,
  });

  const rejAppliedAt = T("2026-06-01T11:00:00Z");
  const rejDecidedAt = T(new Date().toISOString());
  await makeUser({
    label: "rejected",
    email: `rejected.${RUN_ID}@nightride.test`,
    password: "Password123!",
    profile: {
      email: `rejected.${RUN_ID}@nightride.test`,
      displayName: `Rejected ${RUN_ID}`,
      username: `rejected_${RUN_ID}`,
      city: "Tokyo",
      countryCode: "JP",
      organizerStatus: "rejected",
      organizerApplication: {
        submitted: true,
        submittedAt: rejAppliedAt,
        profile: {
          orgName: `Rejected Org ${RUN_ID}`,
          venueName: `Rejected Venue ${RUN_ID}`,
          instagram: "",
          website: "",
          bio: "Application rejected after repeated invalid identity documents.",
          eventTypes: ["Pop-up"],
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
    },
    review: (uid, admUid) => ({
      status: "rejected",
      appliedAt: rejAppliedAt,
      decidedAt: rejDecidedAt,
      decidedBy: admUid,
      rejectionReason: "Unable to verify identity after repeated invalid document submissions.",
      phoneVerified: false,
      steps: {
        venueAddress: reviewStep({ status: "active" }),
        nic: reviewStep({ status: "rejected" }),
        selfie: reviewStep({ status: "active" }),
        video: reviewStep({ status: "pending" }),
        gps: reviewStep({ status: "pending" }),
      },
      updatedAt: rejDecidedAt,
    }),
    adminUid,
  });

  // Mid-review: admin has asked for a clearer NIC resubmission (needs_info),
  // everything else still sitting where the applicant left it.
  const niAppliedAt = T(new Date().toISOString());
  const niReviewedAt = T(new Date().toISOString());
  await makeUser({
    label: "needs_info (mid-review)",
    email: `needsinfo.${RUN_ID}@nightride.test`,
    password: "Password123!",
    profile: {
      email: `needsinfo.${RUN_ID}@nightride.test`,
      displayName: `NeedsInfo ${RUN_ID}`,
      username: `needsinfo_${RUN_ID}`,
      city: "Dubai",
      countryCode: "AE",
      organizerStatus: "none",
      organizerApplication: {
        submitted: true,
        submittedAt: niAppliedAt,
        profile: {
          orgName: `NeedsInfo Org ${RUN_ID}`,
          venueName: `NeedsInfo Venue ${RUN_ID}`,
          instagram: "",
          website: "",
          bio: "Mid-review: NIC kicked back for a clearer resubmission.",
          eventTypes: ["Lounge"],
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
          video: { uploaded: false },
          gps: { attempts: [] },
        },
      },
    },
    review: (uid, admUid) => ({
      status: "pending",
      appliedAt: niAppliedAt,
      decidedAt: null,
      decidedBy: "",
      rejectionReason: "",
      phoneVerified: false,
      steps: {
        venueAddress: reviewStep({ status: "active" }),
        nic: reviewStep({
          status: "needs_info",
          attempt: 1,
          note: "ID photo blurry — please resubmit clear photos of both sides of your NIC.",
          reviewedAt: niReviewedAt,
          reviewedBy: admUid,
        }),
        selfie: reviewStep({ status: "submitted" }),
        video: reviewStep({ status: "pending" }),
        gps: reviewStep({ status: "pending" }),
      },
      updatedAt: niReviewedAt,
    }),
    adminUid,
  });

  console.log("\nAll passwords: Password123!");
  console.log("Done.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
