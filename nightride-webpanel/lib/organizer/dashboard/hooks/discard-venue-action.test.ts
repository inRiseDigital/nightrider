import { describe, expect, it } from "vitest";
import { decideDiscardVenueAction } from "./discard-venue-action";

describe("decideDiscardVenueAction", () => {
  it("withdraws the pending submission when only a submission is present", () => {
    expect(decideDiscardVenueAction(false, "pending")).toEqual({ kind: "withdraw", clearDraft: false });
  });

  it("discards the local draft when only a draft is present", () => {
    expect(decideDiscardVenueAction(true, undefined)).toEqual({ kind: "discardDraft" });
  });

  it("does nothing when there is neither a draft nor a pending submission", () => {
    expect(decideDiscardVenueAction(false, undefined)).toEqual({ kind: "noop" });
  });

  // Regression for the reachable hole: an upload made through a control that
  // should have been read-only while pending (e.g. the hero/gallery photo
  // pickers, before they were gated on `venuePendingReview`) can leave a
  // phantom local draft sitting alongside a genuine pending submission. The
  // Save/Discard bar's button reads "Withdraw submission" in that state, so
  // withdrawing the submission — not silently clearing the phantom draft —
  // is the action it must take. Against the old branch order (local-draft
  // check first), this assertion fails: it would return `discardDraft`
  // instead of `withdraw`, leaving the pending `venueEdits` document in
  // place while telling the organizer "Changes discarded."
  it("withdraws the pending submission — and clears the phantom draft — when both are present", () => {
    expect(decideDiscardVenueAction(true, "pending")).toEqual({ kind: "withdraw", clearDraft: true });
  });

  it("treats a non-pending (e.g. rejected/approved) submission as no submission to withdraw", () => {
    expect(decideDiscardVenueAction(true, "rejected")).toEqual({ kind: "discardDraft" });
    expect(decideDiscardVenueAction(false, "approved")).toEqual({ kind: "noop" });
  });
});
