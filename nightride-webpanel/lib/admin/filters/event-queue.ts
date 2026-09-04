// Pure, React-free filter/search/derivation functions for the event review
// queue. Called by the useEventQueue hook (owned by another agent) and
// exercised directly by tests — no React, no side effects.

import type { EventDoc } from "../schema";
import type { EventQueueFlag, EventQueueStatusFilter } from "../view-models";

export type EventQueueDecidedStatus = "pending" | "approved" | "rejected";

/** Derives the queue's three-state status from the real post-moderation fields. */
export function deriveEventQueueStatus(event: EventDoc): EventQueueDecidedStatus {
  if (event.moderation.flag === "rejected") return "rejected";
  if (event.status === "published" || event.moderation.flag === "clean") return "approved";
  return "pending";
}

export interface EventQueueSearchable {
  name: string;
  venueName: string;
  organizerName: string;
}

export function matchesEventQueueSearch(row: EventQueueSearchable, search: string): boolean {
  const q = search.trim().toLowerCase();
  if (!q) return true;
  return (
    row.name.toLowerCase().includes(q) ||
    row.venueName.toLowerCase().includes(q) ||
    row.organizerName.toLowerCase().includes(q)
  );
}

export function matchesEventQueueStatus(status: EventQueueDecidedStatus, filter: EventQueueStatusFilter): boolean {
  return filter === "all" || filter === status;
}

export function hasDangerFlag(flags: EventQueueFlag[]): boolean {
  return flags.some((f) => f.tone === "danger");
}

export function countByStatus(statuses: EventQueueDecidedStatus[], target: EventQueueDecidedStatus): number {
  return statuses.filter((s) => s === target).length;
}

export const EVENT_REJECT_REASON_PRESETS: string[] = [
  "Duplicate of an event already published at this venue.",
  "Hero image is stock or does not show the venue.",
  "Runs outside the venue's licensed hours.",
  "Venue verification is incomplete.",
];
