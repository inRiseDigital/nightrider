"use client";

import { useMemo } from "react";
import { MOCK_ACTIVITY } from "../mock-data";
import type { ActivityEntry } from "../types";

/** `venues/{venueId}/activity` — read-only. */
export function useActivity() {
  const data = useMemo<{ activity: ActivityEntry[] }>(() => ({ activity: MOCK_ACTIVITY }), []);
  return useMemo(() => ({ data, loading: false, error: null, busy: false, actionError: "" }), [data]);
}

export type ActivityState = ReturnType<typeof useActivity>;
