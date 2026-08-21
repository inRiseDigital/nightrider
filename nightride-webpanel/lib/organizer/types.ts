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
 * Mirrors `ReviewStep.status` in docs/FIRESTORE_SCHEMA.md exactly. This is
 * admin-owned verdict data — the applicant can never write it. `submitted` is
 * a locally-derived presentation state (see lib/organizer/derive.ts): the
 * review doc has no server trigger that flips 'active' to 'submitted' the
 * moment a file lands in Storage, so the UI infers it from the applicant's own
 * advisory `uploaded`/`venueAddress` claim until an admin looks at it.
 */
export type StepStatus = "pending" | "active" | "submitted" | "needs_info" | "accepted";

/** Matches `OrganizerApplication.steps` / `organizerReview.steps` keys exactly. */
export type StepId = "venueAddress" | "nic" | "selfie" | "video" | "gps";

/**
 * The steps whose advisory `uploaded` flag exists in the schema. All three are
 * Storage-backed; only `video` is uploaded from the browser — nic and selfie
 * are captured and uploaded by the mobile app, which then sets their flag.
 */
export type UploadStepId = "nic" | "selfie" | "video";

/**
 * How a step is cleared: a typed form (venueAddress), a browser upload
 * (video), or the Night Ride mobile app (nic/selfie/gps — live captures this
 * webpanel cannot make: a file picker cannot prove an ID scan or a selfie was
 * taken on the spot, and a browser cannot run geolocator's mocked-location
 * check).
 */
export type StepKind = "address" | "upload" | "app";

export interface BaseStepDef {
  id: StepId;
  label: string;
  detail: string;
  kind: StepKind;
  /** Placeholder tile copy — the mobile-app-only steps stand in with one. */
  thumbLabel?: string;
}

/** `users/{uid}.organizerApplication.steps.venueAddress` — applicant-typed, advisory. */
export interface VenueAddressDraft {
  address: string;
  city: string;
  countryCode: string;
  geo: { latitude: number; longitude: number } | null;
  /** "" if the pin was hand-placed rather than resolved from a geocoder. */
  placeId: string;
}

/** `users/{uid}.organizerApplication.profile` — no collection UI exists yet; kept empty. */
export interface ApplicantProfile {
  orgName: string;
  venueName: string;
  instagram: string;
  website: string;
  bio: string;
  eventTypes: string[];
  eventsPerMonth: number;
}

/** `GpsObservation` — written by the mobile app's geolocator, read-only here. */
export interface GpsObservation {
  point: { latitude: number; longitude: number };
  accuracyM: number;
  mocked: boolean;
  capturedAt: unknown;
  attempt: number;
}

export interface ApplicantSteps {
  venueAddress: VenueAddressDraft | null;
  nic: { uploaded: boolean };
  selfie: { uploaded: boolean };
  video: { uploaded: boolean };
  gps: { attempts: GpsObservation[] };
}

/**
 * `users/{uid}.organizerApplication` — applicant-authored and advisory only.
 * Nothing here gates access; the verdict lives in `ReviewDoc` below.
 */
export interface ApplicantApplication {
  submitted: boolean;
  profile: ApplicantProfile;
  steps: ApplicantSteps;
}

/** `users/{uid}/private/organizerReview.steps.<id>` — admin-owned. */
export interface ReviewStep {
  status: StepStatus;
  attempt: number;
  note: string;
  venueId: string | null;
}

export type ReviewStatus = "none" | "pending" | "approved" | "rejected" | "revoked";

/**
 * `users/{uid}/private/organizerReview` — the verdict document. Only the
 * fields this UI actually reads; see docs/FIRESTORE_SCHEMA.md for the rest
 * (decidedAt, decidedBy, phoneVerified, reviewedAt/reviewedBy, mediaDeletedAt).
 */
export interface ReviewDoc {
  status: ReviewStatus;
  rejectionReason: string;
  steps: Record<StepId, ReviewStep>;
}

export interface StepStatusStyle {
  label: string;
  borderClass: string;
  badgeClass: string;
  textClass: string;
}

export type OverallStatusKey = "in_progress" | "action_required" | "under_review" | "approved" | "rejected";

export interface OverallStatusStyle {
  label: string;
  detail: string;
  borderClass: string;
  fillClass: string;
  badgeClass: string;
  textClass: string;
}

/** A step flattened for rendering. */
export interface StepView {
  id: StepId;
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
  /** False only while the review doc says this step is genuinely locked ('pending'). */
  interactive: boolean;
  /** True once the applicant's own claim is ahead of what the review doc has caught up to. */
  awaitingReview: boolean;
  /** True when the review doc allows the applicant to act right now (upload/save/etc). */
  canAct: boolean;
  /** The admin's request or rejection note for this step, "" otherwise. */
  note: string;
  /** The admin-owned attempt counter this step's Storage paths are keyed by. */
  attempt: number;
  thumbLabel?: string;
}

export interface OverallView extends OverallStatusStyle {
  key: OverallStatusKey;
}
