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
 * gates gps, and the identity/venue evidence steps can happen any time in
 * between.
 *
 * nic and selfie are `kind: "app"`: both are live captures — a scan of a
 * physical ID and a face shot taken on the spot — and a browser file picker
 * cannot tell a live capture from a saved image, so the Night Ride app owns
 * them (camera + Storage upload, see Nightride/lib/pages/organizer/verify/).
 * This panel only reports their state. The walkthrough video stays a browser
 * upload: it is footage of a venue, not a liveness check.
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
    detail: "Open the Night Ride app and scan the front and back of your government ID.",
    kind: "app",
    thumbLabel: "nic front + back photo\npending",
  },
  {
    id: "selfie",
    label: "Live Selfie",
    detail: "Open the Night Ride app and take a live selfie so we can match it to your ID.",
    kind: "app",
    thumbLabel: "live selfie\npending",
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

/**
 * Client-side pre-checks — the Storage rule enforces the same limits
 * server-side. Only the video step uploads from the browser now, so these
 * cover the walkthrough and the poster frame extracted from it; the nic and
 * selfie image limits live in the mobile app.
 */
export const KYC_VIDEO_MAX_BYTES = 30 * 1024 * 1024;
export const KYC_POSTER_MAX_BYTES = 2 * 1024 * 1024;
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

/** Minimum digits accepted before the OTP screen will submit. */
export const OTP_MIN_LENGTH = 4;
