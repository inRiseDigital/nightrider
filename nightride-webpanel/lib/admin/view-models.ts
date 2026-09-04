// Typed shapes the five new admin sections' hooks return, plus Dashboard's.
// These are presentation-layer view models, not Firestore doc shapes — see
// ./schema.ts for those. A hook builds one of these from a data-source read
// (./data-source.ts) the same way lib/admin/useOverviewData.ts already turns
// LogEntry[] into ActivityRow[].
//
// `simulated: true` marks a field with NO real Firestore source, ever, given
// the current schema — see docs/FIRESTORE_SCHEMA.md. Components must render
// `<SimulatedBadge/>` next to any such field. Everything else here is either a
// real field, or a pure derivation of real fields (documented per-field).

import type { BadgeType } from "./m3-data";
import type { EventStatus, LogAction, OrganizerStatus } from "./schema";

// ---------------------------------------------------------------------------
// Shared support types
// ---------------------------------------------------------------------------

/** Wraps a field that has no real Firestore source and is fabricated by the mock. */
export interface SimulatedValue<T> {
  readonly value: T;
  readonly simulated: true;
}

export function simulated<T>(value: T): SimulatedValue<T> {
  return { value, simulated: true };
}

export interface ActionResult {
  ok: boolean;
  error?: string;
}

export interface StatTile {
  label: string;
  value: string;
  tone: BadgeType;
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

export interface DashboardStat {
  id: "pendingApplications" | "eventsInReview" | "activeVenues" | "activeOrganizers";
  label: string;
  icon: string;
  /** real: same counts as firestore.ts's getOverviewCounts()/event-queue count. */
  value: number;
  /** no "vs. yesterday" tracking exists anywhere in the schema — fabricated. */
  delta: SimulatedValue<string>;
}

export interface DashboardActivityRow {
  id: string;
  icon: string;
  tone: BadgeType;
  status: string;
  text: string;
  time: string;
}

export interface DashboardViewModel {
  loading: boolean;
  error: string | null;
  stats: DashboardStat[];
  /** real: logs/{id}, same source as useOverviewData.ts's activity feed. */
  activity: DashboardActivityRow[];
  refresh: () => void;
}

// ---------------------------------------------------------------------------
// Event review queue — post-moderation: events are already live, the queue
// only clears a flag or archives with a reason. No pre-publish gate.
// ---------------------------------------------------------------------------

export type EventQueueStatusFilter = "all" | "pending" | "approved" | "rejected";

export interface EventQueueFlag {
  id: string;
  label: string;
  icon: string;
  tone: BadgeType;
  /**
   * true when there is no real detector behind this flag (e.g. "matched a
   * stock photo library" — no image-similarity pipeline exists). false for
   * flags a data-source can actually derive today (e.g. a recurring series,
   * or an end time past the venue's posted hours).
   */
  simulated: boolean;
}

export interface EventQueueRow {
  id: string;
  name: string;
  venue: string;
  venueId: string | null;
  organizer: string;
  organizerUid: string | null;
  city: string;
  /** real: formatted events/{id}.startAt */
  dateLabel: string;
  /** derived from moderation.flag + status — see filters/event-queue.ts */
  status: "pending" | "approved" | "rejected";
  statusTone: BadgeType;
  submittedTimeAgo: string;
  flags: EventQueueFlag[];
  flagCount: number;
  hasDangerFlag: boolean;
}

export interface EventQueueFact {
  label: string;
  value: string;
  mono?: boolean;
}

export interface EventQueueTicketTier {
  name: string;
  price: string;
  qty: string;
}

export interface EventQueueAssetPreview {
  label: string;
  icon: string;
}

export interface EventQueueDetail extends EventQueueRow {
  description: string;
  facts: EventQueueFact[];
  lineup: string[];
  tiers: EventQueueTicketTier[];
  /**
   * The schema stores one coverImage URL, not an asset gallery — the mockup's
   * "3 assets" grid has no backing collection. Fabricated placeholder count.
   */
  assetPreviews: SimulatedValue<EventQueueAssetPreview[]>;
  isPending: boolean;
  isDecided: boolean;
  /** e.g. "Approved by Aisha Darwish · just now" — real once moderation.reviewedBy/updatedAt are resolved to a name. */
  decidedLine: string | null;
  rejectReason: string | null;
}

export interface EventQueueStats {
  awaitingReview: number;
  approvedThisWeek: number;
  rejectedThisWeek: number;
  /** no per-event "entered queue at" tracking cheap enough to query yet — fabricated. */
  oldestInQueue: SimulatedValue<string>;
}

export interface EventQueueViewModel {
  loading: boolean;
  error: string | null;
  rows: EventQueueRow[];
  stats: EventQueueStats;
  selectedId: string | null;
  select: (id: string) => void;
  detail: EventQueueDetail | null;
  statusFilter: EventQueueStatusFilter;
  setStatusFilter: (v: EventQueueStatusFilter) => void;
  search: string;
  setSearch: (v: string) => void;
  rejectReasonDraft: string;
  setRejectReasonDraft: (v: string) => void;
  rejectReasonPresets: string[];
  approve: (id: string) => Promise<ActionResult>;
  reject: (id: string, reason: string) => Promise<ActionResult>;
  /** post-moderation reopen: clears a prior decision, back to "pending" review. */
  reopen: (id: string) => Promise<ActionResult>;
  actionBusy: boolean;
  actionError: string | null;
  refresh: () => void;
}

// ---------------------------------------------------------------------------
// Venues (global directory — distinct from the per-organizer venue list
// already served by useVenueDetail.ts)
// ---------------------------------------------------------------------------

export type VenueCheckKey = "licence" | "gps" | "video";
export type VenueCheckState = "verified" | "pending" | "failed";

/**
 * Backed by the real schema: `venues/{id}.verification.{license,gps,video}`,
 * each a VenueVerifyStep of `{status, attempt, note, reviewedAt, reviewedBy}`
 * whose shape firestore.rules enforces (see verificationStepOk). Our three
 * states map onto that step status — `done` is verified, `needs_info` is
 * failed, `active`/`submitted` are pending. `venues/{id}.verified: boolean`
 * is a separate summary flag, not the per-check source.
 *
 * What is NOT backed: the licence *number* and *expiry* shown in the check's
 * meta line — `verification.license` stores review-workflow state only, so
 * those come from the mock and need schema work to be real.
 */
export interface VenueCheck {
  key: VenueCheckKey;
  title: string;
  icon: string;
  state: VenueCheckState;
  meta: string;
}

export type VenueVerifyState = "verified" | "checksOpen" | "failed";

export interface VenueRow {
  id: string;
  name: string;
  city: string;
  organizer: string;
  organizerUid: string | null;
  /** derived from `checks` — see filters/venues.ts. */
  verifyState: VenueVerifyState;
  openChecksCount: number;
  /**
   * One field, one source of truth. The mockup carries two parallel maps
   * (`suspendedVenues` from the org-scoped screen, `globalSuspended` from this
   * directory) OR-ed together at render — a state bug that only "worked"
   * because both lived in one component. Real schema has no suspend bit at
   * all today (VenueStatus is only 'active' | 'closed'); wiring this needs
   * either a new `suspended: boolean` field or reusing `status`.
   */
  suspended: boolean;
  /** no capacity field on venues/{id} — fabricated. */
  capacity: SimulatedValue<number>;
  /** derived: count of events/{id} where venueId == this venue's id. */
  eventCount: number;
}

export interface VenueDetailField {
  label: string;
  value: string;
  mono?: boolean;
}

export interface VenueEventSummary {
  id: string;
  name: string;
  dateLabel: string;
  status: EventStatus;
  statusTone: BadgeType;
}

export interface VenueHistoryEntry {
  id: string;
  text: string;
  actorLabel: string;
  timeLabel: string;
  icon: string;
  tone: BadgeType;
}

export interface VenueDetail extends VenueRow {
  address: string;
  openingHours: string;
  phone: string;
  /** no licence number/expiry field anywhere on venues/{id} — fabricated. */
  licenceNumber: SimulatedValue<string>;
  licenceExpiryLabel: SimulatedValue<string>;
  /** real once `verified` flips true — derived from updatedAt; '—' while unverified. */
  verifiedOnLabel: string;
  checks: VenueCheck[];
  events: VenueEventSummary[];
  /**
   * logs/{id}.action's closed enum (see schema.ts LogAction) has no venue
   * check-approval or suspend/un-suspend actions — this history is fabricated
   * beyond the one real `venue.create` entry. Needs LogAction + firestore.rules
   * expansion to log for real.
   */
  history: SimulatedValue<VenueHistoryEntry[]>;
}

export interface VenueFilterState {
  search: string;
  city: string | "all";
  verifyState: VenueVerifyState | "all" | "suspended";
}

export interface VenuesViewModel {
  loading: boolean;
  error: string | null;
  rows: VenueRow[];
  stats: StatTile[];
  filter: VenueFilterState;
  setSearch: (v: string) => void;
  setCity: (v: string | "all") => void;
  setVerifyState: (v: VenueFilterState["verifyState"]) => void;
  selectedId: string | null;
  select: (id: string | null) => void;
  detail: VenueDetail | null;
  setCheckState: (venueId: string, key: VenueCheckKey, state: VenueCheckState) => Promise<ActionResult>;
  toggleSuspend: (venueId: string) => Promise<ActionResult>;
  actionBusy: boolean;
  actionError: string | null;
  refresh: () => void;
}

// ---------------------------------------------------------------------------
// Users & organizers (party-goers, approved organizers, admins — one directory)
// ---------------------------------------------------------------------------

export type UserRoleLabel = "Party-goer" | "Organizer" | "Admin";

/**
 * The only real account-level toggle is Firebase Auth's `disabled` flag (see
 * docs/FIRESTORE_SCHEMA.md's logs section: "Account suspension is the Firebase
 * Auth `disabled` flag, not a Firestore field"). The mockup's four states
 * (Active / Suspended / Banned / Deactivated) collapse to two real ones.
 */
export type UserAccountState = "active" | "disabled";

export interface UserRow {
  uid: string;
  name: string;
  email: string;
  phone: string;
  city: string;
  role: UserRoleLabel;
  /** organizers-only per product decision; party-goers carry no identity state — "n/a" is not a status, it's the absence of one. */
  identity: OrganizerStatus | "n/a";
  accountState: UserAccountState;
  /**
   * Auth's `disabled` flag carries no reason text. The mockup's
   * Suspended/Banned/Deactivated distinction and its free-text note are
   * fabricated display dressing over the one real boolean.
   */
  disabledReasonLabel: SimulatedValue<string> | null;
  /** real: users/{uid}.createdAt */
  joinedLabel: string;
  /** no session/last-seen tracking in the schema — fabricated. */
  lastActiveLabel: SimulatedValue<string>;
  /** no attendance-history aggregate in the schema — fabricated. */
  nightsOut: SimulatedValue<number>;
  /** no saved-events aggregate in the schema — fabricated. */
  savedCount: SimulatedValue<number>;
  /** no device/session tracking in the schema — fabricated. */
  device: SimulatedValue<string>;
  /** display-only per product decision: isAdmin is the only real privilege bit. */
  adminScopeLabel: SimulatedValue<string> | null;
}

export interface UserTimelineEntry {
  icon: string;
  tone: BadgeType;
  text: string;
  timeLabel: string;
}

export interface UserDetail extends UserRow {
  /** no activity-timeline collection in the schema — every entry here is fabricated. */
  timeline: SimulatedValue<UserTimelineEntry[]>;
  note: string | null;
  organizerVenueName: string | null;
}

export interface UserFilterState {
  search: string;
  role: UserRoleLabel | "all";
  accountState: UserAccountState | "all";
}

export interface UsersViewModel {
  loading: boolean;
  error: string | null;
  rows: UserRow[];
  stats: StatTile[];
  filter: UserFilterState;
  setSearch: (v: string) => void;
  setRole: (v: UserFilterState["role"]) => void;
  setAccountStateFilter: (v: UserFilterState["accountState"]) => void;
  selectedId: string | null;
  select: (id: string | null) => void;
  detail: UserDetail | null;
  /** flips Firebase Auth's `disabled` flag via the Admin SDK — mirrors banOrganizerAccount()'s wiring style. */
  setAccountState: (uid: string, state: UserAccountState) => Promise<ActionResult>;
  actionBusy: boolean;
  actionError: string | null;
  refresh: () => void;
}

// ---------------------------------------------------------------------------
// Roles & access — admin roster. `users/{uid}.isAdmin` is the only real
// authorization bit; everything else here is display-only per product
// decision and must not be read as an enforced privilege tier.
// ---------------------------------------------------------------------------

export interface AdminRow {
  uid: string;
  name: string;
  email: string;
  initials: string;
  /** real: users/{uid}.isAdmin — the only bit that actually gates anything. */
  isAdmin: boolean;
  /** cosmetic label only ("Super admin" / "Admin") — no tiered role field exists, and none should be inferred from this string. */
  displayLevel: SimulatedValue<string>;
  /** cosmetic ("All cities" / "Dubai · London") — not enforced by firestore.rules or anywhere else. */
  cityScopeLabel: SimulatedValue<string>;
  /** no admin-grant audit trail field exists yet — fabricated. */
  addedLabel: SimulatedValue<string>;
  /** no session tracking — fabricated. */
  lastActiveLabel: SimulatedValue<string>;
  /** true only for the platform-owner row; cosmetic — not a real permission gate, just "the UI won't offer to revoke this one." */
  locked: boolean;
  /** real: mirrors isAdmin. "Invite pending" has no real backing — there is no admin-invite flow in the schema, so that state is mock-only. */
  statusLabel: "Active" | "Revoked" | SimulatedValue<"Invite pending">;
}

export interface NewAdminDraft {
  name: string;
  email: string;
  cityScope: string;
}

export interface RolesViewModel {
  loading: boolean;
  error: string | null;
  rows: AdminRow[];
  activeCountLabel: string;
  addAdminOpen: boolean;
  toggleAddAdmin: () => void;
  newAdminDraft: NewAdminDraft;
  setNewAdminDraft: (draft: Partial<NewAdminDraft>) => void;
  canSubmitNewAdmin: boolean;
  createAdmin: () => Promise<ActionResult>;
  confirmRevokeId: string | null;
  askRevoke: (uid: string) => void;
  cancelRevoke: () => void;
  revokeAdmin: (uid: string) => Promise<ActionResult>;
  toast: string | null;
  /** static display copy, not per-admin data. */
  adminCapabilities: string[];
  superAdminOnlyCapabilities: string[];
  actionBusy: boolean;
  actionError: string | null;
  refresh: () => void;
}

// ---------------------------------------------------------------------------
// Audit log
// ---------------------------------------------------------------------------

export type AuditTypeBadge = "Review" | "Organizer" | "Venue" | "Account" | "Access";
export type AuditRange = "24h" | "7d" | "30d" | "all";

/**
 * logs/{id}.action is a closed enum in firestore.rules (see schema.ts's
 * LogAction) with exactly 10 values, none of which cover admin-roster or
 * account-moderation actions. The members below with no LogAction counterpart
 * are NOT valid `logs/{id}.action` values today — the mockup's audit trail
 * for Roles & Users actions (add/revoke admin, suspend/ban an account, reset
 * a password) has no real logging path until LogAction (and firestore.rules'
 * matching allow-list) is extended to cover them.
 */
export type AuditActionKind =
  | LogAction
  | "role.admin.add"
  | "role.admin.revoke"
  | "role.admin.scopeChange"
  | "account.suspend"
  | "account.unsuspend"
  | "account.ban"
  | "account.unban"
  | "account.passwordReset"
  | "venue.suspend"
  | "venue.unsuspend"
  | "venue.transfer"
  | "venue.checkApprove"
  | "venue.checkFail"
  | "event.flag"
  | "event.submitted"
  | "organizer.submitted";

export interface AuditRow {
  id: string;
  timeLabel: string;
  /** real: logs/{id}.actorUid, resolved to a display name (or "System") at read time — needs a uid -> name lookup. */
  actorLabel: string;
  actorInitials: string;
  isSystemActor: boolean;
  action: AuditActionKind;
  actionLabel: string;
  /** real: logs/{id}.targetId, ideally resolved to a display name — needs a join at wiring time. */
  target: string;
  type: AuditTypeBadge;
  tone: BadgeType;
  /**
   * logs/{id} has no city field. A real value needs joining the target's
   * (venue or user) city — not stored on the log entry itself.
   */
  cityLabel: SimulatedValue<string>;
}

export interface AuditFilterState {
  actor: string | "all";
  type: AuditTypeBadge | "all";
  range: AuditRange;
  search: string;
}

export interface AuditViewModel {
  loading: boolean;
  error: string | null;
  rows: AuditRow[];
  countLabel: string;
  actors: string[];
  filter: AuditFilterState;
  setActor: (v: string | "all") => void;
  setType: (v: AuditTypeBadge | "all") => void;
  setRange: (v: AuditRange) => void;
  setSearch: (v: string) => void;
  refresh: () => void;
}
