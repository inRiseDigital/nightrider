import { beforeAll, afterAll, describe, it, expect } from 'vitest';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, setLogLevel } from 'firebase/firestore';
import { ref, uploadBytes, getBytes, deleteObject } from 'firebase/storage';
import { createTestEnv, initialOrganizerReview, baseVenue, baseEvent, initialVenueVerification, uid } from './helpers.js';

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

async function seedVenueDoc(venueId, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `venues/${venueId}`), data);
  });
}

async function seedEventDoc(eventId, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `events/${eventId}`), data);
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

describe('storage.rules — venuePhotos/{venueId}/**', () => {
  it('87a. venue editor uploads venuePhotos/{venueId}/hero.jpg -> ALLOW', async () => {
    const owner = uid('owner');
    await seedVenueDoc('v87a', baseVenue({ ownerUid: owner, editorUids: [owner], editors: { [owner]: 'owner' } }));
    const ctx = testEnv.authenticatedContext(owner);
    await assertSucceeds(
      uploadBytes(ref(ctx.storage(), 'venuePhotos/v87a/hero.jpg'), JPEG_BYTES, { contentType: 'image/jpeg' }),
    );
  });

  it('87b. non-editor uploads -> DENY', async () => {
    const owner = uid('owner');
    const stranger = uid('stranger');
    await seedVenueDoc('v87b', baseVenue({ ownerUid: owner, editorUids: [owner], editors: { [owner]: 'owner' } }));
    const ctx = testEnv.authenticatedContext(stranger);
    await assertFails(
      uploadBytes(ref(ctx.storage(), 'venuePhotos/v87b/hero.jpg'), JPEG_BYTES, { contentType: 'image/jpeg' }),
    );
  });

  it('87c. anonymous read of venuePhotos -> ALLOW', async () => {
    const owner = uid('owner');
    await seedVenueDoc('v87c', baseVenue({ ownerUid: owner, editorUids: [owner], editors: { [owner]: 'owner' } }));
    const ownerCtx = testEnv.authenticatedContext(owner);
    await uploadBytes(ref(ownerCtx.storage(), 'venuePhotos/v87c/hero.jpg'), JPEG_BYTES, { contentType: 'image/jpeg' });
    const anonCtx = testEnv.unauthenticatedContext();
    await assertSucceeds(getBytes(ref(anonCtx.storage(), 'venuePhotos/v87c/hero.jpg')));
  });

  it('87d. editor overwrites hero.jpg -> ALLOW (the deliberate contrast with KYC; this case is the documentation)', async () => {
    const owner = uid('owner');
    await seedVenueDoc('v87d', baseVenue({ ownerUid: owner, editorUids: [owner], editors: { [owner]: 'owner' } }));
    const ctx = testEnv.authenticatedContext(owner);
    const objRef = ref(ctx.storage(), 'venuePhotos/v87d/hero.jpg');
    await assertSucceeds(uploadBytes(objRef, JPEG_BYTES, { contentType: 'image/jpeg' }));
    await assertSucceeds(uploadBytes(objRef, JPEG_BYTES, { contentType: 'image/jpeg' }));
  });

  it('87e. editor deletes hero.jpg -> ALLOW', async () => {
    const owner = uid('owner');
    await seedVenueDoc('v87e', baseVenue({ ownerUid: owner, editorUids: [owner], editors: { [owner]: 'owner' } }));
    const ctx = testEnv.authenticatedContext(owner);
    const objRef = ref(ctx.storage(), 'venuePhotos/v87e/hero.jpg');
    await assertSucceeds(uploadBytes(objRef, JPEG_BYTES, { contentType: 'image/jpeg' }));
    await assertSucceeds(deleteObject(objRef));
  });

  it('87f. gallery index 4 (outside 0..3) -> DENY', async () => {
    const owner = uid('owner');
    await seedVenueDoc('v87f', baseVenue({ ownerUid: owner, editorUids: [owner], editors: { [owner]: 'owner' } }));
    const ctx = testEnv.authenticatedContext(owner);
    await assertFails(
      uploadBytes(ref(ctx.storage(), 'venuePhotos/v87f/gallery/4.jpg'), JPEG_BYTES, { contentType: 'image/jpeg' }),
    );
  });

  it('87g. contentType: application/pdf -> DENY', async () => {
    const owner = uid('owner');
    await seedVenueDoc('v87g', baseVenue({ ownerUid: owner, editorUids: [owner], editors: { [owner]: 'owner' } }));
    const ctx = testEnv.authenticatedContext(owner);
    await assertFails(
      uploadBytes(ref(ctx.storage(), 'venuePhotos/v87g/hero.jpg'), JPEG_BYTES, { contentType: 'application/pdf' }),
    );
  });

  it('87h. a 7 MB hero.jpg (over the 6 MB cap) -> DENY (T12: client resizes before upload, but the rule is the backstop)', async () => {
    const owner = uid('owner');
    await seedVenueDoc('v87h', baseVenue({ ownerUid: owner, editorUids: [owner], editors: { [owner]: 'owner' } }));
    const ctx = testEnv.authenticatedContext(owner);
    const big = new Uint8Array(7 * 1024 * 1024);
    await assertFails(
      uploadBytes(ref(ctx.storage(), 'venuePhotos/v87h/hero.jpg'), big, { contentType: 'image/jpeg' }),
    );
  });
});

describe('storage.rules — eventMedia/{eventId}/**', () => {
  it('88a. event owner uploads eventMedia/{eventId}/cover.jpg -> ALLOW', async () => {
    const org = uid('org');
    await seedEventDoc('ev88a', baseEvent({ organizerUid: org }));
    const ctx = testEnv.authenticatedContext(org);
    await assertSucceeds(
      uploadBytes(ref(ctx.storage(), 'eventMedia/ev88a/cover.jpg'), JPEG_BYTES, { contentType: 'image/jpeg' }),
    );
  });

  it('88b. a different organizer uploads to the same event -> DENY', async () => {
    const org = uid('org');
    const other = uid('other');
    await seedEventDoc('ev88b', baseEvent({ organizerUid: org }));
    const ctx = testEnv.authenticatedContext(other);
    await assertFails(
      uploadBytes(ref(ctx.storage(), 'eventMedia/ev88b/cover.jpg'), JPEG_BYTES, { contentType: 'image/jpeg' }),
    );
  });

  it('88c. upload before the event document exists -> DENY', async () => {
    const org = uid('org');
    const ctx = testEnv.authenticatedContext(org);
    await assertFails(
      uploadBytes(ref(ctx.storage(), 'eventMedia/ev-nonexistent/cover.jpg'), JPEG_BYTES, { contentType: 'image/jpeg' }),
    );
  });
});

describe('storage.rules — venueKyc/{venueId}/{stepId}/{attempt}/{file}', () => {
  it('89a. venue owner uploads venueKyc/{venueId}/license/0/front.jpg with verification.license.attempt == 0 -> ALLOW', async () => {
    const owner = uid('owner');
    await seedVenueDoc('v89a', baseVenue({
      ownerUid: owner, editorUids: [owner], editors: { [owner]: 'owner' },
      verification: initialVenueVerification(),
    }));
    const ctx = testEnv.authenticatedContext(owner);
    await assertSucceeds(
      uploadBytes(ref(ctx.storage(), 'venueKyc/v89a/license/0/front.jpg'), JPEG_BYTES, { contentType: 'image/jpeg' }),
    );
  });

  it('89b. same path when attempt == 1 -> DENY', async () => {
    const owner = uid('owner');
    await seedVenueDoc('v89b', baseVenue({
      ownerUid: owner, editorUids: [owner], editors: { [owner]: 'owner' },
      verification: initialVenueVerification(),
    }));
    const ctx = testEnv.authenticatedContext(owner);
    await assertFails(
      uploadBytes(ref(ctx.storage(), 'venueKyc/v89b/license/1/front.jpg'), JPEG_BYTES, { contentType: 'image/jpeg' }),
    );
  });

  it("89c. re-upload over an existing venueKyc object -> DENY (the resource == null clause)", async () => {
    const owner = uid('owner');
    await seedVenueDoc('v89c', baseVenue({
      ownerUid: owner, editorUids: [owner], editors: { [owner]: 'owner' },
      verification: initialVenueVerification(),
    }));
    const ctx = testEnv.authenticatedContext(owner);
    const objRef = ref(ctx.storage(), 'venueKyc/v89c/license/0/front.jpg');
    await assertSucceeds(uploadBytes(objRef, JPEG_BYTES, { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(objRef, JPEG_BYTES, { contentType: 'image/jpeg' }));
  });

  it('89d. venueKyc delete -> DENY', async () => {
    const owner = uid('owner');
    const admin = uid('admin');
    await seedVenueDoc('v89d', baseVenue({
      ownerUid: owner, editorUids: [owner], editors: { [owner]: 'owner' },
      verification: initialVenueVerification(),
    }));
    await seedAdmin(admin);
    const ownerCtx = testEnv.authenticatedContext(owner);
    const objRef = ref(ownerCtx.storage(), 'venueKyc/v89d/license/0/front.jpg');
    await assertSucceeds(uploadBytes(objRef, JPEG_BYTES, { contentType: 'image/jpeg' }));
    const adminCtx = testEnv.authenticatedContext(admin);
    await assertFails(deleteObject(ref(adminCtx.storage(), 'venueKyc/v89d/license/0/front.jpg')));
  });

  it('89e. arbitrary filename inside a venueKyc attempt directory -> DENY', async () => {
    const owner = uid('owner');
    await seedVenueDoc('v89e', baseVenue({
      ownerUid: owner, editorUids: [owner], editors: { [owner]: 'owner' },
      verification: initialVenueVerification(),
    }));
    const ctx = testEnv.authenticatedContext(owner);
    await assertFails(
      uploadBytes(ref(ctx.storage(), 'venueKyc/v89e/license/0/notes.txt'), new Uint8Array([1]), { contentType: 'text/plain' }),
    );
  });

  it('89f. anonymous read of venueKyc -> DENY', async () => {
    const owner = uid('owner');
    await seedVenueDoc('v89f', baseVenue({
      ownerUid: owner, editorUids: [owner], editors: { [owner]: 'owner' },
      verification: initialVenueVerification(),
    }));
    const ownerCtx = testEnv.authenticatedContext(owner);
    await uploadBytes(ref(ownerCtx.storage(), 'venueKyc/v89f/license/0/front.jpg'), JPEG_BYTES, { contentType: 'image/jpeg' });
    const anonCtx = testEnv.unauthenticatedContext();
    await assertFails(getBytes(ref(anonCtx.storage(), 'venueKyc/v89f/license/0/front.jpg')));
  });

  it('89g. a manager (not owner) uploads to venueKyc -> DENY', async () => {
    const owner = uid('owner');
    const manager = uid('manager');
    await seedVenueDoc('v89g', baseVenue({
      ownerUid: owner, editorUids: [owner, manager], editors: { [owner]: 'owner', [manager]: 'manager' },
      verification: initialVenueVerification(),
    }));
    const ctx = testEnv.authenticatedContext(manager);
    await assertFails(
      uploadBytes(ref(ctx.storage(), 'venueKyc/v89g/license/0/front.jpg'), JPEG_BYTES, { contentType: 'image/jpeg' }),
    );
  });
});
