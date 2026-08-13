import { FieldValue } from "firebase-admin/firestore";
import { adminDb } from "../../lib/firebase-admin";
import { runRetentionSweep } from "../../lib/admin/kyc-retention";

/**
 * The unattended daily retention run.
 *
 * Without this, the 30-day-after-approval window has no mechanism at all: an
 * inline delete on the approve action cannot fire thirty days later, and a
 * bucket lifecycle rule only catches objects at 180 days. A NIC-plus-selfie pair
 * is exactly the bundle used for identity fraud elsewhere and the London cohort
 * puts this under UK GDPR, so the schedule is the difference between a retention
 * policy and a retention paragraph.
 *
 * There is no caller to authenticate: Netlify invokes scheduled functions
 * internally and they are not reachable over HTTP. The audit entry is therefore
 * attributed to "system" rather than to an admin uid, which is honest about who
 * actually performed the deletion.
 */
export default async function handler(): Promise<Response> {
  const results = await runRetentionSweep();
  const objectsDeleted = results.reduce((sum, row) => sum + row.objectsDeleted, 0);

  if (results.length > 0) {
    await adminDb().collection("logs").add({
      action: "kyc.accept",
      actorUid: "system",
      targetType: "user",
      targetId: results.length === 1 ? results[0].uid : "multiple",
      summary: `Scheduled retention sweep purged ${objectsDeleted} object(s) across ${results.length} applicant(s)`,
      at: FieldValue.serverTimestamp(),
    });
  }

  return Response.json({ applicants: results.length, objectsDeleted });
}

export const config = { schedule: "@daily" };
