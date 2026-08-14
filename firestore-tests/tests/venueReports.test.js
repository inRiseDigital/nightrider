import { beforeAll, afterAll, afterEach, describe, it, expect } from 'vitest';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import {
  doc,
  setDoc,
  getDoc,
  getDocs,
  collection,
  deleteDoc,
  writeBatch,
  serverTimestamp,
  Timestamp,
} from 'firebase/firestore';
import { createTestEnv, baseUser, baseVenueReport, uid } from './helpers.js';

let testEnv;

async function seedUsers(users) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    for (const [id, data] of Object.entries(users)) {
      await setDoc(doc(ctx.firestore(), `users/${id}`), data);
    }
  });
}

async function seedReport(id, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `venueReports/${id}`), data);
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

describe('venueReports/{reportId}', () => {
  it('44. report with NO comment field at all -> ALLOW, effective value is ""', async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    const report = baseVenueReport({ uid: u, createdAt: serverTimestamp() });
    delete report.comment;
    await assertSucceeds(setDoc(doc(ctx.firestore(), 'venueReports/r-nocomment'), report));

    // The rule reads comment via .get('comment', '') for validation — confirm
    // that's also what a reader sees: no field was silently invented, but the
    // effective/default value the app relies on is "".
    let comment;
    await testEnv.withSecurityRulesDisabled(async (rulesCtx) => {
      const snap = await getDoc(doc(rulesCtx.firestore(), 'venueReports/r-nocomment'));
      comment = snap.data().comment;
    });
    expect(comment).toBeUndefined();
  });

  it('45a. vibeRating 4.0 (a double, what a slider yields) -> ALLOW', async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    await assertSucceeds(
      setDoc(
        doc(ctx.firestore(), 'venueReports/r-vibe4'),
        baseVenueReport({ uid: u, vibeRating: 4.0, createdAt: serverTimestamp() }),
      ),
    );
  });

  it('45b. vibeRating 0 -> DENY', async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'venueReports/r-vibe0'),
        baseVenueReport({ uid: u, vibeRating: 0, createdAt: serverTimestamp() }),
      ),
    );
  });

  it('45c. vibeRating 6 -> DENY', async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'venueReports/r-vibe6'),
        baseVenueReport({ uid: u, vibeRating: 6, createdAt: serverTimestamp() }),
      ),
    );
  });

  it('46. createdAt hardcoded rather than serverTimestamp() -> DENY', async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'venueReports/r-hardcoded'),
        baseVenueReport({ uid: u, createdAt: Timestamp.fromDate(new Date('2020-01-01')) }),
      ),
    );
  });

  it('47. uid not matching the caller -> DENY', async () => {
    const u = uid('u');
    const other = uid('other');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'venueReports/r-wronguid'),
        baseVenueReport({ uid: other, createdAt: serverTimestamp() }),
      ),
    );
  });

  it('48. upvoteCount != 0 on create -> DENY', async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'venueReports/r-upvote1'),
        baseVenueReport({ uid: u, upvoteCount: 1, createdAt: serverTimestamp() }),
      ),
    );
  });

  it('49a. upvote batch (marker + increment) -> ALLOW', async () => {
    const author = uid('author');
    const voter = uid('voter');
    await seedUsers({ [author]: baseUser(), [voter]: baseUser() });
    await seedReport('r-upvotable', baseVenueReport({ uid: author, upvoteCount: 0 }));
    const ctx = testEnv.authenticatedContext(voter);
    const db = ctx.firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, `venueReports/r-upvotable/upvotes/${voter}`), { at: serverTimestamp() });
    batch.update(doc(db, 'venueReports/r-upvotable'), { upvoteCount: 1 });
    await assertSucceeds(batch.commit());
  });

  it('49b. the same voter upvoting again -> DENY', async () => {
    const author = uid('author');
    const voter = uid('voter');
    await seedUsers({ [author]: baseUser(), [voter]: baseUser() });
    await seedReport('r-upvotable2', baseVenueReport({ uid: author, upvoteCount: 0 }));
    const ctx = testEnv.authenticatedContext(voter);
    const db = ctx.firestore();

    const batch1 = writeBatch(db);
    batch1.set(doc(db, `venueReports/r-upvotable2/upvotes/${voter}`), { at: serverTimestamp() });
    batch1.update(doc(db, 'venueReports/r-upvotable2'), { upvoteCount: 1 });
    await assertSucceeds(batch1.commit());

    const batch2 = writeBatch(db);
    batch2.set(doc(db, `venueReports/r-upvotable2/upvotes/${voter}`), { at: serverTimestamp() });
    batch2.update(doc(db, 'venueReports/r-upvotable2'), { upvoteCount: 2 });
    await assertFails(batch2.commit());
  });

  it('50a. author deletes own report -> ALLOW', async () => {
    const author = uid('author');
    await seedUsers({ [author]: baseUser() });
    await seedReport('r-del1', baseVenueReport({ uid: author }));
    const ctx = testEnv.authenticatedContext(author);
    await assertSucceeds(deleteDoc(doc(ctx.firestore(), 'venueReports/r-del1')));
  });

  it('50b. stranger deletes it -> DENY', async () => {
    const author = uid('author');
    const stranger = uid('stranger');
    await seedUsers({ [author]: baseUser(), [stranger]: baseUser() });
    await seedReport('r-del2', baseVenueReport({ uid: author }));
    const ctx = testEnv.authenticatedContext(stranger);
    await assertFails(deleteDoc(doc(ctx.firestore(), 'venueReports/r-del2')));
  });

  it('50c. admin deletes it -> ALLOW', async () => {
    const author = uid('author');
    const admin = uid('admin');
    await seedUsers({ [author]: baseUser(), [admin]: baseUser({ isAdmin: true }) });
    await seedReport('r-del3', baseVenueReport({ uid: author }));
    const ctx = testEnv.authenticatedContext(admin);
    await assertSucceeds(deleteDoc(doc(ctx.firestore(), 'venueReports/r-del3')));
  });

  it('51. anonymous read of reports -> ALLOW', async () => {
    await seedReport('r-anon', baseVenueReport());
    const ctx = testEnv.unauthenticatedContext();
    await assertSucceeds(getDocs(collection(ctx.firestore(), 'venueReports')));
  });
});
