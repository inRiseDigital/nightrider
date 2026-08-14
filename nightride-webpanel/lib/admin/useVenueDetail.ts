"use client";

import { useCallback, useEffect, useState } from "react";
import { getUserRecord, getVenueDoc, listTransferCandidates, setVenueStatus, transferVenueOwner } from "./firestore";
import type { UserRecord, Venue } from "./schema";

export function useVenueDetail(venueId: string | null) {
  const [loading, setLoading] = useState(true);
  const [venue, setVenue] = useState<Venue | null>(null);
  const [owner, setOwner] = useState<UserRecord | null>(null);
  const [candidates, setCandidates] = useState<UserRecord[]>([]);
  const [transferOpen, setTransferOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState("");

  const load = useCallback(async () => {
    if (!venueId) return;
    setLoading(true);
    try {
      const v = await getVenueDoc(venueId);
      setVenue(v);
      setOwner(v?.ownerUid ? await getUserRecord(v.ownerUid) : null);
    } finally {
      setLoading(false);
    }
  }, [venueId]);

  useEffect(() => {
    setTransferOpen(false);
    void load();
  }, [load]);

  async function toggleSuspend() {
    if (!venue) return;
    setBusy(true);
    setActionError("");
    try {
      await setVenueStatus(venue.id, venue.status === "active" ? "closed" : "active");
      await load();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : "That action failed.");
    } finally {
      setBusy(false);
    }
  }

  async function openTransfer() {
    setTransferOpen(true);
    setCandidates(await listTransferCandidates(venue?.ownerUid ?? ""));
  }

  async function transferTo(newOwnerUid: string) {
    if (!venue) return;
    setBusy(true);
    setActionError("");
    try {
      await transferVenueOwner(venue.id, newOwnerUid);
      setTransferOpen(false);
      await load();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : "That action failed.");
    } finally {
      setBusy(false);
    }
  }

  return { loading, venue, owner, candidates, transferOpen, setTransferOpen, openTransfer, transferTo, toggleSuspend, busy, actionError };
}

export type VenueDetailState = ReturnType<typeof useVenueDetail>;
