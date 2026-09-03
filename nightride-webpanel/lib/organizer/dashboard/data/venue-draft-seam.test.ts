import { describe, expect, it } from "vitest";
import { computeVenueProfile, isVenueDirty, listingFieldsOf, withLiveFields } from "./venues";
import { MOCK_VENUES } from "../mock-data";

/**
 * The draft/published seam is what makes `useVenues`'s `onSnapshot` listener
 * safe: "a remote snapshot must never clobber an in-progress local edit"
 * (task-8-brief.md). These are the pure functions `useVenues` builds
 * `profile`/`venueDirty` from, so the property is tested directly rather
 * than only being observable by rendering the hook (this repo has no
 * React Testing Library set up for hooks).
 */
describe("computeVenueProfile — snapshot must never clobber an in-progress draft", () => {
  const saved = MOCK_VENUES.sirens;

  it("returns the saved profile untouched when there is no draft", () => {
    expect(computeVenueProfile(undefined, saved)).toEqual(saved);
  });

  it("keeps the draft's listing edits when a newer snapshot changes unrelated saved fields", () => {
    const draft = { ...saved, name: "Sirens Dubai (editing)", capacity: 500 };
    // A new onSnapshot delivery changed something the organizer never
    // touched (e.g. another editor updated the address).
    const nextSaved = { ...saved, address: "New Marina Address" };

    const profile = computeVenueProfile(draft, nextSaved);

    expect(profile.name).toBe("Sirens Dubai (editing)");
    expect(profile.capacity).toBe(500);
    // The listing field the draft never touched still comes from the draft
    // (it was seeded from the pre-snapshot saved value), not from the new
    // snapshot — proving the snapshot did not silently merge into the draft.
    expect(profile.address).toBe(saved.address);
  });

  it("still lets an admin verdict (a live field) flow through while a draft is open", () => {
    const draft = { ...saved, name: "Sirens Dubai (editing)" };
    const nextSaved = { ...saved, verified: false, openVerifyStep: "license" as const };

    const profile = computeVenueProfile(draft, nextSaved);

    // Listing edit survives...
    expect(profile.name).toBe("Sirens Dubai (editing)");
    // ...but the live fields always come from the latest snapshot, draft or not.
    expect(profile.verified).toBe(false);
    expect(profile.openVerifyStep).toBe("license");
  });
});

describe("withLiveFields", () => {
  it("overlays only verified/verificationSteps/openVerifyStep onto the draft", () => {
    const draft = { ...MOCK_VENUES.sirens, name: "Draft name", about: "Draft about" };
    const saved = { ...MOCK_VENUES.sirens, verified: false, openVerifyStep: "gps" as const };

    const merged = withLiveFields(draft, saved);

    expect(merged.name).toBe("Draft name");
    expect(merged.about).toBe("Draft about");
    expect(merged.verified).toBe(false);
    expect(merged.openVerifyStep).toBe("gps");
  });
});

describe("isVenueDirty", () => {
  const saved = MOCK_VENUES.sirens;

  it("is false with no draft", () => {
    expect(isVenueDirty(undefined, saved)).toBe(false);
  });

  it("is false when the draft's listing fields exactly match saved", () => {
    const draft = { ...saved };
    expect(isVenueDirty(draft, saved)).toBe(false);
  });

  it("is true when a listing field differs", () => {
    const draft = { ...saved, about: "Changed" };
    expect(isVenueDirty(draft, saved)).toBe(true);
  });

  it("ignores differences confined to the live fields", () => {
    // Simulates an admin verdict changing mid-edit: the draft is seeded from
    // the old `saved`, so its `verified`/`openVerifyStep` are stale relative
    // to a hypothetical new `saved` — that must never count as "dirty",
    // since the organizer made no listing edit at all.
    const draft = { ...saved, verified: false, openVerifyStep: "license" as const };
    const nextSaved = { ...saved, verified: true, openVerifyStep: null };
    expect(isVenueDirty(draft, nextSaved)).toBe(false);
  });
});

describe("listingFieldsOf", () => {
  it("strips verified/verificationSteps/openVerifyStep and nothing else", () => {
    const stripped = listingFieldsOf(MOCK_VENUES.sirens);
    expect(stripped).not.toHaveProperty("verified");
    expect(stripped).not.toHaveProperty("verificationSteps");
    expect(stripped).not.toHaveProperty("openVerifyStep");
    expect(stripped.name).toBe(MOCK_VENUES.sirens.name);
    expect(stripped.menu).toEqual(MOCK_VENUES.sirens.menu);
  });
});
