import { FieldValue } from "firebase-admin/firestore";
import { adminAuth, adminBucket, adminDb, requireAdmin } from "@/lib/firebase-admin";

/**
 * DELETE /api/admin/account — delete a user account and everything attached to it.
 *
 * firestore.rules denies `delete` on users/{uid} to every client, including the
 * owner. That is not paternalism: a client delete would strand the applicant's
 * KYC objects, which are immutable by the Storage rules and unreachable by any
 * retention flow once the metadata pointing at them is gone. Erasure has to run
 * somewhere that can delete objects, which means here.
 *
 * Order matters. Storage first, then Firestore, then the Auth record: a failure
 * part-way leaves an account that can still be found and retried, rather than an
 * orphaned bucket prefix nothing references.
 *
 * Body: { uid: string }
 */
export async function DELETE(request: Request) {
  const caller = await requireAdmin(request);
  if (!caller) {
    return Response.json({ error: "admin authentication required" }, { status: 403 });
  }

  let body: { uid?: unknown };
  try {
    body = await request.json();
  } catch {
    return Response.json({ error: "body must be JSON" }, { status: 400 });
  }

  const uid = typeof body.uid === "string" ? body.uid : "";
  if (!uid) return Response.json({ error: "expected { uid: string }" }, { status: 400 });

  if (uid === caller.uid) {
    // An admin deleting themselves would leave the panel without the account
    // that authorises this route, and isAdmin cannot be granted from here.
    return Response.json({ error: "an admin cannot delete their own account" }, { status: 400 });
  }

  const bucket = adminBucket();
  let objectsDeleted = 0;
  for (const prefix of [`kyc/${uid}/`, `avatars/${uid}.jpg`]) {
    const [files] = await bucket.getFiles({ prefix });
    for (const file of files) {
      await file.delete({ ignoreNotFound: true });
      objectsDeleted += 1;
    }
  }

  // recursiveDelete takes the subcollections with it: private/organizerReview,
  // favourites, settings, chat_sessions and their messages.
  await adminDb().recursiveDelete(adminDb().doc(`users/${uid}`));

  try {
    await adminAuth().deleteUser(uid);
  } catch (error) {
    // A missing Auth record is the expected case on a retry, not a failure.
    const code = (error as { code?: string }).code;
    if (code !== "auth/user-not-found") throw error;
  }

  await adminDb().collection("logs").add({
    action: "organizer.revoke",
    actorUid: caller.uid,
    targetType: "user",
    targetId: uid,
    summary: `Account deleted — ${objectsDeleted} storage object(s) removed`,
    at: FieldValue.serverTimestamp(),
  });

  return Response.json({ uid, objectsDeleted });
}
