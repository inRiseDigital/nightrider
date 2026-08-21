import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export const PROJECT_ID = 'nightride-test';

const FIRESTORE_RULES_PATH = path.resolve(
  __dirname,
  '../../nightride-webpanel/firestore.rules',
);
const STORAGE_RULES_PATH = path.resolve(
  __dirname,
  '../../nightride-webpanel/storage.rules',
);

/**
 * Creates a fresh RulesTestEnvironment bound to the emulators started by
 * `firebase emulators:exec` (see ../firebase.json for ports). Pass
 * `withStorage: true` for suites that need the Storage emulator too (only
 * storage.test.js does, since its rules cross-call firestore.get()).
 */
export async function createTestEnv({ withStorage = false } = {}) {
  return initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(FIRESTORE_RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 8180,
    },
    ...(withStorage
      ? {
          storage: {
            rules: fs.readFileSync(STORAGE_RULES_PATH, 'utf8'),
            host: '127.0.0.1',
            port: 9299,
          },
        }
      : {}),
  });
}

/** A minimal, schema-valid users/{uid} document (organizerStatus: 'none'). */
export function baseUser(overrides = {}) {
  return {
    email: 'user@example.com',
    displayName: 'Test User',
    username: 'testuser',
    pronouns: '',
    bio: '',
    city: 'Dubai',
    countryCode: 'AE',
    ageRange: '25-34',
    avatarUrl: '',
    instagram: '',
    facebook: '',
    phone: '',
    interests: [],
    genres: [],
    vibes: [],
    features: [],
    rank: 0,
    streakDays: 0,
    partiesAttended: 0,
    friendsCount: 0,
    lastActiveDate: '2026-08-13',
    isAdmin: false,
    organizerStatus: 'none',
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

/**
 * The exact pinned initial shape for users/{uid}/private/organizerReview. Two
 * steps start locked: gps waits on an admin-accepted venue address, video on an
 * admin-published walkthrough script.
 */
export function initialOrganizerReview(overrides = {}) {
  return {
    status: 'none',
    appliedAt: new Date(),
    decidedAt: null,
    decidedBy: '',
    rejectionReason: '',
    phoneVerified: false,
    steps: {
      venueAddress: { status: 'active', attempt: 0, note: '', reviewedAt: null, reviewedBy: null, venueId: null, mediaDeletedAt: null, script: null },
      nic: { status: 'active', attempt: 0, note: '', reviewedAt: null, reviewedBy: null, venueId: null, mediaDeletedAt: null, script: null },
      selfie: { status: 'active', attempt: 0, note: '', reviewedAt: null, reviewedBy: null, venueId: null, mediaDeletedAt: null, script: null },
      gps: { status: 'pending', attempt: 0, note: '', reviewedAt: null, reviewedBy: null, venueId: null, mediaDeletedAt: null, script: null },
      video: { status: 'pending', attempt: 0, note: '', reviewedAt: null, reviewedBy: null, venueId: null, mediaDeletedAt: null, script: null },
    },
    updatedAt: new Date(),
    ...overrides,
  };
}

/** A schema-valid `steps.video.script` — what an admin publishes to unlock the step. */
export function videoScript(overrides = {}) {
  return {
    format: 'list',
    lines: ['Start outside with the signage visible.', 'Walk in and show the door check.'],
    revision: 0,
    updatedAt: new Date(),
    updatedBy: 'admin-uid',
    ...overrides,
  };
}

/** A minimal, schema-valid events/{eventId} document. */
export function baseEvent(overrides = {}) {
  return {
    name: 'Test Event',
    description: 'A test event',
    venueId: null,
    venueName: 'Test Venue',
    city: 'Dubai',
    countryCode: 'AE',
    geo: null,
    startAt: new Date(Date.now() + 86400000),
    endAt: null,
    price: { min: 0, max: 0, currency: 'AED', isFree: true },
    ticketUrl: '',
    coverImage: '',
    genre: '',
    category: '',
    vibe: '',
    language: '',
    performers: [],
    policies: {
      ageRestriction: 18,
      refundPolicy: '',
      reEntryAllowed: true,
      wheelchairAccessible: true,
      allowPets: false,
    },
    interestedCount: 0,
    popularityScore: 0,
    status: 'draft',
    source: 'organizer',
    organizerUid: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

/** A minimal, schema-valid venues/{venueId} document. */
export function baseVenue(overrides = {}) {
  return {
    name: 'Test Venue',
    geo: { latitude: 25.2, longitude: 55.3 },
    geohash: 'thrq40zzz',
    type: 'nightclub',
    typeLabel: 'Nightclub',
    city: 'Dubai',
    countryCode: 'AE',
    address: '123 Test St',
    openingHours: '',
    phone: '',
    website: '',
    photos: [],
    source: 'admin',
    osmId: null,
    ownerUid: null,
    verified: false,
    status: 'active',
    live: {
      status: 'closed',
      crowdLevel: 'empty',
      queueStatus: 'noQueue',
      ticketsAvailable: false,
      tablesAvailable: false,
      tonightDj: '',
      offer: '',
      updatedAt: new Date(),
    },
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

/** A minimal, schema-valid venueReports/{reportId} document. */
export function baseVenueReport(overrides = {}) {
  return {
    venueId: 'venue1',
    uid: 'reporter-uid',
    username: 'reporter',
    avatarUrl: '',
    city: 'Dubai',
    countryCode: 'AE',
    tag: 'busy',
    vibeRating: 4,
    comment: '',
    upvoteCount: 0,
    createdAt: new Date(),
    ...overrides,
  };
}

/** A minimal, schema-valid logs/{logId} document. */
export function baseLog(overrides = {}) {
  return {
    action: 'event.publish',
    actorUid: 'admin-uid',
    targetType: 'event',
    targetId: 'event1',
    summary: 'Published test event',
    at: new Date(),
    ...overrides,
  };
}

export function uid(prefix = 'u') {
  return `${prefix}-${Math.random().toString(36).slice(2, 10)}`;
}
