/**
 * Firebase surfaces codes like `auth/email-already-in-use`. Raw codes are no
 * use to an applicant, so map the ones this flow can actually hit and fall back
 * to the thrown message for our own validation errors.
 */
const AUTH_ERROR_MESSAGES: Record<string, string> = {
  "auth/email-already-in-use": "An account already exists for this email. Log in instead.",
  "auth/invalid-email": "Enter a valid email address, for example you@venue.com.",
  "auth/weak-password": "That password is too weak. Use at least 8 characters with mixed case, a number and a symbol.",
  // Sign-in failures. Modern Firebase collapses wrong-password and unknown-email
  // into `invalid-credential`; the older codes are kept for SDKs that still split
  // them. All three share one message so the form never reveals which it was.
  "auth/invalid-credential": "That email and password don't match an organizer account.",
  "auth/wrong-password": "That email and password don't match an organizer account.",
  "auth/user-not-found": "That email and password don't match an organizer account.",
  "auth/user-disabled": "This account has been disabled. Contact the Night Ride team.",
  // Fires for BOTH email sign-up and phone verification — never name one of them.
  "auth/operation-not-allowed": "This Firebase project is refusing that sign-in method.",
  "auth/admin-restricted-operation": "This Firebase project is refusing that operation.",
  "auth/billing-not-enabled": "This Firebase feature needs billing enabled on the project.",
  "auth/unauthorized-domain": "This domain isn't in the Firebase authorized-domains list.",
  "auth/app-not-authorized": "This app isn't authorized to use Firebase Auth with that API key.",
  "auth/invalid-app-credential": "The reCAPTCHA token was rejected. Reload the page and try again.",
  "auth/missing-app-credential": "The reCAPTCHA check didn't run. Reload the page and try again.",
  "auth/network-request-failed": "Network problem — check your connection and try again.",
  "auth/too-many-requests": "Too many attempts. Wait a few minutes before trying again.",
  "auth/invalid-phone-number": "That phone number isn't valid. Use international format, e.g. +971 50 123 4567.",
  "auth/missing-phone-number": "Enter a phone number.",
  "auth/quota-exceeded": "The SMS quota for this project has been used up. Try again later.",
  "auth/invalid-verification-code": "That code is incorrect. Check it and try again.",
  "auth/code-expired": "That code expired. Request a new one.",
  "auth/credential-already-in-use": "That phone number is already linked to another account.",
  "auth/provider-already-linked": "A phone number is already linked to this account.",
  "auth/requires-recent-login": "For security, sign in again before linking a phone number.",
  "auth/captcha-check-failed": "The reCAPTCHA check failed. Reload the page and try again.",
  "permission-denied": "You don't have permission to write this record. Check firestore.rules.",
  unavailable: "Can't reach Firestore right now. Check your connection and try again.",
};

/**
 * Cloud Storage surfaces codes like `storage/unauthorized`. The KYC rule
 * (nightride-webpanel/storage.rules) denies a re-upload to an already-written
 * path as a matter of design — reviewed evidence is immutable — so that
 * specific code gets applicant-facing copy instead of a raw permission error.
 * Storage does not distinguish "this object already exists" from "this step
 * isn't open for upload" in the error it returns, so this message covers both.
 */
const STORAGE_ERROR_MESSAGES: Record<string, string> = {
  "storage/unauthorized": "This step is already submitted — wait for review.",
  "storage/canceled": "Upload canceled.",
  "storage/retry-limit-exceeded": "Upload failed after repeated retries. Check your connection and try again.",
  "storage/quota-exceeded": "Storage quota exceeded. Contact the Night Ride team.",
  "storage/unauthenticated": "You're signed out. Sign in again and retry the upload.",
};

export function describeUploadError(error: unknown): string {
  if (typeof error === "object" && error !== null && "code" in error) {
    const code = String((error as { code: unknown }).code);
    const known = STORAGE_ERROR_MESSAGES[code];
    if (typeof console !== "undefined") console.error("[organizer] Storage error", code, error);
    return known ?? `Upload failed: ${code}`;
  }
  if (error instanceof Error && error.message) return error.message;
  return "Upload failed. Try again.";
}

export function describeAuthError(error: unknown): string {
  // Anything carrying a Firebase code keeps that code in the visible message.
  // A mapped message can be wrong about the cause; the raw code never is.
  if (typeof error === "object" && error !== null && "code" in error) {
    const code = String((error as { code: unknown }).code);
    const known = AUTH_ERROR_MESSAGES[code];
    if (typeof console !== "undefined") console.error("[organizer] Firebase error", code, error);
    return known ? `${known} (${code})` : `Something went wrong: ${code}`;
  }
  // Our own validation errors — already written for the applicant, left clean.
  if (error instanceof Error && error.message) return error.message;
  return "Something went wrong. Try again.";
}
