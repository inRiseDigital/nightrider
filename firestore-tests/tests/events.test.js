import { beforeAll, afterAll, afterEach, describe, it } from 'vitest';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import {
  doc,
  setDoc,
  getDoc,
  getDocs,
  updateDoc,
  writeBatch,
  collection,
  increment,
  serverTimestamp,
  Timestamp,
  GeoPoint,
} from 'firebase/firestore';
import { createTestEnv, baseUser, baseEvent, uid } from './helpers.js';

let testEnv;

async function seedUsers(users) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    for (const [id, data] of Object.entries(users)) {
      await setDoc(doc(ctx.firestore(), `users/${id}`), data);
    }
  });
}

async function seedEvent(id, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `events/${id}`), data);
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

describe('events/{eventId}', () => {
  it('22. create by approved organizer with a full valid shape -> ALLOW', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, status: 'draft' }),
      ),
    );
  });

  it('23a. create missing startAt -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    const ev = baseEvent({ organizerUid: org });
    delete ev.startAt;
    await assertFails(setDoc(doc(ctx.firestore(), `events/ev-${org}`), ev));
  });

  it('23b. create with startAt as a string instead of Timestamp -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    const ev = baseEvent({ organizerUid: org, startAt: '2026-08-13T20:00:00Z' });
    await assertFails(setDoc(doc(ctx.firestore(), `events/ev-${org}`), ev));
  });

  it("24a. create with countryCode 'gb' (lowercase) -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, countryCode: 'gb' }),
      ),
    );
  });

  it("24b. create with countryCode 'GBR' (3 letters) -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, countryCode: 'GBR' }),
      ),
    );
  });

  it('25a. create with geo omitted/null -> ALLOW (nullable)', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, geo: null }),
      ),
    );
  });

  it('25b. create with geo as a map {lat,lng} instead of GeoPoint -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, geo: { lat: 25.2, lng: 55.3 } }),
      ),
    );
  });

  it("26. create with status 'Published' (capitalized) -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, status: 'Published' }),
      ),
    );
  });

  it("27a. create by an organizer with source 'admin' -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, source: 'admin' }),
      ),
    );
  });

  it('27b. create by an organizer with organizerUid pointing at someone else -> DENY', async () => {
    const org = uid('org');
    const other = uid('other');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(doc(ctx.firestore(), `events/ev-${org}`), baseEvent({ organizerUid: other })),
    );
  });

  it('28. create by an organizer with popularityScore 999 -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, popularityScore: 999 }),
      ),
    );
  });

  it('29. create by a plain (non-organizer, non-admin) user -> DENY', async () => {
    const plain = uid('plain');
    await seedUsers({ [plain]: baseUser() });
    const ctx = testEnv.authenticatedContext(plain);
    await assertFails(
      setDoc(doc(ctx.firestore(), `events/ev-${plain}`), baseEvent({ organizerUid: plain })),
    );
  });

  it("30a. organizer updates own event's popularityScore -> DENY (counters pinned)", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedEvent('ev1', baseEvent({ organizerUid: org, status: 'published' }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(updateDoc(doc(ctx.firestore(), 'events/ev1'), { popularityScore: 50 }));
  });

  it("30b. organizer updates own event's interestedCount -> DENY (counters pinned)", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedEvent('ev2', baseEvent({ organizerUid: org, status: 'published' }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(updateDoc(doc(ctx.firestore(), 'events/ev2'), { interestedCount: 5 }));
  });

  it('31. published event readable by an anonymous/unauthenticated client -> ALLOW', async () => {
    await seedEvent('ev-pub', baseEvent({ status: 'published' }));
    const ctx = testEnv.unauthenticatedContext();
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'events/ev-pub')));
  });

  it('32a. draft event read by a stranger -> DENY', async () => {
    const org = uid('org');
    const stranger = uid('stranger');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }), [stranger]: baseUser() });
    await seedEvent('ev-draft', baseEvent({ organizerUid: org, status: 'draft' }));
    const ctx = testEnv.authenticatedContext(stranger);
    await assertFails(getDoc(doc(ctx.firestore(), 'events/ev-draft')));
  });

  it('32b. draft event read by its own organizer -> ALLOW', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedEvent('ev-draft2', baseEvent({ organizerUid: org, status: 'draft' }));
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'events/ev-draft2')));
  });

  it('32c. draft event read by admin -> ALLOW', async () => {
    const org = uid('org');
    const admin = uid('admin');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }), [admin]: baseUser({ isAdmin: true }) });
    await seedEvent('ev-draft3', baseEvent({ organizerUid: org, status: 'draft' }));
    const ctx = testEnv.authenticatedContext(admin);
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'events/ev-draft3')));
  });

  it('33. interest batch: interested/{uid} + interestedCount+1 in one batch -> ALLOW', async () => {
    const voter = uid('voter');
    await seedUsers({ [voter]: baseUser() });
    await seedEvent('ev-interest', baseEvent({ status: 'published', interestedCount: 0 }));
    const ctx = testEnv.authenticatedContext(voter);
    const db = ctx.firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, `events/ev-interest/interested/${voter}`), { at: serverTimestamp() });
    batch.update(doc(db, 'events/ev-interest'), { interestedCount: 1 });
    await assertSucceeds(batch.commit());
  });

  it('34. the same user doing that batch a second time -> DENY', async () => {
    const voter = uid('voter');
    await seedUsers({ [voter]: baseUser() });
    await seedEvent('ev-interest2', baseEvent({ status: 'published', interestedCount: 0 }));
    const ctx = testEnv.authenticatedContext(voter);
    const db = ctx.firestore();

    const batch1 = writeBatch(db);
    batch1.set(doc(db, `events/ev-interest2/interested/${voter}`), { at: serverTimestamp() });
    batch1.update(doc(db, 'events/ev-interest2'), { interestedCount: 1 });
    await assertSucceeds(batch1.commit());

    const batch2 = writeBatch(db);
    batch2.set(doc(db, `events/ev-interest2/interested/${voter}`), { at: serverTimestamp() });
    batch2.update(doc(db, 'events/ev-interest2'), { interestedCount: 2 });
    await assertFails(batch2.commit());
  });

  it('35. interestedCount+5 in one write -> DENY', async () => {
    const voter = uid('voter');
    await seedUsers({ [voter]: baseUser() });
    await seedEvent('ev-interest3', baseEvent({ status: 'published', interestedCount: 0 }));
    const ctx = testEnv.authenticatedContext(voter);
    const db = ctx.firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, `events/ev-interest3/interested/${voter}`), { at: serverTimestamp() });
    batch.update(doc(db, 'events/ev-interest3'), { interestedCount: 5 });
    await assertFails(batch.commit());
  });

  it('36. update touching interestedCount AND name together by a plain user -> DENY', async () => {
    const voter = uid('voter');
    await seedUsers({ [voter]: baseUser() });
    await seedEvent('ev-interest4', baseEvent({ status: 'published', interestedCount: 0 }));
    const ctx = testEnv.authenticatedContext(voter);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'events/ev-interest4'), {
        interestedCount: 1,
        name: 'Hacked Name',
      }),
    );
  });

  it("66a. organizer creates 'scheduled' with a scheduledPublish timestamp -> ALLOW", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({
          organizerUid: org,
          status: 'scheduled',
          scheduledPublish: new Date(Date.now() + 3600000),
        }),
      ),
    );
  });

  it("66b. organizer creates 'scheduled' with scheduledPublish absent -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, status: 'scheduled' }),
      ),
    );
  });

  it("66c. organizer creates 'in_review' -> ALLOW", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, status: 'in_review' }),
      ),
    );
  });

  it("66d. organizer creates 'cancelled' with cancelReason: '' -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, status: 'cancelled', cancelReason: '' }),
      ),
    );
  });

  it("66e. organizer creates 'cancelled' with a reason -> ALLOW", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, status: 'cancelled', cancelReason: 'Venue closed early' }),
      ),
    );
  });

  it("66f. any writer creates status: 'live' -> DENY (live is derived, never stored)", async () => {
    const org = uid('org');
    const admin = uid('admin');
    await seedUsers({
      [org]: baseUser({ organizerStatus: 'approved' }),
      [admin]: baseUser({ isAdmin: true }),
    });
    const orgCtx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(orgCtx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, status: 'live' }),
      ),
    );
    const adminCtx = testEnv.authenticatedContext(admin);
    await assertFails(
      setDoc(doc(adminCtx.firestore(), 'events/ev-admin-live'), baseEvent({ status: 'live' })),
    );
  });

  it("66g. organizer creates 'archived' -> DENY (not an initial state)", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, status: 'archived' }),
      ),
    );
  });

  it("67a. anonymous read of a 'scheduled' event -> DENY", async () => {
    await seedEvent('ev67a', baseEvent({
      status: 'scheduled',
      scheduledPublish: new Date(Date.now() + 3600000),
    }));
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), 'events/ev67a')));
  });

  it("67b. anonymous read of an 'in_review' event -> DENY", async () => {
    await seedEvent('ev67b', baseEvent({ status: 'in_review' }));
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), 'events/ev67b')));
  });

  it("67c. anonymous read of a 'cancelled' event -> ALLOW", async () => {
    await seedEvent('ev67c', baseEvent({ status: 'cancelled', cancelReason: 'Cancelled' }));
    const ctx = testEnv.unauthenticatedContext();
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'events/ev67c')));
  });

  it("67d. owner-organizer reads their own 'in_review' event -> ALLOW", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedEvent('ev67d', baseEvent({ organizerUid: org, status: 'in_review' }));
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'events/ev67d')));
  });

  it("68a. organizer writes moderation.flag: 'clean' -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedEvent('ev68a', baseEvent({ organizerUid: org, status: 'published' }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'events/ev68a'), { moderation: { flag: 'clean' } }),
    );
  });

  it("68b. admin writes moderation.flag: 'clean' -> ALLOW", async () => {
    const admin = uid('admin');
    await seedUsers({ [admin]: baseUser({ isAdmin: true }) });
    await seedEvent('ev68b', baseEvent({ status: 'published' }));
    const ctx = testEnv.authenticatedContext(admin);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), 'events/ev68b'), { moderation: { flag: 'clean' } }),
    );
  });

  it('69a. organizer writes sales.sold -> DENY', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedEvent('ev69a', baseEvent({ organizerUid: org, status: 'published' }));
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      updateDoc(doc(ctx.firestore(), 'events/ev69a'), { sales: { sold: 10 } }),
    );
  });

  it('69b. organizer update leaving moderation and sales untouched -> ALLOW', async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    await seedEvent('ev69b', baseEvent({ organizerUid: org, status: 'published' }));
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), 'events/ev69b'), { name: 'Renamed Event' }),
    );
  });

  it("70. organizer creates source: 'organizer' with endAt: null -> DENY", async () => {
    const org = uid('org');
    await seedUsers({ [org]: baseUser({ organizerStatus: 'approved' }) });
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), `events/ev-${org}`),
        baseEvent({ organizerUid: org, source: 'organizer', endAt: null }),
      ),
    );
  });
});
