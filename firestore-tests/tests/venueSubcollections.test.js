import { beforeAll, afterAll, afterEach, describe, it } from 'vitest';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, getDocs, collection, updateDoc, serverTimestamp, Timestamp } from 'firebase/firestore';
import {
  createTestEnv,
  baseUser,
  baseVenue,
  baseMenuSection,
  baseActivity,
  basePromotion,
  basePushCampaign,
  baseBoost,
  uid,
} from './helpers.js';

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

async function seedSub(path, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

async function seedVenueWithRoles(venueId, { owner, manager, door } = {}) {
  const editorUids = [owner, manager, door].filter(Boolean);
  const editors = {};
  if (owner) editors[owner] = 'owner';
  if (manager) editors[manager] = 'manager';
  if (door) editors[door] = 'door';
  await seedVenue(venueId, baseVenue({ ownerUid: owner ?? null, editorUids, editors }));
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

describe('venues/{venueId}/menuSections/{sectionId}', () => {
  it('77a. manager creates a menuSection -> ALLOW', async () => {
    const manager = uid('manager');
    await seedUsers({ [manager]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v77a', { owner: uid('owner'), manager });
    const ctx = testEnv.authenticatedContext(manager);
    await assertSucceeds(
      setDoc(doc(ctx.firestore(), 'venues/v77a/menuSections/s1'), baseMenuSection()),
    );
  });

  it('77b. door-staff creates a menuSection -> DENY', async () => {
    const door = uid('door');
    await seedUsers({ [door]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v77b', { owner: uid('owner'), door });
    const ctx = testEnv.authenticatedContext(door);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'venues/v77b/menuSections/s1'), baseMenuSection()),
    );
  });

  it('77c. anonymous read of a menuSection -> ALLOW (public menu)', async () => {
    await seedVenueWithRoles('v77c', { owner: uid('owner') });
    await seedSub('venues/v77c/menuSections/s1', baseMenuSection());
    const ctx = testEnv.unauthenticatedContext();
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'venues/v77c/menuSections/s1')));
  });

  it('77d. items written as a map instead of a list -> DENY', async () => {
    const manager = uid('manager');
    await seedUsers({ [manager]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v77d', { owner: uid('owner'), manager });
    const ctx = testEnv.authenticatedContext(manager);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'venues/v77d/menuSections/s1'), baseMenuSection({ items: { 0: {} } })),
    );
  });
});

describe('venues/{venueId}/activity/{entryId}', () => {
  it('78a. editor creates an activity entry with actorUid == self and at == request.time -> ALLOW', async () => {
    const owner = uid('owner');
    await seedUsers({ [owner]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v78a', { owner });
    const ctx = testEnv.authenticatedContext(owner);
    await assertSucceeds(
      setDoc(
        doc(ctx.firestore(), 'venues/v78a/activity/a1'),
        baseActivity({ actorUid: owner, at: serverTimestamp() }),
      ),
    );
  });

  it('78b. activity create with actorUid = another uid -> DENY', async () => {
    const owner = uid('owner');
    const other = uid('other');
    await seedUsers({ [owner]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v78b', { owner });
    const ctx = testEnv.authenticatedContext(owner);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'venues/v78b/activity/a1'),
        baseActivity({ actorUid: other, at: serverTimestamp() }),
      ),
    );
  });

  it('78c. activity create with a client clock for at -> DENY', async () => {
    const owner = uid('owner');
    await seedUsers({ [owner]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v78c', { owner });
    const ctx = testEnv.authenticatedContext(owner);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'venues/v78c/activity/a1'),
        baseActivity({ actorUid: owner, at: Timestamp.fromDate(new Date('2020-01-01')) }),
      ),
    );
  });

  it('78d. activity update -> DENY', async () => {
    const owner = uid('owner');
    await seedUsers({ [owner]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v78d', { owner });
    await seedSub('venues/v78d/activity/a1', baseActivity({ actorUid: owner }));
    const ctx = testEnv.authenticatedContext(owner);
    await assertFails(updateDoc(doc(ctx.firestore(), 'venues/v78d/activity/a1'), { what: 'changed' }));
  });

  it('78e. non-editor reads activity -> DENY', async () => {
    const owner = uid('owner');
    const stranger = uid('stranger');
    await seedUsers({
      [owner]: baseUser({ organizerStatus: 'approved' }),
      [stranger]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenueWithRoles('v78e', { owner });
    await seedSub('venues/v78e/activity/a1', baseActivity({ actorUid: owner }));
    const ctx = testEnv.authenticatedContext(stranger);
    await assertFails(getDoc(doc(ctx.firestore(), 'venues/v78e/activity/a1')));
  });

  it('78f. door-staff creates an activity entry -> ALLOW', async () => {
    const owner = uid('owner');
    const door = uid('door');
    await seedUsers({
      [owner]: baseUser({ organizerStatus: 'approved' }),
      [door]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenueWithRoles('v78f', { owner, door });
    const ctx = testEnv.authenticatedContext(door);
    await assertSucceeds(
      setDoc(
        doc(ctx.firestore(), 'venues/v78f/activity/a1'),
        baseActivity({ actorUid: door, at: serverTimestamp() }),
      ),
    );
  });
});

describe('venues/{venueId}/team/{memberId}', () => {
  it('79a. editor reads team -> ALLOW', async () => {
    const owner = uid('owner');
    await seedUsers({ [owner]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v79a', { owner });
    await seedSub('venues/v79a/team/m1', { uid: owner, name: 'Owner', email: 'o@example.com', role: 'owner', invitedBy: null, invitedAt: null, acceptedAt: null });
    const ctx = testEnv.authenticatedContext(owner);
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'venues/v79a/team/m1')));
  });

  it('79b. owner writes team -> DENY (function-owned)', async () => {
    const owner = uid('owner');
    await seedUsers({ [owner]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v79b', { owner });
    const ctx = testEnv.authenticatedContext(owner);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'venues/v79b/team/m1'), {
        uid: owner, name: 'Owner', email: 'o@example.com', role: 'owner',
        invitedBy: null, invitedAt: null, acceptedAt: null,
      }),
    );
  });
});

describe('venueInvites/{inviteId}', () => {
  it("79c. an invitee reads venueInvites matching their token email -> ALLOW", async () => {
    const invitee = uid('invitee');
    await seedUsers({ [invitee]: baseUser({ organizerStatus: 'none' }) });
    await seedSub('venueInvites/inv1', {
      venueId: 'v1', venueName: 'Test Venue', email: 'invitee@example.com', role: 'manager',
      invitedBy: 'owner-uid', invitedAt: new Date(), expiresAt: new Date(Date.now() + 86400000),
      acceptedAt: null, acceptedByUid: null,
    });
    const ctx = testEnv.authenticatedContext(invitee, { email: 'invitee@example.com' });
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'venueInvites/inv1')));
  });

  it('79d. a signed-in user reads a venueInvites doc for another email -> DENY', async () => {
    const someone = uid('someone');
    await seedUsers({ [someone]: baseUser({ organizerStatus: 'none' }) });
    await seedSub('venueInvites/inv2', {
      venueId: 'v1', venueName: 'Test Venue', email: 'invitee@example.com', role: 'manager',
      invitedBy: 'owner-uid', invitedAt: new Date(), expiresAt: new Date(Date.now() + 86400000),
      acceptedAt: null, acceptedByUid: null,
    });
    const ctx = testEnv.authenticatedContext(someone, { email: 'someone-else@example.com' });
    await assertFails(getDoc(doc(ctx.firestore(), 'venueInvites/inv2')));
  });
});

describe('venues/{venueId}/metrics/{periodId}', () => {
  it('80a. editor reads metrics/last30 -> ALLOW', async () => {
    const owner = uid('owner');
    await seedUsers({ [owner]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v80a', { owner });
    await seedSub('venues/v80a/metrics/last30', { attendance: {}, funnel: {}, topNights: [] });
    const ctx = testEnv.authenticatedContext(owner);
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'venues/v80a/metrics/last30')));
  });

  it('80b. editor writes metrics/last30 -> DENY', async () => {
    const owner = uid('owner');
    await seedUsers({ [owner]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v80b', { owner });
    const ctx = testEnv.authenticatedContext(owner);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'venues/v80b/metrics/last30'), { attendance: {}, funnel: {}, topNights: [] }),
    );
  });

  it('80c. non-editor reads metrics -> DENY', async () => {
    const owner = uid('owner');
    const stranger = uid('stranger');
    await seedUsers({
      [owner]: baseUser({ organizerStatus: 'approved' }),
      [stranger]: baseUser({ organizerStatus: 'approved' }),
    });
    await seedVenueWithRoles('v80c', { owner });
    await seedSub('venues/v80c/metrics/last30', { attendance: {}, funnel: {}, topNights: [] });
    const ctx = testEnv.authenticatedContext(stranger);
    await assertFails(getDoc(doc(ctx.firestore(), 'venues/v80c/metrics/last30')));
  });
});

describe('venues/{venueId}/aiVisibility/current', () => {
  it('81a. editor reads aiVisibility/current -> ALLOW', async () => {
    const owner = uid('owner');
    await seedUsers({ [owner]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v81a', { owner });
    await seedSub('venues/v81a/aiVisibility/current', { score: 50, prompts: [], tips: [], updatedAt: new Date() });
    const ctx = testEnv.authenticatedContext(owner);
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'venues/v81a/aiVisibility/current')));
  });

  it('81b. editor writes aiVisibility/current -> DENY', async () => {
    const owner = uid('owner');
    await seedUsers({ [owner]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v81b', { owner });
    const ctx = testEnv.authenticatedContext(owner);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'venues/v81b/aiVisibility/current'), { score: 50, prompts: [], tips: [], updatedAt: serverTimestamp() }),
    );
  });
});

describe('venues/{venueId}/promotions/{promoId}', () => {
  it('82a. manager creates a promo with used: 0 -> ALLOW', async () => {
    const manager = uid('manager');
    await seedUsers({ [manager]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v82a', { owner: uid('owner'), manager });
    const ctx = testEnv.authenticatedContext(manager);
    await assertSucceeds(
      setDoc(doc(ctx.firestore(), 'venues/v82a/promotions/p1'), basePromotion({ used: 0 })),
    );
  });

  it('82b. manager sets used: 5 on create -> DENY', async () => {
    const manager = uid('manager');
    await seedUsers({ [manager]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v82b', { owner: uid('owner'), manager });
    const ctx = testEnv.authenticatedContext(manager);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'venues/v82b/promotions/p1'), basePromotion({ used: 5 })),
    );
  });

  it('82c. manager increments used on update -> DENY', async () => {
    const manager = uid('manager');
    await seedUsers({ [manager]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v82c', { owner: uid('owner'), manager });
    await seedSub('venues/v82c/promotions/p1', basePromotion({ used: 0 }));
    const ctx = testEnv.authenticatedContext(manager);
    await assertFails(updateDoc(doc(ctx.firestore(), 'venues/v82c/promotions/p1'), { used: 1 }));
  });

  it('82d. door-staff creates a promo -> DENY', async () => {
    const door = uid('door');
    await seedUsers({ [door]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v82d', { owner: uid('owner'), door });
    const ctx = testEnv.authenticatedContext(door);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'venues/v82d/promotions/p1'), basePromotion({ used: 0 })),
    );
  });
});

describe('venues/{venueId}/pushCampaigns/{campaignId} and promoState/current', () => {
  it("83a. manager creates a pushCampaign with status: 'queued' -> ALLOW", async () => {
    const manager = uid('manager');
    await seedUsers({ [manager]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v83a', { owner: uid('owner'), manager });
    const ctx = testEnv.authenticatedContext(manager);
    await assertSucceeds(
      setDoc(doc(ctx.firestore(), 'venues/v83a/pushCampaigns/c1'), basePushCampaign({ status: 'queued' })),
    );
  });

  it("83b. create with status: 'sent' -> DENY", async () => {
    const manager = uid('manager');
    await seedUsers({ [manager]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v83b', { owner: uid('owner'), manager });
    const ctx = testEnv.authenticatedContext(manager);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'venues/v83b/pushCampaigns/c1'), basePushCampaign({ status: 'sent' })),
    );
  });

  it('83c. organizer updates a campaign -> DENY', async () => {
    const manager = uid('manager');
    await seedUsers({ [manager]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v83c', { owner: uid('owner'), manager });
    await seedSub('venues/v83c/pushCampaigns/c1', basePushCampaign());
    const ctx = testEnv.authenticatedContext(manager);
    await assertFails(updateDoc(doc(ctx.firestore(), 'venues/v83c/pushCampaigns/c1'), { status: 'sent' }));
  });

  it('83d. editor writes promoState/current -> DENY', async () => {
    const owner = uid('owner');
    await seedUsers({ [owner]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v83d', { owner });
    const ctx = testEnv.authenticatedContext(owner);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'venues/v83d/promoState/current'), { sentThisWeek: 1 }),
    );
  });
});

describe('venues/{venueId}/boosts/{boostId}', () => {
  it("84a. owner creates a boost with status: 'pending' -> ALLOW", async () => {
    const owner = uid('owner');
    await seedUsers({ [owner]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v84a', { owner });
    const ctx = testEnv.authenticatedContext(owner);
    await assertSucceeds(
      setDoc(doc(ctx.firestore(), 'venues/v84a/boosts/b1'), baseBoost({ status: 'pending' })),
    );
  });

  it("84b. create with status: 'active' -> DENY", async () => {
    const owner = uid('owner');
    await seedUsers({ [owner]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v84b', { owner });
    const ctx = testEnv.authenticatedContext(owner);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'venues/v84b/boosts/b1'), baseBoost({ status: 'active' })),
    );
  });

  it('84c. organizer flips pending -> active -> DENY', async () => {
    const owner = uid('owner');
    await seedUsers({ [owner]: baseUser({ organizerStatus: 'approved' }) });
    await seedVenueWithRoles('v84c', { owner });
    await seedSub('venues/v84c/boosts/b1', baseBoost({ status: 'pending' }));
    const ctx = testEnv.authenticatedContext(owner);
    await assertFails(updateDoc(doc(ctx.firestore(), 'venues/v84c/boosts/b1'), { status: 'active' }));
  });
});
