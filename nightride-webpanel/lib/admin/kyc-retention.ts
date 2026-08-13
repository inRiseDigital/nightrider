import { FieldValue } from "firebase-admin/firestore";
// Relative rather than the "@/" alias: this module is also bundled by Netlify's
// esbuild for the functions in netlify/functions/, which does not read the
// tsconfig path aliases that Next resolves.
import { adminBucket, adminDb } from "../firebase-admin";

/**
 * KYC retention.
 *
 * A NIC-plus-selfie pair is exactly the bundle used for identity fraud
 * elsewhere, and the London cohort puts this under UK GDPR — so deletion is a
 * requirement, not hygiene. The policy:
 *
 *   identity images (nic, selfie)  30 days after approval, 90 after rejection
 *   walkthrough video              retained while active, 90 days after rejection
 *   gps observations               structured, tiny, retained indefinitely
 *
 * Firestore metadata (paths, sizes, reviewer, timestamps, notes) is retained
 * permanently. That keeps a provable audit trail at no breach cost.
 *
 * A bucket lifecycle rule of `age > 180 days` on `kyc/**` backstops anything
 * this sweep misses. Object Versioning must stay off for the prefix — it would
 * resurrect deleted identity documents.
 */

export const IDENTITY_STEPS = ["nic", "selfie"] as const;
export const VIDEO_STEP = "video" as const;

export const DAYS_AFTER_APPROVAL_IDENTITY = 30;
export const DAYS_AFTER_REJECTION = 90;

export type PurgeStep = (typeof IDENTITY_STEPS)[number] | typeof VIDEO_STEP;

export type PurgeResult = {
  uid: string;
  steps: PurgeStep[];
  objectsDeleted: number;
};

const DAY_MS = 24 * 60 * 60 * 1000;

function daysSince(at: Date, now: number): number {
  return (now - at.getTime()) / DAY_MS;
}

/**
 * Deletes every object under the given KYC steps for one applicant and stamps
 * `mediaDeletedAt` on each step of their review document.
 *
 * Deleting the objects before stamping is deliberate: a crash between the two
 * leaves a step marked as still holding media that is already gone, which reads
 * as a stale record. The reverse order would leave real identity images behind
 * a step that claims they were deleted, which reads as a completed erasure that
 * never happened.
 */
export async function purgeKycSteps(uid: string, steps: PurgeStep[]): Promise<PurgeResult> {
  const bucket = adminBucket();
  let objectsDeleted = 0;

  for (const step of steps) {
    const [files] = await bucket.getFiles({ prefix: `kyc/${uid}/${step}/` });
    for (const file of files) {
      await file.delete({ ignoreNotFound: true });
      objectsDeleted += 1;
    }
  }

  if (steps.length > 0) {
    const stamps: Record<string, unknown> = {};
    for (const step of steps) {
      stamps[`steps.${step}.mediaDeletedAt`] = FieldValue.serverTimestamp();
    }
    stamps.updatedAt = FieldValue.serverTimestamp();
    await adminDb().doc(`users/${uid}/private/organizerReview`).set(stamps, { merge: true });
  }

  return { uid, steps, objectsDeleted };
}

/**
 * Which steps are due for deletion for one review document, given its decision
 * state. Returns an empty array when nothing is due yet, and skips steps whose
 * media was already purged.
 */
export function stepsDueForPurge(
  review: {
    status?: string;
    decidedAt?: { toDate(): Date } | null;
    steps?: Record<string, { mediaDeletedAt?: unknown } | undefined>;
  },
  now: number = Date.now()
): PurgeStep[] {
  const decidedAt = review.decidedAt?.toDate?.();
  if (!decidedAt) return [];

  const age = daysSince(decidedAt, now);
  const alreadyGone = (step: PurgeStep) => Boolean(review.steps?.[step]?.mediaDeletedAt);

  const due: PurgeStep[] = [];

  if (review.status === "approved" && age >= DAYS_AFTER_APPROVAL_IDENTITY) {
    // The video is the organizer's own venue walkthrough and stays while they
    // are active; only the identity documents go.
    for (const step of IDENTITY_STEPS) if (!alreadyGone(step)) due.push(step);
  }

  if ((review.status === "rejected" || review.status === "revoked") && age >= DAYS_AFTER_REJECTION) {
    for (const step of [...IDENTITY_STEPS, VIDEO_STEP] as PurgeStep[]) {
      if (!alreadyGone(step)) due.push(step);
    }
  }

  return due;
}

/**
 * Sweeps every decided application and purges what is due. Intended to be
 * called from a scheduled job or by hand from the admin panel; it is safe to
 * run repeatedly, because a purged step is skipped on the next pass.
 */
export async function runRetentionSweep(now: number = Date.now()): Promise<PurgeResult[]> {
  const reviews = await adminDb()
    .collectionGroup("private")
    .where("status", "in", ["approved", "rejected", "revoked"])
    .get();

  const results: PurgeResult[] = [];

  for (const doc of reviews.docs) {
    // collectionGroup('private') would also match any future sibling document
    // in that subcollection, so the id is checked rather than assumed.
    if (doc.id !== "organizerReview") continue;

    const uid = doc.ref.parent.parent?.id;
    if (!uid) continue;

    const due = stepsDueForPurge(doc.data() as Parameters<typeof stepsDueForPurge>[0], now);
    if (due.length === 0) continue;

    results.push(await purgeKycSteps(uid, due));
  }

  return results;
}
