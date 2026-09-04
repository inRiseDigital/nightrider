// Composes the FABRICATED seed modules in this directory (./seed.ts,
// ./users.ts, ./venues.ts, ./events.ts, ./roles.ts, ./audit.ts) into
// `mockAdminDataSource: AdminDataSource`. This is the mock implementation of
// the seam defined in ../data-source.ts — see ../data-source-instance.ts for
// which implementation is actually wired up.

import type { LogAction, LogEntry, LogTargetType } from "../schema";
import type {
  AdminDataSource,
  AdminRosterEntry,
  AuditFilter,
  AuditLogEntry,
  DashboardCounts,
  EventQueueEntry,
  EventQueueFilter,
  UserDirectoryEntry,
  UserDirectoryFilter,
  VenueDirectoryFilter,
  VenueVerification,
} from "../data-source";
import { deriveEventQueueStatus, matchesEventQueueSearch, matchesEventQueueStatus } from "../filters/event-queue";
import { matchesUserAccountState, matchesUserRole, matchesUserSearch, deriveUserRole } from "../filters/users";
import { deriveVenueVerifyState, matchesVenueCity, matchesVenueSearch, matchesVenueVerifyFilter } from "../filters/venues";
import { auditActionType, matchesAuditActor, matchesAuditSearch, matchesAuditType, withinAuditRange } from "../filters/audit";
import { allMockAdmins, addMockAdmin, setMockAdminRevoked } from "./roles";
import { allMockAudit } from "./audit";
import { allMockEvents, decideMockEvent, getMockEvent, reopenMockEvent } from "./events";
import { allMockUsers, getMockUser, setMockUserAccountState } from "./users";
import { allMockVenues, getMockVenue, setMockVenueCheck, setMockVenueSuspended } from "./venues";

// logs/{id}.action's closed enum per firestore.rules — see schema.ts's LogAction.
const REAL_LOG_ACTIONS = new Set<LogAction>([
  "event.publish",
  "event.archive",
  "organizer.approve",
  "organizer.reject",
  "organizer.revoke",
  "venue.create",
  "report.delete",
  "kyc.needsInfo",
  "kyc.accept",
  "kyc.script",
]);

function findUserDisplayName(uid: string): string {
  return getMockUser(uid)?.record.displayName ?? allMockAdmins().find((a) => a.record.uid === uid)?.record.displayName ?? uid;
}

function organizerNameFor(organizerUid: string): string {
  return getMockUser(organizerUid)?.record.displayName ?? "—";
}

function toEventQueueEntry(id: string): EventQueueEntry | null {
  const e = getMockEvent(id);
  if (!e) return null;
  return {
    event: e.event,
    organizer: getMockUser(e.organizerUid)?.record ?? null,
    venue: getMockVenue(e.event.venueId ?? "")?.venue ?? null,
    flags: e.flags,
    reviewedByLabel: e.reviewedByLabel,
  };
}

function toVenueVerification(id: string): VenueVerification | null {
  const v = getMockVenue(id);
  if (!v) return null;
  return {
    venue: v.venue,
    organizer: getMockUser(v.organizerUid)?.record ?? null,
    checks: v.checks,
    suspended: v.suspended,
    eventCount: allMockEvents().filter((e) => e.event.venueId === id).length,
    capacity: v.capacity,
    licenceNumber: v.licenceNumber,
    licenceExpiryLabel: v.licenceExpiryLabel,
  };
}

function toUserDirectoryEntry(uid: string): UserDirectoryEntry | null {
  const u = getMockUser(uid);
  if (!u) return null;
  return {
    user: u.record,
    accountState: u.accountState,
    disabledReason: u.disabledReason,
    lastActiveLabel: u.lastActiveLabel,
    nightsOut: u.nightsOut,
    savedCount: u.savedCount,
    device: u.device,
    note: u.note,
    organizerVenueName: u.organizerVenueName,
  };
}

export const mockAdminDataSource: AdminDataSource = {
  // Dashboard ------------------------------------------------------------
  async getDashboardCounts(): Promise<DashboardCounts> {
    const users = allMockUsers();
    const events = allMockEvents();
    const venues = allMockVenues();
    return {
      // No applicant-in-review users are seeded in this mock user directory —
      // that queue is org-apps' own (already-real) data, out of this seam's
      // scope. This will read 0 until the two directories are joined.
      pendingApplications: users.filter((u) => u.record.organizerStatus === "pending").length,
      eventsInReview: events.filter((e) => deriveEventQueueStatus(e.event) === "pending").length,
      activeVenues: venues.filter((v) => v.venue.status === "active").length,
      activeOrganizers: users.filter((u) => u.record.organizerStatus === "approved").length,
    };
  },

  async listRecentActivity(max = 8): Promise<LogEntry[]> {
    // Only rows whose action is one of logs/{id}.action's real 10 values can
    // ever be a real LogEntry — everything else in the mock audit trail
    // (role/account/venue-management rows) has no real logging path today,
    // see ../filters/audit.ts's header comment.
    return allMockAudit()
      .filter((r): r is typeof r & { action: LogAction } => REAL_LOG_ACTIONS.has(r.action as LogAction))
      .sort((a, b) => b.at.toMillis() - a.at.toMillis())
      .slice(0, max)
      .map((r) => ({
        id: r.id,
        action: r.action,
        actorUid: r.actorLabel,
        targetType: "event" as LogTargetType,
        targetId: r.target,
        summary: `${r.actionLabel} — ${r.target}`,
        at: r.at,
      }));
  },

  // Event review queue -----------------------------------------------------
  async listEventQueue(filter: EventQueueFilter): Promise<EventQueueEntry[]> {
    return allMockEvents()
      .filter((e) => {
        const status = deriveEventQueueStatus(e.event);
        const organizerName = organizerNameFor(e.organizerUid);
        return (
          matchesEventQueueStatus(status, filter.status) &&
          matchesEventQueueSearch({ name: e.event.name, venueName: e.event.venueName, organizerName }, filter.search)
        );
      })
      .map((e) => toEventQueueEntry(e.event.id))
      .filter((e): e is EventQueueEntry => e !== null);
  },

  async getEventQueueEntry(eventId: string): Promise<EventQueueEntry | null> {
    return toEventQueueEntry(eventId);
  },

  async approveEvent(eventId: string, adminUid: string): Promise<void> {
    decideMockEvent(eventId, "approved", findUserDisplayName(adminUid));
  },

  async rejectEvent(eventId: string, adminUid: string, reason: string): Promise<void> {
    if (!reason.trim()) throw new Error("A rejection needs a reason.");
    decideMockEvent(eventId, "rejected", findUserDisplayName(adminUid), reason);
  },

  async reopenEvent(eventId: string): Promise<void> {
    reopenMockEvent(eventId);
  },

  // Venues (global directory) ----------------------------------------------
  async listVenueDirectory(filter: VenueDirectoryFilter): Promise<VenueVerification[]> {
    return allMockVenues()
      .filter((v) => {
        const verifyState = deriveVenueVerifyState(Object.values(v.checks));
        const organizerName = organizerNameFor(v.organizerUid);
        return (
          matchesVenueSearch({ name: v.venue.name, organizerName, address: v.venue.address }, filter.search) &&
          matchesVenueCity(v.venue.city, filter.city) &&
          matchesVenueVerifyFilter(verifyState, v.suspended, filter.verifyState)
        );
      })
      .map((v) => toVenueVerification(v.venue.id))
      .filter((v): v is VenueVerification => v !== null);
  },

  async getVenueVerification(venueId: string): Promise<VenueVerification | null> {
    return toVenueVerification(venueId);
  },

  async setVenueCheckState(venueId, key, state): Promise<void> {
    setMockVenueCheck(venueId, key, state);
  },

  async setVenueSuspended(venueId, suspended): Promise<void> {
    setMockVenueSuspended(venueId, suspended);
  },

  // Users & organizers -------------------------------------------------------
  async listUserDirectory(filter: UserDirectoryFilter): Promise<UserDirectoryEntry[]> {
    return allMockUsers()
      .filter((u) => {
        const role = deriveUserRole(u.record.isAdmin, u.record.organizerStatus);
        return (
          matchesUserSearch({ name: u.record.displayName, email: u.record.email, phone: u.record.phone }, filter.search) &&
          matchesUserRole(role, filter.role) &&
          matchesUserAccountState(u.accountState, filter.accountState)
        );
      })
      .map((u) => toUserDirectoryEntry(u.record.uid))
      .filter((u): u is UserDirectoryEntry => u !== null);
  },

  async getUserDirectoryEntry(uid: string): Promise<UserDirectoryEntry | null> {
    return toUserDirectoryEntry(uid);
  },

  async setUserAccountState(uid, state): Promise<void> {
    setMockUserAccountState(uid, state);
  },

  // Roles & access -------------------------------------------------------------
  async listAdminRoster(): Promise<AdminRosterEntry[]> {
    return allMockAdmins().map((a) => ({
      user: a.record,
      displayLevel: a.displayLevel,
      cityScopeLabel: a.cityScopeLabel,
      addedLabel: a.addedLabel,
      lastActiveLabel: a.lastActiveLabel,
      locked: a.locked,
      invitePending: a.invitePending,
      revoked: a.revoked,
    }));
  },

  async inviteAdmin(name, email, cityScope): Promise<void> {
    if (!name.trim() || !email.trim()) throw new Error("Name and email are both required.");
    addMockAdmin(name.trim(), email.trim(), cityScope);
  },

  async revokeAdminAccess(uid): Promise<void> {
    const a = setMockAdminRevoked(uid, true);
    if (a?.locked) throw new Error("The platform owner's access can't be revoked.");
  },

  async restoreAdminAccess(uid): Promise<void> {
    setMockAdminRevoked(uid, false);
  },

  // Audit log -----------------------------------------------------------------
  async listAudit(filter: AuditFilter): Promise<AuditLogEntry[]> {
    return allMockAudit()
      .filter(
        (r) =>
          matchesAuditActor(r.actorLabel, filter.actor) &&
          matchesAuditType(auditActionType(r.action), filter.type) &&
          withinAuditRange(r.at, filter.range) &&
          matchesAuditSearch(r, filter.search),
      )
      .sort((a, b) => b.at.toMillis() - a.at.toMillis())
      .map((r) => ({
        log: { id: r.id, action: r.action, actorUid: r.actorLabel, targetId: r.target, summary: r.actionLabel, atLabel: r.at.toDate().toLocaleString() },
        actorLabel: r.actorLabel,
        cityLabel: r.cityLabel,
      }));
  },
};
