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
 * period splits that way. The venue read is whichever one the switcher has
 * selected, or the organizer's first venue while it's on "All venues" —
 * there is one metrics document per venue, not a combined one.
 */
export function usePerformance(events: OrganizerEvent[], venueOrder: string[], now: Date | null) {
  const [perfVenueFilter, setPerfVenueFilterState] = useState("all");
  const [perfEventId, setPerfEventId] = useState<string | null>(null);
  const [metrics, setMetrics] = useState<VenueMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const effectiveVenueId = perfVenueFilter !== "all" ? perfVenueFilter : (venueOrder[0] ?? null);
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
        (e) => (isEventLive(e, now) || e.status === "scheduled" || e.status === "in_review") && (id === "all" || e.venue === id)
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
