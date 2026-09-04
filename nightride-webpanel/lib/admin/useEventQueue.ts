"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { dataSource } from "./data-source-instance";
import type { EventQueueEntry } from "./data-source";
import {
  countByStatus,
  deriveEventQueueStatus,
  EVENT_REJECT_REASON_PRESETS,
  hasDangerFlag,
  matchesEventQueueSearch,
  matchesEventQueueStatus,
  type EventQueueDecidedStatus,
} from "./filters/event-queue";
import { badgeColors, type BadgeType } from "./m3-data";
import { formatTimestamp, timeAgo } from "./present";
import { simulated } from "./view-models";
import type {
  ActionResult,
  EventQueueAssetPreview,
  EventQueueDetail,
  EventQueueFact,
  EventQueueRow,
  EventQueueStats,
  EventQueueStatusFilter,
} from "./view-models";
import { useAdminAuth } from "./auth";
import type { Timestamp } from "firebase/firestore";

const STATUS_LABEL: Record<EventQueueDecidedStatus, string> = {
  pending: "Awaiting review",
  approved: "Approved",
  rejected: "Rejected",
};

const STATUS_TONE: Record<EventQueueDecidedStatus, BadgeType> = {
  pending: "warning",
  approved: "success",
  rejected: "danger",
};

function eventDateLabel(ts: Timestamp | null): string {
  if (!ts) return "—";
  return ts.toDate().toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
}

function timeOfDay(ts: Timestamp | null): string {
  if (!ts) return "—";
  return ts.toDate().toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
}

function moneyLabel(price: number, currency: string): string {
  return `${currency} ${price.toLocaleString("en-US")}`;
}

/** Deterministic, non-random placeholder count for the fabricated asset grid — see EventQueueDetail.assetPreviews. */
function fabricatedAssetCount(eventId: string): number {
  let hash = 0;
  for (let i = 0; i < eventId.length; i++) hash = (hash * 31 + eventId.charCodeAt(i)) >>> 0;
  return 1 + (hash % 3); // 1..3
}

function daysAgoShort(ts: Timestamp | null): string {
  if (!ts) return "—";
  const diffMs = Date.now() - ts.toDate().getTime();
  const days = Math.floor(diffMs / 86400000);
  if (days >= 1) return `${days}d`;
  const hours = Math.max(1, Math.floor(diffMs / 3600000));
  return `${hours}h`;
}

function withinLastWeek(ts: Timestamp | null): boolean {
  if (!ts) return false;
  return Date.now() - ts.toDate().getTime() <= 7 * 86400000;
}

function buildRow(entry: EventQueueEntry, status: EventQueueDecidedStatus): EventQueueRow {
  const { event } = entry;
  return {
    id: event.id,
    name: event.name,
    venue: event.venueName,
    venueId: event.venueId,
    organizer: entry.organizer?.displayName ?? "—",
    organizerUid: event.organizerUid,
    city: event.city,
    dateLabel: eventDateLabel(event.startAt),
    status,
    statusTone: STATUS_TONE[status],
    submittedTimeAgo: timeAgo(event.moderation.requestedAt ?? event.createdAt),
    flags: entry.flags,
    flagCount: entry.flags.length,
    hasDangerFlag: hasDangerFlag(entry.flags),
  };
}

function buildDetail(entry: EventQueueEntry, status: EventQueueDecidedStatus): EventQueueDetail {
  const { event } = entry;
  const isPending = status === "pending";
  const facts: EventQueueFact[] = [
    { label: "Venue", value: event.venueName },
    { label: "Organizer", value: entry.organizer?.displayName ?? "—" },
    { label: "City", value: event.city },
    { label: "Date", value: eventDateLabel(event.startAt) },
    { label: "Doors → close", value: `${timeOfDay(event.startAt)} → ${timeOfDay(event.endAt)}`, mono: true },
    { label: "Age policy", value: event.policies.ageRestriction > 0 ? `${event.policies.ageRestriction}+` : "All ages" },
    { label: "Genres", value: event.genre || "—" },
    { label: "Expected attendance", value: String(event.interestedCount), mono: true },
    { label: "Submitted", value: formatTimestamp(event.moderation.requestedAt ?? event.createdAt), mono: true },
  ];
  const assetCount = fabricatedAssetCount(event.id);
  const assetPreviews: EventQueueAssetPreview[] = Array.from({ length: assetCount }, (_, i) => ({
    icon: i === 0 ? "image" : "photo_library",
    label: i === 0 ? "Hero image" : `Asset ${i + 1}`,
  }));
  const rejectReason = status === "rejected" && event.moderation.note ? event.moderation.note : null;

  return {
    ...buildRow(entry, status),
    description: event.description,
    facts,
    lineup: event.performers.map((p) => p.name),
    tiers: event.tickets.tiers.map((t) => ({ name: t.name, price: moneyLabel(t.price, event.tickets.currency), qty: String(t.qty) })),
    assetPreviews: simulated(assetPreviews),
    isPending,
    isDecided: !isPending,
    decidedLine: !isPending && entry.reviewedByLabel ? `${STATUS_LABEL[status]} by ${entry.reviewedByLabel} · ${timeAgo(event.updatedAt)}` : null,
    rejectReason,
    hasSeries: event.recurring && !!event.recurrenceLabel,
    series: event.recurrenceLabel,
  };
}

/**
 * Event review queue — post-moderation: events are already live when they
 * reach this queue. `approve` clears the review flag on a live event,
 * `reject` archives it with a reason the organizer sees, `reopen` clears a
 * prior decision back to pending. There is no pre-publish gate.
 */
export function useEventQueue(initialEventId?: string | null) {
  const { user } = useAdminAuth();
  const actorUid = user?.uid ?? "";

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [entries, setEntries] = useState<EventQueueEntry[]>([]);

  const [selectedId, setSelectedId] = useState<string | null>(initialEventId ?? null);
  const [statusFilter, setStatusFilter] = useState<EventQueueStatusFilter>("pending");
  const [search, setSearch] = useState("");

  const [actionBusy, setActionBusy] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  const [rejectOpen, setRejectOpen] = useState(false);
  const [rejectReasonDraft, setRejectReasonDraft] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const all = await dataSource.listEventQueue({ status: "all", search: "" });
      setEntries(all);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load the event queue.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  // Only meant to seed/deep-link the selection when the caller passes one.
  useEffect(() => {
    if (initialEventId) {
      setSelectedId(initialEventId);
    }
  }, [initialEventId]);

  const statuses = useMemo(
    () => new Map(entries.map((e) => [e.event.id, deriveEventQueueStatus(e.event)])),
    [entries],
  );

  const rows = useMemo(() => {
    return entries
      .filter((e) => {
        const status = statuses.get(e.event.id) ?? "pending";
        return (
          matchesEventQueueStatus(status, statusFilter) &&
          matchesEventQueueSearch(
            { name: e.event.name, venueName: e.event.venueName, organizerName: e.organizer?.displayName ?? "—" },
            search,
          )
        );
      })
      .map((e) => buildRow(e, statuses.get(e.event.id) ?? "pending"));
  }, [entries, statuses, statusFilter, search]);

  const selectedEntry = useMemo(() => {
    const byId = selectedId ? entries.find((e) => e.event.id === selectedId) : undefined;
    if (byId) return byId;
    const firstRowId = rows[0]?.id;
    const byFirstRow = firstRowId ? entries.find((e) => e.event.id === firstRowId) : undefined;
    return byFirstRow ?? entries[0] ?? null;
  }, [entries, rows, selectedId]);

  const detail = useMemo(() => {
    if (!selectedEntry) return null;
    return buildDetail(selectedEntry, statuses.get(selectedEntry.event.id) ?? "pending");
  }, [selectedEntry, statuses]);

  const stats: EventQueueStats = useMemo(() => {
    const all = entries.map((e) => statuses.get(e.event.id) ?? "pending");
    const pendingEntries = entries.filter((e) => statuses.get(e.event.id) === "pending");
    const oldestPending = pendingEntries.reduce<Timestamp | null>((oldest, e) => {
      const at = e.event.moderation.requestedAt ?? e.event.createdAt;
      if (!at) return oldest;
      if (!oldest || at.toMillis() < oldest.toMillis()) return at;
      return oldest;
    }, null);
    return {
      awaitingReview: countByStatus(all, "pending"),
      approvedThisWeek: entries.filter((e) => statuses.get(e.event.id) === "approved" && withinLastWeek(e.event.updatedAt)).length,
      rejectedThisWeek: entries.filter((e) => statuses.get(e.event.id) === "rejected" && withinLastWeek(e.event.updatedAt)).length,
      oldestInQueue: simulated(oldestPending ? daysAgoShort(oldestPending) : "—"),
    };
  }, [entries, statuses]);

  async function runAction(fn: () => Promise<void>): Promise<ActionResult> {
    setActionBusy(true);
    setActionError(null);
    try {
      await fn();
      await load();
      return { ok: true };
    } catch (err) {
      const message = err instanceof Error ? err.message : "That action failed.";
      setActionError(message);
      return { ok: false, error: message };
    } finally {
      setActionBusy(false);
    }
  }

  function select(id: string) {
    setSelectedId(id);
    setRejectOpen(false);
    setRejectReasonDraft("");
  }

  function approve(id: string): Promise<ActionResult> {
    return runAction(() => dataSource.approveEvent(id, actorUid));
  }

  function reject(id: string, reason: string): Promise<ActionResult> {
    return runAction(() => dataSource.rejectEvent(id, actorUid, reason));
  }

  function reopen(id: string): Promise<ActionResult> {
    return runAction(() => dataSource.reopenEvent(id, actorUid));
  }

  function openReject() {
    setRejectOpen(true);
  }
  function cancelReject() {
    setRejectOpen(false);
    setRejectReasonDraft("");
  }
  async function confirmReject(id: string) {
    const reason = rejectReasonDraft.trim();
    if (!reason) return;
    const result = await reject(id, reason);
    if (result.ok) {
      setRejectOpen(false);
      setRejectReasonDraft("");
    }
  }

  return {
    loading,
    error,
    rows,
    stats,
    selectedId: selectedEntry?.event.id ?? null,
    select,
    detail,
    statusFilter,
    setStatusFilter,
    search,
    setSearch,
    rejectReasonDraft,
    setRejectReasonDraft,
    rejectReasonPresets: EVENT_REJECT_REASON_PRESETS,
    approve,
    reject,
    reopen,
    actionBusy,
    actionError,
    refresh: load,
    // UI-only extras beyond the EventQueueViewModel contract, following the
    // same pattern as useApplicantDetail's rejectBoxOpen/setRejectBoxOpen.
    rejectOpen,
    openReject,
    cancelReject,
    confirmReject,
  };
}

export type EventQueue = ReturnType<typeof useEventQueue>;
