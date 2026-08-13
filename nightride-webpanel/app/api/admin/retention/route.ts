import { FieldValue } from "firebase-admin/firestore";
import { adminDb, requireAdmin } from "@/lib/firebase-admin";
import { runRetentionSweep } from "@/lib/admin/kyc-retention";

/**
 * POST /api/admin/retention — sweep every decided application and delete the
 * KYC media whose retention window has passed.
 *
 * The approve and reject actions delete inline, so this is the catch-up path for
 * anything that failed at decision time, plus the mechanism behind the 30-day
 * approval window (which by definition cannot happen inline). Safe to call
 * repeatedly: an already-purged step is skipped.
 *
 * GET returns what the sweep would do, deleting nothing, so the window can be
 * inspected before it is acted on.
 */

async function sweep(request: Request, dryRun: boolean) {
  const caller = await requireAdmin(request);
  if (!caller) {
    return Response.json({ error: "admin authentication required" }, { status: 403 });
  }

  if (dryRun) {
    // Reuse the same predicate as the real sweep by running it against a bucket
    // it cannot touch: simplest honest dry run is to report the candidates from
    // Firestore alone, without calling into Storage at all.
    const reviews = await adminDb()
      .collectionGroup("private")
      .where("status", "in", ["approved", "rejected", "revoked"])
      .get();

    const { stepsDueForPurge } = await import("@/lib/admin/kyc-retention");
    const candidates = reviews.docs
      .filter((doc) => doc.id === "organizerReview")
      .map((doc) => ({
        uid: doc.ref.parent.parent?.id ?? "",
        steps: stepsDueForPurge(doc.data() as Parameters<typeof stepsDueForPurge>[0]),
      }))
      .filter((row) => row.uid && row.steps.length > 0);

    return Response.json({ dryRun: true, candidates });
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

export async function GET(request: Request) {
  return sweep(request, true);
}

export async function POST(request: Request) {
  return sweep(request, false);
}
