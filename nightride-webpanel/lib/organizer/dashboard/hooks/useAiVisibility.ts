"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { getDoc } from "firebase/firestore";
import { venueAiVisibilityDocRef } from "../data/refs";
import { parseVenueAiVisibility, type VenueAiVisibility } from "../data/analytics";
import { describeFirestoreError } from "../data/errors";

/** `venues/{venueId}/aiVisibility/current` — read-only, one `getDoc` per selected venue. */
export function useAiVisibility(venueId: string | null) {
  const [visibility, setVisibility] = useState<VenueAiVisibility | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const fetchVisibility = useCallback(async () => {
    if (!venueId) {
      setVisibility(null);
      setLoading(false);
      setError("");
      return;
    }
    setLoading(true);
    try {
      const snap = await getDoc(venueAiVisibilityDocRef(venueId));
      setVisibility(parseVenueAiVisibility(snap.exists() ? (snap.data() as Record<string, unknown>) : undefined));
      setError("");
    } catch (err) {
      setVisibility(null);
      setError(describeFirestoreError(err));
    } finally {
      setLoading(false);
    }
  }, [venueId]);

  useEffect(() => {
    fetchVisibility();
  }, [fetchVisibility]);

  const data = useMemo(() => ({ visibility }), [visibility]);

  return useMemo(() => ({ data, loading, error, busy: false, actionError: "" }), [data, loading, error]);
}

export type AiVisibilityState = ReturnType<typeof useAiVisibility>;
