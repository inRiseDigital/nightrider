// FABRICATED seed data for the mock AdminDataSource's audit log. Ported from
// docs/design/admin-dashboard-v3.dc.html's getAudit() (same actors, actions,
// targets, and timestamps). Replaced wholesale once
// lib/admin/data-source-instance.ts points at a Firestore-backed
// AdminDataSource.
//
// logs/{id}.action is a closed enum in firestore.rules (see schema.ts's
// LogAction) — many entries below use an AuditActionKind member that is NOT
// one of those 10 values (role/account/venue-management actions). Those rows
// have no real logging path today; see view-models.ts's AuditActionKind
// comment. `cityLabel` is always simulated: logs/{id} carries no city field.

import type { AuditActionKind } from "../view-models";
import { dateAt } from "./seed";

export interface MockAuditRow {
  id: string;
  at: ReturnType<typeof dateAt>;
  actorLabel: string;
  action: AuditActionKind;
  actionLabel: string;
  target: string;
  cityLabel: string;
}

const rows: MockAuditRow[] = [
  { id: "log-1", at: dateAt(2026, 8, 4, 18, 44), actorLabel: "Aisha Darwish", action: "event.publish", actionLabel: "Approved event", target: "Neon Fox Anniversary · Neon Fox", cityLabel: "Melbourne" },
  { id: "log-2", at: dateAt(2026, 8, 4, 18, 2), actorLabel: "Mei Lin", action: "event.archive", actionLabel: "Rejected event", target: "Chapel After Hours · Chapel Underground", cityLabel: "Tokyo" },
  { id: "log-3", at: dateAt(2026, 8, 4, 16, 31), actorLabel: "Tomás Neves", action: "venue.suspend", actionLabel: "Suspended venue", target: "Fox Annex", cityLabel: "Melbourne" },
  { id: "log-4", at: dateAt(2026, 8, 4, 15, 58), actorLabel: "System", action: "event.flag", actionLabel: "Flagged event for duplicate content", target: "Sunset to Sunrise", cityLabel: "Melbourne" },
  { id: "log-5", at: dateAt(2026, 8, 4, 14, 12), actorLabel: "Aisha Darwish", action: "organizer.approve", actionLabel: "Approved organizer application", target: "Riley Khan", cityLabel: "Melbourne" },
  { id: "log-6", at: dateAt(2026, 8, 4, 12, 47), actorLabel: "Grace Okoro", action: "venue.checkApprove", actionLabel: "Approved licence check", target: "Brick Lane Social", cityLabel: "Melbourne" },
  { id: "log-7", at: dateAt(2026, 8, 4, 11, 20), actorLabel: "Mei Lin", action: "kyc.needsInfo", actionLabel: "Requested additional info", target: "Jamie Reyes", cityLabel: "Tokyo" },
  { id: "log-8", at: dateAt(2026, 8, 4, 9, 5), actorLabel: "Aisha Darwish", action: "role.admin.add", actionLabel: "Added admin", target: "Grace Okoro · Melbourne scope", cityLabel: "All cities" },
  { id: "log-9", at: dateAt(2026, 8, 3, 22, 38), actorLabel: "Tomás Neves", action: "account.ban", actionLabel: "Banned account", target: "@johndoe22 · spam reviews", cityLabel: "London" },
  { id: "log-10", at: dateAt(2026, 8, 3, 20, 11), actorLabel: "System", action: "event.submitted", actionLabel: "Received event submission", target: "Basement Bass · The Basement", cityLabel: "London" },
  { id: "log-11", at: dateAt(2026, 8, 3, 18, 49), actorLabel: "Grace Okoro", action: "account.suspend", actionLabel: "Suspended account 7 days", target: "@lane_regular", cityLabel: "Melbourne" },
  { id: "log-12", at: dateAt(2026, 8, 3, 15, 3), actorLabel: "Aisha Darwish", action: "venue.transfer", actionLabel: "Transferred venue", target: "The Basement → Haruto Kobayashi", cityLabel: "London" },
  { id: "log-13", at: dateAt(2026, 8, 2, 19, 27), actorLabel: "Mei Lin", action: "kyc.accept", actionLabel: "Approved video walkthrough", target: "Warehouse 9", cityLabel: "Tokyo" },
  { id: "log-14", at: dateAt(2026, 8, 2, 13, 44), actorLabel: "Tomás Neves", action: "organizer.reject", actionLabel: "Rejected organizer application", target: "Yuki Walker · face mismatch", cityLabel: "Tokyo" },
  { id: "log-15", at: dateAt(2026, 8, 2, 10, 2), actorLabel: "Aisha Darwish", action: "role.admin.revoke", actionLabel: "Revoked admin access", target: "Dev Sandbox account", cityLabel: "All cities" },
  { id: "log-16", at: dateAt(2026, 8, 1, 23, 15), actorLabel: "System", action: "venue.checkFail", actionLabel: "GPS check failed", target: "Chapel Underground", cityLabel: "Tokyo" },
  { id: "log-17", at: dateAt(2026, 8, 1, 17, 40), actorLabel: "Grace Okoro", action: "account.passwordReset", actionLabel: "Reset password", target: "kenji.yamamoto@mail.com", cityLabel: "Melbourne" },
  { id: "log-18", at: dateAt(2026, 7, 31, 21, 6), actorLabel: "Mei Lin", action: "event.publish", actionLabel: "Approved event", target: "Techno Fridays · 12-date series", cityLabel: "Tokyo" },
  { id: "log-19", at: dateAt(2026, 7, 30, 14, 22), actorLabel: "Tomás Neves", action: "role.admin.scopeChange", actionLabel: "Changed admin scope", target: "Mei Lin → Tokyo only", cityLabel: "All cities" },
  { id: "log-20", at: dateAt(2026, 7, 29, 11, 11), actorLabel: "Aisha Darwish", action: "venue.unsuspend", actionLabel: "Un-suspended venue", target: "Fahidi Social Club", cityLabel: "London" },
  { id: "log-21", at: dateAt(2026, 7, 12, 9, 38), actorLabel: "System", action: "organizer.submitted", actionLabel: "Received organizer application", target: "Layla Osman", cityLabel: "Dubai" },
  { id: "log-22", at: dateAt(2026, 7, 4, 8, 20), actorLabel: "Aisha Darwish", action: "role.admin.add", actionLabel: "Added admin", target: "Tomás Neves · Dubai, London scope", cityLabel: "All cities" },
];

export function allMockAudit(): MockAuditRow[] {
  return rows;
}
