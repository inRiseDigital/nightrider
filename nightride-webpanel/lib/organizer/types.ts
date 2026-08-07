export type ApplicationStage = "signup" | "phone" | "otp" | "review";

/** Layout of the verification flow on the review stage. */
export type FlowLayout = "checklist" | "timeline";

export type AccentTheme = "pink" | "teal" | "lime";

export type CopyTone = "direct" | "reassuring";

export interface AccentTokens {
  color: string;
  hover: string;
  /** Border/ring colour — the accent at ~30% alpha. */
  ring: string;
  /** Fill colour — the accent at ~10% alpha. */
  fill: string;
}

/**
 * `needs_info` is what an admin-requested extra step starts as, `scheduled` only
 * ever applies to the live video call step.
 */
export type StepStatus = "pending" | "active" | "needs_info" | "scheduled" | "done";

export type BaseStepId = "nic" | "selfie" | "gps" | "video_request";

export type ExtraStepType = "more_info" | "postcard" | "video_call";

/**
 * How the applicant clears a step: `app` is completed from the mobile app,
 * `code` is a code typed into this page, `schedule` is picking a meeting slot.
 */
export type StepKind = "app" | "code" | "schedule";

export interface BaseStepDef {
  id: BaseStepId;
  label: string;
  detail: string;
  thumbLabel: string;
}

export interface ExtraStepDef {
  label: string;
  detail: string;
  kind: StepKind;
  thumbLabel?: string;
}

/**
 * Persisted to Firestore. The typed-but-unsubmitted postcard code is
 * deliberately absent — it is transient input, kept in local draft state.
 */
export interface ExtraStep {
  id: string;
  type: ExtraStepType;
  status: StepStatus;
  scheduledSlot: string | null;
}

export interface StepStatusStyle {
  label: string;
  borderClass: string;
  badgeClass: string;
  textClass: string;
}

export type OverallStatusKey = "in_progress" | "action_required" | "under_review" | "rejected";

export interface OverallStatusStyle {
  label: string;
  detail: string;
  borderClass: string;
  fillClass: string;
  badgeClass: string;
  textClass: string;
}

/** A step flattened for rendering — base and admin-requested steps share this shape. */
export interface StepView {
  id: string;
  label: string;
  detail: string;
  kind: StepKind;
  status: StepStatus;
  statusLabel: string;
  borderClass: string;
  badgeClass: string;
  statusTextClass: string;
  badgeContent: string;
  isOpen: boolean;
  interactive: boolean;
  showThumb: boolean;
  thumbLabel?: string;
  showAppPill: boolean;
  showCode: boolean;
  codeValue: string;
  showSlots: boolean;
  slots: string[];
}

export interface OverallView extends OverallStatusStyle {
  key: OverallStatusKey;
}
