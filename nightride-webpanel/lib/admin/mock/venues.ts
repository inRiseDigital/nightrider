// FABRICATED seed data for the mock AdminDataSource's venue directory. Ported
// from docs/design/admin-dashboard-v3.dc.html's getVenues()/venueExtra() (the
// same venue names, cities, addresses, and check states). Replaced wholesale
// once lib/admin/data-source-instance.ts points at a Firestore-backed
// AdminDataSource — see that file's header comment.
//
// What IS real: the three-way check breakdown. Firestore carries
// venues/{id}.verification.{license,gps,video}, each a VenueVerifyStep of
// {status, attempt, note, reviewedAt, reviewedBy} whose shape firestore.rules
// enforces. lib/admin/schema.ts's Venue simply doesn't mirror that field yet
// (it models only what the org-apps screens needed), so wiring the checks is
// a type addition, not schema work.
//
// What is NOT real: capacity is present but often 0/unknown; the licence
// number and expiry have no field at all (verification.license stores review
// state only); and suspension has no field today (VenueStatus is 'active' |
// 'closed'). This in-memory store stands in for those until schema work lands.

import type { Timestamp } from "firebase/firestore";
import type { Venue, VenueSource, VenueStatus } from "../schema";
import type { VenueCheckKey, VenueCheckState } from "../view-models";
import { dateAt } from "./seed";

export interface MockVenue {
  venue: Venue;
  organizerUid: string;
  capacity: number;
  licenceNumber: string;
  licenceExpiryLabel: string;
  hoursLabel: string;
  checks: Record<VenueCheckKey, VenueCheckState>;
  suspended: boolean;
  verifiedOnLabel: string;
}

function baseVenue(partial: {
  id: string;
  name: string;
  city: string;
  address: string;
  phone: string;
  ownerUid: string;
  createdAt: Timestamp;
}): Venue {
  return {
    id: partial.id,
    name: partial.name,
    geo: null,
    geohash: "",
    type: "nightclub",
    typeLabel: "Nightclub",
    city: partial.city,
    countryCode: "",
    address: partial.address,
    openingHours: "",
    phone: partial.phone,
    website: "",
    photos: [],
    source: "organizer" as VenueSource,
    osmId: null,
    ownerUid: partial.ownerUid,
    verified: true,
    status: "active" as VenueStatus,
    createdAt: partial.createdAt,
    updatedAt: partial.createdAt,
  };
}

const store = new Map<string, MockVenue>();

function seedVenue(v: MockVenue) {
  v.venue.verified = Object.values(v.checks).every((s) => s === "verified");
  store.set(v.venue.id, v);
}

seedVenue({
  venue: baseVenue({ id: "neon-fox", name: "Neon Fox", city: "Melbourne", address: "26 Al Fahidi St, Melbourne", phone: "+61 3 8765 4321", ownerUid: "kenji-yamamoto", createdAt: dateAt(2026, 6, 20, 19, 55) }),
  organizerUid: "kenji-yamamoto",
  capacity: 420,
  licenceNumber: "VIC-LIQ-88214",
  licenceExpiryLabel: "31 Mar 2027",
  hoursLabel: "Wed–Sun · 21:00–04:00",
  checks: { licence: "verified", gps: "verified", video: "verified" },
  suspended: false,
  verifiedOnLabel: "22 Jul 2026",
});

seedVenue({
  venue: baseVenue({ id: "fox-annex", name: "Fox Annex", city: "Melbourne", address: "30 Al Fahidi St, Melbourne", phone: "+61 3 8765 4399", ownerUid: "kenji-yamamoto", createdAt: dateAt(2026, 7, 4, 9, 30) }),
  organizerUid: "kenji-yamamoto",
  capacity: 140,
  licenceNumber: "VIC-LIQ-88219",
  licenceExpiryLabel: "31 Mar 2027",
  hoursLabel: "Fri–Sat · 22:00–03:00",
  checks: { licence: "verified", gps: "pending", video: "pending" },
  suspended: true,
  verifiedOnLabel: "—",
});

seedVenue({
  venue: baseVenue({ id: "warehouse-9", name: "Warehouse 9", city: "Tokyo", address: "53 Collins St, Tokyo", phone: "+81 3 4567 8901", ownerUid: "casey-alfarsi", createdAt: dateAt(2026, 6, 8) }),
  organizerUid: "casey-alfarsi",
  capacity: 900,
  licenceNumber: "TYO-NC-40127",
  licenceExpiryLabel: "12 Dec 2026",
  hoursLabel: "Fri–Sun · 22:00–05:00",
  checks: { licence: "verified", gps: "verified", video: "verified" },
  suspended: false,
  verifiedOnLabel: "08 Jul 2026",
});

seedVenue({
  venue: baseVenue({ id: "collins-basement", name: "Collins Basement", city: "Tokyo", address: "53a Collins St, Tokyo", phone: "+81 3 4567 8907", ownerUid: "casey-alfarsi", createdAt: dateAt(2026, 8, 2, 8, 15) }),
  organizerUid: "casey-alfarsi",
  capacity: 220,
  licenceNumber: "TYO-NC-40133",
  licenceExpiryLabel: "12 Dec 2026",
  hoursLabel: "Fri–Sat · 23:00–05:00",
  checks: { licence: "pending", gps: "pending", video: "pending" },
  suspended: false,
  verifiedOnLabel: "—",
});

seedVenue({
  venue: baseVenue({ id: "full-moon", name: "Full Moon Rooftop", city: "Melbourne", address: "77 Shibuya Crossing, Melbourne", phone: "+61 3 9012 3456", ownerUid: "sara-whitfield", createdAt: dateAt(2026, 6, 1) }),
  organizerUid: "sara-whitfield",
  capacity: 310,
  licenceNumber: "VIC-LIQ-77032",
  licenceExpiryLabel: "30 Jun 2027",
  hoursLabel: "Thu–Sat · 20:00–02:00",
  checks: { licence: "verified", gps: "verified", video: "verified" },
  suspended: false,
  verifiedOnLabel: "01 Jul 2026",
});

seedVenue({
  venue: baseVenue({ id: "brick-lane", name: "Brick Lane Social", city: "Melbourne", address: "2 Brick Lane, Melbourne", phone: "+61 3 2345 6789", ownerUid: "riley-khan", createdAt: dateAt(2026, 5, 9) }),
  organizerUid: "riley-khan",
  capacity: 260,
  licenceNumber: "VIC-LIQ-51188",
  licenceExpiryLabel: "28 Feb 2027",
  hoursLabel: "Wed–Sat · 19:00–01:00",
  checks: { licence: "verified", gps: "verified", video: "pending" },
  suspended: false,
  verifiedOnLabel: "—",
});

seedVenue({
  venue: baseVenue({ id: "chapel-underground", name: "Chapel Underground", city: "Tokyo", address: "43 Chapel St, Tokyo", phone: "+81 3 5678 1234", ownerUid: "yuki-walker", createdAt: dateAt(2026, 3, 15) }),
  organizerUid: "yuki-walker",
  capacity: 480,
  licenceNumber: "TYO-NC-31904",
  licenceExpiryLabel: "09 Sep 2026",
  hoursLabel: "Fri–Sat · 23:00–05:00",
  checks: { licence: "verified", gps: "failed", video: "verified" },
  suspended: false,
  verifiedOnLabel: "—",
});

seedVenue({
  venue: baseVenue({ id: "fahidi-social", name: "Fahidi Social Club", city: "London", address: "81 Al Fahidi St, London", phone: "+44 20 7946 0958", ownerUid: "haruto-kobayashi", createdAt: dateAt(2026, 2, 20) }),
  organizerUid: "haruto-kobayashi",
  capacity: 350,
  licenceNumber: "LDN-PRM-20447",
  licenceExpiryLabel: "31 Jan 2027",
  hoursLabel: "Tue–Sun · 20:00–03:00",
  checks: { licence: "verified", gps: "verified", video: "verified" },
  suspended: false,
  verifiedOnLabel: "20 Mar 2026",
});

seedVenue({
  venue: baseVenue({ id: "fahidi-basement", name: "The Basement", city: "London", address: "81a Al Fahidi St, London", phone: "+44 20 7946 0960", ownerUid: "haruto-kobayashi", createdAt: dateAt(2026, 4, 2) }),
  organizerUid: "haruto-kobayashi",
  capacity: 180,
  licenceNumber: "LDN-PRM-20448",
  licenceExpiryLabel: "31 Jan 2027",
  hoursLabel: "Fri–Sat · 22:00–04:00",
  checks: { licence: "verified", gps: "verified", video: "verified" },
  suspended: false,
  verifiedOnLabel: "02 May 2026",
});

export function allMockVenues(): MockVenue[] {
  return Array.from(store.values());
}

export function getMockVenue(id: string): MockVenue | null {
  return store.get(id) ?? null;
}

export function setMockVenueCheck(id: string, key: VenueCheckKey, state: VenueCheckState): void {
  const v = store.get(id);
  if (!v) return;
  v.checks = { ...v.checks, [key]: state };
  v.venue = { ...v.venue, verified: Object.values(v.checks).every((s) => s === "verified") };
}

export function setMockVenueSuspended(id: string, suspended: boolean): void {
  const v = store.get(id);
  if (!v) return;
  v.suspended = suspended;
}
