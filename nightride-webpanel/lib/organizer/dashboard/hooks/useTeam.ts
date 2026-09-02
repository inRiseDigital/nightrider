"use client";

import { useCallback, useMemo, useState } from "react";
import { MOCK_TEAM } from "../mock-data";
import type { TeamMember, TeamRole } from "../types";

/** `venues/{venueId}/team` — function-owned in production; a seeded roster for this task. */
export function useTeam(showSnack: (text: string, tone?: "info" | "error") => void) {
  const [team, setTeam] = useState<TeamMember[]>(MOCK_TEAM);
  const [inviteEmail, setInviteEmail] = useState("");
  const [removeTargetId, setRemoveTargetId] = useState<string | null>(null);
  const [removePassword, setRemovePasswordState] = useState("");
  const [removeAck, setRemoveAck] = useState(false);
  const [removeError, setRemoveError] = useState("");

  const sendInvite = useCallback(() => {
    const email = inviteEmail.trim();
    if (!email) {
      showSnack("Enter an email address first.");
      return;
    }
    const name = email.split("@")[0].replace(/[._-]+/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
    setTeam((p) => [...p, { id: `tm${Date.now()}`, name, email, role: "Door staff" }]);
    setInviteEmail("");
    showSnack(`Invite sent to ${email}.`);
  }, [inviteEmail, showSnack]);

  const setTeamRole = useCallback(
    (id: string, role: TeamRole) => {
      setTeam((p) => p.map((m) => (m.id === id ? { ...m, role } : m)));
      const member = team.find((m) => m.id === id);
      if (member) showSnack(`${member.name} is now ${role}.`);
    },
    [team, showSnack]
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

  const confirmRemoveTeamMember = useCallback(() => {
    if (!removeTarget) return;
    if (removePassword.length < 6) {
      setRemoveError("Enter your account password to continue.");
      return;
    }
    if (removePassword === "wrongpass") {
      setRemoveError("That password doesn't match our records.");
      return;
    }
    if (!removeAck) {
      setRemoveError("Tick the box to confirm you understand.");
      return;
    }
    setTeam((p) => p.filter((m) => m.id !== removeTarget.id));
    resetRemoveFlow();
    showSnack(`${removeTarget.name} removed — access revoked and the platform admin was notified.`);
  }, [removeTarget, removePassword, removeAck, resetRemoveFlow, showSnack]);

  const data = useMemo(
    () => ({ team, inviteEmail, removeTarget, removePassword, removeAck, removeError }),
    [team, inviteEmail, removeTarget, removePassword, removeAck, removeError]
  );

  return useMemo(
    () => ({
      data,
      loading: false,
      error: null,
      busy: false,
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
    [data, setInviteEmail, sendInvite, setTeamRole, startRemoveTeamMember, setRemovePassword, toggleRemoveAck, resetRemoveFlow, confirmRemoveTeamMember]
  );
}

export type TeamState = ReturnType<typeof useTeam>;
