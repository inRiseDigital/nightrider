import {
  AccountStatus,
  ActivityLogEntry,
  AdminAccessLevel,
  Club,
  EventRecord,
  EventStatus,
  PlatformUser,
  Role,
  VerificationStatus,
} from "./types";
import { MOCK_CURRENT_ADMIN_ID } from "./constants";

// Deterministic PRNG so server-rendered and client-hydrated output always match
// (Math.random()/Date.now() would diverge between the two renders).
function mulberry32(seed: number) {
  let a = seed;
  return function rand() {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const rand = mulberry32(20260722);
const pick = <T,>(arr: T[]): T => arr[Math.floor(rand() * arr.length)];
const pickN = <T,>(arr: T[], n: number): T[] => {
  const copy = [...arr];
  const out: T[] = [];
  for (let i = 0; i < n && copy.length; i++) {
    out.push(copy.splice(Math.floor(rand() * copy.length), 1)[0]);
  }
  return out;
};
const intBetween = (min: number, max: number) => Math.floor(rand() * (max - min + 1)) + min;

const BASE_NOW = new Date("2026-07-20T12:00:00.000Z").getTime();
const DAY = 24 * 60 * 60 * 1000;
const daysAgo = (n: number) => new Date(BASE_NOW - n * DAY).toISOString();
const daysFromNow = (n: number) => new Date(BASE_NOW + n * DAY).toISOString();

const FIRST_NAMES = [
  "Alex", "Sam", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Jamie", "Yuki", "Haruto",
  "Aiko", "Mei", "Kenji", "Sara", "Layla", "Omar", "Fatima", "Ahmed", "Zainab", "Hassan",
  "Olivia", "Liam", "Emma", "Noah", "Ava", "Ethan", "Mia", "Lucas", "Sophia", "Mason",
  "Chloe", "Ryu", "Nina", "Karim", "Priya", "Devon", "Harper", "Felix", "Amara", "Leo",
];
const LAST_NAMES = [
  "Carter", "Nakamura", "Al-Farsi", "Bennett", "Suzuki", "Khan", "Whitfield", "Tanaka",
  "Reyes", "Osman", "Hughes", "Ito", "Mansour", "Walker", "Kobayashi", "Farouk", "Sinclair",
  "Yamamoto", "Hassan", "Foster",
];
const CITIES = ["Dubai", "Tokyo", "London", "Melbourne"];
const CLUB_NAMES = [
  "Neon Mirage", "Velvet Static", "The Hollow Room", "Paper Moon", "Kaiju Nightclub",
  "Riptide Social", "Obsidian Loft", "Glasshouse", "The Analog", "Low Tide", "Static Bloom",
];
const GENRES = ["House", "Techno", "Hip-Hop", "Afrobeats", "Drum & Bass", "Pop", "Amapiano"];

function fullNameFrom(i: number) {
  return `${FIRST_NAMES[i % FIRST_NAMES.length]} ${LAST_NAMES[(i * 3 + 7) % LAST_NAMES.length]}`;
}

function avatarFor(seed: string) {
  return `https://api.dicebear.com/9.x/notionists/svg?seed=${encodeURIComponent(seed)}`;
}

// ---- Clubs -----------------------------------------------------------------

export const MOCK_CLUBS: Club[] = CLUB_NAMES.map((name, i) => {
  const id = `club_${String(i + 1).padStart(3, "0")}`;
  const approvalPool: Club["approvalStatus"][] = ["approved", "approved", "approved", "pending", "rejected"];
  return {
    id,
    name,
    logoUrl: avatarFor(name),
    organizerId: null,
    organizerName: null,
    status: i === CLUB_NAMES.length - 1 ? "deactivated" : "active",
    approvalStatus: pick(approvalPool),
    location: pick(CITIES),
    contactEmail: `bookings@${name.toLowerCase().replace(/[^a-z]/g, "")}.com`,
    contactPhone: `+1 555 01${intBetween(10, 99)}`,
    description: `${name} is a resident nightlife venue known for ${pick(GENRES)} nights and late closes.`,
    upcomingEventsCount: 0,
    createdAt: daysAgo(intBetween(60, 400)),
    lastUpdatedAt: daysAgo(intBetween(1, 40)),
  };
});

// ---- Users -------------------------------------------------------------------

const TOTAL_USERS = 46;
const ADMIN_COUNT = 5;
const ORGANIZER_COUNT = MOCK_CLUBS.length - 1; // one club left unassigned

export const MOCK_USERS: PlatformUser[] = Array.from({ length: TOTAL_USERS }, (_, i) => {
  const id = i === 0 ? MOCK_CURRENT_ADMIN_ID : `usr_${String(i + 1).padStart(3, "0")}`;
  const fullName = i === 0 ? "Priyanka Sethi" : fullNameFrom(i);
  const isAdmin = i === 0 || (i < ADMIN_COUNT && i > 0);
  const isOrganizer = !isAdmin && i - ADMIN_COUNT < ORGANIZER_COUNT;
  const role: Role = isAdmin ? "admin" : isOrganizer ? "organizer" : i % 3 === 0 ? "verified" : "user";
  const verificationStatus: VerificationStatus =
    role === "user" ? (i % 4 === 0 ? "unverified" : "verified") : "verified";

  const statusPool: AccountStatus[] = ["active", "active", "active", "active", "deactivated", "banned"];
  const accountStatus: AccountStatus = isAdmin ? "active" : pick(statusPool);

  const club = isOrganizer ? MOCK_CLUBS[i - ADMIN_COUNT] : undefined;

  const user: PlatformUser = {
    id,
    fullName,
    email: `${fullName.toLowerCase().replace(/\s+/g, ".")}@mail.com`,
    avatarUrl: avatarFor(id),
    phone: `+1 555 0${intBetween(100, 999)}`,
    instagram: `@${fullName.toLowerCase().replace(/\s+/g, "")}`,
    bio: "Nightlife enthusiast exploring the city one venue at a time.",
    city: pick(CITIES),
    role,
    verificationStatus,
    accountStatus,
    isOrganizer,
    isAdmin,
    registeredAt: daysAgo(intBetween(10, 700)),
    lastActiveAt: daysAgo(intBetween(0, 30)),
    adminNotes:
      accountStatus !== "active"
        ? [
            {
              id: `note_${id}_1`,
              author: "Priyanka Sethi",
              note:
                accountStatus === "banned"
                  ? "Repeated community guideline violations reported by venue staff."
                  : "Requested temporary deactivation.",
              createdAt: daysAgo(intBetween(1, 20)),
            },
          ]
        : [],
    organizerDetails: isOrganizer
      ? {
          approvalStatus: i % 7 === 0 ? "pending" : "approved",
          clubId: club?.id ?? null,
          eventsCreated: intBetween(2, 40),
          recentActivity: [
            "Published a new event",
            "Updated club opening hours",
            "Uploaded new club photos",
          ],
        }
      : undefined,
    adminDetails: isAdmin
      ? {
          accessLevel: (i === 0 ? "super_admin" : i % 2 === 0 ? "admin" : "moderator") as AdminAccessLevel,
          grantedAt: daysAgo(intBetween(30, 500)),
          grantedBy: i === 0 ? "System" : "Priyanka Sethi",
        }
      : undefined,
  };

  if (club) {
    club.organizerId = user.id;
    club.organizerName = user.fullName;
    club.upcomingEventsCount = intBetween(1, 6);
  }

  return user;
});

export const MOCK_ADMINS = MOCK_USERS.filter((u) => u.isAdmin);
export const MOCK_ORGANIZERS = MOCK_USERS.filter((u) => u.isOrganizer);

// ---- Events -------------------------------------------------------------------

const EVENT_STATUS_POOL: EventStatus[] = [
  "draft",
  "scheduled",
  "scheduled",
  "starting_soon",
  "ongoing",
  "completed",
  "completed",
  "cancelled",
  "emergency_closure",
];

export const MOCK_EVENTS: EventRecord[] = Array.from({ length: 32 }, (_, i) => {
  const club = MOCK_CLUBS[i % MOCK_CLUBS.length];
  const organizerId = club.organizerId ?? MOCK_ORGANIZERS[0]?.id ?? MOCK_USERS[0].id;
  const organizerName = club.organizerName ?? MOCK_ORGANIZERS[0]?.fullName ?? MOCK_USERS[0].fullName;
  const status = EVENT_STATUS_POOL[i % EVENT_STATUS_POOL.length];
  const offset = intBetween(-20, 30);
  const id = `evt_${String(i + 1).padStart(3, "0")}`;

  const history = [
    {
      status: "draft" as EventStatus,
      changedAt: daysAgo(intBetween(15, 60)),
      changedBy: organizerName,
    },
  ];
  if (status !== "draft") {
    history.push({
      status: "scheduled" as EventStatus,
      changedAt: daysAgo(intBetween(5, 14)),
      changedBy: organizerName,
    });
  }
  if (status === "cancelled" || status === "emergency_closure") {
    history.push({
      status,
      changedAt: daysAgo(intBetween(0, 4)),
      changedBy: "Priyanka Sethi",
    });
  }

  return {
    id,
    title: `${pick(GENRES)} Night at ${club.name}`,
    clubId: club.id,
    clubName: club.name,
    organizerId,
    organizerName,
    dateTime: offset >= 0 ? daysFromNow(offset) : daysAgo(-offset),
    location: club.location,
    status,
    attendeesCount: status === "draft" ? 0 : intBetween(20, 850),
    createdAt: daysAgo(intBetween(20, 90)),
    description: `Doors open 10pm. ${pick(GENRES)} all night with resident and guest DJs.`,
    cancellationReason:
      status === "cancelled"
        ? "Organizer rescheduling due to a booking conflict."
        : status === "emergency_closure"
        ? "Venue closed for the night due to a safety/compliance issue."
        : undefined,
    statusHistory: history,
  };
});

// ---- Activity log --------------------------------------------------------------

export const MOCK_ACTIVITY_LOG: ActivityLogEntry[] = [
  {
    id: "log_001",
    adminId: MOCK_CURRENT_ADMIN_ID,
    adminName: "Priyanka Sethi",
    actionType: "organizer_approved",
    targetType: "organizer",
    targetId: MOCK_ORGANIZERS[0]?.id ?? "usr_006",
    targetLabel: MOCK_ORGANIZERS[0]?.fullName ?? "Organizer",
    newValue: "approved",
    timestamp: daysAgo(6),
  },
  {
    id: "log_002",
    adminId: MOCK_CURRENT_ADMIN_ID,
    adminName: "Priyanka Sethi",
    actionType: "user_banned",
    targetType: "user",
    targetId: MOCK_USERS.find((u) => u.accountStatus === "banned")?.id ?? "usr_010",
    targetLabel: MOCK_USERS.find((u) => u.accountStatus === "banned")?.fullName ?? "User",
    previousValue: "active",
    newValue: "banned",
    reason: "Repeated community guideline violations.",
    timestamp: daysAgo(5),
  },
  {
    id: "log_003",
    adminId: MOCK_CURRENT_ADMIN_ID,
    adminName: "Priyanka Sethi",
    actionType: "club_approved",
    targetType: "club",
    targetId: MOCK_CLUBS[0].id,
    targetLabel: MOCK_CLUBS[0].name,
    newValue: "approved",
    timestamp: daysAgo(4),
  },
  {
    id: "log_004",
    adminId: MOCK_CURRENT_ADMIN_ID,
    adminName: "Priyanka Sethi",
    actionType: "event_cancelled",
    targetType: "event",
    targetId: MOCK_EVENTS.find((e) => e.status === "cancelled")?.id ?? "evt_008",
    targetLabel: MOCK_EVENTS.find((e) => e.status === "cancelled")?.title ?? "Event",
    reason: "Organizer rescheduling due to a booking conflict.",
    timestamp: daysAgo(3),
  },
  {
    id: "log_005",
    adminId: MOCK_CURRENT_ADMIN_ID,
    adminName: "Priyanka Sethi",
    actionType: "admin_access_granted",
    targetType: "admin",
    targetId: MOCK_ADMINS[MOCK_ADMINS.length - 1]?.id ?? "usr_005",
    targetLabel: MOCK_ADMINS[MOCK_ADMINS.length - 1]?.fullName ?? "Admin",
    newValue: "moderator",
    timestamp: daysAgo(2),
  },
  {
    id: "log_006",
    adminId: MOCK_CURRENT_ADMIN_ID,
    adminName: "Priyanka Sethi",
    actionType: "role_changed",
    targetType: "user",
    targetId: MOCK_USERS[8]?.id ?? "usr_009",
    targetLabel: MOCK_USERS[8]?.fullName ?? "User",
    previousValue: "user",
    newValue: "verified",
    timestamp: daysAgo(1),
  },
  {
    id: "log_007",
    adminId: MOCK_CURRENT_ADMIN_ID,
    adminName: "Priyanka Sethi",
    actionType: "permission_changed",
    targetType: "role",
    targetId: "organizer",
    targetLabel: "Organizer",
    previousValue: "cancel_events: false",
    newValue: "cancel_events: true",
    timestamp: daysAgo(1),
  },
];
