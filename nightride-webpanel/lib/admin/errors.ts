const AUTH_ERROR_MESSAGES: Record<string, string> = {
  "auth/invalid-email": "Enter a valid email address.",
  "auth/invalid-credential": "That email and password don't match an admin account.",
  "auth/wrong-password": "That email and password don't match an admin account.",
  "auth/user-not-found": "That email and password don't match an admin account.",
  "auth/user-disabled": "This account has been disabled.",
  "auth/too-many-requests": "Too many attempts. Wait a few minutes before trying again.",
  "auth/network-request-failed": "Network problem — check your connection and try again.",
  "permission-denied": "You don't have permission to do that. Check firestore.rules.",
  unavailable: "Can't reach Firestore right now. Check your connection and try again.",
};

export function describeAdminError(error: unknown): string {
  if (typeof error === "object" && error !== null && "code" in error) {
    const code = String((error as { code: unknown }).code);
    const known = AUTH_ERROR_MESSAGES[code];
    console.error("[admin] Firebase error", code, error);
    return known ? `${known} (${code})` : `Something went wrong: ${code}`;
  }
  if (error instanceof Error && error.message) return error.message;
  return "Something went wrong. Try again.";
}
