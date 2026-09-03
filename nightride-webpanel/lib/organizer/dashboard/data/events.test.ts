import { Timestamp } from "firebase/firestore";
import { describe, expect, it } from "vitest";
import { parseOrganizerEvent, toEventDocFields } from "./events";
import type { OrganizerEvent, VenueMeta } from "../types";
import { MOCK_EVENTS } from "../mock-data";

const meta: VenueMeta = {
  id: "sirens",
  ownerUid: "u1",
  city: "Dubai",
  countryCode: "AE",
  timeZone: "Asia/Dubai",
  geo: { latitude: 25.1, longitude: 55.2 },
  status: "active",
  verified: true,
};

describe("parseOrganizerEvent(toEventDocFields(ui, ctx)) round-trip", () => {
  it("round-trips a published event, including unmapped raw keys", () => {
    const ui: OrganizerEvent = { ...MOCK_EVENTS[0], status: "published" };
    const raw = {
      description: "Rooftop techno with a skyline view.",
      policies: { ageRestriction: 21, refundPolicy: "none", reEntryAllowed: true, wheelchairAccessible: true, allowPets: false },
      genre: "Techno",
      category: "Nightclub",
      vibe: "High energy",
      language: "en",
      ticketUrl: "https://example.com/tickets",
      interestedCount: 42,
      popularityScore: 7,
    };

    const fields = toEventDocFields(ui, { meta, venueName: "Sirens Dubai", raw });

    // Raw-remainder merge: fields only the Flutter app reads survive untouched.
    expect(fields.description).toBe(raw.description);
    expect(fields.policies).toEqual(raw.policies);
    expect(fields.genre).toBe(raw.genre);
    expect(fields.interestedCount).toBe(42);
    expect(fields.popularityScore).toBe(7);

    const back = parseOrganizerEvent(ui.id, fields, meta.timeZone);
    expect(back.name).toBe(ui.name);
    expect(back.venue).toBe(ui.venue);
    expect(back.date).toBe(ui.date);
    expect(back.startTime).toBe(ui.startTime);
    expect(back.endTime).toBe(ui.endTime);
    expect(back.lineup).toEqual(ui.lineup);
    expect(back.tiers).toEqual(ui.tiers);
    expect(back.status).toBe(ui.status);
    expect(back.recurring).toBe(ui.recurring);
    expect(back.notifyOnChange).toBe(ui.notifyOnChange);
  });

  it("derives price.min/max/isFree from tiers on every write", () => {
    const ui: OrganizerEvent = {
      ...MOCK_EVENTS[0],
      tiers: [
        { name: "Early Bird", price: 80, qty: 100 },
        { name: "General", price: 120, qty: 300 },
      ],
    };
    const fields = toEventDocFields(ui, { meta, venueName: "Sirens Dubai", raw: {} });
    expect(fields.price).toEqual({ min: 80, max: 120, currency: "", isFree: false });
  });

  it("writes no lineup field — maps to performers[i].name with type DJ", () => {
    const ui: OrganizerEvent = { ...MOCK_EVENTS[0], lineup: ["DJ Kalima", "Nyx"] };
    const fields = toEventDocFields(ui, { meta, venueName: "Sirens Dubai", raw: {} });
    expect(fields.lineup).toBeUndefined();
    expect(fields.performers).toEqual([
      { name: "DJ Kalima", type: "DJ", bio: "" },
      { name: "Nyx", type: "DJ", bio: "" },
    ]);
  });

  it("never writes moderation or sales — both are producer-owned and pass through from raw untouched", () => {
    const ui: OrganizerEvent = { ...MOCK_EVENTS[0], moderationFlag: "clean", moderationEta: "" };
    const raw = {
      moderation: { flag: "pending", eta: Timestamp.fromDate(new Date("2026-08-08T22:00:00Z")) },
      sales: { sold: 120, gross: 9600 },
    };

    const fields = toEventDocFields(ui, { meta, venueName: "Sirens Dubai", raw });

    // UI carries a different moderationFlag ("clean") than the stored doc
    // ("pending") — the write must still leave moderation byte-identical to
    // what was stored, or producerFieldsPinned() rejects the update.
    expect(fields.moderation).toEqual(raw.moderation);
    expect(fields.sales).toEqual(raw.sales);
  });

  it("re-derives venueName from ctx on every write, never carrying forward the stored value", () => {
    const ui: OrganizerEvent = { ...MOCK_EVENTS[0], venue: "sirens" };
    const raw = { venueName: "Old Stale Name (venue since renamed)" };
    const fields = toEventDocFields(ui, { meta, venueName: "Sirens Dubai", raw });
    expect(fields.venueName).toBe("Sirens Dubai");
    expect(fields.venueName).not.toBe(raw.venueName);
  });

  it("tolerates endAt === null on read, returning endTime ''", () => {
    const back = parseOrganizerEvent(
      "e9",
      { name: "Scraped Night", startAt: Timestamp.fromDate(new Date("2026-08-08T22:00:00Z")), endAt: null },
      meta.timeZone
    );
    expect(back.endTime).toBe("");
    expect(back.date).toBe("2026-08-09"); // Asia/Dubai is UTC+4
  });
});
