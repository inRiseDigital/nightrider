import { describe, expect, it } from "vitest";
import { parseTonight, parseVenueProfile, toLiveFields, toVenueDocFields } from "./venues";
import type { DoorStatus, TonightState, VenueProfile } from "../types";

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
  menu: [],
  tableLink: "",
  photos: [],
};

describe("parseVenueProfile(toVenueDocFields(ui)) round-trip", () => {
  it("preserves the reviewable listing fields", () => {
    const ui = MOCK_VENUE;
    const fields = toVenueDocFields(ui, { raw: {} });
    const back = parseVenueProfile("sirens", fields, ui.menu);
    // Listing fields only — verified/verificationSteps/openVerifyStep are
    // live fields that intentionally never round-trip through this mapper.
    expect(back.name).toBe(ui.name);
    expect(back.city).toBe(ui.city);
    expect(back.address).toBe(ui.address);
    expect(back.about).toBe(ui.about);
    expect(back.socialLinks).toEqual(ui.socialLinks);
    expect(back.genres).toEqual(ui.genres);
    expect(back.dressCode).toBe(ui.dressCode);
    expect(back.agePolicy).toBe(ui.agePolicy);
    expect(back.coverMin).toBe(ui.coverMin);
    expect(back.coverMax).toBe(ui.coverMax);
    expect(back.currency).toBe(ui.currency);
    expect(back.capacity).toBe(ui.capacity);
    expect(back.amenities).toEqual(ui.amenities);
    expect(back.hours).toEqual(ui.hours);
    expect(back.exceptions).toEqual(ui.exceptions);
    expect(back.tableLink).toBe(ui.tableLink);
  });

  it("preserves unmapped raw keys (editorUids, live, verification)", () => {
    const raw = { editorUids: ["u1"], live: { status: "open" }, verification: { license: { status: "done" } } };
    const fields = toVenueDocFields(MOCK_VENUE, { raw });
    expect(fields.editorUids).toEqual(["u1"]);
    expect(fields.live).toEqual({ status: "open" });
  });
});

describe("parseTonight(toLiveFields(t)) round-trip for all five doorStatus values", () => {
  const capacity = 450;
  const base: TonightState = {
    status: "open",
    inVenue: 100,
    queueMinutes: 5,
    emergencyActive: false,
    flashActive: true,
    flashText: "Free entry before midnight",
    flashUntil: "23:59",
  };

  const statuses: DoorStatus[] = ["open", "filling", "capacity", "guestlist", "closed"];

  for (const status of statuses) {
    it(`round-trips doorStatus "${status}"`, () => {
      const t: TonightState = { ...base, status };
      const fields = toLiveFields(t, { capacity, raw: {} });
      const back = parseTonight(fields, capacity);
      expect(back).toEqual(t);
    });
  }
});
