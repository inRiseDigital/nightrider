import {
  AccentTheme,
  AccentTokens,
  BaseStepDef,
  CopyTone,
  ExtraStepDef,
  ExtraStepType,
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
    intro: "Takes about 5 minutes — we'll guide you through everything from the app.",
    reviewIntro: "No rush — work through these whenever you're ready, in any order.",
  },
  direct: {
    intro: "",
    reviewIntro: "Complete these from the Night Ride mobile app.",
  },
};

/** The four checks every organizer completes, in order. */
export const BASE_STEPS: BaseStepDef[] = [
  {
    id: "nic",
    label: "NIC / ID Scan",
    detail: "Open the Night Ride app and scan the front and back of your government ID.",
    thumbLabel: "nic front + back\nphoto pending",
  },
  {
    id: "selfie",
    label: "Live Selfie",
    detail: "Take a live selfie in the app so we can match it to your ID.",
    thumbLabel: "live selfie\ncapture pending",
  },
  {
    id: "gps",
    label: "On-Site GPS Check",
    detail: "Open the app while standing at the venue so we can confirm the location on record.",
    thumbLabel: "gps ping\npending",
  },
  {
    id: "video_request",
    label: "Video Walkthrough",
    detail: "Record a walkthrough showing the entrance, the bar, and the POS terminal.",
    thumbLabel: "walkthrough video\npending",
  },
];

/** Extra steps an admin can add to an application while it is under review. */
export const EXTRA_STEPS: Record<ExtraStepType, ExtraStepDef> = {
  more_info: {
    label: "Additional Info Requested",
    detail: "An admin requested a clearer photo of your business license. Upload it from the mobile app.",
    kind: "app",
    thumbLabel: "business license\nphoto pending",
  },
  postcard: {
    label: "Mailed Verification Code",
    detail:
      "We mailed a postcard with a verification code to your registered business address. Enter it once it arrives.",
    kind: "code",
  },
  video_call: {
    label: "Live Video Call",
    detail:
      "An admin requested a live video call instead of a recording. We'll schedule a meeting — pick a time that works.",
    kind: "schedule",
  },
};

export const VIDEO_CALL_SLOTS = ["Tue 2:00pm", "Wed 11:00am", "Thu 4:00pm"];

export const STEP_STATUS_STYLES: Record<StepStatus, StepStatusStyle> = {
  done: {
    label: "Completed",
    borderClass: "border-emerald-500/30",
    badgeClass: "bg-emerald-500/10 text-emerald-400",
    textClass: "text-emerald-400",
  },
  active: {
    label: "In progress — waiting on mobile app",
    borderClass: "border-[var(--org-accent-ring)]",
    badgeClass: "bg-[var(--org-accent-fill)] text-[var(--org-accent)]",
    textClass: "text-[var(--org-accent)]",
  },
  needs_info: {
    label: "Action required",
    borderClass: "border-amber-500/30",
    badgeClass: "bg-amber-500/10 text-amber-400",
    textClass: "text-amber-400",
  },
  scheduled: {
    label: "Scheduled",
    borderClass: "border-nr-primary-light/30",
    badgeClass: "bg-nr-primary-light/10 text-nr-primary-light",
    textClass: "text-nr-primary-light",
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
    detail: "Finish the remaining steps in the mobile app to submit your application.",
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
  rejected: {
    label: "Rejected",
    detail: "",
    borderClass: "border-red-500/30",
    fillClass: "bg-red-500/10",
    badgeClass: "bg-red-500/30 text-red-100",
    textClass: "text-red-400",
  },
};

export const REJECTION_REASON =
  "Business license photo was blurry and the venue address on file did not match the GPS check.";

export const OTP_LENGTH = 6;

/** Minimum digits accepted before the OTP screen will submit. */
export const OTP_MIN_LENGTH = 4;
