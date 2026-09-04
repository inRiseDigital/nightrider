// FABRICATED seed data for the mock AdminDataSource's user directory. Ported
// from docs/design/admin-dashboard-v3.dc.html's getUsers() (same names,
// cities, roles, and statuses). Replaced wholesale once
// lib/admin/data-source-instance.ts points at a Firestore-backed
// AdminDataSource.
//
// "Active/Suspended/Banned/Deactivated" collapse to Firebase Auth's single
// `disabled` boolean in reality (see docs/FIRESTORE_SCHEMA.md — account
// suspension is an Auth flag, not a Firestore field); `disabledReason`,
// `lastActiveLabel`, `nightsOut`, `savedCount`, and `device` have no real
// Firestore source at all and stay fabricated after wiring too.
//
// casey-alfarsi and sara-whitfield are organizers the mockup's getVenues()/
// getOrgs() reference as venue owners but omits from its own getUsers() list
// — added here so venue-owner joins in the mock data source resolve.

import type { OrganizerStatus, UserRecord } from "../schema";
import type { UserAccountState } from "../view-models";
import { dateAt } from "./seed";

export interface MockUser {
  record: UserRecord;
  accountState: UserAccountState;
  disabledReason: string | null;
  lastActiveLabel: string;
  nightsOut: number;
  savedCount: number;
  device: string;
  note: string | null;
  organizerVenueName: string | null;
  adminScopeLabel: string | null;
}

function baseUser(partial: {
  uid: string;
  email: string;
  displayName: string;
  city: string;
  phone: string;
  isAdmin?: boolean;
  organizerStatus?: OrganizerStatus;
  createdAt: ReturnType<typeof dateAt>;
}): UserRecord {
  return {
    uid: partial.uid,
    email: partial.email,
    displayName: partial.displayName,
    city: partial.city,
    phone: partial.phone,
    instagram: "",
    isAdmin: partial.isAdmin ?? false,
    organizerStatus: partial.organizerStatus ?? "none",
    organizerApplication: null,
    applicationSubmittedAt: null,
    createdAt: partial.createdAt,
    updatedAt: partial.createdAt,
  };
}

const users: MockUser[] = [
  {
    record: baseUser({ uid: "u-amina", email: "amina.nasser@mail.com", displayName: "Amina Nasser", city: "Dubai", phone: "+971 50 884 2210", createdAt: dateAt(2026, 7, 2) }),
    accountState: "active", disabledReason: null, lastActiveLabel: "11 min ago",
    nightsOut: 14, savedCount: 27, device: "iPhone 15 · iOS 19.2", note: null, organizerVenueName: null, adminScopeLabel: null,
  },
  {
    record: baseUser({ uid: "u-tomas", email: "tomas.l@mail.com", displayName: "Tomas Lindqvist", city: "London", phone: "+44 7700 900318", createdAt: dateAt(2026, 6, 28) }),
    accountState: "active", disabledReason: null, lastActiveLabel: "2h ago",
    nightsOut: 6, savedCount: 9, device: "Pixel 9 · Android 17", note: null, organizerVenueName: null, adminScopeLabel: null,
  },
  {
    record: baseUser({ uid: "u-mei", email: "mei.tanaka@mail.com", displayName: "Mei Tanaka", city: "Tokyo", phone: "+81 90 4412 8890", createdAt: dateAt(2026, 6, 19) }),
    accountState: "disabled", disabledReason: "Suspended 7 days after repeated no-shows on guest-list bookings.", lastActiveLabel: "Yesterday",
    nightsOut: 31, savedCount: 52, device: "iPhone 14 · iOS 18.6", note: "Suspended 7 days after repeated no-shows on guest-list bookings.", organizerVenueName: null, adminScopeLabel: null,
  },
  {
    record: baseUser({ uid: "u-jordan", email: "jordan.brooks@mail.com", displayName: "Jordan Brooks", city: "Melbourne", phone: "+61 4 1122 8890", createdAt: dateAt(2026, 6, 14) }),
    accountState: "active", disabledReason: null, lastActiveLabel: "3d ago",
    nightsOut: 3, savedCount: 4, device: "iPhone 13 · iOS 18.4", note: null, organizerVenueName: null, adminScopeLabel: null,
  },
  {
    record: baseUser({ uid: "kenji-yamamoto", email: "kenji.yamamoto@mail.com", displayName: "Kenji Yamamoto", city: "Melbourne", phone: "+61 3 8765 4321", organizerStatus: "approved", createdAt: dateAt(2026, 6, 22) }),
    accountState: "active", disabledReason: null, lastActiveLabel: "38 min ago",
    nightsOut: 0, savedCount: 0, device: "MacBook · Chrome 141", note: null, organizerVenueName: "Neon Fox", adminScopeLabel: null,
  },
  {
    record: baseUser({ uid: "u-priya", email: "priya.raman@mail.com", displayName: "Priya Raman", city: "Dubai", phone: "+971 55 220 7714", createdAt: dateAt(2026, 6, 9) }),
    accountState: "disabled", disabledReason: "Banned for harassment reported by two venues in Dubai.", lastActiveLabel: "5h ago",
    nightsOut: 22, savedCount: 18, device: "Galaxy S25 · Android 17", note: "Banned for harassment reported by two venues in Dubai.", organizerVenueName: null, adminScopeLabel: null,
  },
  {
    record: baseUser({ uid: "haruto-kobayashi", email: "haruto.kobayashi@mail.com", displayName: "Haruto Kobayashi", city: "London", phone: "+44 20 7946 0958", organizerStatus: "approved", createdAt: dateAt(2026, 2, 20) }),
    accountState: "active", disabledReason: null, lastActiveLabel: "1h ago",
    nightsOut: 0, savedCount: 0, device: "Windows · Edge 140", note: null, organizerVenueName: "Fahidi Social Club", adminScopeLabel: null,
  },
  {
    record: baseUser({ uid: "u-aisha", email: "admin@nightride.app", displayName: "Aisha Darwish", city: "Dubai", phone: "+971 50 111 0044", isAdmin: true, createdAt: dateAt(2026, 0, 11) }),
    accountState: "active", disabledReason: null, lastActiveLabel: "Online now",
    nightsOut: 0, savedCount: 0, device: "MacBook · Chrome 141", note: null, organizerVenueName: null, adminScopeLabel: "Full platform access",
  },
  {
    record: baseUser({ uid: "u-noah", email: "noah.weber@mail.com", displayName: "Noah Weber", city: "Melbourne", phone: "+61 4 5566 1120", createdAt: dateAt(2026, 6, 4) }),
    accountState: "active", disabledReason: null, lastActiveLabel: "6d ago",
    nightsOut: 9, savedCount: 11, device: "iPhone 15 Pro · iOS 19.1", note: null, organizerVenueName: null, adminScopeLabel: null,
  },
  {
    record: baseUser({ uid: "yuki-walker", email: "yuki.walker@mail.com", displayName: "Yuki Walker", city: "Tokyo", phone: "+81 3 5678 1234", organizerStatus: "approved", createdAt: dateAt(2026, 3, 15) }),
    accountState: "active", disabledReason: null, lastActiveLabel: "4d ago",
    nightsOut: 0, savedCount: 0, device: "iPad · Safari 19", note: null, organizerVenueName: "Chapel Underground", adminScopeLabel: null,
  },
  {
    record: baseUser({ uid: "u-marco", email: "marco.silva@nightride.app", displayName: "Marco Silva", city: "London", phone: "+44 7700 900112", isAdmin: true, createdAt: dateAt(2026, 1, 2) }),
    accountState: "active", disabledReason: null, lastActiveLabel: "25 min ago",
    nightsOut: 0, savedCount: 0, device: "MacBook · Chrome 141", note: null, organizerVenueName: null, adminScopeLabel: "Content moderation · London",
  },
  {
    record: baseUser({ uid: "u-hana", email: "hana.kim@mail.com", displayName: "Hana Kim", city: "Tokyo", phone: "+81 80 3344 5566", createdAt: dateAt(2026, 5, 30) }),
    accountState: "disabled", disabledReason: "Account deactivated at the user's own request.", lastActiveLabel: "12d ago",
    nightsOut: 17, savedCount: 30, device: "Galaxy S24 · Android 16", note: "Account deactivated at the user's own request.", organizerVenueName: null, adminScopeLabel: null,
  },
  {
    record: baseUser({ uid: "u-elias", email: "elias.farah@mail.com", displayName: "Elias Farah", city: "Dubai", phone: "+971 52 908 4412", createdAt: dateAt(2026, 5, 21) }),
    accountState: "active", disabledReason: null, lastActiveLabel: "1h ago",
    nightsOut: 11, savedCount: 6, device: "iPhone 12 · iOS 18.2", note: null, organizerVenueName: null, adminScopeLabel: null,
  },
  {
    record: baseUser({ uid: "riley-khan", email: "riley.khan@mail.com", displayName: "Riley Khan", city: "Melbourne", phone: "+61 3 2345 6789", organizerStatus: "approved", createdAt: dateAt(2026, 5, 9) }),
    accountState: "active", disabledReason: null, lastActiveLabel: "2d ago",
    nightsOut: 0, savedCount: 0, device: "MacBook · Safari 19", note: null, organizerVenueName: "Brick Lane Social", adminScopeLabel: null,
  },
  {
    record: baseUser({ uid: "u-sofia", email: "sofia.costa@mail.com", displayName: "Sofia Costa", city: "London", phone: "+44 7700 900774", createdAt: dateAt(2026, 5, 2) }),
    accountState: "active", disabledReason: null, lastActiveLabel: "9h ago",
    nightsOut: 25, savedCount: 41, device: "iPhone 15 · iOS 19.2", note: null, organizerVenueName: null, adminScopeLabel: null,
  },
  // Referenced as venue owners by ../mock/venues.ts but absent from the
  // mockup's own getUsers() — added for referential integrity, see header.
  {
    record: baseUser({ uid: "casey-alfarsi", email: "casey.al-farsi@mail.com", displayName: "Casey Al-Farsi", city: "Tokyo", phone: "+81 3 4567 8901", organizerStatus: "approved", createdAt: dateAt(2026, 6, 8) }),
    accountState: "active", disabledReason: null, lastActiveLabel: "1h ago",
    nightsOut: 0, savedCount: 0, device: "MacBook · Chrome 141", note: null, organizerVenueName: "Warehouse 9", adminScopeLabel: null,
  },
  {
    record: baseUser({ uid: "sara-whitfield", email: "sara.whitfield@mail.com", displayName: "Sara Whitfield", city: "Melbourne", phone: "+61 3 9012 3456", organizerStatus: "approved", createdAt: dateAt(2026, 6, 1) }),
    accountState: "active", disabledReason: null, lastActiveLabel: "3h ago",
    nightsOut: 0, savedCount: 0, device: "MacBook · Safari 19", note: null, organizerVenueName: "Full Moon Rooftop", adminScopeLabel: null,
  },
];

const store = new Map<string, MockUser>(users.map((u) => [u.record.uid, u]));

export function allMockUsers(): MockUser[] {
  return Array.from(store.values());
}

export function getMockUser(uid: string): MockUser | null {
  return store.get(uid) ?? null;
}

export function setMockUserAccountState(uid: string, state: UserAccountState): void {
  const u = store.get(uid);
  if (!u) return;
  u.accountState = state;
  if (state === "active") u.disabledReason = null;
}
