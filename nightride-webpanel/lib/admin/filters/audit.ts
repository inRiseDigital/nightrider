// Pure, React-free filter/search/derivation functions for the audit log.
// Called by the useAudit hook (owned by another agent) and exercised
// directly by tests — no React, no side effects. Date-range bucketing uses
// the real clock (Date.now()), unlike the design mockup's hardcoded
// `new Date(2026, 8, 4)` "now".

import type { Timestamp } from "firebase/firestore";
import type { BadgeType } from "../m3-data";
import type { AuditActionKind, AuditRange, AuditTypeBadge } from "../view-models";

const ACTION_TYPE: Record<AuditActionKind, AuditTypeBadge> = {
  "event.publish": "Review",
  "event.archive": "Review",
  "event.flag": "Review",
  "event.submitted": "Review",
  "organizer.approve": "Organizer",
  "organizer.reject": "Organizer",
  "organizer.revoke": "Organizer",
  "organizer.submitted": "Organizer",
  "kyc.needsInfo": "Organizer",
  "kyc.accept": "Venue",
  "kyc.script": "Organizer",
  "venue.create": "Venue",
  "venue.suspend": "Venue",
  "venue.unsuspend": "Venue",
  "venue.transfer": "Venue",
  "venue.checkApprove": "Venue",
  "venue.checkFail": "Venue",
  "report.delete": "Review",
  "account.suspend": "Account",
  "account.unsuspend": "Account",
  "account.ban": "Account",
  "account.unban": "Account",
  "account.passwordReset": "Account",
  "role.admin.add": "Access",
  "role.admin.revoke": "Access",
  "role.admin.scopeChange": "Access",
};

const TYPE_TONE: Record<AuditTypeBadge, BadgeType> = {
  Review: "info",
  Venue: "neutral",
  Organizer: "success",
  Account: "danger",
  Access: "warning",
};

export function auditActionType(action: AuditActionKind): AuditTypeBadge {
  return ACTION_TYPE[action] ?? "Review";
}

export function auditTypeTone(type: AuditTypeBadge): BadgeType {
  return TYPE_TONE[type] ?? "neutral";
}

const RANGE_DAYS: Record<AuditRange, number> = { "24h": 1, "7d": 7, "30d": 30, all: Infinity };

/** `nowMs` defaults to the real clock — pass it explicitly from a test for determinism. */
export function withinAuditRange(at: Timestamp | null, range: AuditRange, nowMs: number = Date.now()): boolean {
  if (!at) return range === "all";
  const days = RANGE_DAYS[range] ?? Infinity;
  if (days === Infinity) return true;
  return (nowMs - at.toDate().getTime()) / 86_400_000 < days;
}

export interface AuditSearchable {
  actionLabel: string;
  target: string;
  actorLabel: string;
}

export function matchesAuditSearch(row: AuditSearchable, search: string): boolean {
  const q = search.trim().toLowerCase();
  if (!q) return true;
  return (
    row.actionLabel.toLowerCase().includes(q) ||
    row.target.toLowerCase().includes(q) ||
    row.actorLabel.toLowerCase().includes(q)
  );
}

export function matchesAuditActor(actorLabel: string, filter: string | "all"): boolean {
  return filter === "all" || actorLabel === filter;
}

export function matchesAuditType(type: AuditTypeBadge, filter: AuditTypeBadge | "all"): boolean {
  return filter === "all" || type === filter;
}

export function initialsFor(actorLabel: string): string {
  if (actorLabel === "System") return "";
  return actorLabel
    .split(/\s+/)
    .filter(Boolean)
    .map((w) => w[0])
    .join("")
    .toUpperCase();
}
