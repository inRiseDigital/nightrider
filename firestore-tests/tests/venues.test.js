import { beforeAll, afterAll, afterEach, describe, it } from 'vitest';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDocs, collection, updateDoc, serverTimestamp, Timestamp } from 'firebase/firestore';
import { createTestEnv, baseUser, baseVenue, initialVenueVerification, uid } from './helpers.js';

let testEnv;

async function seedUsers(users) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    for (const [id, data] of Object.entries(users)) {
      await setDoc(doc(ctx.firestore(), `users/${id}`), data);
    }
  });
}

async function seedVenue(id, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `venues/${id}`), data);
  });
}

beforeAll(async () => {
  testEnv = await createTestEnv();
}, 60000);

afterEach(async () => {
  await testEnv.clearFirestore();
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe('venues/{venueId}', () => {
  it('37. anonymous read -> ALLOW', async () => {
    await seedVenue('v1', baseVenue());
    const ctx = testEnv.unauthenticatedContext();
    await assertSucceeds(getDocs(collection(ctx.firestore(), 'venues')));
  });

  it('38a. create by a plain user -> DENY', async () => {
    const plain = uid('plain');
    await seedUsers({ [plain]: baseUser() });
    const ctx = testEnv.authenticatedContext(plain);
    await assertFails(setDoc(doc(ctx.firestore(), 'venues/v-plain'), baseVenue()));
  });

  // INVERTED (was DENY): organizer venue-creation is now a designed feature
  // (see B4/organizerCreateOk() in firestore.rules). A plain baseVenue() call
  // is not enough on its own any more — organizerCreateOk() requires
  // source: 'organizer', ownerUid: self, and a matching `editors` map — so
  // this now asserts the full valid organizer-create shape succeeds. Case 71a
  // below re-covers the same ALLOW with explicit fields spelled out; this one
  // stays as the smoke test at its original number.
  it('38b. create by an organizer with a valid organizer-create shape -> ALLOW', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    const venue = baseVenue({
      source: 'organizer',
      ownerUid: org,
      verified: false,
      status: 'active',
      editorUids: [org],
      editors: { [org]: 'owner' },
    });
    // A brand-new venue nobody has reported on has no `live` map at all —
    // inventing one (even 'closed') is a lie, not a default.
    delete venue.live;
    await assertSucceeds(setDoc(doc(ctx.firestore(), 'venues/v-org'), venue));
  });

  it('38c. create by admin -> ALLOW', async () => {
    const admin = uid('admin');
    await seedUsers({ [admin]: baseUser({ isAdmin: true }) });
    const ctx = testEnv.authenticatedContext(admin);
    await assertSucceeds(setDoc(doc(ctx.firestore(), 'venues/v-admin'), baseVenue()));
  });

  it('39. owner-organizer updates venue.live with a valid map and live.updatedAt = serverTimestamp() -> ALLOW', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v-live', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), 'venues/v-live'), {
        live: {
          status: 'open',
          crowdLevel: 'busy',
          queueStatus: 'short',
          ticketsAvailable: true,
          tablesAvailable: false,
          tonightDj: 'DJ Test',
          offer: '',
          updatedAt: serverTimestamp(),
        },
      }),
    );
  });

  it("40a. owner-organizer sets live.status 'OPEN' (wrong case) -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v-live2', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'venues/v-live2'), {
        live: {
          status: 'OPEN',
          crowdLevel: 'busy',
          queueStatus: 'short',
          ticketsAvailable: true,
          tablesAvailable: false,
          tonightDj: '',
          offer: '',
          updatedAt: serverTimestamp(),
        },
      }),
    );
  });

  it("40b. owner-organizer sets live.crowdLevel 'jammed' -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v-live3', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'venues/v-live3'), {
        live: {
          status: 'open',
          crowdLevel: 'jammed',
          queueStatus: 'short',
          ticketsAvailable: true,
          tablesAvailable: false,
          tonightDj: '',
          offer: '',
          updatedAt: serverTimestamp(),
        },
      }),
    );
  });

  it('41. owner-organizer sets live.updatedAt to a hardcoded Timestamp -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v-live4', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'venues/v-live4'), {
        live: {
          status: 'open',
          crowdLevel: 'busy',
          queueStatus: 'short',
          ticketsAvailable: true,
          tablesAvailable: false,
          tonightDj: '',
          offer: '',
          updatedAt: Timestamp.fromDate(new Date('2020-01-01')),
        },
      }),
    );
  });

  it('42a. owner-organizer touches ownerUid -> DENY', async () => {
    const org = uid('org');
    const other = uid('other');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v-pin1', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(updateDoc(doc(ctx.firestore(), 'venues/v-pin1'), { ownerUid: other }));
  });

  it('42b. owner-organizer touches verified -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v-pin2', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(updateDoc(doc(ctx.firestore(), 'venues/v-pin2'), { verified: true }));
  });

  it('42c. owner-organizer touches geo -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v-pin3', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'venues/v-pin3'), {
        geo: { latitude: 1, longitude: 1 },
      }),
    );
  });

  it('42d. owner-organizer touches geohash -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v-pin4', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(updateDoc(doc(ctx.firestore(), 'venues/v-pin4'), { geohash: 'zzzzzzzzz' }));
  });

  it("43. a non-owner approved organizer updates someone else's venue -> DENY", async () => {
    const org = uid('org');
    const otherOrg = uid('otherOrg');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [otherOrg]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenue('v-other', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(otherOrg);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'venues/v-other'), {
        live: {
          status: 'open',
          crowdLevel: 'busy',
          queueStatus: 'short',
          ticketsAvailable: true,
          tablesAvailable: false,
          tonightDj: '',
          offer: '',
          updatedAt: serverTimestamp(),
        },
      }),
    );
  });

  // A valid organizer-create payload, minus `live` (a brand-new venue has
  // none) — unless the caller explicitly overrides `live` (case 71h).
  function orgVenue(org, overrides = {}) {
    const venue = baseVenue({
      source: 'organizer',
      ownerUid: org,
      verified: false,
      status: 'active',
      editorUids: [org],
      editors: { [org]: 'owner' },
      ...overrides,
    });
    if (!('live' in overrides)) delete venue.live;
    return venue;
  }

  it("71a. organizer creates verified:false, source:'organizer', ownerUid:self, status:'active', editors:{self:'owner'} -> ALLOW", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(setDoc(doc(ctx.firestore(), 'venues/v71a'), orgVenue(org)));
  });

  it('71b. same with verified: true -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'venues/v71b'), orgVenue(org, { verified: true })),
    );
  });

  it("71c. same with ownerUid = another uid -> DENY", async () => {
    const org = uid('org');
    const other = uid('other');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'venues/v71c'), orgVenue(org, { ownerUid: other })),
    );
  });

  it("71d. same with source: 'osm' -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'venues/v71d'), orgVenue(org, { source: 'osm' })),
    );
  });

  it("71e. same with editors: {self:'manager'} -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'venues/v71e'),
        orgVenue(org, { editors: { [org]: 'manager' } }),
      ),
    );
  });

  it('71f. editorUids disagrees with editors.keys() -> DENY', async () => {
    const org = uid('org');
    const other = uid('other');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'venues/v71f'), orgVenue(org, { editorUids: [org, other] })),
    );
  });

  it('71g. organizer create missing geohash -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    const venue = orgVenue(org);
    delete venue.geohash;
    await assertFails(setDoc(doc(ctx.firestore(), 'venues/v71g'), venue));
  });

  it('71h. organizer create including a live map -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    // orgVenue() strips `live`; put a legacy-shaped one back to prove a
    // brand-new venue may not invent even a default live map.
    const venue = orgVenue(org, {
      live: {
        status: 'closed', crowdLevel: 'empty', queueStatus: 'noQueue',
        ticketsAvailable: false, tablesAvailable: false, tonightDj: '', offer: '',
        doorStatus: 'closed', inVenue: 0, queueMinutes: 0, emergencyActive: false,
        flash: null, updatedAt: serverTimestamp(),
      },
    });
    await assertFails(setDoc(doc(ctx.firestore(), 'venues/v71h'), venue));
  });

  it('72a. admin updates a legacy venue lacking about/hours/capacity -> ALLOW (the .get() guard)', async () => {
    const admin = uid('admin');
    await seedUsers({ [admin]: baseUser({ isAdmin: true }) });
    const legacy = baseVenue();
    delete legacy.about;
    delete legacy.hours;
    delete legacy.capacity;
    await seedVenue('v72a', legacy);
    const ctx = testEnv.authenticatedContext(admin);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), 'venues/v72a'), { name: 'Renamed Venue' }),
    );
  });

  it('72b. admin create missing geohash -> DENY (shapeOk now applies to admins too)', async () => {
    const admin = uid('admin');
    await seedUsers({ [admin]: baseUser({ isAdmin: true }) });
    const ctx = testEnv.authenticatedContext(admin);
    const venue = baseVenue();
    delete venue.geohash;
    await assertFails(setDoc(doc(ctx.firestore(), 'venues/v72b'), venue));
  });

  it('73a. manager edits a profile field on the venue document -> ALLOW (only name/address route through venueEdits)', async () => {
    const org = uid('org');
    const manager = uid('manager');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [manager]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenue(
      'v73a',
      baseVenue({ ownerUid: org, editorUids: [org, manager], editors: { [org]: 'owner', [manager]: 'manager' } }),
    );
    const ctx = testEnv.authenticatedContext(manager);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), 'venues/v73a'), { about: 'New description' }));
  });

  it('73a-i. manager edits hours/photos/socialLinks/tableLink directly -> ALLOW', async () => {
    const org = uid('org');
    const manager = uid('manager');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [manager]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenue(
      'v73a1',
      baseVenue({ ownerUid: org, editorUids: [org, manager], editors: { [org]: 'owner', [manager]: 'manager' } }),
    );
    const ctx = testEnv.authenticatedContext(manager);
    const hours = Array.from({ length: 7 }, (_, i) => ({ day: i, open: '20:00', close: '04:00', closed: false }));
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), 'venues/v73a1'), {
        hours,
        photos: ['https://example.com/hero.jpg'],
        socialLinks: [{ network: 'instagram', value: '@testvenue' }],
        tableLink: 'https://example.com/book',
      }),
    );
  });

  it('73a-ii. manager edits name directly -> DENY (must route through venueEdits)', async () => {
    const org = uid('org');
    const manager = uid('manager');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [manager]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenue(
      'v73a2',
      baseVenue({ ownerUid: org, editorUids: [org, manager], editors: { [org]: 'owner', [manager]: 'manager' } }),
    );
    const ctx = testEnv.authenticatedContext(manager);
    await assertFails(updateDoc(doc(ctx.firestore(), 'venues/v73a2'), { name: 'New Name' }));
  });

  it('73a-iii. manager edits address directly -> DENY (must route through venueEdits)', async () => {
    const org = uid('org');
    const manager = uid('manager');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [manager]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenue(
      'v73a3',
      baseVenue({ ownerUid: org, editorUids: [org, manager], editors: { [org]: 'owner', [manager]: 'manager' } }),
    );
    const ctx = testEnv.authenticatedContext(manager);
    await assertFails(updateDoc(doc(ctx.firestore(), 'venues/v73a3'), { address: 'New Address' }));
  });

  it('73a-iv. manager writes an oversized "about" directly -> DENY (venueShapeOk sweep still runs on a direct write)', async () => {
    const org = uid('org');
    const manager = uid('manager');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [manager]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenue(
      'v73a4',
      baseVenue({ ownerUid: org, editorUids: [org, manager], editors: { [org]: 'owner', [manager]: 'manager' } }),
    );
    const ctx = testEnv.authenticatedContext(manager);
    await assertFails(updateDoc(doc(ctx.firestore(), 'venues/v73a4'), { about: 'x'.repeat(2001) }));
  });

  it('73a-v. manager writes a 9-element "hours" directly -> DENY (venueShapeOk sweep still runs on a direct write)', async () => {
    const org = uid('org');
    const manager = uid('manager');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [manager]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenue(
      'v73a5',
      baseVenue({ ownerUid: org, editorUids: [org, manager], editors: { [org]: 'owner', [manager]: 'manager' } }),
    );
    const ctx = testEnv.authenticatedContext(manager);
    const hours = Array.from({ length: 9 }, (_, i) => ({ day: i, open: '20:00', close: '04:00', closed: false }));
    await assertFails(updateDoc(doc(ctx.firestore(), 'venues/v73a5'), { hours }));
  });

  it('73a-vi. admin renames a venue directly -> ALLOW (approval path)', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v73a6', baseVenue({ ownerUid: org }));
    const admin = uid('admin');
    await seedUsers({ [admin]: baseUser({ isAdmin: true }) });
    const ctx = testEnv.authenticatedContext(admin);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), 'venues/v73a6'), { name: 'Approved New Name', address: 'Approved New Address' }),
    );
  });

  it('73b. door-staff editor sets live.emergencyActive: true -> ALLOW', async () => {
    const org = uid('org');
    const door = uid('door');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [door]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenue(
      'v73b',
      baseVenue({ ownerUid: org, editorUids: [org, door], editors: { [org]: 'owner', [door]: 'door' } }),
    );
    const ctx = testEnv.authenticatedContext(door);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), 'venues/v73b'), {
        'live.emergencyActive': true,
        'live.updatedAt': serverTimestamp(),
      }),
    );
  });

  it('73c. door-staff editor edits capacity -> DENY', async () => {
    const org = uid('org');
    const door = uid('door');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [door]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenue(
      'v73c',
      baseVenue({ ownerUid: org, editorUids: [org, door], editors: { [org]: 'owner', [door]: 'door' } }),
    );
    const ctx = testEnv.authenticatedContext(door);
    await assertFails(updateDoc(doc(ctx.firestore(), 'venues/v73c'), { capacity: 200 }));
  });

  it('73d. a uid absent from editors updates live -> DENY', async () => {
    const org = uid('org');
    const stranger = uid('stranger');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [stranger]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenue('v73d', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(stranger);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'venues/v73d'), {
        'live.emergencyActive': true,
        'live.updatedAt': serverTimestamp(),
      }),
    );
  });

  it('73e. an approved organizer who is not an editor updates live -> DENY', async () => {
    const org = uid('org');
    const otherOrg = uid('otherOrg');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [otherOrg]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenue('v73e', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(otherOrg);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'venues/v73e'), {
        'live.emergencyActive': true,
        'live.updatedAt': serverTimestamp(),
      }),
    );
  });

  it('74a. live.inVenue: -1 -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v74a', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'venues/v74a'), {
        'live.inVenue': -1,
        'live.updatedAt': serverTimestamp(),
      }),
    );
  });

  it('74b. live.queueMinutes: 601 -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v74b', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'venues/v74b'), {
        'live.queueMinutes': 601,
        'live.updatedAt': serverTimestamp(),
      }),
    );
  });

  it("74c. live.flash: {active:true, text:'x', until:'23:59'} -> ALLOW", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v74c', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), 'venues/v74c'), {
        'live.flash': { active: true, text: 'x', until: '23:59' },
        'live.updatedAt': serverTimestamp(),
      }),
    );
  });

  it('74d. live.flash.text over 200 chars -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v74d', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'venues/v74d'), {
        'live.flash': { active: true, text: 'x'.repeat(201), until: '23:59' },
        'live.updatedAt': serverTimestamp(),
      }),
    );
  });

  it('74e. legacy live map written without the new numerics -> ALLOW', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    // A pre-migration live map: none of doorStatus/inVenue/queueMinutes/
    // emergencyActive/flash exist yet.
    const legacy = baseVenue({ ownerUid: org });
    legacy.live = {
      status: 'closed', crowdLevel: 'empty', queueStatus: 'noQueue',
      ticketsAvailable: false, tablesAvailable: false, tonightDj: '', offer: '',
      updatedAt: new Date(),
    };
    await seedVenue('v74e', legacy);
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), 'venues/v74e'), {
        'live.status': 'open',
        'live.updatedAt': serverTimestamp(),
      }),
    );
  });

  it("74f. live.doorStatus: 'rammed' -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v74f', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'venues/v74f'), {
        'live.doorStatus': 'rammed',
        'live.updatedAt': serverTimestamp(),
      }),
    );
  });

  it('75a. organizer touches verification -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v75a', baseVenue({ ownerUid: org, verification: initialVenueVerification() }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'venues/v75a'), {
        'verification.license.status': 'submitted',
      }),
    );
  });

  it("75b. admin sets verification.license.status: 'done' -> ALLOW", async () => {
    const admin = uid('admin');
    await seedUsers({ [admin]: baseUser({ isAdmin: true }) });
    await seedVenue('v75b', baseVenue({ verification: initialVenueVerification() }));
    const ctx = testEnv.authenticatedContext(admin);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), 'venues/v75b'), {
        'verification.license.status': 'done',
      }),
    );
  });

  it('75c. organizer create with verification in the pinned initial shape -> ALLOW', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(
      setDoc(
        doc(ctx.firestore(), 'venues/v75c'),
        orgVenue(org, { verification: initialVenueVerification() }),
      ),
    );
  });

  it("75d. organizer create with verification.license.status: 'done' -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'venues/v75d'),
        orgVenue(org, {
          verification: initialVenueVerification({
            license: { status: 'done', attempt: 0, note: '', reviewedAt: null, reviewedBy: null },
          }),
        }),
      ),
    );
  });

  it('75e. organizer touches editors on update -> DENY', async () => {
    const org = uid('org');
    const other = uid('other');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v75e', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'venues/v75e'), {
        editors: { [org]: 'owner', [other]: 'manager' },
        editorUids: [org, other],
      }),
    );
  });
});
