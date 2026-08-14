import { beforeAll, afterAll, afterEach, describe, it } from 'vitest';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc, deleteDoc, serverTimestamp, Timestamp } from 'firebase/firestore';
import { createTestEnv, baseUser, baseLog, uid } from './helpers.js';

let testEnv;

async function seedUsers(users) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    for (const [id, data] of Object.entries(users)) {
      await setDoc(doc(ctx.firestore(), `users/${id}`), data);
    }
  });
}

async function seedLog(id, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `logs/${id}`), data);
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

describe('logs/{logId}', () => {
  it('52. admin creates a log with at = serverTimestamp() and a valid action/targetType -> ALLOW', async () => {
    const admin = uid('admin');
    await seedUsers({ [admin]: baseUser({ isAdmin: true }) });
    const ctx = testEnv.authenticatedContext(admin);
    await assertSucceeds(
      setDoc(
        doc(ctx.firestore(), 'logs/log1'),
        baseLog({ actorUid: admin, at: serverTimestamp() }),
      ),
    );
  });

  it('53a. action not in the enum -> DENY', async () => {
    const admin = uid('admin');
    await seedUsers({ [admin]: baseUser({ isAdmin: true }) });
    const ctx = testEnv.authenticatedContext(admin);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'logs/log2'),
        baseLog({ actorUid: admin, action: 'event.delete', at: serverTimestamp() }),
      ),
    );
  });

  it("53b. targetType 'club' -> DENY", async () => {
    const admin = uid('admin');
    await seedUsers({ [admin]: baseUser({ isAdmin: true }) });
    const ctx = testEnv.authenticatedContext(admin);
    await assertFails(
      setDoc(
        doc(ctx.firestore(), 'logs/log3'),
        baseLog({ actorUid: admin, targetType: 'club', at: serverTimestamp() }),
      ),
    );
  });

  it('54. actorUid != caller -> DENY', async () => {
    const admin = uid('admin');
    const other = uid('other');
    await seedUsers({ [admin]: baseUser({ isAdmin: true }) });
    const ctx = testEnv.authenticatedContext(admin);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'logs/log4'), baseLog({ actorUid: other, at: serverTimestamp() })),
    );
  });

  it('55. non-admin creates a log -> DENY', async () => {
    const u = uid('u');
    await seedUsers({ [u]: baseUser() });
    const ctx = testEnv.authenticatedContext(u);
    await assertFails(
      setDoc(doc(ctx.firestore(), 'logs/log5'), baseLog({ actorUid: u, at: serverTimestamp() })),
    );
  });

  it('56a. any update of a log -> DENY (even by admin)', async () => {
    const admin = uid('admin');
    await seedUsers({ [admin]: baseUser({ isAdmin: true }) });
    await seedLog('log6', baseLog({ actorUid: admin }));
    const ctx = testEnv.authenticatedContext(admin);
    await assertFails(updateDoc(doc(ctx.firestore(), 'logs/log6'), { summary: 'edited' }));
  });

  it('56b. any delete of a log -> DENY (even by admin)', async () => {
    const admin = uid('admin');
    await seedUsers({ [admin]: baseUser({ isAdmin: true }) });
    await seedLog('log7', baseLog({ actorUid: admin }));
    const ctx = testEnv.authenticatedContext(admin);
    await assertFails(deleteDoc(doc(ctx.firestore(), 'logs/log7')));
  });
});
