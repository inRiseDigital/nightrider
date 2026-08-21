#!/usr/bin/env node
// unseed-production-test-data.mjs
//
// The undo for seed-production-test-data.mjs. Deletes exactly the documents
// and Auth users that script creates -- nothing else. Every id it touches is
// hardcoded below and prefixed "test-", so it cannot reach real data even if
// the seed script has drifted.
//
// Usage:
//   node unseed-production-test-data.mjs --i-know-this-is-production

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
      "This script deletes real Auth users and Firestore documents from the",
      "live nightride-a9173 project with the Admin SDK. Every target is a",
      'hardcoded "test-" id, but re-run with the flag once you are sure.',
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

// Kept in lockstep with seed-production-test-data.mjs. If you add an identity,
// venue, or event there, add it here too.
const UIDS = [
  "test-admin-uid",
  "test-rider-uid",
  "test-organizer-verified-uid",
  "test-organizer-pending-uid",
  "test-organizer-rejected-uid",
];

const VENUE_IDS = ["test-venue-verified-dubai"];
const EVENT_IDS = ["test-evt-01", "test-evt-02", "test-evt-03"];

// A guard, not a formality: a typo that dropped a prefix would otherwise
// delete a real document with the Admin SDK and no rules in the way.
for (const id of [...UIDS, ...VENUE_IDS, ...EVENT_IDS]) {
  if (!id.startsWith("test-")) {
    console.error(`Refusing to run: "${id}" is not a test- id.`);
    process.exit(1);
  }
}

console.log(`Removing TEST data from PRODUCTION project: ${serviceAccount.project_id}`);
console.log("");

async function main() {
  console.log(`Deleting ${EVENT_IDS.length} events...`);
  for (const id of EVENT_IDS) {
    await db.collection("events").doc(id).delete();
  }

  console.log(`Deleting ${VENUE_IDS.length} venues...`);
  for (const id of VENUE_IDS) {
    await db.collection("venues").doc(id).delete();
  }

  // The private/organizerReview document is a subcollection member: deleting
  // the parent user document does not remove it.
  console.log("Deleting user documents and their private subcollection...");
  for (const uid of UIDS) {
    const userRef = db.collection("users").doc(uid);
    const priv = await userRef.collection("private").get();
    for (const doc of priv.docs) {
      await doc.ref.delete();
    }
    await userRef.delete();
  }

  console.log(`Deleting ${UIDS.length} Auth users...`);
  for (const uid of UIDS) {
    try {
      await auth.deleteUser(uid);
    } catch (err) {
      if (err.code === "auth/user-not-found") {
        console.log(`  (${uid} already gone)`);
      } else {
        throw err;
      }
    }
  }

  console.log("\nDone.\n");
}

main().catch((err) => {
  console.error("Cleanup failed:", err);
  process.exit(1);
});
