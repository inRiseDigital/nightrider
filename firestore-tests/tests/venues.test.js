import { beforeAll, afterAll, afterEach, describe, it } from 'vitest';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDocs, collection, updateDoc, serverTimestamp, Timestamp } from 'firebase/firestore';
import { createTestEnv, baseUser, baseVenue, uid } from './helpers.js';

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

  it('38b. create by an organizer -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(setDoc(doc(ctx.firestore(), 'venues/v-org'), baseVenue()));
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
});
