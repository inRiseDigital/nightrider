/**
 * `venues/{venueId}/team/{memberId}` <-> `TeamMember`. Read-only from the
 * client — `firestore.rules` denies every client write to this collection
 * outright; `/api/organizer/team` owns invites, role changes and removals
 * and does not exist yet (see `docs/FIRESTORE_SCHEMA.md`).
 */
import type { TeamMember, TeamRole } from "../types";

const TEAM_ROLES: readonly TeamRole[] = ["Owner", "Manager", "Door staff"];

function isTeamRole(v: unknown): v is TeamRole {
  return typeof v === "string" && (TEAM_ROLES as readonly string[]).includes(v);
}

/** `venues/{venueId}/team/{id}` -> `TeamMember`. An unrecognised `role` degrades to "Door staff" rather than throwing. */
export function parseTeamMember(id: string, raw: Record<string, unknown> | undefined): TeamMember {
  const d = raw ?? {};
  return {
    id,
    name: typeof d.name === "string" ? d.name : "",
    email: typeof d.email === "string" ? d.email : "",
    role: isTeamRole(d.role) ? d.role : "Door staff",
  };
}
