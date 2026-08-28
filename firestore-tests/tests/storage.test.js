import { beforeAll, afterAll, describe, it, expect } from 'vitest';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, setLogLevel } from 'firebase/firestore';
import { ref, uploadBytes, getBytes, deleteObject } from 'firebase/storage';
import { createTestEnv, initialOrganizerReview, uid } from './helpers.js';

setLogLevel('error');

let testEnv;

const JPEG_BYTES = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]);
const MP4_BYTES = new Uint8Array(1024).fill(1);

async function seedReview(applicantUid, steps) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(
      doc(ctx.firestore(), `users/${applicantUid}/private/organizerReview`),
      initialOrganizerReview({ steps: { ...initialOrganizerReview().steps, ...steps } }),
    );
  });
}

async function seedAdmin(adminUid) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `users/${adminUid}`), {
      isAdmin: true,
      organizerStatus: 'none',
      rank: 0,
    });
  });
}

beforeAll(async () => {
  testEnv = await createTestEnv({ withStorage: true });
}, 60000);

afterAll(async () => {
  await testEnv.cleanup();
});

describe('storage.rules — kyc/{uid}/{stepId}/{attempt}/{file}', () => {
  it('SPIKE: Storage emulator evaluates cross-service firestore.get() (kyc upload allowed when nic step is active/attempt 0)', async () => {
    const applicant = uid('spike');
    await seedReview(applicant, { nic: { status: 'active', attempt: 0 } });

    const ctx = testEnv.authenticatedContext(applicant);
    await assertSucceeds(
      uploadBytes(ref(ctx.storage(), `kyc/${applicant}/nic/0/front.jpg`), JPEG_BYTES, {
        contentType: 'image/jpeg',
      }),
    );
  });

  it('denies upload to attempt path that does not match the admin-owned attempt counter', async () => {
    const applicant = uid('u');
    await seedReview(applicant, { nic: { status: 'active', attempt: 0 } });
    const ctx = testEnv.authenticatedContext(applicant);
    await assertFails(
      uploadBytes(ref(ctx.storage(), `kyc/${applicant}/nic/1/front.jpg`), JPEG_BYTES, {
        contentType: 'image/jpeg',
      }),
    );
  });

  it('denies upload when nic.status is accepted', async () => {
    const applicant = uid('u');
    await seedReview(applicant, { nic: { status: 'accepted', attempt: 0 } });
    const ctx = testEnv.authenticatedContext(applicant);
    await assertFails(
      uploadBytes(ref(ctx.storage(), `kyc/${applicant}/nic/0/front.jpg`), JPEG_BYTES, {
        contentType: 'image/jpeg',
      }),
    );
  });

  it('denies upload when nic.status is pending', async () => {
    const applicant = uid('u');
    await seedReview(applicant, { nic: { status: 'pending', attempt: 0 } });
    const ctx = testEnv.authenticatedContext(applicant);
    await assertFails(
      uploadBytes(ref(ctx.storage(), `kyc/${applicant}/nic/0/front.jpg`), JPEG_BYTES, {
        contentType: 'image/jpeg',
      }),
    );
  });

  it('denies upload to another uid\'s kyc path', async () => {
    const applicant = uid('u');
    const attacker = uid('atk');
    await seedReview(applicant, { nic: { status: 'active', attempt: 0 } });
    const ctx = testEnv.authenticatedContext(attacker);
    await assertFails(
      uploadBytes(ref(ctx.storage(), `kyc/${applicant}/nic/0/front.jpg`), JPEG_BYTES, {
        contentType: 'image/jpeg',
      }),
    );
  });

  it('denies overwriting an existing kyc object, even as the owner', async () => {
    const applicant = uid('u');
    await seedReview(applicant, { nic: { status: 'active', attempt: 0 } });
    const ctx = testEnv.authenticatedContext(applicant);
    const objRef = ref(ctx.storage(), `kyc/${applicant}/nic/0/front.jpg`);
    await assertSucceeds(uploadBytes(objRef, JPEG_BYTES, { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(objRef, JPEG_BYTES, { contentType: 'image/jpeg' }));
  });

  it('denies deleting a kyc object, even as admin', async () => {
    const applicant = uid('u');
    const admin = uid('admin');
    await seedReview(applicant, { nic: { status: 'active', attempt: 0 } });
    await seedAdmin(admin);
    const ownerCtx = testEnv.authenticatedContext(applicant);
    const objRef = ref(ownerCtx.storage(), `kyc/${applicant}/nic/0/front.jpg`);
    await assertSucceeds(uploadBytes(objRef, JPEG_BYTES, { contentType: 'image/jpeg' }));

    const adminCtx = testEnv.authenticatedContext(admin);
    await assertFails(deleteObject(ref(adminCtx.storage(), `kyc/${applicant}/nic/0/front.jpg`)));
  });

  // The Storage emulator hardcodes a 130 MB raw-body ceiling of its own
  // (firebase-tools' emulator/storage/server.js), well under our 250 MB
  // rule cap, so a file that actually exceeds the cap can't be uploaded to
  // the emulator to exercise this path. Production Storage has no such
  // ceiling. Skipped here; the cap value itself is asserted by the rule.
  it.skip('denies a walkthrough.mp4 over the 250 MB cap', async () => {
    const applicant = uid('u');
    await seedReview(applicant, { video: { status: 'active', attempt: 0 } });
    const ctx = testEnv.authenticatedContext(applicant);
    const big = new Uint8Array(251 * 1024 * 1024);
    await assertFails(
      uploadBytes(ref(ctx.storage(), `kyc/${applicant}/video/0/walkthrough.mp4`), big, {
        contentType: 'video/mp4',
      }),
    );
  });

  it('allows a small walkthrough.mp4', async () => {
    const applicant = uid('u');
    await seedReview(applicant, { video: { status: 'active', attempt: 0 } });
    const ctx = testEnv.authenticatedContext(applicant);
    await assertSucceeds(
      uploadBytes(ref(ctx.storage(), `kyc/${applicant}/video/0/walkthrough.mp4`), MP4_BYTES, {
        contentType: 'video/mp4',
      }),
    );
  });

  it('allows poster.jpg for the video step', async () => {
    const applicant = uid('u');
    await seedReview(applicant, { video: { status: 'active', attempt: 0 } });
    const ctx = testEnv.authenticatedContext(applicant);
    await assertSucceeds(
      uploadBytes(ref(ctx.storage(), `kyc/${applicant}/video/0/poster.jpg`), JPEG_BYTES, {
        contentType: 'image/jpeg',
      }),
    );
  });

  it('denies an arbitrary filename under the video step', async () => {
    const applicant = uid('u');
    await seedReview(applicant, { video: { status: 'active', attempt: 0 } });
    const ctx = testEnv.authenticatedContext(applicant);
    await assertFails(
      uploadBytes(ref(ctx.storage(), `kyc/${applicant}/video/0/notes.txt`), new Uint8Array([1]), {
        contentType: 'text/plain',
      }),
    );
  });

  it('admin can read another user\'s kyc object', async () => {
    const applicant = uid('u');
    const admin = uid('admin');
    await seedReview(applicant, { nic: { status: 'active', attempt: 0 } });
    await seedAdmin(admin);
    const ownerCtx = testEnv.authenticatedContext(applicant);
    await assertSucceeds(
      uploadBytes(ref(ownerCtx.storage(), `kyc/${applicant}/nic/0/front.jpg`), JPEG_BYTES, {
        contentType: 'image/jpeg',
      }),
    );
    const adminCtx = testEnv.authenticatedContext(admin);
    await assertSucceeds(getBytes(ref(adminCtx.storage(), `kyc/${applicant}/nic/0/front.jpg`)));
  });

  it('a stranger cannot read another user\'s kyc object', async () => {
    const applicant = uid('u');
    const stranger = uid('stranger');
    await seedReview(applicant, { nic: { status: 'active', attempt: 0 } });
    const ownerCtx = testEnv.authenticatedContext(applicant);
    await assertSucceeds(
      uploadBytes(ref(ownerCtx.storage(), `kyc/${applicant}/nic/0/front.jpg`), JPEG_BYTES, {
        contentType: 'image/jpeg',
      }),
    );
    const strangerCtx = testEnv.authenticatedContext(stranger);
    await assertFails(getBytes(ref(strangerCtx.storage(), `kyc/${applicant}/nic/0/front.jpg`)));
  });
});

describe('storage.rules — avatars/{uid}.jpg', () => {
  it('owner can write their own avatar', async () => {
    const owner = uid('u');
    const ctx = testEnv.authenticatedContext(owner);
    await assertSucceeds(
      uploadBytes(ref(ctx.storage(), `avatars/${owner}.jpg`), JPEG_BYTES, {
        contentType: 'image/jpeg',
      }),
    );
  });

  it('denies writing another uid\'s avatar', async () => {
    const owner = uid('u');
    const attacker = uid('atk');
    const ctx = testEnv.authenticatedContext(attacker);
    await assertFails(
      uploadBytes(ref(ctx.storage(), `avatars/${owner}.jpg`), JPEG_BYTES, {
        contentType: 'image/jpeg',
      }),
    );
  });

  it('denies a 3 MB avatar', async () => {
    const owner = uid('u');
    const ctx = testEnv.authenticatedContext(owner);
    const big = new Uint8Array(3 * 1024 * 1024);
    await assertFails(
      uploadBytes(ref(ctx.storage(), `avatars/${owner}.jpg`), big, {
        contentType: 'image/jpeg',
      }),
    );
  });

  it('anonymous read of an avatar is allowed', async () => {
    const owner = uid('u');
    const ownerCtx = testEnv.authenticatedContext(owner);
    await assertSucceeds(
      uploadBytes(ref(ownerCtx.storage(), `avatars/${owner}.jpg`), JPEG_BYTES, {
        contentType: 'image/jpeg',
      }),
    );
    const anonCtx = testEnv.unauthenticatedContext();
    await assertSucceeds(getBytes(ref(anonCtx.storage(), `avatars/${owner}.jpg`)));
  });
});
