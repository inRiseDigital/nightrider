import { beforeAll, afterAll, afterEach, describe, it } from 'vitest';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import { createTestEnv, baseUser, initialOrganizerReview, uid } from './helpers.js';

let testEnv;

async function seedUsers(users) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    for (const [id, data] of Object.entries(users)) {
      await setDoc(doc(ctx.firestore(), `users/${id}`), data);
    }
  });
}

async function seedReview(applicant, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `users/${applicant}/private/organizerReview`), data);
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

describe('users/{uid}/private/organizerReview', () => {
  it('12. owner creates it in the exact initial shape from the schema doc -> ALLOW', async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    await assertSucceeds(
      setDoc(
        doc(ctx.firestore(), `users/${u}/private/organizerReview`),
        initialOrganizerReview(),
      ),
    );
  });

  it("13. owner creates it with steps.nic.status 'accepted' -> DENY", async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    const bad = initialOrganizerReview();
    bad.steps.nic.status = 'accepted';
    await assertFails(setDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), bad));
  });

  it("14. owner creates it with steps.gps.status 'active' -> DENY (gps must start pending)", async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    const bad = initialOrganizerReview();
    bad.steps.gps.status = 'active';
    await assertFails(setDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), bad));
  });

  it('15. owner creates it with any attempt != 0 -> DENY', async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    const bad = initialOrganizerReview();
    bad.steps.nic.attempt = 1;
    await assertFails(setDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), bad));
  });

  it("16. owner creates it with status 'approved' -> DENY", async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    const bad = initialOrganizerReview({ status: 'approved' });
    await assertFails(setDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), bad));
  });

  it('17. owner UPDATES it at all -> DENY (applicant can never write a verdict)', async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    await seedReview(u, initialOrganizerReview());
    const ctx = testEnv.authenticatedContext(u);
    const ref = doc(ctx.firestore(), `users/${u}/private/organizerReview`);
    await assertFails(updateDoc(ref, { 'steps.nic.attempt': 1 }));
    await assertFails(updateDoc(ref, { 'steps.nic.note': 'please resubmit' }));
    await assertFails(updateDoc(ref, { reviewedBy: u }));
  });

  it("18. admin updates it: nic.status 'needs_info' + nic.attempt 1 -> ALLOW", async () => {
    const u = uid('u');
    const admin = uid('admin');
    await seedUsers({ [u]: baseUser(), [admin]: baseUser({ isAdmin: true }) });
    const review = initialOrganizerReview();
    await seedReview(u, review);
    const ctx = testEnv.authenticatedContext(admin);
    const nextSteps = { ...review.steps, nic: { ...review.steps.nic, status: 'needs_info', attempt: 1 } };
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), {
        steps: nextSteps,
      }),
    );
  });

  it('19. admin sets nic.attempt 4 -> DENY (capped at 3)', async () => {
    const u = uid('u');
    const admin = uid('admin');
    await seedUsers({ [u]: baseUser(), [admin]: baseUser({ isAdmin: true }) });
    const review = initialOrganizerReview();
    await seedReview(u, review);
    const ctx = testEnv.authenticatedContext(admin);
    const nextSteps = { ...review.steps, nic: { ...review.steps.nic, status: 'needs_info', attempt: 4 } };
    await assertFails(
      updateDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), {
        steps: nextSteps,
      }),
    );
  });

  it('20a. owner can read it', async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    await seedReview(u, initialOrganizerReview());
    const ctx = testEnv.authenticatedContext(u);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`)));
  });

  it('20b. admin can read it', async () => {
    const u = uid('u');
    const admin = uid('admin');
    await seedUsers({ [u]: baseUser(), [admin]: baseUser({ isAdmin: true }) });
    await seedReview(u, initialOrganizerReview());
    const ctx = testEnv.authenticatedContext(admin);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`)));
  });

  it('20c. a stranger cannot read it', async () => {
    const u = uid('u');
    const stranger = uid('stranger');
    await seedUsers({ [u]: baseUser(), [stranger]: baseUser() });
    await seedReview(u, initialOrganizerReview());
    const ctx = testEnv.authenticatedContext(stranger);
    await assertFails(getDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`)));
  });

  it('21. delete by anyone -> DENY', async () => {
    const u = uid('u');
    const admin = uid('admin');
    await seedUsers({ [u]: baseUser(), [admin]: baseUser({ isAdmin: true }) });
    await seedReview(u, initialOrganizerReview());
    const ownerCtx = testEnv.authenticatedContext(u);
    const adminCtx = testEnv.authenticatedContext(admin);
    await assertFails(deleteDoc(doc(ownerCtx.firestore(), `users/${u}/private/organizerReview`)));
    await assertFails(deleteDoc(doc(adminCtx.firestore(), `users/${u}/private/organizerReview`)));
  });
});
