// Pure, React-free filter/search/derivation functions for the users &
// organizers directory. Called by the useUsers hook (owned by another agent)
// and exercised directly by tests — no React, no side effects.

import type { OrganizerStatus } from "../schema";
import type { UserAccountState, UserRoleLabel } from "../view-models";

export function deriveUserRole(isAdmin: boolean, organizerStatus: OrganizerStatus): UserRoleLabel {
  if (isAdmin) return "Admin";
  if (organizerStatus === "approved") return "Organizer";
  return "Party-goer";
}

/** Identity/NIC verification is organizers-only — party-goers have no identity state. */
export function deriveUserIdentity(role: UserRoleLabel, organizerStatus: OrganizerStatus): OrganizerStatus | "n/a" {
  return role === "Organizer" ? organizerStatus : "n/a";
}

export interface UserSearchable {
  name: string;
  email: string;
  phone: string;
}

export function matchesUserSearch(row: UserSearchable, search: string): boolean {
  const q = search.trim().toLowerCase();
  if (!q) return true;
  return (
    row.name.toLowerCase().includes(q) ||
    row.email.toLowerCase().includes(q) ||
    row.phone.toLowerCase().includes(q)
  );
}

export function matchesUserRole(role: UserRoleLabel, filter: UserRoleLabel | "all"): boolean {
  return filter === "all" || role === filter;
}

export function matchesUserAccountState(state: UserAccountState, filter: UserAccountState | "all"): boolean {
  return filter === "all" || state === filter;
}

export function countByRole(roles: UserRoleLabel[], target: UserRoleLabel): number {
  return roles.filter((r) => r === target).length;
}

export function countByAccountState(states: UserAccountState[], target: UserAccountState): number {
  return states.filter((s) => s === target).length;
}
