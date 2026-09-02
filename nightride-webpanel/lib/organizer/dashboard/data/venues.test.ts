import { describe, expect, it } from "vitest";
import { parseTonight, parseVenueProfile, toLiveFields, toVenueDocFields } from "./venues";
import type { DoorStatus, TonightState } from "../types";
import { MOCK_VENUES } from "../mock-data";

describe("parseVenueProfile(toVenueDocFields(ui)) round-trip", () => {
  it("preserves the reviewable listing fields", () => {
    const ui = MOCK_VENUES.sirens;
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
    const fields = toVenueDocFields(MOCK_VENUES.sirens, { raw });
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
