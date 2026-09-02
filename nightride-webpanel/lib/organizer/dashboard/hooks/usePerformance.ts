"use client";

import { useCallback, useMemo, useState } from "react";
import {
  ATTENDANCE_CEILING,
  MOCK_ATTENDANCE,
  MOCK_ATTENDANCE_AVG,
  MOCK_ATTENDANCE_PEAK,
  MOCK_DISCOVERY_FUNNEL,
  MOCK_TOP_NIGHTS,
} from "../mock-analytics";
import { isEventLive } from "../format";
import type { OrganizerEvent } from "../types";

/** `venues/{venueId}/metrics/{periodId}` — read-only analytics for the Audience destination. */
export function usePerformance(events: OrganizerEvent[], now: Date | null) {
  const [perfVenueFilter, setPerfVenueFilterState] = useState("all");
  const [perfEventId, setPerfEventId] = useState<string | null>(null);

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
    () => ({
      perfVenueFilter,
      perfEventId,
      attendance: MOCK_ATTENDANCE,
      attendanceCeiling: ATTENDANCE_CEILING,
      attendanceAvg: MOCK_ATTENDANCE_AVG,
      attendancePeak: MOCK_ATTENDANCE_PEAK,
      funnel: MOCK_DISCOVERY_FUNNEL,
      topNights: MOCK_TOP_NIGHTS,
    }),
    [perfVenueFilter, perfEventId]
  );

  return useMemo(
    () => ({ data, loading: false, error: null, busy: false, actionError: "", setPerfVenueFilter, setPerfEventId }),
    [data, setPerfVenueFilter]
  );
}

export type PerformanceState = ReturnType<typeof usePerformance>;
