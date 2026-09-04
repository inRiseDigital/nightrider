import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { GeoPoint } from 'firebase/firestore';

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

/**
 * A minimal, schema-valid events/{eventId} document.
 *
 * endAt defaults to a real Timestamp (not null): source defaults to
 * 'organizer', and shapeOk() now requires endAt non-null whenever
 * source == 'organizer' (a derived `live` status cannot guess an end time).
 * Tests that specifically exercise the scraped/null-endAt path override it.
 */
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
    endAt: new Date(Date.now() + 86400000 + 4 * 3600000),
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

/**
 * A minimal, schema-valid venues/{venueId} document.
 *
 * editorUids/editors are derived from ownerUid (the migration backfill rule:
 * `editorUids = ownerUid ? [ownerUid] : []`, `editors = ownerUid ?
 * {[ownerUid]: 'owner'} : {}`) unless the caller overrides them explicitly.
 * This is what flips case 38b from DENY to ALLOW: an organizer creating a
 * venue with `ownerUid: self` now also gets a matching `editors` map, which
 * `organizerCreateOk()` requires.
 */
export function baseVenue(overrides = {}) {
  const ownerUid = 'ownerUid' in overrides ? overrides.ownerUid : null;
  return {
    name: 'Test Venue',
    // A real GeoPoint, not a {latitude,longitude} map: venueShapeOk() now
    // requires `d.geo is latlng`, which only a GeoPoint satisfies. Pre-
    // organizer-access venue create had zero validation, so this distinction
    // never mattered until now.
    geo: new GeoPoint(25.2, 55.3),
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
    ownerUid,
    verified: false,
    status: 'active',
    capacity: 0,
    timeZone: 'Asia/Dubai',
    editorUids: ownerUid ? [ownerUid] : [],
    editors: ownerUid ? { [ownerUid]: 'owner' } : {},
    live: {
      status: 'closed',
      crowdLevel: 'empty',
      queueStatus: 'noQueue',
      ticketsAvailable: false,
      tablesAvailable: false,
      tonightDj: '',
      offer: '',
      doorStatus: 'closed',
      inVenue: 0,
      queueMinutes: 0,
      emergencyActive: false,
      flash: null,
      updatedAt: new Date(),
    },
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

/** The pinned initial `venues/{id}.verification` shape an organizer create must match. */
export function initialVenueVerification(overrides = {}) {
  return {
    license: { status: 'active', attempt: 0, note: '', reviewedAt: null, reviewedBy: null },
    gps: { status: 'active', attempt: 0, note: '', reviewedAt: null, reviewedBy: null },
    video: { status: 'active', attempt: 0, note: '', reviewedAt: null, reviewedBy: null },
    ...overrides,
  };
}

/** A minimal, schema-valid venueEdits/{venueId} draft document. */
export function baseVenueEdit(overrides = {}) {
  return {
    venueId: 'venue1',
    status: 'pending',
    listing: { name: 'New Venue Name', address: 'New Address' },
    submittedBy: 'organizer-uid',
    submittedAt: new Date(),
    reviewedBy: null,
    reviewedAt: null,
    note: '',
    ...overrides,
  };
}

/** A minimal, schema-valid venues/{venueId}/menuSections/{sectionId} document. */
export function baseMenuSection(overrides = {}) {
  return {
    name: 'Cocktails',
    order: 0,
    items: [],
    updatedAt: new Date(),
    ...overrides,
  };
}

/** A minimal, schema-valid venues/{venueId}/activity/{entryId} document. */
export function baseActivity(overrides = {}) {
  return {
    actorUid: 'actor-uid',
    actorName: 'Test Actor',
    what: 'updated the menu',
    targetType: 'menuSection',
    targetId: 'section1',
    at: new Date(),
    ...overrides,
  };
}

/** A minimal, schema-valid venues/{venueId}/promotions/{promoId} document. */
export function basePromotion(overrides = {}) {
  return {
    code: 'VIP10',
    used: 0,
    limit: 100,
    createdAt: new Date(),
    ...overrides,
  };
}

/** A minimal, schema-valid venues/{venueId}/pushCampaigns/{campaignId} document. */
export function basePushCampaign(overrides = {}) {
  return {
    title: 'Tonight only',
    body: 'Free entry before 11pm',
    status: 'queued',
    createdAt: new Date(),
    ...overrides,
  };
}

/** A minimal, schema-valid venues/{venueId}/boosts/{boostId} document. */
export function baseBoost(overrides = {}) {
  return {
    status: 'pending',
    startAt: new Date(),
    endAt: new Date(Date.now() + 86400000),
    createdAt: new Date(),
    ...overrides,
  };
}

/** A minimal, schema-valid users/{uid}/inbox/{messageId} document. */
export function baseInboxMessage(overrides = {}) {
  return {
    subject: 'Policy update',
    from: 'Night Ride Trust & Safety',
    type: 'policy',
    body: 'Please review the updated content policy.',
    venueId: null,
    at: new Date(),
    readAt: null,
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
