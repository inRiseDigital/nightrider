// FABRICATED seed data for the mock AdminDataSource's event review queue.
// Ported from docs/design/admin-dashboard-v3.dc.html's getEvents() (same
// names, venues, organizers, dates, and flags). Replaced wholesale once
// lib/admin/data-source-instance.ts points at a Firestore-backed
// AdminDataSource.
//
// Events are post-moderation: `status`/`moderation.flag` below are real
// events/{id} fields per docs/FIRESTORE_SCHEMA.md — there is no pre-publish
// gate. Each flag's `simulated` bit says whether a real detector could ever
// back it (a stock-photo match has none; a recurring-series or venue-
// verification flag is a straightforward derivation from real fields).

import type { EventDoc } from "../schema";
import type { EventQueueFlag } from "../view-models";
import { dateAt, nowTimestamp } from "./seed";

export interface MockEvent {
  event: EventDoc;
  organizerUid: string;
  flags: EventQueueFlag[];
  reviewedByLabel: string | null;
  rejectReason: string | null;
}

function baseEvent(partial: {
  id: string;
  name: string;
  description: string;
  venueId: string;
  venueName: string;
  city: string;
  organizerUid: string;
  startAt: ReturnType<typeof dateAt>;
  endAt: ReturnType<typeof dateAt>;
  ageRestriction: number;
  genre: string;
  currency: string;
  tiers: { name: string; price: number; qty: number }[];
  recurring?: boolean;
  recurrenceLabel?: string;
  status: EventDoc["status"];
  flag: EventDoc["moderation"]["flag"];
  requestedAt: ReturnType<typeof dateAt>;
  reviewedBy?: string | null;
  note?: string;
}): EventDoc {
  return {
    id: partial.id,
    name: partial.name,
    description: partial.description,
    venueId: partial.venueId,
    venueName: partial.venueName,
    city: partial.city,
    countryCode: "",
    startAt: partial.startAt,
    endAt: partial.endAt,
    price: { min: 0, max: 0, currency: partial.currency, isFree: false },
    coverImage: "",
    genre: partial.genre,
    performers: [],
    policies: { ageRestriction: partial.ageRestriction },
    interestedCount: 0,
    status: partial.status,
    source: "organizer",
    organizerUid: partial.organizerUid,
    recurring: partial.recurring ?? false,
    recurrenceLabel: partial.recurrenceLabel ?? "",
    tickets: { currency: partial.currency, tiers: partial.tiers },
    moderation: {
      flag: partial.flag,
      requestedAt: partial.requestedAt,
      eta: null,
      reviewedBy: partial.reviewedBy ?? null,
      note: partial.note ?? "",
    },
    createdAt: partial.requestedAt,
    updatedAt: partial.requestedAt,
  };
}

const events: MockEvent[] = [
  {
    event: baseEvent({
      id: "ev-1", name: "Full Moon Rooftop", description: "Open-air rooftop session running to sunrise. Two rooms, resident crew on the terrace and guest sets on the main floor.",
      venueId: "full-moon", venueName: "Full Moon Rooftop", city: "Melbourne", organizerUid: "sara-whitfield",
      startAt: dateAt(2026, 8, 12, 22, 0), endAt: dateAt(2026, 8, 13, 4, 0), ageRestriction: 21, genre: "House · Disco",
      currency: "AED", tiers: [{ name: "Early bird", price: 80, qty: 100 }, { name: "General", price: 120, qty: 300 }],
      status: "in_review", flag: "pending", requestedAt: dateAt(2026, 8, 4, 18, 42),
    }),
    organizerUid: "sara-whitfield",
    flags: [{ id: "dup-window", label: "Similar event by the same organizer 3 nights later", icon: "content_copy", tone: "warning", simulated: false }],
    reviewedByLabel: null, rejectReason: null,
  },
  {
    event: baseEvent({
      id: "ev-2", name: "Techno Fridays", description: "Weekly resident night in the main hall. Recurring submission — approving publishes the full series.",
      venueId: "warehouse-9", venueName: "Warehouse 9", city: "Tokyo", organizerUid: "casey-alfarsi",
      startAt: dateAt(2026, 8, 11, 23, 0), endAt: dateAt(2026, 8, 12, 5, 0), ageRestriction: 18, genre: "Techno",
      currency: "JPY", tiers: [{ name: "Door", price: 3000, qty: 400 }],
      recurring: true, recurrenceLabel: "Every Friday until 27 Nov",
      status: "in_review", flag: "pending", requestedAt: dateAt(2026, 8, 4, 17, 55),
    }),
    organizerUid: "casey-alfarsi",
    flags: [{ id: "recurring-series", label: "Recurring series — 12 dates publish at once", icon: "repeat", tone: "info", simulated: false }],
    reviewedByLabel: null, rejectReason: null,
  },
  {
    event: baseEvent({
      id: "ev-3", name: "Sunset to Sunrise", description: "Ten-hour marathon set on the terrace with a sunrise close.",
      venueId: "full-moon", venueName: "Full Moon Rooftop", city: "Melbourne", organizerUid: "sara-whitfield",
      startAt: dateAt(2026, 8, 13, 20, 0), endAt: dateAt(2026, 8, 14, 6, 0), ageRestriction: 21, genre: "Melodic House",
      currency: "AED", tiers: [{ name: "General", price: 100, qty: 250 }],
      status: "in_review", flag: "pending", requestedAt: dateAt(2026, 8, 4, 15, 30),
    }),
    organizerUid: "sara-whitfield",
    flags: [
      { id: "past-close", label: "Runs 2h past the venue's licensed close (04:00)", icon: "schedule", tone: "danger", simulated: false },
      { id: "missing-hero", label: "Only one asset uploaded — hero image missing", icon: "image_not_supported", tone: "warning", simulated: true },
    ],
    reviewedByLabel: null, rejectReason: null,
  },
  {
    event: baseEvent({
      id: "ev-4", name: "Members Only: Vol. 3", description: "Invite-led night in the basement room. Lineup announced 48h before doors.",
      venueId: "warehouse-9", venueName: "Warehouse 9", city: "Tokyo", organizerUid: "casey-alfarsi",
      startAt: dateAt(2026, 8, 19, 22, 0), endAt: dateAt(2026, 8, 20, 5, 0), ageRestriction: 20, genre: "Deep House",
      currency: "JPY", tiers: [{ name: "Members", price: 2500, qty: 200 }, { name: "Guest", price: 4000, qty: 150 }],
      status: "in_review", flag: "pending", requestedAt: dateAt(2026, 8, 4, 13, 20),
    }),
    organizerUid: "casey-alfarsi",
    flags: [{ id: "stock-hero", label: "Hero image matched a stock photo library", icon: "photo_library", tone: "danger", simulated: true }],
    reviewedByLabel: null, rejectReason: null,
  },
  {
    event: baseEvent({
      id: "ev-5", name: "Basement Bass", description: "Three-way b2b in the low room. Capacity capped at 180 by licence.",
      venueId: "fahidi-basement", venueName: "The Basement", city: "London", organizerUid: "haruto-kobayashi",
      startAt: dateAt(2026, 8, 18, 22, 0), endAt: dateAt(2026, 8, 19, 4, 0), ageRestriction: 18, genre: "Drum & Bass",
      currency: "GBP", tiers: [{ name: "Advance", price: 12, qty: 120 }, { name: "Door", price: 18, qty: 60 }],
      status: "in_review", flag: "pending", requestedAt: dateAt(2026, 8, 3, 20, 10),
    }),
    organizerUid: "haruto-kobayashi",
    flags: [],
    reviewedByLabel: null, rejectReason: null,
  },
  {
    event: baseEvent({
      id: "ev-6", name: "Brick Lane Sundays", description: "Live band residency, early close. Same format as the approved August run.",
      venueId: "brick-lane", venueName: "Brick Lane Social", city: "Melbourne", organizerUid: "riley-khan",
      startAt: dateAt(2026, 8, 20, 19, 0), endAt: dateAt(2026, 8, 21, 1, 0), ageRestriction: 18, genre: "Soul · Funk",
      currency: "AED", tiers: [{ name: "General", price: 60, qty: 220 }],
      recurring: true, recurrenceLabel: "Every Sunday until 15 Nov",
      status: "in_review", flag: "pending", requestedAt: dateAt(2026, 8, 2, 11, 5),
    }),
    organizerUid: "riley-khan",
    flags: [],
    reviewedByLabel: null, rejectReason: null,
  },
  {
    event: baseEvent({
      id: "ev-7", name: "Neon Fox Anniversary", description: "Five-year anniversary across both rooms, capacity to licence.",
      venueId: "neon-fox", venueName: "Neon Fox", city: "Melbourne", organizerUid: "kenji-yamamoto",
      startAt: dateAt(2026, 8, 26, 21, 0), endAt: dateAt(2026, 8, 27, 4, 0), ageRestriction: 21, genre: "Techno · House",
      currency: "AED", tiers: [{ name: "Phase 1", price: 90, qty: 150 }, { name: "Phase 2", price: 130, qty: 270 }],
      status: "published", flag: "clean", requestedAt: dateAt(2026, 8, 2, 9, 44), reviewedBy: "u-aisha",
    }),
    organizerUid: "kenji-yamamoto",
    flags: [],
    reviewedByLabel: "Aisha Darwish", rejectReason: null,
  },
  {
    event: baseEvent({
      id: "ev-8", name: "Chapel After Hours", description: "Late-late room, no advance tickets.",
      venueId: "chapel-underground", venueName: "Chapel Underground", city: "Tokyo", organizerUid: "yuki-walker",
      startAt: dateAt(2026, 8, 12, 23, 0), endAt: dateAt(2026, 8, 13, 5, 0), ageRestriction: 18, genre: "Hard Techno",
      currency: "JPY", tiers: [{ name: "Door", price: 3500, qty: 480 }],
      status: "archived", flag: "rejected", requestedAt: dateAt(2026, 9, 1, 22, 16), reviewedBy: "u-mei",
      note: "Venue GPS check has not passed — cannot publish events at an unverified venue.",
    }),
    organizerUid: "yuki-walker",
    flags: [{ id: "venue-unverified", label: "Venue verification incomplete (GPS)", icon: "location_off", tone: "danger", simulated: false }],
    reviewedByLabel: "Mei Lin", rejectReason: "Venue GPS check has not passed — cannot publish events at an unverified venue.",
  },
];

const store = new Map<string, MockEvent>(events.map((e) => [e.event.id, e]));

export function allMockEvents(): MockEvent[] {
  return Array.from(store.values());
}

export function getMockEvent(id: string): MockEvent | null {
  return store.get(id) ?? null;
}

export function decideMockEvent(id: string, decision: "approved" | "rejected", adminName: string, reason?: string): void {
  const e = store.get(id);
  if (!e) return;
  const at = nowTimestamp();
  if (decision === "approved") {
    e.event = { ...e.event, status: "published", updatedAt: at, moderation: { ...e.event.moderation, flag: "clean", reviewedBy: adminName, note: "" } };
    e.rejectReason = null;
  } else {
    e.event = { ...e.event, status: "archived", updatedAt: at, moderation: { ...e.event.moderation, flag: "rejected", reviewedBy: adminName, note: reason ?? "" } };
    e.rejectReason = reason ?? "";
  }
  e.reviewedByLabel = adminName;
}

export function reopenMockEvent(id: string): void {
  const e = store.get(id);
  if (!e) return;
  e.event = { ...e.event, status: "in_review", updatedAt: nowTimestamp(), moderation: { ...e.event.moderation, flag: "pending", reviewedBy: null, note: "" } };
  e.reviewedByLabel = null;
  e.rejectReason = null;
}
