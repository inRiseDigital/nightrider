import { beforeAll, afterAll, afterEach, describe, it } from 'vitest';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, updateDoc, deleteDoc, serverTimestamp, Timestamp } from 'firebase/firestore';
import { createTestEnv, baseUser, baseVenue, baseVenueEdit, uid } from './helpers.js';

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

async function seedVenueEdit(venueId, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `venueEdits/${venueId}`), data);
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

// venueEdits/{venueId} — document id IS the venue id (see Part A3 of the
// task-2 brief for why: one idempotent setDoc to save, one deleteDoc to
// discard, and the admin queue is a plain single-collection query where the
// doc id is the join key).
describe('venueEdits/{venueId}', () => {
  it("76a. owner submits a draft with status: 'pending' -> ALLOW", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v76a', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(
      setDoc(
        doc(ctx.firestore(), 'venueEdits/v76a'),
        baseVenueEdit({ venueId: 'v76a', submittedBy: org, submittedAt: serverTimestamp() }),
      ),
    );
  });

  it('76b. a non-editor submits -> DENY', async () => {
    const org = uid('org');
    const stranger = uid('stranger');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [stranger]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenue('v76b', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(stranger);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'venueEdits/v76b'),
        baseVenueEdit({ venueId: 'v76b', submittedBy: stranger, submittedAt: serverTimestamp() }),
      ),
    );
  });

  it('76c. door-staff submits -> DENY', async () => {
    const org = uid('org');
    const door = uid('door');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [door]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenue(
      'v76c',
      baseVenue({ ownerUid: org, editorUids: [org, door], editors: { [org]: 'owner', [door]: 'door' } }),
    );
    const ctx = testEnv.authenticatedContext(door);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'venueEdits/v76c'),
        baseVenueEdit({ venueId: 'v76c', submittedBy: door, submittedAt: serverTimestamp() }),
      ),
    );
  });

  it("76d. submit with status: 'approved' -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v76d', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'venueEdits/v76d'),
        baseVenueEdit({
          venueId: 'v76d', status: 'approved', submittedBy: org, submittedAt: serverTimestamp(),
        }),
      ),
    );
  });

  it("76e. organizer moves pending -> approved -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v76e', baseVenue({ ownerUid: org }));
    await seedVenueEdit('v76e', baseVenueEdit({ venueId: 'v76e', submittedBy: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(updateDoc(doc(ctx.firestore(), 'venueEdits/v76e'), { status: 'approved' }));
  });

  it("76f. admin sets approved -> ALLOW", async () => {
    const org = uid('org');
    const admin = uid('admin');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [admin]: baseUser({ isAdmin: true }),
    });
    await seedVenue('v76f', baseVenue({ ownerUid: org }));
    await seedVenueEdit('v76f', baseVenueEdit({ venueId: 'v76f', submittedBy: org }));
    const ctx = testEnv.authenticatedContext(admin);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), 'venueEdits/v76f'), {
        status: 'approved',
        reviewedBy: admin,
        reviewedAt: serverTimestamp(),
      }),
    );
  });

  it('76g. anonymous read -> DENY', async () => {
    const org = uid('org');
    await seedVenue('v76g', baseVenue({ ownerUid: org }));
    await seedVenueEdit('v76g', baseVenueEdit({ venueId: 'v76g', submittedBy: org }));
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), 'venueEdits/v76g')));
  });

  it("76h. owner reads their own venue's draft -> ALLOW", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v76h', baseVenue({ ownerUid: org }));
    await seedVenueEdit('v76h', baseVenueEdit({ venueId: 'v76h', submittedBy: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'venueEdits/v76h')));
  });

  it('76i. venueId field not matching the document id -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v76i', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'venueEdits/v76i'),
        baseVenueEdit({ venueId: 'some-other-venue', submittedBy: org, submittedAt: serverTimestamp() }),
      ),
    );
  });

  it('76j. owner deletes their own draft (discard) -> ALLOW', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v76j', baseVenue({ ownerUid: org }));
    await seedVenueEdit('v76j', baseVenueEdit({ venueId: 'v76j', submittedBy: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(deleteDoc(doc(ctx.firestore(), 'venueEdits/v76j')));
  });

  it('76k. submittedAt set to a client clock -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenue('v76k', baseVenue({ ownerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'venueEdits/v76k'),
        baseVenueEdit({
          venueId: 'v76k', submittedBy: org, submittedAt: Timestamp.fromDate(new Date('2020-01-01')),
        }),
      ),
    );
  });
});
