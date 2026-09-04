// FABRICATED seed data for the mock AdminDataSource's admin roster. Ported
// from docs/design/admin-dashboard-v3.dc.html's `admins` state array (same
// names, emails, and city-scope labels). Replaced wholesale once
// lib/admin/data-source-instance.ts points at a Firestore-backed
// AdminDataSource.
//
// `users/{uid}.isAdmin` is the only real bit here (see docs/ROLES.md and the
// product decision recorded in lib/admin/view-models.ts's AdminRow comment).
// displayLevel, cityScopeLabel, addedLabel, and lastActiveLabel are cosmetic
// only and have no real Firestore source.

import type { OrganizerStatus, UserRecord } from "../schema";
import { dateAt } from "./seed";

export interface MockAdmin {
  record: UserRecord;
  displayLevel: string;
  cityScopeLabel: string;
  addedLabel: string;
  lastActiveLabel: string;
  locked: boolean;
  invitePending: boolean;
  revoked: boolean;
}

function baseAdmin(uid: string, name: string, email: string, createdAt: ReturnType<typeof dateAt>): UserRecord {
  return {
    uid,
    email,
    displayName: name,
    city: "",
    phone: "",
    instagram: "",
    isAdmin: true,
    organizerStatus: "none" as OrganizerStatus,
    organizerApplication: null,
    applicationSubmittedAt: null,
    createdAt,
    updatedAt: createdAt,
  };
}

const admins: MockAdmin[] = [
  {
    record: baseAdmin("aisha", "Aisha Darwish", "admin@nightride.app", dateAt(2026, 0, 1)),
    displayLevel: "Super admin", cityScopeLabel: "All cities", addedLabel: "Platform owner", lastActiveLabel: "Online now",
    locked: true, invitePending: false, revoked: false,
  },
  {
    record: baseAdmin("tomas", "Tomás Neves", "tomas@nightride.app", dateAt(2026, 2, 12)),
    displayLevel: "Admin", cityScopeLabel: "Dubai · London", addedLabel: "by Aisha Darwish · 12 Mar 2026", lastActiveLabel: "2h ago",
    locked: false, invitePending: false, revoked: false,
  },
  {
    record: baseAdmin("mei", "Mei Lin", "mei@nightride.app", dateAt(2026, 4, 4)),
    displayLevel: "Admin", cityScopeLabel: "Tokyo", addedLabel: "by Aisha Darwish · 04 May 2026", lastActiveLabel: "25 min ago",
    locked: false, invitePending: false, revoked: false,
  },
  {
    record: baseAdmin("grace", "Grace Okoro", "grace@nightride.app", dateAt(2026, 5, 21)),
    displayLevel: "Admin", cityScopeLabel: "Melbourne", addedLabel: "by Tomás Neves · 21 Jun 2026", lastActiveLabel: "Yesterday",
    locked: false, invitePending: false, revoked: false,
  },
];

const store = new Map<string, MockAdmin>(admins.map((a) => [a.record.uid, a]));
let counter = 0;

export function allMockAdmins(): MockAdmin[] {
  return Array.from(store.values());
}

export function addMockAdmin(name: string, email: string, cityScope: string): void {
  counter += 1;
  const uid = `invited-admin-${counter}`;
  store.set(uid, {
    record: baseAdmin(uid, name, email, dateAt(2026, 8, 4)),
    displayLevel: "Admin",
    cityScopeLabel: cityScope,
    addedLabel: "by Aisha Darwish · 04 Sep 2026",
    lastActiveLabel: "Invite pending",
    locked: false,
    invitePending: true,
    revoked: false,
  });
}

export function setMockAdminRevoked(uid: string, revoked: boolean): MockAdmin | null {
  const a = store.get(uid);
  if (!a) return null;
  a.revoked = revoked;
  return a;
}
