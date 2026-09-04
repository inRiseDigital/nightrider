"use client";

// Hook backing the "Roles & access" section — the admin roster. Follows the
// same load()/runAction() convention as useVenueDetail.ts / useApplicantDetail.ts,
// built against the RolesViewModel contract in ./view-models.ts.
//
// Revoked access comes back on AdminRosterEntry.revoked, so revoke/restore is
// plain write-then-refetch like every other mutation here — no local override
// of what the read returned.

import { useCallback, useEffect, useState } from "react";
import { dataSource } from "./data-source-instance";
import { useAdminAuth } from "./auth";
import { initialsFor } from "./present";
import { simulated, type ActionResult, type AdminRow, type NewAdminDraft, type RolesViewModel } from "./view-models";
import type { AdminRosterEntry } from "./data-source";

const ADMIN_CAPABILITIES: string[] = [
  "Review organizer applications and event submissions",
  "Verify, suspend and transfer venues",
  "Suspend or ban party-goer and organizer accounts",
  "Add other admins and revoke their access",
  "Read the full audit log",
];

const SUPER_ADMIN_ONLY_CAPABILITIES: string[] = [
  "Cannot be revoked, renamed or re-scoped by anyone",
  "Owns billing and the platform-wide configuration",
];

const EMPTY_DRAFT: NewAdminDraft = { name: "", email: "", cityScope: "All cities" };

function toAdminRow(entry: AdminRosterEntry): AdminRow {
  const { user, revoked } = entry;
  return {
    uid: user.uid,
    name: user.displayName || user.email,
    email: user.email,
    initials: initialsFor(user.displayName, user.email),
    isAdmin: user.isAdmin && !revoked,
    displayLevel: simulated(entry.displayLevel),
    cityScopeLabel: simulated(entry.cityScopeLabel),
    addedLabel: simulated(entry.addedLabel),
    lastActiveLabel: simulated(entry.lastActiveLabel),
    locked: entry.locked,
    statusLabel: revoked ? "Revoked" : entry.invitePending ? simulated("Invite pending") : "Active",
  };
}

export function useRoles(): RolesViewModel {
  const { user } = useAdminAuth();
  const adminUid = user?.uid ?? "";

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [roster, setRoster] = useState<AdminRosterEntry[]>([]);

  const [addAdminOpen, setAddAdminOpen] = useState(false);
  const [newAdminDraft, setNewAdminDraftState] = useState<NewAdminDraft>(EMPTY_DRAFT);
  const [confirmRevokeId, setConfirmRevokeId] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const [actionBusy, setActionBusy] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const entries = await dataSource.listAdminRoster();
      setRoster(entries);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load the admin roster.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const runAction = useCallback(async (fn: () => Promise<void>): Promise<ActionResult> => {
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
  }, [load]);

  const toggleAddAdmin = useCallback(() => {
    setAddAdminOpen((open) => !open);
    setToast(null);
    setNewAdminDraftState(EMPTY_DRAFT);
  }, []);

  const setNewAdminDraft = useCallback((draft: Partial<NewAdminDraft>) => {
    setNewAdminDraftState((prev) => ({ ...prev, ...draft }));
  }, []);

  const canSubmitNewAdmin = !!newAdminDraft.name.trim() && !!newAdminDraft.email.trim();

  const createAdmin = useCallback(async (): Promise<ActionResult> => {
    const name = newAdminDraft.name.trim();
    const email = newAdminDraft.email.trim();
    if (!name || !email) return { ok: false, error: "Name and email are both required." };

    const result = await runAction(() => dataSource.inviteAdmin(name, email, newAdminDraft.cityScope, adminUid));
    if (result.ok) {
      setAddAdminOpen(false);
      setNewAdminDraftState(EMPTY_DRAFT);
      setToast(`Invite sent to ${email} — access starts when they accept.`);
    }
    return result;
  }, [newAdminDraft, adminUid, runAction]);

  const askRevoke = useCallback((uid: string) => {
    setConfirmRevokeId(uid);
  }, []);

  const cancelRevoke = useCallback(() => {
    setConfirmRevokeId(null);
  }, []);

  const revokeAdmin = useCallback(async (uid: string): Promise<ActionResult> => {
    const entry = roster.find((r) => r.user.uid === uid);
    const wasRevoked = !!entry?.revoked;
    const name = entry?.user.displayName ?? "";

    const result = await runAction(async () => {
      if (wasRevoked) {
        await dataSource.restoreAdminAccess(uid, adminUid);
      } else {
        await dataSource.revokeAdminAccess(uid, adminUid);
      }
    });
    if (result.ok) {
      setConfirmRevokeId(null);
      setToast(name ? (wasRevoked ? `${name}’s access restored.` : `${name}’s admin access revoked.`) : null);
    }
    return result;
  }, [roster, adminUid, runAction]);

  const rows: AdminRow[] = roster.map(toAdminRow);
  const activeCountLabel = `${rows.filter((r) => r.statusLabel !== "Revoked").length} active`;

  return {
    loading,
    error,
    rows,
    activeCountLabel,
    addAdminOpen,
    toggleAddAdmin,
    newAdminDraft,
    setNewAdminDraft,
    canSubmitNewAdmin,
    createAdmin,
    confirmRevokeId,
    askRevoke,
    cancelRevoke,
    revokeAdmin,
    toast,
    adminCapabilities: ADMIN_CAPABILITIES,
    superAdminOnlyCapabilities: SUPER_ADMIN_ONLY_CAPABILITIES,
    actionBusy,
    actionError,
    refresh: () => void load(),
  };
}

export type Roles = ReturnType<typeof useRoles>;
