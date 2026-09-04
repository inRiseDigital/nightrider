import { describe, expect, it } from "vitest";
import {
  applyPendingListing,
  computeVenueProfile,
  isVenueDirty,
  isVenueIdentityDirty,
  listingFieldsOf,
  toVenueDirectFields,
  toVenueEditListing,
  withLiveFields,
} from "./venues";
import type { VenueProfile } from "../types";

const MOCK_VENUE: VenueProfile = {
  verified: true,
  verificationSteps: { license: "done", gps: "done", video: "done" },
  openVerifyStep: null,
  name: "Sirens Dubai",
  city: "Dubai, UAE",
  address: "Marina Walk, Dubai Marina, Dubai, UAE",
  about: "Rooftop techno and house on the Marina skyline.",
  socialLinks: [
    { network: "instagram", value: "@sirensdubai" },
    { network: "tiktok", value: "@sirensdubai" },
  ],
  genres: ["Techno", "House"],
  dressCode: "Smart Casual",
  agePolicy: "21+",
  coverMin: 50,
  coverMax: 150,
  currency: "AED",
  capacity: 450,
  amenities: ["Rooftop", "Cloakroom"],
  hours: [
    { day: "Mon", closed: true, open: "22:00", close: "04:00" },
    { day: "Tue", closed: true, open: "22:00", close: "04:00" },
    { day: "Wed", closed: false, open: "22:00", close: "04:00" },
    { day: "Thu", closed: false, open: "22:00", close: "04:00" },
    { day: "Fri", closed: false, open: "22:00", close: "04:00" },
    { day: "Sat", closed: false, open: "22:00", close: "04:00" },
    { day: "Sun", closed: false, open: "22:00", close: "04:00" },
  ],
  exceptions: [],
  menu: [
    {
      id: "ms1",
      name: "Bottle service & tables",
      items: [
        {
          id: "mi1",
          name: "Skyline table — Grey Goose",
          price: 3200,
          desc: "Reserved terrace table with skyline view, two mixers per bottle.",
          size: "1.5L magnum",
          serves: "6",
          tags: ["Signature"],
          nights: [4, 5],
          soldOut: false,
          image: "",
        },
      ],
    },
  ],
  tableLink: "",
  photos: [],
};

/**
 * The draft/published seam is what makes `useVenues`'s `onSnapshot` listener
 * safe: "a remote snapshot must never clobber an in-progress local edit"
 * (task-8-brief.md). These are the pure functions `useVenues` builds
 * `profile`/`venueDirty` from, so the property is tested directly rather
 * than only being observable by rendering the hook (this repo has no
 * React Testing Library set up for hooks).
 */
describe("computeVenueProfile — snapshot must never clobber an in-progress draft", () => {
  const saved = MOCK_VENUE;

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

  it("shows a menu edit made while a listing draft is open (menu bypasses the draft entirely)", () => {
    // The draft was seeded from `saved` at draft-creation time, so its
    // `menu` is frozen at whatever the snapshot held then.
    const draft = { ...saved, name: "Sirens Dubai (editing)" };
    // The organizer then edits the Menu tab, which writes straight to
    // Firestore — the next snapshot reflects it in `saved.menu`.
    const nextSaved = { ...saved, menu: [...saved.menu, { id: "new-section", name: "New section", items: [] }] };

    const profile = computeVenueProfile(draft, nextSaved);

    expect(profile.name).toBe("Sirens Dubai (editing)");
    expect(profile.menu).toEqual(nextSaved.menu);
    expect(profile.menu).not.toEqual(draft.menu);
  });
});

describe("withLiveFields", () => {
  it("overlays verified/verificationSteps/openVerifyStep/menu onto the draft, nothing else", () => {
    const draft = { ...MOCK_VENUE, name: "Draft name", about: "Draft about", menu: [] };
    const saved = {
      ...MOCK_VENUE,
      verified: false,
      openVerifyStep: "gps" as const,
      menu: MOCK_VENUE.menu,
    };

    const merged = withLiveFields(draft, saved);

    expect(merged.name).toBe("Draft name");
    expect(merged.about).toBe("Draft about");
    expect(merged.verified).toBe(false);
    expect(merged.openVerifyStep).toBe("gps");
    // `saved.menu` (non-empty, from MOCK_VENUE) and `draft.menu` ([]) are
    // deliberately different here, so this proves `menu` is overlaid from
    // `saved` rather than leaking through from the draft.
    expect(merged.menu).toEqual(saved.menu);
    expect(merged.menu).not.toEqual(draft.menu);
  });
});

describe("isVenueDirty", () => {
  const saved = MOCK_VENUE;

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

  it("ignores a menu-only difference between the frozen draft and a fresher snapshot", () => {
    // The draft's `menu` is frozen at draft-creation time; a menu edit made
    // meanwhile writes straight to Firestore and shows up in `saved.menu`
    // without ever being a "listing" edit the organizer is reviewing.
    const draft = { ...saved };
    const nextSaved = { ...saved, menu: [...saved.menu, { id: "new", name: "New", items: [] }] };
    expect(isVenueDirty(draft, nextSaved)).toBe(false);
  });
});

describe("listingFieldsOf", () => {
  it("strips verified/verificationSteps/openVerifyStep/menu and nothing else", () => {
    const stripped = listingFieldsOf(MOCK_VENUE);
    expect(stripped).not.toHaveProperty("verified");
    expect(stripped).not.toHaveProperty("verificationSteps");
    expect(stripped).not.toHaveProperty("openVerifyStep");
    expect(stripped).not.toHaveProperty("menu");
    expect(stripped.name).toBe(MOCK_VENUE.name);
  });
});

describe("isVenueIdentityDirty — only name/address require admin review", () => {
  const saved = MOCK_VENUE;

  it("is false with no draft", () => {
    expect(isVenueIdentityDirty(undefined, saved)).toBe(false);
  });

  it("is false when name/address are unchanged, even if other fields are dirty", () => {
    const draft = { ...saved, about: "Changed", hours: [], capacity: 999 };
    expect(isVenueIdentityDirty(draft, saved)).toBe(false);
  });

  it("is true when name changed", () => {
    const draft = { ...saved, name: "New Name" };
    expect(isVenueIdentityDirty(draft, saved)).toBe(true);
  });

  it("is true when address changed", () => {
    const draft = { ...saved, address: "New Address" };
    expect(isVenueIdentityDirty(draft, saved)).toBe(true);
  });
});

describe("toVenueEditListing — the venueEdits.listing shape", () => {
  it("carries exactly name and address, nothing else", () => {
    const listing = toVenueEditListing(MOCK_VENUE);
    expect(listing).toEqual({ name: MOCK_VENUE.name, address: MOCK_VENUE.address });
  });
});

describe("toVenueDirectFields — the direct venue-doc write, minus name/address", () => {
  it("omits name and address (those route through venueEdits instead)", () => {
    const fields = toVenueDirectFields(MOCK_VENUE, { timeZone: "Asia/Dubai" });
    expect(fields).not.toHaveProperty("name");
    expect(fields).not.toHaveProperty("address");
    expect(fields.about).toBe(MOCK_VENUE.about);
    expect(fields.hours).toEqual(MOCK_VENUE.hours);
    expect(fields.photos).toEqual(MOCK_VENUE.photos);
    expect(fields.cover).toEqual({ min: MOCK_VENUE.coverMin, max: MOCK_VENUE.coverMax, currency: MOCK_VENUE.currency });
    expect(fields.timeZone).toBe("Asia/Dubai");
  });
});

describe("applyPendingListing — overlays only the reviewed fields (name/address)", () => {
  it("overlays name/address from a pending submission, leaving everything else at saved", () => {
    const overlaid = applyPendingListing(MOCK_VENUE, { name: "Pending Name", address: "Pending Address" });
    expect(overlaid.name).toBe("Pending Name");
    expect(overlaid.address).toBe("Pending Address");
    expect(overlaid.about).toBe(MOCK_VENUE.about);
    expect(overlaid.hours).toEqual(MOCK_VENUE.hours);
  });

  it("falls back to saved when the listing is malformed or partial", () => {
    const overlaid = applyPendingListing(MOCK_VENUE, { name: 42 });
    expect(overlaid.name).toBe(MOCK_VENUE.name);
    expect(overlaid.address).toBe(MOCK_VENUE.address);
  });

  it("falls back to saved entirely when listing is undefined", () => {
    expect(applyPendingListing(MOCK_VENUE, undefined)).toEqual(MOCK_VENUE);
  });
});
