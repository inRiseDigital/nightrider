"use client";

import { UserMinus, UserPlus } from "lucide-react";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { TEAM_ROLES } from "@/lib/organizer/dashboard/constants";
import type { TeamRole } from "@/lib/organizer/dashboard/types";
import { FilledButton, IconButton, PanelCard, Select, TextField } from "../ui/Primitives";
import { RemoveTeammateDialog } from "./RemoveTeammateDialog";

function initialsFor(name: string) {
  return name
    .split(" ")
    .filter(Boolean)
    .map((w) => w[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();
}

export function TeamSection() {
  const {
    team,
    inviteEmail,
    setInviteEmail,
    sendInvite,
    setTeamRole,
    startRemoveTeamMember,
    activity,
  } = useOrganizerDashboard();

  return (
    <>
      <div className="mb-6 max-w-[820px] overflow-hidden rounded-xl bg-[var(--m3-surf1)] py-2">
        {team.map((tm) => (
          <div
            key={tm.id}
            className="flex min-h-[72px] flex-wrap items-center gap-4 border-b border-[var(--m3-outlinev)] px-5 py-3 last:border-b-0"
          >
            <span
              className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-sm font-medium"
              style={{ background: "var(--m3-surf3)", color: "var(--m3-on)" }}
            >
              {initialsFor(tm.name)}
            </span>
            <div className="min-w-0 flex-1">
              <p className="text-sm font-medium text-[var(--m3-on)]">{tm.name}</p>
              <p className="text-[13px] text-[var(--m3-onv)]">{tm.email}</p>
            </div>
            <Select
              dense
              aria-label={`Role for ${tm.name}`}
              value={tm.role}
              onChange={(e) => setTeamRole(tm.id, e.target.value as TeamRole)}
              options={TEAM_ROLES}
              wrapperClassName="w-[140px] shrink-0"
            />
            <IconButton
              danger
              aria-label={`Remove ${tm.name}`}
              onClick={() => startRemoveTeamMember(tm.id)}
            >
              <UserMinus size={19} />
            </IconButton>
          </div>
        ))}

        <div className="flex flex-wrap items-center gap-3 px-5 py-4">
          <TextField
            type="email"
            aria-label="Invite by email"
            value={inviteEmail}
            onChange={(e) => setInviteEmail(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && sendInvite()}
            placeholder="Invite by email"
            wrapperClassName="min-w-[220px] flex-1"
          />
          <FilledButton icon={<UserPlus size={17} />} onClick={sendInvite}>
            Send invite
          </FilledButton>
        </div>
      </div>

      <PanelCard title="Activity Log" className="max-w-[820px]">
        {activity.map((a, i) => (
          <div
            key={i}
            className="flex flex-wrap gap-3.5 border-b border-[var(--m3-outlinev)] px-5 py-3 text-xs last:border-b-0"
          >
            <span className="w-[110px] shrink-0 font-semibold text-[var(--m3-on)]">{a.who}</span>
            <span className="min-w-[160px] flex-1 text-[var(--m3-onv)]">{a.what}</span>
            <span className="shrink-0 font-mono text-[var(--m3-outline)]">{a.when}</span>
          </div>
        ))}
      </PanelCard>

      <RemoveTeammateDialog />
    </>
  );
}
