import { Timestamp } from "firebase/firestore";
import { describe, expect, it } from "vitest";
import { parseOrganizerEvent, toEventDocFields } from "./events";
import type { OrganizerEvent, VenueMeta } from "../types";

const MOCK_EVENT: OrganizerEvent = {
  id: "e1",
  name: "Full Moon Rooftop",
  venue: "sirens",
  date: "2026-08-08",
  startTime: "22:00",
  endTime: "04:00",
  lineup: ["DJ Kalima", "Nyx"],
  tiers: [
    { name: "Early Bird", price: 80, qty: 100 },
    { name: "General", price: 120, qty: 300 },
  ],
  status: "published",
  recurring: false,
  recurrenceLabel: "",
  scheduledPublish: "",
  notifyOnChange: true,
  moderationFlag: "clean",
  moderationEta: "",
  cancelReason: "",
  sold: 268,
  revenue: 21440,
};

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
    const ui: OrganizerEvent = { ...MOCK_EVENT, status: "published" };
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
      ...MOCK_EVENT,
      tiers: [
        { name: "Early Bird", price: 80, qty: 100 },
        { name: "General", price: 120, qty: 300 },
      ],
    };
    const fields = toEventDocFields(ui, { meta, venueName: "Sirens Dubai", raw: {} });
    expect(fields.price).toEqual({ min: 80, max: 120, currency: "", isFree: false });
  });

  it("writes no lineup field — maps to performers[i].name with type DJ", () => {
    const ui: OrganizerEvent = { ...MOCK_EVENT, lineup: ["DJ Kalima", "Nyx"] };
    const fields = toEventDocFields(ui, { meta, venueName: "Sirens Dubai", raw: {} });
    expect(fields.lineup).toBeUndefined();
    expect(fields.performers).toEqual([
      { name: "DJ Kalima", type: "DJ", bio: "" },
      { name: "Nyx", type: "DJ", bio: "" },
    ]);
  });

  it("never writes moderation or sales — both are producer-owned and pass through from raw untouched", () => {
    const ui: OrganizerEvent = { ...MOCK_EVENT, moderationFlag: "clean", moderationEta: "" };
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
    const ui: OrganizerEvent = { ...MOCK_EVENT, venue: "sirens" };
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

  // Fix round 1: an organizer can load and re-save an admin/scraped document
  // assigned to them (organizerUid set, source left as-is) that has no
  // stored endAt — parseOrganizerEvent correctly yields endTime: "". The
  // write must round-trip endAt as null, not fabricate a midnight close via
  // eventWindowToTimestamps' old minutesOf("") === 0 behaviour, and not have
  // `window?.endAt ?? toTimestampOrNull(ctx.raw.endAt)` silently reinstate
  // whatever stale endAt happened to be on the stored document.
  it("edit-save of a null-endAt (scraped/admin) document round-trips endAt as null, never fabricating one", () => {
    const raw = {
      name: "Scraped Night",
      startAt: Timestamp.fromDate(new Date("2026-08-08T22:00:00Z")),
      endAt: null,
      source: "scraped",
    };
    const parsed = parseOrganizerEvent("e10", raw, meta.timeZone);
    expect(parsed.endTime).toBe("");

    const edited: OrganizerEvent = { ...parsed, name: "Scraped Night (Retitled)" };
    const fields = toEventDocFields(edited, { meta, venueName: "Sirens Dubai", raw });

    expect(fields.endAt).toBeNull();

    const back = parseOrganizerEvent("e10", fields, meta.timeZone);
    expect(back.endTime).toBe("");
    expect(back.name).toBe("Scraped Night (Retitled)");
  });

  it("does not silently reinstate a stale stored endAt when the UI's endTime is legitimately empty", () => {
    // A pathological but rules-permitted stored document: source stays
    // 'scraped'/'admin' (never touched by the organizer's write), but an
    // earlier write happened to leave a (now-superseded) endAt on it. The
    // organizer's own edit, with endTime parsed as "", must still write
    // endAt: null — not resurrect the old stored value via a `??` that can't
    // tell "no window" from "window says null".
    const raw = {
      name: "Scraped Night",
      startAt: Timestamp.fromDate(new Date("2026-08-08T22:00:00Z")),
      endAt: Timestamp.fromDate(new Date("2026-08-09T02:00:00Z")),
      source: "scraped",
    };
    const uiWithNoEndTime: OrganizerEvent = {
      ...MOCK_EVENT,
      date: "2026-08-08",
      startTime: "22:00",
      endTime: "",
    };
    const fields = toEventDocFields(uiWithNoEndTime, { meta, venueName: "Sirens Dubai", raw });
    expect(fields.endAt).toBeNull();
  });

  it("duplicating a null-endAt document's mapper output never invents a midnight close", () => {
    // What useEvents.ts's duplicateEvent() builds: a fresh draft UI sourced
    // from the parsed original, empty raw (no producer fields carried over).
    // The hook itself refuses to duplicate an event with no endTime (see
    // useEvents.ts) — this asserts the mapper-level guarantee that fix round
    // 1 relies on: even without that guard, the mapper would write `null`,
    // never a fabricated Timestamp.
    const src = parseOrganizerEvent(
      "e11",
      { name: "Scraped Night", startAt: Timestamp.fromDate(new Date("2026-08-08T22:00:00Z")), endAt: null },
      meta.timeZone
    );
    const duplicateDraft: OrganizerEvent = { ...src, id: "", name: `${src.name} (Copy)`, status: "draft" };
    const fields = toEventDocFields(duplicateDraft, { meta, venueName: "Sirens Dubai", raw: {} });
    expect(fields.endAt).toBeNull();
  });
});
