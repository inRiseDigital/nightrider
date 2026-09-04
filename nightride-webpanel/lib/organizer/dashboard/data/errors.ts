/**
 * Firestore write-error copy for the organizer dashboard, mirroring the style
 * of `lib/organizer/errors.ts:describeAuthError`. Load-bearing once real
 * writes land: `firestore.rules` will start rejecting things the current
 * mock-backed UI happily allows, and this is the only place that turns a raw
 * Firestore error code into copy an organizer can act on.
 */
export function describeFirestoreError(err: unknown): string {
  const code =
    typeof err === "object" && err !== null && "code" in err
      ? String((err as { code: unknown }).code)
      : "";

  switch (code) {
    case "permission-denied":
      return "You don't have permission to change that.";
    case "unavailable":
    case "failed-precondition":
      return "You're offline — that change wasn't saved.";
    case "invalid-argument":
      return "Something in that form isn't valid.";
    default:
      return err instanceof Error && err.message ? err.message : "Something went wrong. Try again.";
  }
}
