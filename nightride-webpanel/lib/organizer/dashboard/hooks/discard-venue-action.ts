/**
 * Decides which of `discardVenue`'s two effects applies (see `useVenues.ts`).
 * Pulled out as a pure, dependency-free function — separate from `useVenues.ts`
 * itself, which imports `@/lib/firebase` and isn't resolvable in this repo's
 * unconfigured Vitest setup — so the branch order is unit-testable without
 * mounting the hook or touching Firestore.
 *
 * The order matters: a pending withdraw must be checked BEFORE the
 * local-draft clear, since the Save/Discard bar's button reads "Withdraw
 * submission" whenever a submission is pending, even if a (phantom) local
 * draft also exists (e.g. from an upload made through a control that should
 * have been read-only while pending).
 */
export type DiscardVenueAction =
  | { kind: "withdraw"; clearDraft: boolean }
  | { kind: "discardDraft" }
  | { kind: "noop" };

export function decideDiscardVenueAction(
  hasLocalDraft: boolean,
  pendingStatus: string | undefined
): DiscardVenueAction {
  if (pendingStatus === "pending") {
    return { kind: "withdraw", clearDraft: hasLocalDraft };
  }
  if (hasLocalDraft) return { kind: "discardDraft" };
  return { kind: "noop" };
}
