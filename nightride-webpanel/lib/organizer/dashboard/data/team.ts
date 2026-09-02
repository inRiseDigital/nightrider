/** `venues/{venueId}/team/{memberId}` <-> `TeamMember`. Function-owned in
 * production (`/api/organizer/team`); this task only builds the mapper. */
import type { TeamMember, TeamRole } from "../types";

const TEAM_ROLES: readonly TeamRole[] = ["Owner", "Manager", "Door staff"];

function parseTeamRole(raw: unknown): TeamRole {
  return typeof raw === "string" && (TEAM_ROLES as readonly string[]).includes(raw)
    ? (raw as TeamRole)
    : "Door staff";
}

export function parseTeamMember(id: string, data: Record<string, unknown> | undefined): TeamMember {
  const d = data ?? {};
  return {
    id,
    name: typeof d.name === "string" ? d.name : "",
    email: typeof d.email === "string" ? d.email : "",
    role: parseTeamRole(d.role),
  };
}

export function toTeamMemberFields(ui: TeamMember, ctx: { raw: Record<string, unknown> }): Record<string, unknown> {
  return { ...ctx.raw, name: ui.name, email: ui.email, role: ui.role };
}
