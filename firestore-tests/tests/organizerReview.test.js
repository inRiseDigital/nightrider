import { beforeAll, afterAll, afterEach, describe, it } from 'vitest';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import { createTestEnv, baseUser, initialOrganizerReview, videoScript, uid } from './helpers.js';

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

  it("14b. owner creates it with steps.video.status 'active' -> DENY (video must start pending)", async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    const bad = initialOrganizerReview();
    bad.steps.video.status = 'active';
    await assertFails(setDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), bad));
  });

  it('14c. owner creates it with a walkthrough script already attached -> DENY', async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    const bad = initialOrganizerReview();
    bad.steps.video.script = videoScript();
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

  it('19b. admin publishes a walkthrough script and unlocks the video step -> ALLOW', async () => {
    const u = uid('u');
    const admin = uid('admin');
    await seedUsers({ [u]: baseUser(), [admin]: baseUser({ isAdmin: true }) });
    const review = initialOrganizerReview();
    await seedReview(u, review);
    const ctx = testEnv.authenticatedContext(admin);
    const nextSteps = {
      ...review.steps,
      video: { ...review.steps.video, status: 'active', script: videoScript() },
    };
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), { steps: nextSteps }),
    );
  });

  it('19c. admin revises a published script without touching video.attempt -> ALLOW', async () => {
    const u = uid('u');
    const admin = uid('admin');
    await seedUsers({ [u]: baseUser(), [admin]: baseUser({ isAdmin: true }) });
    const review = initialOrganizerReview();
    review.steps.video = { ...review.steps.video, status: 'active', script: videoScript() };
    await seedReview(u, review);
    const ctx = testEnv.authenticatedContext(admin);
    const nextSteps = {
      ...review.steps,
      video: {
        ...review.steps.video,
        script: videoScript({ revision: 1, lines: ['Show the fire exit too.'] }),
      },
    };
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), { steps: nextSteps }),
    );
  });

  it('19d. applicant writes their own script -> DENY', async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const review = initialOrganizerReview();
    await seedReview(u, review);
    const ctx = testEnv.authenticatedContext(u);
    const nextSteps = {
      ...review.steps,
      video: { ...review.steps.video, status: 'active', script: videoScript() },
    };
    await assertFails(
      updateDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), { steps: nextSteps }),
    );
  });

  it('19e. admin publishes a 21-line script -> DENY (capped at 20)', async () => {
    const u = uid('u');
    const admin = uid('admin');
    await seedUsers({ [u]: baseUser(), [admin]: baseUser({ isAdmin: true }) });
    const review = initialOrganizerReview();
    await seedReview(u, review);
    const ctx = testEnv.authenticatedContext(admin);
    const lines = Array.from({ length: 21 }, (_, i) => `Shot ${i + 1}`);
    const nextSteps = {
      ...review.steps,
      video: { ...review.steps.video, status: 'active', script: videoScript({ lines }) },
    };
    await assertFails(
      updateDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), { steps: nextSteps }),
    );
  });

  it('19f. admin publishes an empty script -> DENY (needs at least one line)', async () => {
    const u = uid('u');
    const admin = uid('admin');
    await seedUsers({ [u]: baseUser(), [admin]: baseUser({ isAdmin: true }) });
    const review = initialOrganizerReview();
    await seedReview(u, review);
    const ctx = testEnv.authenticatedContext(admin);
    const nextSteps = {
      ...review.steps,
      video: { ...review.steps.video, status: 'active', script: videoScript({ lines: [] }) },
    };
    await assertFails(
      updateDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), { steps: nextSteps }),
    );
  });

  it("19g. admin publishes a script with an unknown format -> DENY", async () => {
    const u = uid('u');
    const admin = uid('admin');
    await seedUsers({ [u]: baseUser(), [admin]: baseUser({ isAdmin: true }) });
    const review = initialOrganizerReview();
    await seedReview(u, review);
    const ctx = testEnv.authenticatedContext(admin);
    const nextSteps = {
      ...review.steps,
      video: { ...review.steps.video, status: 'active', script: videoScript({ format: 'storyboard' }) },
    };
    await assertFails(
      updateDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), { steps: nextSteps }),
    );
  });

  it('19h. admin publishes a script with an extra key -> DENY', async () => {
    const u = uid('u');
    const admin = uid('admin');
    await seedUsers({ [u]: baseUser(), [admin]: baseUser({ isAdmin: true }) });
    const review = initialOrganizerReview();
    await seedReview(u, review);
    const ctx = testEnv.authenticatedContext(admin);
    const nextSteps = {
      ...review.steps,
      video: { ...review.steps.video, status: 'active', script: videoScript({ dueAt: new Date() }) },
    };
    await assertFails(
      updateDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), { steps: nextSteps }),
    );
  });

  it('19i. admin attaches a script to a step other than video -> DENY', async () => {
    const u = uid('u');
    const admin = uid('admin');
    await seedUsers({ [u]: baseUser(), [admin]: baseUser({ isAdmin: true }) });
    const review = initialOrganizerReview();
    await seedReview(u, review);
    const ctx = testEnv.authenticatedContext(admin);
    const nextSteps = { ...review.steps, nic: { ...review.steps.nic, script: videoScript() } };
    await assertFails(
      updateDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), { steps: nextSteps }),
    );
  });

  it('19j. admin updates a review document written before `script` existed -> ALLOW', async () => {
    const u = uid('u');
    const admin = uid('admin');
    await seedUsers({ [u]: baseUser(), [admin]: baseUser({ isAdmin: true }) });
    // The shape production had before this field: no `script` key anywhere. A
    // missing map key is an evaluation error in rules, so this is what keeps
    // the `get(..., null)` guards honest.
    const legacy = initialOrganizerReview();
    for (const step of Object.values(legacy.steps)) delete step.script;
    await seedReview(u, legacy);
    const ctx = testEnv.authenticatedContext(admin);
    const nextSteps = { ...legacy.steps, nic: { ...legacy.steps.nic, status: 'accepted' } };
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `users/${u}/private/organizerReview`), { steps: nextSteps }),
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
