import { KYC_VIDEO_MAX_BYTES, KYC_VIDEO_TYPE } from "./constants";
import type { VenueAddressDraft } from "./types";

export const PASSWORD_MIN_LENGTH = 8;

export interface PasswordRule {
  id: string;
  /** Short form shown in the requirements checklist under the field. */
  label: string;
  /** Sentence shown in the error box when this is the first unmet rule. */
  error: string;
  test: (password: string) => boolean;
}

export const PASSWORD_RULES: PasswordRule[] = [
  {
    id: "length",
    label: `${PASSWORD_MIN_LENGTH}+ characters`,
    error: `Password must be at least ${PASSWORD_MIN_LENGTH} characters.`,
    test: (password) => password.length >= PASSWORD_MIN_LENGTH,
  },
  {
    id: "uppercase",
    label: "One uppercase letter",
    error: "Password must include an uppercase letter.",
    test: (password) => /[A-Z]/.test(password),
  },
  {
    id: "lowercase",
    label: "One lowercase letter",
    error: "Password must include a lowercase letter.",
    test: (password) => /[a-z]/.test(password),
  },
  {
    id: "number",
    label: "One number",
    error: "Password must include a number.",
    test: (password) => /\d/.test(password),
  },
  {
    id: "symbol",
    label: "One symbol",
    error: "Password must include a symbol, for example ! ? @ or #.",
    test: (password) => /[^A-Za-z0-9]/.test(password),
  },
];

/**
 * The WHATWG email-input pattern, tightened to require a dot-separated TLD —
 * `admin@localhost` is valid per the spec but never a real organizer address.
 */
const EMAIL_PATTERN =
  /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/;

/** Returns an error message, or null when the email is usable. */
export function validateEmail(email: string): string | null {
  const trimmed = email.trim();
  if (!trimmed) return "Enter your email address.";
  if (!EMAIL_PATTERN.test(trimmed)) return "Enter a valid email address, for example you@venue.com.";
  return null;
}

/** Returns the first unmet rule's message, or null when the password passes all of them. */
export function validatePassword(password: string): string | null {
  if (!password) return "Enter a password.";
  return PASSWORD_RULES.find((rule) => !rule.test(password))?.error ?? null;
}

export function checkPasswordRules(password: string) {
  return PASSWORD_RULES.map((rule) => ({ id: rule.id, label: rule.label, met: rule.test(password) }));
}

const MB = 1024 * 1024;

/**
 * Client-side pre-check so a bad file gets a real message instead of a
 * Storage permission error — the rule enforces the same size/type limits
 * server-side (nightride-webpanel/storage.rules, kyc/{uid}/{stepId}/... block).
 * Images are no longer picked in the browser (nic and selfie are captured in
 * the mobile app), so only the walkthrough video needs one here.
 */
export function validateKycVideo(file: File): string | null {
  if (file.type !== KYC_VIDEO_TYPE) return "Use an MP4 video.";
  if (file.size > KYC_VIDEO_MAX_BYTES) return `Video must be under ${KYC_VIDEO_MAX_BYTES / MB} MB.`;
  return null;
}

/**
 * Nothing here is rules-enforced (organizerApplication is advisory), but an
 * empty or malformed address is useless to the admin reviewing it.
 */
export function validateVenueAddress(draft: VenueAddressDraft): string | null {
  if (!draft.address.trim()) return "Enter the venue's street address.";
  if (!draft.city.trim()) return "Enter the venue's city.";
  if (!/^[A-Za-z]{2}$/.test(draft.countryCode.trim())) return "Enter a 2-letter country code, for example AE.";
  return null;
}
