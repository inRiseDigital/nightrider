// Real Firestore shapes this admin console reads/writes. Mirrors
// docs/FIRESTORE_SCHEMA.md exactly — do not add fields that aren't there.
// Shared applicant-authored shapes are imported from lib/organizer/types.ts
// (the same doc, read from the other side) rather than redefined here.

import type { Timestamp } from "firebase/firestore";
import type { ApplicantApplication, GpsObservation, StepId, StepStatus, VideoScript } from "@/lib/organizer/types";

export type { ApplicantApplication, GpsObservation, StepId, StepStatus };

export type OrganizerStatus = "none" | "pending" | "approved" | "rejected" | "revoked";

/** `users/{uid}` — only the fields this console reads. */
export interface UserRecord {
  uid: string;
  email: string;
  displayName: string;
  city: string;
  phone: string;
  instagram: string;
  isAdmin: boolean;
  organizerStatus: OrganizerStatus;
  organizerApplication: ApplicantApplication | null;
  /** organizerApplication.submittedAt — kept separate since the shared ApplicantApplication type omits it. */
  applicationSubmittedAt: Timestamp | null;
  createdAt: Timestamp | null;
  updatedAt: Timestamp | null;
}

/** `users/{uid}/private/organizerReview.steps.<id>` — full admin-owned shape. */
export interface AdminReviewStep {
  status: StepStatus;
  attempt: number;
  note: string;
  reviewedAt: Timestamp | null;
  reviewedBy: string | null;
  venueId: string | null;
  mediaDeletedAt: Timestamp | null;
  /** video only: the walkthrough script this admin (or another) published. */
  script: VideoScript | null;
}

/** `users/{uid}/private/organizerReview` — the verdict document, in full. */
export interface AdminReviewDoc {
  status: OrganizerStatus;
  appliedAt: Timestamp | null;
  decidedAt: Timestamp | null;
  decidedBy: string;
  rejectionReason: string;
  phoneVerified: boolean;
  steps: Record<StepId, AdminReviewStep>;
  updatedAt: Timestamp | null;
}

export type VenueStatus = "active" | "closed";
export type VenueSource = "osm" | "organizer" | "admin";

/** `venues/{venueId}` */
export interface Venue {
  id: string;
  name: string;
  geo: { latitude: number; longitude: number } | null;
  geohash: string;
  type: string;
  typeLabel: string;
  city: string;
  countryCode: string;
  address: string;
  openingHours: string;
  phone: string;
  website: string;
  photos: string[];
  source: VenueSource;
  osmId: string | null;
  ownerUid: string | null;
  verified: boolean;
  status: VenueStatus;
  createdAt: Timestamp | null;
  updatedAt: Timestamp | null;
}

/** The closed enum firestore.rules accepts for `logs/{logId}.action`. */
export type LogAction =
  | "event.publish"
  | "event.archive"
  | "organizer.approve"
  | "organizer.reject"
  | "organizer.revoke"
  | "venue.create"
  | "report.delete"
  | "kyc.needsInfo"
  | "kyc.accept"
  | "kyc.script";

export type LogTargetType = "event" | "venue" | "user" | "report";

/** `logs/{logId}` */
export interface LogEntry {
  id: string;
  action: LogAction;
  actorUid: string;
  targetType: LogTargetType;
  targetId: string;
  summary: string;
  at: Timestamp | null;
}

/**
 * A step's real display status layers the applicant's own advisory claim on
 * top of the review doc's stored status — mirrors lib/organizer/derive.ts
 * exactly, so both sides of the review flow agree on what "submitted" means.
 * Nothing here is written to Firestore; it's presentation only.
 */
export function deriveDisplayStepStatus(rawStatus: StepStatus, applicantClaim: boolean): StepStatus {
  return rawStatus === "active" && applicantClaim ? "submitted" : rawStatus;
}

// ---------------------------------------------------------------------------
// events/{eventId} — added for the admin console's Event review queue
// (Phase 2, data seam). Mirrors docs/FIRESTORE_SCHEMA.md's `events/{eventId}`
// exactly, trimmed to the fields this console's queue reads/writes. Events are
// already live when submitted (post-moderation, not a pre-publish gate): the
// queue only clears `moderation.flag` or archives the event with a reason.
// ---------------------------------------------------------------------------

export type EventStatus = "draft" | "scheduled" | "in_review" | "published" | "cancelled" | "archived";
export type EventModerationFlag = "" | "pending" | "clean" | "rejected";
export type EventSource = "organizer" | "admin" | "scraped";

export interface EventPerformer {
  name: string;
  type: "DJ" | "Band" | "Comedian" | "LiveAct" | "Other";
  bio: string;
}

export interface EventTicketTier {
  name: string;
  price: number;
  qty: number;
}

/** admin/producer-owned, pinned — the review queue's own state on the event. */
export interface EventModeration {
  flag: EventModerationFlag;
  requestedAt: Timestamp | null;
  eta: Timestamp | null;
  reviewedBy: string | null;
  note: string;
}

/** `events/{eventId}` — only the fields the review queue reads. */
export interface EventDoc {
  id: string;
  name: string;
  description: string;
  venueId: string | null;
  venueName: string;
  city: string;
  countryCode: string;
  startAt: Timestamp | null;
  endAt: Timestamp | null;
  price: { min: number; max: number; currency: string; isFree: boolean };
  coverImage: string;
  genre: string;
  performers: EventPerformer[];
  policies: { ageRestriction: number };
  interestedCount: number;
  status: EventStatus;
  source: EventSource;
  organizerUid: string | null;
  recurring: boolean;
  recurrenceLabel: string;
  tickets: { currency: string; tiers: EventTicketTier[] };
  moderation: EventModeration;
  createdAt: Timestamp | null;
  updatedAt: Timestamp | null;
}
