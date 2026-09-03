"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { getDocs } from "firebase/firestore";
import { EmailAuthProvider, reauthenticateWithCredential, type User } from "firebase/auth";
import { venueTeamCol } from "../data/refs";
import { parseTeamMember } from "../data/team";
import { describeFirestoreError } from "../data/errors";
import { describeAuthError } from "@/lib/organizer/errors";
import type { TeamMember, TeamRole } from "../types";

/**
 * `venues/{venueId}/team` across every venue the organizer edits —
 * read-only from the client. `firestore.rules` denies every client write to
 * `team/{memberId}` outright; `/api/organizer/team` owns invites, role
 * changes and removals and does not exist yet, so `sendInvite`/`setTeamRole`
 * stay honest no-ops rather than faking success. The one thing that becomes
 * real here is the remove flow's password prompt, verified against Firebase
 * Auth (`reauthenticateWithCredential`) rather than a string compare.
 */
export function useTeam(venueIds: string[], user: User | null, showSnack: (text: string, tone?: "info" | "error") => void) {
  const [team, setTeam] = useState<TeamMember[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [inviteEmail, setInviteEmail] = useState("");
  const [removeTargetId, setRemoveTargetId] = useState<string | null>(null);
  const [removePassword, setRemovePasswordState] = useState("");
  const [removeAck, setRemoveAck] = useState(false);
  const [removeError, setRemoveError] = useState("");
  const [removeBusy, setRemoveBusy] = useState(false);

  const venueIdsKey = venueIds.join(",");

  const fetchTeam = useCallback(async () => {
    setLoading(true);
    try {
      const chunks = venueIds.length === 0 ? [] : await Promise.all(venueIds.map((id) => getDocs(venueTeamCol(id))));
      const next: TeamMember[] = [];
      for (const snap of chunks) {
        snap.forEach((d) => next.push(parseTeamMember(d.id, d.data() as Record<string, unknown>)));
      }
      setTeam(next);
      setError("");
    } catch (err) {
      setError(describeFirestoreError(err));
    } finally {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [venueIdsKey]);

  useEffect(() => {
    fetchTeam();
  }, [fetchTeam]);

  const sendInvite = useCallback(() => {
    showSnack("Team invites need the team management API, which hasn't shipped yet.", "error");
  }, [showSnack]);

  const setTeamRole = useCallback(
    (_id: string, _role: TeamRole) => {
      showSnack("Role changes need the team management API, which hasn't shipped yet.", "error");
    },
    [showSnack]
  );

  const removeTarget = team.find((m) => m.id === removeTargetId) ?? null;

  const resetRemoveFlow = useCallback(() => {
    setRemoveTargetId(null);
    setRemovePasswordState("");
    setRemoveAck(false);
    setRemoveError("");
  }, []);

  const startRemoveTeamMember = useCallback((id: string) => {
    setRemoveTargetId(id);
    setRemovePasswordState("");
    setRemoveAck(false);
    setRemoveError("");
  }, []);

  const setRemovePassword = useCallback((v: string) => {
    setRemovePasswordState(v);
    setRemoveError("");
  }, []);

  const toggleRemoveAck = useCallback(() => {
    setRemoveAck((v) => !v);
    setRemoveError("");
  }, []);

  const confirmRemoveTeamMember = useCallback(async () => {
    if (!removeTarget) return;
    if (removePassword.length < 6) {
      setRemoveError("Enter your account password to continue.");
      return;
    }
    if (!removeAck) {
      setRemoveError("Tick the box to confirm you understand.");
      return;
    }
    if (!user || !user.email) {
      setRemoveError("You're signed out. Sign in again to continue.");
      return;
    }
    setRemoveBusy(true);
    try {
      const credential = EmailAuthProvider.credential(user.email, removePassword);
      await reauthenticateWithCredential(user, credential);
      // Password verified for real — but the removal itself is
      // `/api/organizer/team`'s job (it has to fan out atomically across
      // this document, `venues.editors`/`.editorUids` and an activity entry)
      // and that endpoint doesn't exist yet; `firestore.rules` denies a
      // client write to `team/{memberId}` outright. Failing honestly here
      // rather than pretending a removal happened.
      setRemoveError(
        "Password verified, but removing teammates isn't available yet — this ships with the team management API."
      );
    } catch (err) {
      setRemoveError(describeAuthError(err));
    } finally {
      setRemoveBusy(false);
    }
  }, [removeTarget, removePassword, removeAck, user]);

  const data = useMemo(
    () => ({ team, inviteEmail, removeTarget, removePassword, removeAck, removeError }),
    [team, inviteEmail, removeTarget, removePassword, removeAck, removeError]
  );

  return useMemo(
    () => ({
      data,
      loading,
      error,
      busy: removeBusy,
      actionError: "",
      setInviteEmail,
      sendInvite,
      setTeamRole,
      startRemoveTeamMember,
      setRemovePassword,
      toggleRemoveAck,
      cancelRemoveTeamMember: resetRemoveFlow,
      confirmRemoveTeamMember,
    }),
    [
      data,
      loading,
      error,
      removeBusy,
      sendInvite,
      setTeamRole,
      startRemoveTeamMember,
      setRemovePassword,
      toggleRemoveAck,
      resetRemoveFlow,
      confirmRemoveTeamMember,
    ]
  );
}

export type TeamState = ReturnType<typeof useTeam>;
