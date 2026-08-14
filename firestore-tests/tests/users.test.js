import { beforeAll, afterAll, afterEach, describe, it, expect } from 'vitest';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import {
  doc,
  setDoc,
  getDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
  Timestamp,
} from 'firebase/firestore';
import { createTestEnv, baseUser, uid } from './helpers.js';

let testEnv;

async function seed(users) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    for (const [id, data] of Object.entries(users)) {
      await setDoc(doc(ctx.firestore(), `users/${id}`), data);
    }
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

describe('users/{uid}', () => {
  it('1. admin edits own displayName -> ALLOW', async () => {
    const admin = uid('admin');
    await seed({ [admin]: baseUser({ isAdmin: true, displayName: 'Old Name' }) });
    const ctx = testEnv.authenticatedContext(admin);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `users/${admin}`), { displayName: 'New Name' }),
    );
  });

  it('2. non-admin creates own doc with isAdmin: true -> DENY', async () => {
    const u = uid('u');
    const ctx = testEnv.authenticatedContext(u);
    await assertFails(setDoc(doc(ctx.firestore(), `users/${u}`), baseUser({ isAdmin: true })));
  });

  it('3. non-admin creates own doc with rank: 500 -> DENY', async () => {
    const u = uid('u');
    const ctx = testEnv.authenticatedContext(u);
    await assertFails(setDoc(doc(ctx.firestore(), `users/${u}`), baseUser({ rank: 500 })));
  });

  it("4a. create with organizerStatus: 'none' -> ALLOW", async () => {
    const u = uid('u');
    const ctx = testEnv.authenticatedContext(u);
    await assertSucceeds(
      setDoc(doc(ctx.firestore(), `users/${u}`), baseUser({ organizerStatus: 'none' })),
    );
  });

  it("4b. create with organizerStatus: 'approved' -> DENY", async () => {
    const u = uid('u');
    const ctx = testEnv.authenticatedContext(u);
    await assertFails(
      setDoc(doc(ctx.firestore(), `users/${u}`), baseUser({ organizerStatus: 'approved' })),
    );
  });

  it('5. self-update that touches isAdmin -> DENY', async () => {
    const u = uid('u');
    await seed({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    await assertFails(updateDoc(doc(ctx.firestore(), `users/${u}`), { isAdmin: true }));
  });

  it('6. self-update that touches organizerStatus -> DENY', async () => {
    const u = uid('u');
    await seed({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `users/${u}`), { organizerStatus: 'approved' }),
    );
  });

  it('7a. self-update raising rank by 40 -> ALLOW', async () => {
    const u = uid('u');
    await seed({ [u]: baseUser({ rank: 100 }) });
    const ctx = testEnv.authenticatedContext(u);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `users/${u}`), { rank: 140 }));
  });

  it('7b. self-update raising rank by 200 -> DENY', async () => {
    const u = uid('u');
    await seed({ [u]: baseUser({ rank: 100 }) });
    const ctx = testEnv.authenticatedContext(u);
    await assertFails(updateDoc(doc(ctx.firestore(), `users/${u}`), { rank: 300 }));
  });

  it('8a. update organizerApplication with submittedAt = serverTimestamp() -> ALLOW', async () => {
    const u = uid('u');
    await seed({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `users/${u}`), {
        organizerApplication: {
          submitted: true,
          submittedAt: serverTimestamp(),
          profile: {
            orgName: 'Org',
            venueName: 'Venue',
            instagram: '',
            website: '',
            bio: '',
            eventTypes: [],
            eventsPerMonth: 1,
          },
          steps: {
            venueAddress: null,
            nic: { uploaded: false },
            selfie: { uploaded: false },
            video: { uploaded: false },
            gps: { attempts: [] },
          },
        },
      }),
    );
  });

  it('8b. update organizerApplication with a hardcoded past Timestamp -> DENY (no queue-jumping)', async () => {
    const u = uid('u');
    await seed({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `users/${u}`), {
        organizerApplication: {
          submitted: true,
          submittedAt: Timestamp.fromDate(new Date('2020-01-01')),
          profile: {
            orgName: 'Org',
            venueName: 'Venue',
            instagram: '',
            website: '',
            bio: '',
            eventTypes: [],
            eventsPerMonth: 1,
          },
          steps: {
            venueAddress: null,
            nic: { uploaded: false },
            selfie: { uploaded: false },
            video: { uploaded: false },
            gps: { attempts: [] },
          },
        },
      }),
    );
  });

  it('9a. any client delete of users/{uid} -> DENY (including own)', async () => {
    const u = uid('u');
    await seed({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    await assertFails(deleteDoc(doc(ctx.firestore(), `users/${u}`)));
  });

  it('9b. admin delete of another user -> DENY', async () => {
    const admin = uid('admin');
    const other = uid('u');
    await seed({ [admin]: baseUser({ isAdmin: true }), [other]: baseUser() });
    const ctx = testEnv.authenticatedContext(admin);
    await assertFails(deleteDoc(doc(ctx.firestore(), `users/${other}`)));
  });

  it("10a. admin updating another user's organizerStatus -> ALLOW", async () => {
    const admin = uid('admin');
    const other = uid('u');
    await seed({ [admin]: baseUser({ isAdmin: true }), [other]: baseUser() });
    const ctx = testEnv.authenticatedContext(admin);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `users/${other}`), {
        organizerStatus: 'approved',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it("10b. admin updating another user's displayName -> DENY", async () => {
    const admin = uid('admin');
    const other = uid('u');
    await seed({ [admin]: baseUser({ isAdmin: true }), [other]: baseUser() });
    const ctx = testEnv.authenticatedContext(admin);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `users/${other}`), { displayName: 'Hacked' }),
    );
  });

  it("11a. stranger reads another user's doc -> DENY", async () => {
    const other = uid('u');
    const stranger = uid('stranger');
    await seed({ [other]: baseUser() });
    const ctx = testEnv.authenticatedContext(stranger);
    await assertFails(getDoc(doc(ctx.firestore(), `users/${other}`)));
  });

  it('11b. admin reads any user doc -> ALLOW', async () => {
    const admin = uid('admin');
    const other = uid('u');
    await seed({ [admin]: baseUser({ isAdmin: true }), [other]: baseUser() });
    const ctx = testEnv.authenticatedContext(admin);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `users/${other}`)));
  });
});

describe('users/{uid}/chat_sessions (email-verification gate)', () => {
  it('65a. write to chat_sessions/{id} with email_verified true -> ALLOW', async () => {
    const u = uid('u');
    await seed({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u, { email_verified: true });
    await assertSucceeds(
      setDoc(doc(ctx.firestore(), `users/${u}/chat_sessions/s1`), {
        title: 'Session 1',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('65b. write to chat_sessions/{id} with email_verified false -> DENY', async () => {
    const u = uid('u');
    await seed({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u, { email_verified: false });
    await assertFails(
      setDoc(doc(ctx.firestore(), `users/${u}/chat_sessions/s2`), {
        title: 'Session 2',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('65c. write to chat_sessions/{id}/messages/{id} with email_verified true -> ALLOW', async () => {
    const u = uid('u');
    await seed({ [u]: baseUser() });
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `users/${u}/chat_sessions/s3`), {
        title: 'Session 3',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
    });
    const ctx = testEnv.authenticatedContext(u, { email_verified: true });
    await assertSucceeds(
      setDoc(doc(ctx.firestore(), `users/${u}/chat_sessions/s3/messages/m1`), {
        role: 'user',
        text: 'hello',
        at: serverTimestamp(),
      }),
    );
  });

  it('65d. write to chat_sessions/{id}/messages/{id} with email_verified false -> DENY', async () => {
    const u = uid('u');
    await seed({ [u]: baseUser() });
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `users/${u}/chat_sessions/s4`), {
        title: 'Session 4',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
    });
    const ctx = testEnv.authenticatedContext(u, { email_verified: false });
    await assertFails(
      setDoc(doc(ctx.firestore(), `users/${u}/chat_sessions/s4/messages/m2`), {
        role: 'user',
        text: 'hello',
        at: serverTimestamp(),
      }),
    );
  });
});
