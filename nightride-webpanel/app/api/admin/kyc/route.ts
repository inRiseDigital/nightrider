import { FieldValue } from "firebase-admin/firestore";
import { adminDb, requireAdmin } from "@/lib/firebase-admin";
import { IDENTITY_STEPS, VIDEO_STEP, purgeKycSteps, type PurgeStep } from "@/lib/admin/kyc-retention";

/**
 * POST /api/admin/kyc — delete an applicant's KYC evidence.
 *
 * storage.rules denies `delete` on `kyc/**` to every client, admins included,
 * so that reviewed evidence cannot be altered by any compromised session. That
 * makes this route the only deletion path, and it is the one the approve and
 * reject actions call inline.
 *
 * Body: { uid: string, scope: "identity" | "all" }
 *   identity — nic + selfie, the 30-day-after-approval case
 *   all      — nic + selfie + video, the 90-day-after-rejection case
 */

const SCOPES: Record<string, PurgeStep[]> = {
  identity: [...IDENTITY_STEPS],
  all: [...IDENTITY_STEPS, VIDEO_STEP],
};

export async function POST(request: Request) {
  const caller = await requireAdmin(request);
  if (!caller) {
    return Response.json({ error: "admin authentication required" }, { status: 403 });
  }

  let body: { uid?: unknown; scope?: unknown };
  try {
    body = await request.json();
  } catch {
    return Response.json({ error: "body must be JSON" }, { status: 400 });
  }

  const uid = typeof body.uid === "string" ? body.uid : "";
  const scopeKey = typeof body.scope === "string" ? body.scope : "";
  const steps = SCOPES[scopeKey];

  if (!uid || !steps) {
    return Response.json(
      { error: 'expected { uid: string, scope: "identity" | "all" }' },
      { status: 400 }
    );
  }

  const review = await adminDb().doc(`users/${uid}/private/organizerReview`).get();
  if (!review.exists) {
    return Response.json({ error: "no organizer review for that uid" }, { status: 404 });
  }

  const result = await purgeKycSteps(uid, steps);

  await adminDb().collection("logs").add({
    action: "kyc.accept",
    actorUid: caller.uid,
    targetType: "user",
    targetId: uid,
    summary: `Deleted KYC media (${steps.join(", ")}) — ${result.objectsDeleted} object(s)`,
    at: FieldValue.serverTimestamp(),
  });

  return Response.json(result);
}
