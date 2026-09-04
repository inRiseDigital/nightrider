// Pure, React-free filter/search/derivation functions for the venue
// directory. Called by the useVenues hook (owned by another agent) and
// exercised directly by tests — no React, no side effects.

import type { VenueCheckState, VenueVerifyState } from "../view-models";

export function deriveVenueVerifyState(checks: VenueCheckState[]): VenueVerifyState {
  if (checks.includes("failed")) return "failed";
  // No checks is not the same as every check passing. firestore.rules
  // deliberately lets a venue predating `verification` through with an empty
  // map (see verificationStepOk's `.get()` defaults), so a plain `every()`
  // would call those venues fully verified on vacuous truth alone.
  if (checks.length === 0) return "checksOpen";
  if (checks.every((s) => s === "verified")) return "verified";
  return "checksOpen";
}

export function countOpenChecks(checks: VenueCheckState[]): number {
  return checks.filter((s) => s !== "verified").length;
}

export interface VenueSearchable {
  name: string;
  organizerName: string;
  address: string;
}

export function matchesVenueSearch(row: VenueSearchable, search: string): boolean {
  const q = search.trim().toLowerCase();
  if (!q) return true;
  return (
    row.name.toLowerCase().includes(q) ||
    row.organizerName.toLowerCase().includes(q) ||
    row.address.toLowerCase().includes(q)
  );
}

export function matchesVenueCity(city: string, filter: string | "all"): boolean {
  return filter === "all" || city === filter;
}

export function matchesVenueVerifyFilter(
  verifyState: VenueVerifyState,
  suspended: boolean,
  filter: "all" | VenueVerifyState | "suspended",
): boolean {
  if (filter === "all") return true;
  if (filter === "suspended") return suspended;
  return verifyState === filter;
}
