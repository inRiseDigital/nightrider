// Real Firestore shapes this admin console reads/writes. Mirrors
// docs/FIRESTORE_SCHEMA.md exactly — do not add fields that aren't there.
// Shared applicant-authored shapes are imported from lib/organizer/types.ts
// (the same doc, read from the other side) rather than redefined here.

import type { Timestamp } from "firebase/firestore";
import type { ApplicantApplication, GpsObservation, StepId, StepStatus } from "@/lib/organizer/types";

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
  | "kyc.accept";

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
