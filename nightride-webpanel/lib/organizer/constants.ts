import {
  AccentTheme,
  AccentTokens,
  BaseStepDef,
  CopyTone,
  FlowLayout,
  OverallStatusKey,
  OverallStatusStyle,
  StepStatus,
  StepStatusStyle,
} from "./types";

/**
 * Accent palettes the application flow can be themed with. `lime` is the brand
 * accent (`--nr-accent`) and the one this flow ships with; pink mirrors
 * `--nr-primary` and teal `--nr-primary-light`.
 */
export const ACCENT_THEMES: Record<AccentTheme, AccentTokens> = {
  pink: { color: "#ff3d73", hover: "#d63b7a", ring: "#ff3d734d", fill: "#ff3d731a" },
  teal: { color: "#62d6c8", hover: "#4fbbae", ring: "#62d6c84d", fill: "#62d6c81a" },
  lime: { color: "#dfff2f", hover: "#c7e62a", ring: "#dfff2f4d", fill: "#dfff2f1a" },
};

export const ACTIVE_ACCENT: AccentTheme = "lime";

export const FLOW_LAYOUT: FlowLayout = "timeline";

export const COPY_TONE: CopyTone = "reassuring";

export const TONE_COPY: Record<CopyTone, { intro: string; reviewIntro: string }> = {
  reassuring: {
    intro: "Takes about 5 minutes — we'll guide you through everything on this page.",
    reviewIntro: "No rush — work through these whenever you're ready, in any order.",
  },
  direct: {
    intro: "",
    reviewIntro: "Complete these steps to finish your application.",
  },
};

/** True outside production builds — gates dev-only hints, never a privileged write. */
export const IS_DEV = process.env.NODE_ENV !== "production";

/**
 * The five checks every organizer completes, in schema order: venueAddress
 * gates gps, and the three identity/venue uploads can happen any time in
 * between.
 */
export const BASE_STEPS: BaseStepDef[] = [
  {
    id: "venueAddress",
    label: "Venue Address",
    detail: "Tell us where your venue is. An admin confirms this before the on-site GPS check unlocks.",
    kind: "address",
  },
  {
    id: "nic",
    label: "NIC / ID Scan",
    detail: "Upload a clear photo of the front and back of your government ID.",
    kind: "upload",
  },
  {
    id: "selfie",
    label: "Live Selfie",
    detail: "Upload a live selfie so we can match it to your ID.",
    kind: "upload",
  },
  {
    id: "video",
    label: "Video Walkthrough",
    detail: "Upload a short walkthrough (up to 60 seconds) showing the entrance, the bar, and the POS terminal.",
    kind: "upload",
  },
  {
    id: "gps",
    label: "On-Site GPS Check",
    detail: "Open the Night Ride app on-site so we can confirm the location on record.",
    kind: "app",
    thumbLabel: "gps ping\npending",
  },
];

/** Client-side pre-checks — the Storage rule enforces the same limits server-side. */
export const KYC_IMAGE_MAX_BYTES = 6 * 1024 * 1024;
export const KYC_VIDEO_MAX_BYTES = 30 * 1024 * 1024;
export const KYC_POSTER_MAX_BYTES = 2 * 1024 * 1024;
export const KYC_IMAGE_TYPES = ["image/jpeg", "image/png"];
export const KYC_VIDEO_TYPE = "video/mp4";

export const STEP_STATUS_STYLES: Record<StepStatus, StepStatusStyle> = {
  accepted: {
    label: "Accepted",
    borderClass: "border-[var(--suc)]/30",
    badgeClass: "bg-[var(--succ)] text-[var(--onsucc)]",
    textClass: "text-[var(--suc)]",
  },
  active: {
    label: "In progress",
    borderClass: "border-[var(--org-accent-ring)]",
    badgeClass: "bg-[var(--org-accent-fill)] text-[var(--org-accent)]",
    textClass: "text-[var(--org-accent)]",
  },
  submitted: {
    label: "Submitted — waiting on review",
    borderClass: "border-[var(--ter)]/30",
    badgeClass: "bg-[var(--terc)] text-[var(--onterc)]",
    textClass: "text-[var(--ter)]",
  },
  needs_info: {
    label: "Action required",
    borderClass: "border-[var(--warn)]/30",
    badgeClass: "bg-[var(--warnc)] text-[var(--onwarnc)]",
    textClass: "text-[var(--warn)]",
  },
  pending: {
    label: "Locked",
    borderClass: "border-nr-border",
    badgeClass: "bg-[var(--surf3)] text-nr-text-hint",
    textClass: "text-nr-text-hint",
  },
};

export const OVERALL_STATUS_STYLES: Record<OverallStatusKey, OverallStatusStyle> = {
  in_progress: {
    label: "In progress",
    detail: "Finish the remaining steps below to submit your application.",
    borderClass: "border-nr-border",
    fillClass: "bg-nr-surface",
    badgeClass: "bg-[var(--pric)] text-[var(--onpric)]",
    textClass: "text-nr-text-secondary",
  },
  action_required: {
    label: "Action required",
    detail: "An admin needs more information before approving your application.",
    borderClass: "border-transparent",
    fillClass: "bg-[var(--warnc)]",
    badgeClass: "bg-[var(--warn)] text-[var(--onwarnc)]",
    textClass: "text-[var(--onwarnc)]",
  },
  under_review: {
    label: "Under review",
    detail:
      "You're all set. Our team is reviewing your application — we'll notify you once it's approved.",
    borderClass: "border-transparent",
    fillClass: "bg-[var(--terc)]",
    badgeClass: "bg-[var(--ter)] text-[var(--onterc)]",
    textClass: "text-[var(--onterc)]",
  },
  approved: {
    label: "Approved",
    detail: "You're approved. Head to your organizer dashboard.",
    borderClass: "border-transparent",
    fillClass: "bg-[var(--succ)]",
    badgeClass: "bg-[var(--suc)] text-[var(--onsucc)]",
    textClass: "text-[var(--onsucc)]",
  },
  rejected: {
    label: "Rejected",
    detail: "",
    borderClass: "border-transparent",
    fillClass: "bg-[var(--errc)]",
    badgeClass: "bg-[var(--err)] text-[var(--onerrc)]",
    textClass: "text-[var(--onerrc)]",
  },
};

export const OTP_LENGTH = 6;

/**
 * Seconds the "Resend code" control stays locked after a send. Firebase does
 * not rate-limit resends at this granularity and reCAPTCHA does not stop a
 * human clicking twice, so the cooldown is ours to enforce — every send is a
 * billed SMS.
 */
export const OTP_RESEND_COOLDOWN_SECONDS = 60;

/**
 * Hard cap on SMS sends per page load, cooldown elapsed or not. It lives in
 * memory, so a reload resets it — this is a brake on a frustrated applicant
 * running up an SMS bill, not an abuse control (that is Firebase's own
 * per-number/per-IP quota, which the client cannot see).
 */
export const OTP_MAX_SENDS = 3;

/**
 * The element invisible reCAPTCHA renders into. `RecaptchaVerifier` resolves
 * it at construction time, so whichever stage is about to send has to already
 * have it in the DOM (see _components/RecaptchaContainer.tsx).
 */
export const RECAPTCHA_CONTAINER_ID = "organizer-recaptcha";

/**
 * Mocks phone verification: no reCAPTCHA, no SMS, and any OTP_LENGTH digits
 * are accepted. Everything else — the E.164 check, the cooldown, the send cap,
 * the stage transitions — behaves exactly as it does for real, so what gets
 * demoed is what ships once this is off.
 *
 * It exists because real phone auth needs billing enabled on the Firebase
 * project (`auth/billing-not-enabled` until it is), and the apply flow has to
 * be walkable before that happens.
 *
 * Two consequences worth knowing:
 *
 *  - No phone credential is linked, so `auth.currentUser.phoneNumber` stays
 *    null and the resume path falls back to `organizerApplication.submitted`.
 *  - Nothing writes `phoneVerified`. It stays `false` in the admin-owned
 *    review doc, which is the honest answer: an applicant who came through
 *    the mock has *not* been verified, and the admin reviewing them sees that.
 *
 * `next.config.mjs` sets `output: "export"`, so this is inlined at build time.
 * Changing it on Netlify needs a redeploy, not just an env edit.
 */
export const PHONE_AUTH_MOCK = process.env.NEXT_PUBLIC_PHONE_AUTH_MOCK === "true";
