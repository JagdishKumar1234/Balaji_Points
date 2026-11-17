// Rules tests for deleting notification_logs records.
// Run:  cd firestore-tests && npx firebase emulators:exec --only firestore \
//   --project demo-balaji-rules "node --test notification_logs.rules.test.mjs"
import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, deleteDoc } from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-balaji-rules',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});
after(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/sa'), { role: 'super_admin', email: 'aaijitechstudio@gmail.com' });
    await setDoc(doc(db, 'users/adm1'), { role: 'admin', branchId: 'b1' });
    await setDoc(doc(db, 'users/adm2'), { role: 'admin', branchId: 'b2' });
    await setDoc(doc(db, 'users/m1'), { role: 'carpenter', branchId: 'b1' });
    const logs = {
      personal: { userId: 'm1', type: 'billApproved', title: 't', body: 'b' },
      shared: { userId: null, isBroadcast: true, branchId: 'b1', type: 'announcement', title: 't', body: 'b' },
      alert: { isBroadcast: true, branchId: 'b1', type: 'newPendingBill', title: 't', body: 'b' },
      noBranch: { isBroadcast: true, type: 'greeting', title: 't', body: 'b' },
    };
    for (const [id, data] of Object.entries(logs)) {
      await setDoc(doc(db, `notification_logs/${id}`), data);
    }
  });
});

const guest = () => env.unauthenticatedContext().firestore();
const as = (uid) => env.authenticatedContext(uid).firestore();
const del = (db, id) => deleteDoc(doc(db, `notification_logs/${id}`));

test('a member (PIN, no sign-in) can delete their personal notification', async () => {
  await assertSucceeds(del(guest(), 'personal'));
});

test('a member can never delete a shared notification for the branch', async () => {
  await assertFails(del(guest(), 'shared'));
  await assertFails(del(guest(), 'alert'));
  await assertFails(del(guest(), 'noBranch'));
  await assertFails(del(as('m1'), 'shared'));
});

test('the branch admin deletes their own branch\'s shared notifications', async () => {
  await assertSucceeds(del(as('adm1'), 'shared'));
  await assertSucceeds(del(as('adm1'), 'alert'));
});

test('another branch\'s admin cannot', async () => {
  await assertFails(del(as('adm2'), 'shared'));
  await assertFails(del(as('adm2'), 'alert'));
  await assertFails(del(as('adm1'), 'noBranch'));
});

test('the super admin can delete any shared notification', async () => {
  await assertSucceeds(del(as('sa'), 'noBranch'));
  await assertSucceeds(del(as('sa'), 'shared'));
});
