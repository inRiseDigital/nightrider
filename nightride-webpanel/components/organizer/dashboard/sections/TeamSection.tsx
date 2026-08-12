"use client";

import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { TEAM_ROLES } from "@/lib/organizer/dashboard/constants";
import { Chip, FieldLabel, PanelCard, SlimInput } from "../ui/Primitives";

export function TeamSection() {
  const {
    inviteName,
    setInviteName,
    inviteEmail,
    setInviteEmail,
    inviteRole,
    setInviteRole,
    addTeamMember,
    team,
    removeTeamMember,
    activity,
  } = useOrganizerDashboard();

  return (
    <>
      <div className="mb-4 rounded-lg border border-nr-border bg-nr-surface p-[18px]">
        <FieldLabel className="mb-2.5">Invite staff — scoped roles</FieldLabel>
        <div className="mb-2.5 flex flex-wrap gap-2.5">
          <SlimInput
            value={inviteName}
            onChange={(e) => setInviteName(e.target.value)}
            placeholder="Name"
            className="min-w-[160px] flex-1"
          />
          <SlimInput
            type="email"
            value={inviteEmail}
            onChange={(e) => setInviteEmail(e.target.value)}
            placeholder="Email"
            className="min-w-[160px] flex-1"
          />
        </div>
        <div className="mb-3 flex gap-2">
          {TEAM_ROLES.map((r) => (
            <Chip
              key={r}
              label={r}
              active={inviteRole === r}
              onClick={() => setInviteRole(r)}
              className="px-3.5 py-1.5"
            />
          ))}
        </div>
        <button
          onClick={addTeamMember}
          className="rounded-lg bg-nr-accent px-4 py-2.5 text-xs font-semibold text-nr-bg hover:bg-nr-accent/80"
        >
          + Invite
        </button>
      </div>

      <div className="mb-4 overflow-hidden rounded-lg border border-nr-border bg-nr-surface">
        {team.length === 0 ? (
          <p className="px-[18px] py-5 text-xs text-nr-text-hint">No team members yet.</p>
        ) : (
          team.map((tm, i) => (
            <div
              key={`${tm.email}-${i}`}
              className="flex flex-wrap items-center gap-3.5 border-b border-nr-border/60 px-[18px] py-3 last:border-b-0"
            >
              <div className="min-w-0 flex-1">
                <p className="text-[13px] font-semibold text-nr-text-primary">{tm.name}</p>
                <p className="mt-px font-mono text-[11px] text-nr-text-hint">{tm.email}</p>
              </div>
              <span className="rounded-full border border-nr-primary-light/30 bg-nr-primary-light/10 px-2.5 py-0.5 text-[11px] font-semibold text-nr-primary-light">
                {tm.role}
              </span>
              <button
                onClick={() => removeTeamMember(i)}
                className="text-xs text-nr-text-hint hover:text-red-400"
              >
                Remove
              </button>
            </div>
          ))
        )}
      </div>

      <PanelCard title="Activity Log">
        {activity.map((a, i) => (
          <div
            key={i}
            className="flex flex-wrap gap-3.5 border-b border-nr-border/60 px-[18px] py-3 text-xs last:border-b-0"
          >
            <span className="w-[110px] shrink-0 font-semibold text-nr-text-primary">{a.who}</span>
            <span className="min-w-[160px] flex-1 text-nr-text-secondary">{a.what}</span>
            <span className="shrink-0 font-mono text-nr-text-hint">{a.when}</span>
          </div>
        ))}
      </PanelCard>
    </>
  );
}
