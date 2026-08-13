import { FieldValue } from "firebase-admin/firestore";
import { adminDb, requireAdmin } from "../../lib/firebase-admin";
import { runRetentionSweep, stepsDueForPurge } from "../../lib/admin/kyc-retention";

/**
 * /api/admin/retention — delete the KYC media whose retention window has passed.
 *
 * GET  reports what would be deleted, touching nothing.
 * POST performs the sweep.
 *
 * The approve and reject actions delete inline, so this is the catch-up path for
 * anything that failed at decision time, plus the mechanism behind the 30-day
 * post-approval window, which by definition cannot happen inline. Safe to call
 * repeatedly: an already-purged step is skipped.
 *
 * See admin-scheduled-retention.mts for the unattended daily run. Both exist on
 * purpose: the schedule is what makes the policy real, and the manual endpoint is
 * what lets an admin prove it works without waiting a day.
 */
export default async function handler(request: Request): Promise<Response> {
  const caller = await requireAdmin(request);
  if (!caller) {
    return Response.json({ error: "admin authentication required" }, { status: 403 });
  }

  if (request.method === "GET") {
    const reviews = await adminDb()
      .collectionGroup("private")
      .where("status", "in", ["approved", "rejected", "revoked"])
      .get();

    const candidates = reviews.docs
      .filter((doc) => doc.id === "organizerReview")
      .map((doc) => ({
        uid: doc.ref.parent.parent?.id ?? "",
        steps: stepsDueForPurge(doc.data() as Parameters<typeof stepsDueForPurge>[0]),
      }))
      .filter((row) => row.uid && row.steps.length > 0);

    return Response.json({ dryRun: true, candidates });
  }

  if (request.method !== "POST") {
    return Response.json({ error: "GET or POST only" }, { status: 405 });
  }

  const results = await runRetentionSweep();
  const objectsDeleted = results.reduce((sum, row) => sum + row.objectsDeleted, 0);

  if (results.length > 0) {
    await adminDb().collection("logs").add({
      action: "kyc.accept",
      actorUid: caller.uid,
      targetType: "user",
      targetId: results.length === 1 ? results[0].uid : "multiple",
      summary: `Retention sweep purged ${objectsDeleted} object(s) across ${results.length} applicant(s)`,
      at: FieldValue.serverTimestamp(),
    });
  }

  return Response.json({ dryRun: false, applicants: results.length, objectsDeleted, results });
}

export const config = { path: "/api/admin/retention" };
