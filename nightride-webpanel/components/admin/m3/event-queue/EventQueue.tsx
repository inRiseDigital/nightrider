"use client";

import { EmptyState, FilterBar, SearchInput, SelectFilter, StatTile } from "../primitives";
import { SimulatedBadge } from "../SimulatedBadge";
import { EventQueueList } from "./EventQueueList";
import { EventDetail } from "./EventDetail";
import { SURFACE, TEXT } from "@/lib/admin/tokens";
import { useEventQueue } from "@/lib/admin/useEventQueue";
import type { EventQueueStatusFilter } from "@/lib/admin/view-models";

/**
 * Event review queue — master-detail container. Post-moderation: events are
 * already live when they land here; this screen clears a review flag or
 * takes an event down, it does not gate publishing. See lines 820-998 of
 * docs/design/admin-dashboard-v3.dc.html for the source layout.
 */
export function EventQueue({ activeEventId }: { activeEventId?: string | null }) {
  const queue = useEventQueue(activeEventId ?? null);

  if (queue.loading && queue.rows.length === 0) {
    return <EmptyState message="Loading the event queue…" icon="hourglass_top" />;
  }
  if (queue.error) {
    return <EmptyState message={queue.error} icon="error" />;
  }

  const stats = [
    { label: "Awaiting review", value: String(queue.stats.awaitingReview), color: "#F5C452" },
    { label: "Approved this week", value: String(queue.stats.approvedThisWeek), color: "#7BE0A8" },
    { label: "Rejected this week", value: String(queue.stats.rejectedThisWeek), color: "#FFB4AB" },
  ];

  return (
    <div>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 24, background: SURFACE.raised, borderRadius: 16, padding: "16px 24px", marginBottom: 16 }}>
        {stats.map((s) => (
          <StatTile key={s.label} value={s.value} label={s.label} color={s.color} />
        ))}
        <div style={{ minWidth: 96 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <div style={{ fontSize: 26, fontWeight: 300, lineHeight: 1.2, color: "#EDE0E4", fontFamily: "'Roboto Mono', monospace" }}>
              {queue.stats.oldestInQueue.value}
            </div>
            <SimulatedBadge />
          </div>
          <div style={{ fontSize: 12, color: TEXT.muted, marginTop: 2 }}>Oldest in queue</div>
        </div>
      </div>

      <FilterBar>
        <SearchInput
          value={queue.search}
          onChange={(e) => queue.setSearch(e.target.value)}
          placeholder="Search event, venue or organizer"
          maxWidth={380}
        />
        <SelectFilter value={queue.statusFilter} onChange={(e) => queue.setStatusFilter(e.target.value as EventQueueStatusFilter)}>
          <option value="pending">Awaiting review</option>
          <option value="approved">Approved</option>
          <option value="rejected">Rejected</option>
          <option value="all">All submissions</option>
        </SelectFilter>
      </FilterBar>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 16, alignItems: "flex-start" }}>
        <EventQueueList queue={queue} />
        {queue.detail ? <EventDetail queue={queue} /> : null}
      </div>
    </div>
  );
}
