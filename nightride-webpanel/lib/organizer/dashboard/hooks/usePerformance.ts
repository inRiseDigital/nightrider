"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { getDoc } from "firebase/firestore";
import { venueMetricsDocRef } from "../data/refs";
import { isoWeekId, parseVenueMetrics, type VenueMetrics } from "../data/analytics";
import { describeFirestoreError } from "../data/errors";
import { isEventLive } from "../format";
import type { OrganizerEvent } from "../types";

/**
 * `venues/{venueId}/metrics/{periodId}` — read-only analytics for the
 * Audience destination, plus the Live Operations KPI strip's "profile
 * views" number. Two point reads per venue (`last30` and the current ISO
 * week), not a query — see `data/analytics.ts`'s module doc for why the
 * period splits that way.
 *
 * There is no "All venues" option here (fix round 1): metrics documents are
 * per-venue, and there is no way to sum derived funnel widths or percentage
 * strings into a meaningful combined figure. A switcher that offered "All
 * venues" while silently rendering one venue's numbers is the same honesty
 * failure the brief names for empty states — a number that looks like one
 * thing and is another. `perfVenueFilter` always holds a real venue id
 * (repaired to the organizer's first venue whenever it isn't one, e.g. on
 * first load or after a venue is removed) and nothing outside this hook
 * reads it, so this is contained.
 */
export function usePerformance(events: OrganizerEvent[], venueOrder: string[], now: Date | null) {
  const [perfVenueFilter, setPerfVenueFilterState] = useState("");
  const [perfEventId, setPerfEventId] = useState<string | null>(null);
  const [metrics, setMetrics] = useState<VenueMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    if (venueOrder.length > 0 && !venueOrder.includes(perfVenueFilter)) {
      setPerfVenueFilterState(venueOrder[0]);
    }
  }, [venueOrder, perfVenueFilter]);

  const effectiveVenueId = venueOrder.includes(perfVenueFilter) ? perfVenueFilter : null;
  const weekId = now ? isoWeekId(now) : null;

  const fetchMetrics = useCallback(async () => {
    if (!effectiveVenueId) {
      setMetrics(null);
      setLoading(false);
      setError("");
      return;
    }
    setLoading(true);
    try {
      const [last30Snap, weekSnap] = await Promise.all([
        getDoc(venueMetricsDocRef(effectiveVenueId, "last30")),
        weekId ? getDoc(venueMetricsDocRef(effectiveVenueId, weekId)) : Promise.resolve(null),
      ]);
      setMetrics(
        parseVenueMetrics(
          last30Snap.exists() ? (last30Snap.data() as Record<string, unknown>) : undefined,
          weekSnap?.exists() ? (weekSnap.data() as Record<string, unknown>) : undefined
        )
      );
      setError("");
    } catch (err) {
      setMetrics(null);
      setError(describeFirestoreError(err));
    } finally {
      setLoading(false);
    }
  }, [effectiveVenueId, weekId]);

  useEffect(() => {
    fetchMetrics();
  }, [fetchMetrics]);

  const setPerfVenueFilter = useCallback(
    (id: string) => {
      setPerfVenueFilterState(id);
      const eligible = events.filter(
        (e) => (isEventLive(e, now) || e.status === "scheduled" || e.status === "in_review") && e.venue === id
      );
      setPerfEventId((prev) => (eligible.some((e) => e.id === prev) ? prev : (eligible[0]?.id ?? null)));
    },
    [events, now]
  );

  const data = useMemo(
    () => ({ perfVenueFilter, perfEventId, metrics }),
    [perfVenueFilter, perfEventId, metrics]
  );

  return useMemo(
    () => ({ data, loading, error, busy: false, actionError: "", setPerfVenueFilter, setPerfEventId }),
    [data, loading, error, setPerfVenueFilter]
  );
}

export type PerformanceState = ReturnType<typeof usePerformance>;
