/**
 * `venues/{venueId}/team/{memberId}` <-> `TeamMember`. Read-only from the
 * client — `firestore.rules` denies every client write to this collection
 * outright; `/api/organizer/team` owns invites, role changes and removals
 * and does not exist yet (see `docs/FIRESTORE_SCHEMA.md`).
 *
 * The stored vocabulary is lowercase (`'owner' | 'manager' | 'door'` —
 * confirmed against `scripts/seed-emulator/seed.mjs` and the same vocabulary
 * `firestore.rules`' `editors` map uses), while the UI's `TeamRole` is the
 * capitalised display form (`types.ts`). `rawToDisplayRole`/`displayToRawRole`
 * is an explicit pair, not a one-way guess, the same shape as the Flutter
 * task's `_rawToDisplay`/`_displayToRaw`: `/api/organizer/team` will need the
 * inverse direction too, and leaving only half the mapping here would invite
 * the next implementer to invent the other half differently.
 */
import type { TeamMember, TeamRole } from "../types";

const RAW_TO_DISPLAY: Record<string, TeamRole> = {
  owner: "Owner",
  manager: "Manager",
  door: "Door staff",
};

const DISPLAY_TO_RAW: Record<TeamRole, string> = {
  Owner: "owner",
  Manager: "manager",
  "Door staff": "door",
};

/** Stored role string -> display `TeamRole`. A genuinely unrecognised value degrades to "Door staff" rather than throwing. */
export function rawToDisplayRole(raw: unknown): TeamRole {
  return typeof raw === "string" && raw in RAW_TO_DISPLAY ? RAW_TO_DISPLAY[raw] : "Door staff";
}

/** Display `TeamRole` -> the stored role string. For `/api/organizer/team`'s future role-change payloads. */
export function displayToRawRole(role: TeamRole): string {
  return DISPLAY_TO_RAW[role];
}

/** `venues/{venueId}/team/{id}` -> `TeamMember`. */
export function parseTeamMember(id: string, raw: Record<string, unknown> | undefined): TeamMember {
  const d = raw ?? {};
  return {
    id,
    name: typeof d.name === "string" ? d.name : "",
    email: typeof d.email === "string" ? d.email : "",
    role: rawToDisplayRole(d.role),
  };
}
