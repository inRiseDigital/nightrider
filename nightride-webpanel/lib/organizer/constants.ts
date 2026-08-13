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
    borderClass: "border-emerald-500/30",
    badgeClass: "bg-emerald-500/10 text-emerald-400",
    textClass: "text-emerald-400",
  },
  active: {
    label: "In progress",
    borderClass: "border-[var(--org-accent-ring)]",
    badgeClass: "bg-[var(--org-accent-fill)] text-[var(--org-accent)]",
    textClass: "text-[var(--org-accent)]",
  },
  submitted: {
    label: "Submitted — waiting on review",
    borderClass: "border-nr-primary-light/30",
    badgeClass: "bg-nr-primary-light/10 text-nr-primary-light",
    textClass: "text-nr-primary-light",
  },
  needs_info: {
    label: "Action required",
    borderClass: "border-amber-500/30",
    badgeClass: "bg-amber-500/10 text-amber-400",
    textClass: "text-amber-400",
  },
  pending: {
    label: "Locked",
    borderClass: "border-nr-border",
    badgeClass: "bg-white/5 text-nr-text-hint",
    textClass: "text-nr-text-hint",
  },
};

export const OVERALL_STATUS_STYLES: Record<OverallStatusKey, OverallStatusStyle> = {
  in_progress: {
    label: "In progress",
    detail: "Finish the remaining steps below to submit your application.",
    borderClass: "border-[var(--org-accent-ring)]",
    fillClass: "bg-[var(--org-accent-fill)]",
    badgeClass: "bg-[var(--org-accent-ring)] text-nr-bg",
    textClass: "text-[var(--org-accent)]",
  },
  action_required: {
    label: "Action required",
    detail: "An admin needs more information before approving your application.",
    borderClass: "border-amber-500/30",
    fillClass: "bg-amber-500/10",
    badgeClass: "bg-amber-500/30 text-amber-100",
    textClass: "text-amber-400",
  },
  under_review: {
    label: "Under review",
    detail:
      "You're all set. Our team is reviewing your application — we'll notify you once it's approved.",
    borderClass: "border-nr-primary-light/30",
    fillClass: "bg-nr-primary-light/10",
    badgeClass: "bg-nr-primary-light/30 text-nr-bg",
    textClass: "text-nr-primary-light",
  },
  approved: {
    label: "Approved",
    detail: "You're approved. Head to your organizer dashboard.",
    borderClass: "border-emerald-500/30",
    fillClass: "bg-emerald-500/10",
    badgeClass: "bg-emerald-500/30 text-emerald-100",
    textClass: "text-emerald-400",
  },
  rejected: {
    label: "Rejected",
    detail: "",
    borderClass: "border-red-500/30",
    fillClass: "bg-red-500/10",
    badgeClass: "bg-red-500/30 text-red-100",
    textClass: "text-red-400",
  },
};

export const OTP_LENGTH = 6;

/** Minimum digits accepted before the OTP screen will submit. */
export const OTP_MIN_LENGTH = 4;
