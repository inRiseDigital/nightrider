import { describe, expect, it } from "vitest";
import { setPhotoAt, toVenueDocFields } from "./venues";
import type { VenueProfile } from "../types";

/**
 * T12 fix round 1, finding 1: the four gallery tiles are independently
 * droppable in any order (nothing enforces filling them front-to-back), so
 * `store.tsx`'s `commitSlotImage`/`removeSlotImage` must never leave
 * `photos[]` sparse — a hole spreads into a real `undefined`
 * (`[...sparse][0] === undefined`), and `toVenueEditListing`'s bare
 * `{ ...p }` would carry that straight into `saveVenue`'s batch write, which
 * the Firestore SDK rejects outright (no `ignoreUndefinedProperties` set
 * anywhere in `lib/firebase.ts`) — a Storage upload that already succeeded
 * would then fail to save with an opaque error.
 */
describe("setPhotoAt", () => {
  it("sets index 0 on an empty/undefined array without padding", () => {
    expect(setPhotoAt(undefined, 0, "hero.jpg")).toEqual(["hero.jpg"]);
    expect(setPhotoAt([], 0, "hero.jpg")).toEqual(["hero.jpg"]);
  });

  it("filling gallery slot 2 first (out of order) on a brand-new venue pads slots 0..2 with '', never a hole", () => {
    // photos[] starts empty — organizer drops a photo straight into the
    // third gallery tile (`gallery-{venueId}-2` -> photos[3]) before
    // touching the hero or the earlier gallery slots.
    const next = setPhotoAt(undefined, 3, "gallery-2.jpg");
    expect(next).toEqual(["", "", "", "gallery-2.jpg"]);
    expect(next.every((v) => v !== undefined)).toBe(true);
    expect([...next]).toEqual(next); // spreading is stable — no holes to reveal
  });

  it("out-of-order sequence (hero, then gallery slot 2, skipping 0/1) never produces undefined and survives a JSON round-trip", () => {
    let photos: string[] | undefined = undefined;
    photos = setPhotoAt(photos, 0, "hero.jpg");
    photos = setPhotoAt(photos, 3, "gallery-2.jpg"); // gallery-{venueId}-2 -> photos[3]
    expect(photos).toEqual(["hero.jpg", "", "", "gallery-2.jpg"]);
    expect(photos.every((v) => v !== undefined)).toBe(true);
    // JSON.stringify silently drops `undefined` array elements (they become
    // `null`) — proving round-trip equality is a stronger guarantee than
    // just checking `!== undefined` above.
    expect(JSON.parse(JSON.stringify(photos))).toEqual(photos);
  });

  it("replacing an existing value in place does not grow the array", () => {
    expect(setPhotoAt(["a", "b", "c"], 1, "b2")).toEqual(["a", "b2", "c"]);
  });

  it("clearing (remove) writes '' at the index rather than shortening the array", () => {
    expect(setPhotoAt(["a", "b", "c"], 1, "")).toEqual(["a", "", "c"]);
  });

  it("what saveVenue would actually write (toVenueDocFields) carries no undefined after an out-of-order fill", () => {
    const base: VenueProfile = {
      verified: true,
      name: "New Venue",
      city: "Dubai, UAE",
      address: "",
      about: "",
      socialLinks: [],
      genres: [],
      dressCode: "Casual",
      agePolicy: "18+",
      coverMin: 0,
      coverMax: 0,
      currency: "$",
      capacity: 0,
      amenities: [],
      hours: [],
      exceptions: [],
      menu: [],
      tableLink: "",
      photos: setPhotoAt(undefined, 3, "gallery-2.jpg"),
    };
    const fields = toVenueDocFields(base, { raw: {} });
    // The exact bug this test guards: a sparse `photos` array spread into
    // the write payload would put `undefined` at indices 0-2, which
    // `JSON.stringify` (a stand-in for what Firestore's SDK inspects) turns
    // into `null` — this asserts there is nothing to turn into anything,
    // because there are no holes.
    expect(fields.photos).toEqual(["", "", "", "gallery-2.jpg"]);
    expect((fields.photos as string[]).every((v) => v !== undefined)).toBe(true);
  });
});
