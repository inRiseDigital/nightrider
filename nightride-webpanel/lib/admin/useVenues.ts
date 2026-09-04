"use client";

// Hook backing the Venues directory section — the global, cross-organizer
// venue list plus its detail/verification screen. Follows the same
// load()/runAction() convention as useVenueDetail.ts / useApplicantDetail.ts
// / useRoles.ts, built against the VenuesViewModel contract in
// ./view-models.ts. Filtering/search/derivation is delegated to the pure
// functions in ./filters/venues.ts — this hook only shapes data and owns
// state.

import { useCallback, useEffect, useState } from "react";
import { dataSource } from "./data-source-instance";
import { useAdminAuth } from "./auth";
import { countOpenChecks, deriveVenueVerifyState } from "./filters/venues";
import { formatTimestamp } from "./present";
import { simulated } from "./view-models";
import type {
  ActionResult,
  StatTile,
  VenueCheck,
  VenueCheckKey,
  VenueCheckState,
  VenueDetail,
  VenueEventSummary,
  VenueFilterState,
  VenueHistoryEntry,
  VenueRow,
  VenuesViewModel,
} from "./view-models";
import type { EventStatus } from "./schema";
import type { EventQueueEntry, VenueVerification } from "./data-source";

const EVENT_STATUS_CHROME: Record<EventStatus, { label: string; tone: StatTile["tone"] }> = {
  draft: { label: "Draft", tone: "neutral" },
  scheduled: { label: "Scheduled", tone: "info" },
  in_review: { label: "In review", tone: "warning" },
  published: { label: "Published", tone: "success" },
  cancelled: { label: "Cancelled", tone: "danger" },
  archived: { label: "Archived", tone: "neutral" },
};

const CHECK_DEFS: { key: VenueCheckKey; title: string; icon: string }[] = [
  { key: "licence", title: "Liquor / entertainment licence", icon: "description" },
  { key: "gps", title: "On-site GPS check", icon: "my_location" },
  { key: "video", title: "Video walkthrough", icon: "videocam" },
];

// Ported from docs/design/admin-dashboard-v3.dc.html's venueHistory() —
// per-venue check/approval timelines have no real logging path today (see
// VenueDetail.history's comment in view-models.ts), so this stands in until
// logs/{id}.action grows a venue-check-approval / suspend action. Venues with
// no entry here fall back to a single "submitted by organizer" row built
// from the real venue + organizer record.
const VENUE_HISTORY: Record<string, VenueHistoryEntry[]> = {
  "neon-fox": [
    { id: "nf-1", text: "Video walkthrough approved", actorLabel: "Aisha Darwish", timeLabel: "22 Jul 2026 · 14:20", icon: "videocam", tone: "success" },
    { id: "nf-2", text: "GPS check passed — 12 m from stated address", actorLabel: "System", timeLabel: "22 Jul 2026 · 13:02", icon: "where_to_vote", tone: "success" },
    { id: "nf-3", text: "Licence VIC-LIQ-88214 verified against state register", actorLabel: "Tomás Neves", timeLabel: "21 Jul 2026 · 10:41", icon: "description", tone: "success" },
    { id: "nf-4", text: "Venue submitted by organizer", actorLabel: "Kenji Yamamoto", timeLabel: "20 Jul 2026 · 19:55", icon: "add_business", tone: "neutral" },
  ],
  "fox-annex": [
    { id: "fa-1", text: "GPS check returned 180 m from stated address", actorLabel: "System", timeLabel: "05 Aug 2026 · 23:41", icon: "location_off", tone: "warning" },
    { id: "fa-2", text: "Licence VIC-LIQ-88219 verified", actorLabel: "Grace Okoro", timeLabel: "04 Aug 2026 · 12:10", icon: "description", tone: "success" },
    { id: "fa-3", text: "Venue submitted by organizer", actorLabel: "Kenji Yamamoto", timeLabel: "04 Aug 2026 · 09:30", icon: "add_business", tone: "neutral" },
  ],
  "collins-basement": [
    { id: "cb-1", text: "Awaiting all three checks", actorLabel: "System", timeLabel: "2 Sep 2026 · 08:15", icon: "hourglass_top", tone: "warning" },
    { id: "cb-2", text: "Venue submitted by organizer", actorLabel: "Casey Al-Farsi", timeLabel: "2 Sep 2026 · 08:14", icon: "add_business", tone: "neutral" },
  ],
  "chapel-underground": [
    { id: "cu-1", text: "Event “Chapel After Hours” rejected — venue unverified", actorLabel: "Mei Lin", timeLabel: "1 Sep 2026 · 22:40", icon: "block", tone: "danger" },
    { id: "cu-2", text: "GPS check failed — pin 2.4 km from stated address", actorLabel: "System", timeLabel: "15 Apr 2026 · 21:18", icon: "location_off", tone: "danger" },
    { id: "cu-3", text: "Licence TYO-NC-31904 verified", actorLabel: "Mei Lin", timeLabel: "15 Apr 2026 · 15:00", icon: "description", tone: "success" },
  ],
};

/**
 * `VenueRow` (view-models.ts) doesn't declare `address`, even though the
 * mockup's list table shows one — only `VenueDetail` carries it. Rather than
 * widen the shared contract type, this attaches `address` to every row
 * object as a bonus runtime field (the directory read already has it) that
 * `VenuesList.tsx` reads back off the same object it's handed.
 */
function toRow(v: VenueVerification): VenueRow {
  const checkStates = Object.values(v.checks);
  return {
    id: v.venue.id,
    name: v.venue.name,
    city: v.venue.city,
    organizer: v.organizer?.displayName || v.organizer?.email || "—",
    organizerUid: v.venue.ownerUid,
    verifyState: deriveVenueVerifyState(checkStates),
    openChecksCount: countOpenChecks(checkStates),
    suspended: v.suspended,
    capacity: v.capacity,
    eventCount: v.eventCount,
    address: v.venue.address || "—",
  };
}

function buildStats(rows: VenueRow[]): StatTile[] {
  return [
    { label: "Venues", value: String(rows.length), tone: "neutral" },
    { label: "Fully verified", value: String(rows.filter((r) => r.verifyState === "verified").length), tone: "success" },
    { label: "Checks open", value: String(rows.filter((r) => r.verifyState === "checksOpen").length), tone: "warning" },
    { label: "Failed / suspended", value: String(rows.filter((r) => r.verifyState === "failed" || r.suspended).length), tone: "danger" },
  ];
}

function toChecks(v: VenueVerification): VenueCheck[] {
  return CHECK_DEFS.map((def) => {
    const state = v.checks[def.key];
    let meta: string;
    if (def.key === "licence") meta = `${v.licenceNumber} · expires ${v.licenceExpiryLabel}`;
    else if (def.key === "gps") meta = state === "failed" ? "Pin dropped 180 m from stated address" : "Pin dropped 12 m from stated address";
    else meta = "Entrance, main floor and bar — 1 min 48 s";
    return { key: def.key, title: def.title, icon: def.icon, state, meta };
  });
}

function toEvents(venueId: string, entries: EventQueueEntry[]): VenueEventSummary[] {
  return entries
    .filter((e) => e.event.venueId === venueId)
    .map((e) => {
      const chrome = EVENT_STATUS_CHROME[e.event.status] ?? EVENT_STATUS_CHROME.draft;
      return {
        id: e.event.id,
        name: e.event.name,
        dateLabel: formatTimestamp(e.event.startAt),
        status: e.event.status,
        statusTone: chrome.tone,
      };
    });
}

export function useVenues(): VenuesViewModel {
  const { user } = useAdminAuth();
  const adminUid = user?.uid ?? "";

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [rows, setRows] = useState<VenueRow[]>([]);
  const [stats, setStats] = useState<StatTile[]>([]);

  const [search, setSearch] = useState("");
  const [city, setCity] = useState<string | "all">("all");
  const [verifyState, setVerifyState] = useState<VenueFilterState["verifyState"]>("all");

  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [detail, setDetail] = useState<VenueDetail | null>(null);

  const [actionBusy, setActionBusy] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [filtered, all] = await Promise.all([
        dataSource.listVenueDirectory({ search, city, verifyState }),
        dataSource.listVenueDirectory({ search: "", city: "all", verifyState: "all" }),
      ]);
      setRows(filtered.map(toRow));
      setStats(buildStats(all.map(toRow)));

      if (selectedId) {
        const [v, queue] = await Promise.all([
          dataSource.getVenueVerification(selectedId),
          dataSource.listEventQueue({ status: "all", search: "" }),
        ]);
        if (!v) {
          setDetail(null);
        } else {
          const row = toRow(v);
          const history = VENUE_HISTORY[v.venue.id] ?? [
            {
              id: `${v.venue.id}-submitted`,
              text: "Venue submitted by organizer",
              actorLabel: v.organizer?.displayName || v.organizer?.email || "—",
              timeLabel: formatTimestamp(v.venue.createdAt),
              icon: "add_business",
              tone: "neutral",
            },
          ];
          setDetail({
            ...row,
            openingHours: v.venue.openingHours || "—",
            phone: v.venue.phone || "—",
            licenceNumber: simulated(v.licenceNumber),
            licenceExpiryLabel: simulated(v.licenceExpiryLabel),
            verifiedOnLabel: v.venue.verified ? formatTimestamp(v.venue.updatedAt) : "—",
            checks: toChecks(v),
            events: toEvents(v.venue.id, queue),
            history: simulated(history),
          });
        }
      } else {
        setDetail(null);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load the venues directory.");
    } finally {
      setLoading(false);
    }
  }, [search, city, verifyState, selectedId]);

  useEffect(() => {
    void load();
  }, [load]);

  const runAction = useCallback(
    async (fn: () => Promise<void>): Promise<ActionResult> => {
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
    },
    [load],
  );

  const setCheckState = useCallback(
    (venueId: string, key: VenueCheckKey, state: VenueCheckState) =>
      runAction(() => dataSource.setVenueCheckState(venueId, key, state, adminUid)),
    [runAction, adminUid],
  );

  const toggleSuspend = useCallback(
    (venueId: string) => {
      const current = detail?.id === venueId ? detail.suspended : rows.find((r) => r.id === venueId)?.suspended ?? false;
      return runAction(() => dataSource.setVenueSuspended(venueId, !current, adminUid));
    },
    [runAction, adminUid, detail, rows],
  );

  const select = useCallback((id: string | null) => {
    setActionError(null);
    setSelectedId(id);
  }, []);

  return {
    loading,
    error,
    rows,
    stats,
    filter: { search, city, verifyState },
    setSearch,
    setCity,
    setVerifyState,
    selectedId,
    select,
    detail,
    setCheckState,
    toggleSuspend,
    actionBusy,
    actionError,
    refresh: () => void load(),
  };
}

export type Venues = ReturnType<typeof useVenues>;
