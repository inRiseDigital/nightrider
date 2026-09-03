"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { getDocs, limit, orderBy, query, Timestamp } from "firebase/firestore";
import { venueActivityCol } from "../data/refs";
import { parseActivityEntry } from "../data/activity";
import { describeFirestoreError } from "../data/errors";
import type { ActivityEntry } from "../types";

/**
 * `venues/{venueId}/activity` across every venue the organizer edits, merged
 * and sorted newest-first. `orderBy('at', 'desc')` on a single subcollection
 * needs no composite index; venue-by-venue reads are merged client-side
 * rather than queried across venues (there is no `collectionGroup` rule
 * granting an organizer read access to every venue's activity at once, only
 * their own venues' subcollections).
 *
 * This is accountability among teammates, not a tamper-proof ledger, and it
 * grows unbounded (180-day pruning is a named follow-up) — an organizer can
 * see and reconstruct recent changes here, but this is not the record admins
 * use for that (`logs`, admin-only both ways, deliberately out of reach).
 */
export function useActivity(venueIds: string[]) {
  const [activity, setActivity] = useState<ActivityEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const venueIdsKey = venueIds.join(",");

  const fetchActivity = useCallback(async () => {
    setLoading(true);
    try {
      const snaps = venueIds.length
        ? await Promise.all(
            // `limit(50)` — finding 7: an unbounded read of a subcollection
            // the module doc above already says "grows unbounded". Each
            // venue's own most-recent 50 is plenty for "reconstruct recent
            // changes"; the 180-day pruning follow-up is the real fix.
            venueIds.map((id) => getDocs(query(venueActivityCol(id), orderBy("at", "desc"), limit(50))))
          )
        : [];
      const entries: { entry: ActivityEntry; atMs: number }[] = [];
      for (const snap of snaps) {
        snap.forEach((d) => {
          const raw = d.data() as Record<string, unknown>;
          const at = raw.at instanceof Timestamp ? raw.at.toMillis() : 0;
          entries.push({ entry: parseActivityEntry(raw), atMs: at });
        });
      }
      entries.sort((a, b) => b.atMs - a.atMs);
      setActivity(entries.map((e) => e.entry));
      setError("");
    } catch (err) {
      setActivity([]);
      setError(describeFirestoreError(err));
    } finally {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [venueIdsKey]);

  useEffect(() => {
    fetchActivity();
  }, [fetchActivity]);

  const data = useMemo<{ activity: ActivityEntry[] }>(() => ({ activity }), [activity]);
  return useMemo(() => ({ data, loading, error, busy: false, actionError: "" }), [data, loading, error]);
}

export type ActivityState = ReturnType<typeof useActivity>;
