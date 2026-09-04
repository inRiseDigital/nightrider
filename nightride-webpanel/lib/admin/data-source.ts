// The read/write seam for the five new admin sections (plus Dashboard). One
// method per read and mutation the view-model hooks in these sections need.
// Signatures follow lib/admin/firestore.ts's own style: async reads returning
// parsed types, mutations returning Promise<void> and throwing on failure —
// the hooks' runAction() catches. lib/admin/data-source-instance.ts is the
// only place that picks which implementation backs this interface; wiring
// this to Firestore later is a one-file change.

import type { EventDoc, LogEntry, UserRecord, Venue } from "./schema";
import type {
  AuditActionKind,
  AuditRange,
  EventQueueFlag,
  UserAccountState,
  UserModerationState,
  VenueCheckKey,
  VenueCheckState,
} from "./view-models";

// ---------------------------------------------------------------------------
// Filter argument shapes
// ---------------------------------------------------------------------------

export interface EventQueueFilter {
  status: "all" | "pending" | "approved" | "rejected";
  search: string;
}

export interface VenueDirectoryFilter {
  search: string;
  city: string | "all";
  verifyState: "all" | "verified" | "checksOpen" | "failed" | "suspended";
}

export interface UserDirectoryFilter {
  search: string;
  role: "all" | "Party-goer" | "Organizer" | "Admin";
  moderationState: "all" | UserModerationState;
}

export interface AuditFilter {
  actor: string | "all";
  type: "all" | "Review" | "Organizer" | "Venue" | "Account" | "Access";
  range: AuditRange;
  search: string;
}

// ---------------------------------------------------------------------------
// Read-model row shapes the data source hands back — one level below the
// view models in view-models.ts (which add presentation-only derivations
// like colors and formatted labels on top of these).
// ---------------------------------------------------------------------------

export interface DashboardCounts {
  pendingApplications: number;
  eventsInReview: number;
  activeVenues: number;
  activeOrganizers: number;
}

export interface EventQueueEntry {
  event: EventDoc;
  organizer: UserRecord | null;
  venue: Venue | null;
  flags: EventQueueFlag[];
  reviewedByLabel: string | null;
}

export interface VenueVerification {
  venue: Venue;
  organizer: UserRecord | null;
  checks: Record<VenueCheckKey, VenueCheckState>;
  suspended: boolean;
  eventCount: number;
  capacity: number;
  licenceNumber: string;
  licenceExpiryLabel: string;
}

export interface UserDirectoryEntry {
  user: UserRecord;
  accountState: UserAccountState;
  /** which of the four console states — see UserModerationState in ./view-models. */
  moderationState: UserModerationState;
  disabledReason: string | null;
  lastActiveLabel: string;
  nightsOut: number;
  savedCount: number;
  device: string;
  note: string | null;
  organizerVenueName: string | null;
  /** e.g. "Content moderation · London" — display-only, admins have no real scope. */
  adminScopeLabel: string | null;
}

export interface AdminRosterEntry {
  user: UserRecord;
  displayLevel: string;
  cityScopeLabel: string;
  addedLabel: string;
  lastActiveLabel: string;
  locked: boolean;
  invitePending: boolean;
  /**
   * Access has been revoked but the row is still listed (dimmed, restorable).
   * Distinct from simply not being on the roster at all. Wired for real this
   * reads `users/{uid}.isAdmin === false` on someone who was previously
   * granted it — which is why revoking has to be an Admin-SDK write, not a
   * client one.
   */
  revoked: boolean;
}

export interface AuditLogEntry {
  log: LogEntry | { id: string; action: AuditActionKind; actorUid: string; targetId: string; summary: string; atLabel: string };
  actorLabel: string;
  cityLabel: string;
}

// ---------------------------------------------------------------------------
// The interface
// ---------------------------------------------------------------------------

export interface AdminDataSource {
  // Dashboard ----------------------------------------------------------
  getDashboardCounts(): Promise<DashboardCounts>;
  listRecentActivity(max?: number): Promise<LogEntry[]>;

  // Event review queue ---------------------------------------------------
  listEventQueue(filter: EventQueueFilter): Promise<EventQueueEntry[]>;
  getEventQueueEntry(eventId: string): Promise<EventQueueEntry | null>;
  approveEvent(eventId: string, adminUid: string): Promise<void>;
  rejectEvent(eventId: string, adminUid: string, reason: string): Promise<void>;
  /** Post-moderation reopen: clears a prior decision back to `moderation.flag = 'pending'`. */
  reopenEvent(eventId: string, adminUid: string): Promise<void>;

  // Venues (global directory) --------------------------------------------
  listVenueDirectory(filter: VenueDirectoryFilter): Promise<VenueVerification[]>;
  getVenueVerification(venueId: string): Promise<VenueVerification | null>;
  setVenueCheckState(venueId: string, key: VenueCheckKey, state: VenueCheckState, adminUid: string): Promise<void>;
  setVenueSuspended(venueId: string, suspended: boolean, adminUid: string): Promise<void>;

  // Users & organizers -----------------------------------------------------
  listUserDirectory(filter: UserDirectoryFilter): Promise<UserDirectoryEntry[]>;
  getUserDirectoryEntry(uid: string): Promise<UserDirectoryEntry | null>;
  setUserModerationState(uid: string, state: UserModerationState, adminUid: string): Promise<void>;

  // Roles & access -----------------------------------------------------------
  listAdminRoster(): Promise<AdminRosterEntry[]>;
  inviteAdmin(name: string, email: string, cityScope: string, invitedByUid: string): Promise<void>;
  revokeAdminAccess(uid: string, adminUid: string): Promise<void>;
  restoreAdminAccess(uid: string, adminUid: string): Promise<void>;

  // Audit log ---------------------------------------------------------------
  listAudit(filter: AuditFilter): Promise<AuditLogEntry[]>;
}
