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
      <div className="mb-4 rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
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
          className="rounded-lg bg-[var(--m3-warn)] px-4 py-2.5 text-xs font-semibold text-[var(--m3-onpri)] hover:bg-[var(--m3-warn)]/80"
        >
          + Invite
        </button>
      </div>

      <div className="mb-4 overflow-hidden rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)]">
        {team.length === 0 ? (
          <p className="px-[18px] py-5 text-xs text-[var(--m3-outline)]">No team members yet.</p>
        ) : (
          team.map((tm, i) => (
            <div
              key={`${tm.email}-${i}`}
              className="flex flex-wrap items-center gap-3.5 border-b border-[var(--m3-outlinev)] px-[18px] py-3 last:border-b-0"
            >
              <div className="min-w-0 flex-1">
                <p className="text-[13px] font-semibold text-[var(--m3-on)]">{tm.name}</p>
                <p className="mt-px font-mono text-[11px] text-[var(--m3-outline)]">{tm.email}</p>
              </div>
              <span className="rounded-full border border-[var(--m3-ter)]/30 bg-[var(--m3-ter)]/10 px-2.5 py-0.5 text-[11px] font-semibold text-[var(--m3-ter)]">
                {tm.role}
              </span>
              <button
                onClick={() => removeTeamMember(i)}
                className="text-xs text-[var(--m3-outline)] hover:text-red-400"
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
            className="flex flex-wrap gap-3.5 border-b border-[var(--m3-outlinev)] px-[18px] py-3 text-xs last:border-b-0"
          >
            <span className="w-[110px] shrink-0 font-semibold text-[var(--m3-on)]">{a.who}</span>
            <span className="min-w-[160px] flex-1 text-[var(--m3-onv)]">{a.what}</span>
            <span className="shrink-0 font-mono text-[var(--m3-outline)]">{a.when}</span>
          </div>
        ))}
      </PanelCard>
    </>
  );
}
