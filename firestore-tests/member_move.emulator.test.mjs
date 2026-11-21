// End-to-end server test for changeMemberBranchRole (admin fixes branch / role),
// for BOTH branches. Local emulators only.
// Run (needs Java 21+ and Node 22):
//   npx -y firebase-tools@15 emulators:exec --only auth,firestore,functions \
//     --project demo-balaji-rules --config ../firebase.emulators.test.json \
//     "node --test --test-force-exit member_move.emulator.test.mjs"
import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';

const require = createRequire(new URL('../functions/', import.meta.url));
const admin = require('firebase-admin');

const PROJECT = 'demo-balaji-rules';
process.env.FIREBASE_AUTH_EMULATOR_HOST ||= '127.0.0.1:9099';
process.env.FIRESTORE_EMULATOR_HOST ||= '127.0.0.1:8080';
process.env.GCLOUD_PROJECT = PROJECT;
const SUPER_EMAIL = 'aaijitechstudio@gmail.com';
const AUTH = `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`;
const FUNCTIONS = 'http://127.0.0.1:5001';

admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();

const tokens = {};

async function call(name, data, token) {
  const res = await fetch(`${FUNCTIONS}/${PROJECT}/us-central1/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify({ data }),
  });
  const body = await res.json();
  if (body.error) { const e = new Error(body.error.message); e.status = body.error.status; throw e; }
  return body.result;
}

async function signIn(email, password) {
  const res = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  return (await res.json()).idToken;
}

// A PIN admin's sign-in, exactly as adminPinSignIn issues it.
async function pinAdminToken(uid, branchId) {
  const custom = await admin.auth().createCustomToken(uid, { role: 'admin', branchId, loginMethod: 'pin' });
  const res = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token: custom, returnSecureToken: true }),
  });
  return (await res.json()).idToken;
}

const exists = async (path) => (await db.doc(path).get()).exists;
const count = async (col, field, value) =>
  (await db.collection(col).where(field, '==', value).get()).size;
const get = async (path) => (await db.doc(path).get()).data();

/**
 * A carpenter with 2 approved bills (₹10,000 at 5,000/pt = 2 pts each,
 * i.e. wrongly signed up as architect), 1 pending, 1 rejected, a spin
 * entry of 5 points, and matching points_history docs.
 */
async function seedMember(id, branchId, phone, role = 'architect') {
  await db.doc(`users/${id}`).set({
    uid: id, firstName: 'Test', lastName: 'Member', role, roleId: role, branchId, phone,
    profile_verified: true, totalPoints: 9, tier: 'Bronze',
  });
  const bills = {};
  for (const [key, status, amount, pts] of [
    ['a1', 'approved', 10000, 2], ['a2', 'approved', 10000, 2],
    ['p1', 'pending', 2500, 0], ['r1', 'rejected', 3000, 0],
  ]) {
    const ref = db.collection('bills').doc(`${id}_${key}`);
    await ref.set({ carpenterId: id, carpenterPhone: phone, branchId, amount, status,
      pointsEarned: pts, rupeesPerPoint: 5000, ...(status === 'pending' ? { expectedPoints: 0.5 } : {}) });
    bills[key] = ref.id;
  }
  await db.doc(`user_points/${id}`).set({ userId: id, branchId, totalPoints: 9, tier: 'Bronze', pointsHistory: [
    { billId: bills.a1, points: 2, branchId }, { billId: bills.a2, points: 2, branchId },
    { reason: 'Daily spin', points: 5, branchId },
  ] });
  await db.collection('points_history').add({ userId: id, carpenterId: id, billId: bills.a1, points: 2, branchId });
  await db.collection('points_history').add({ userId: id, carpenterId: id, billId: bills.a2, points: 2, branchId });
  return bills;
}

before(async () => {
  for (const [name, branchId] of [['erodeAdmin', 'erode_main'], ['karurAdmin', 'karur_branch']]) {
    await db.doc(`branches/${branchId}`).set({ name: `${branchId} name`, shortName: branchId, branchCode: branchId.toUpperCase(), isActive: true });
    await db.doc(`users/${name}`).set({ role: 'admin', roleId: 'admin', branchId, phone: name === 'erodeAdmin' ? '9100000001' : '9100000002' });
    tokens[name] = await pinAdminToken(name, branchId);
  }
  await db.doc('branches/closed_branch').set({ name: 'Closed', isActive: false });
  await admin.auth().createUser({ uid: 'superAdmin', email: SUPER_EMAIL, password: 'password-1', emailVerified: true });
  await db.doc('users/superAdmin').set({ role: 'super_admin', email: SUPER_EMAIL });
  tokens.super = await signIn(SUPER_EMAIL, 'password-1');
  await admin.auth().createUser({ uid: 'plainMember', email: 'plain@test.local', password: 'password-1' });
  await db.doc('users/plainMember').set({ role: 'carpenter', branchId: 'erode_main', phone: '9100000009' });
  tokens.member = await signIn('plain@test.local', 'password-1');
});

for (const [key, adminName, branchId, otherBranch, phone] of [
  ['erode', 'erodeAdmin', 'erode_main', 'karur_branch', '9811111111'],
  ['karur', 'karurAdmin', 'karur_branch', 'erode_main', '9822222222'],
]) {
  test(`[${key}] role change recalculates every bill at the new rate`, async () => {
    const id = `role_${key}`;
    const bills = await seedMember(id, branchId, phone);
    const r = await call('changeMemberBranchRole', { userId: id, branchId, role: 'carpenter' }, tokens[adminName]);
    assert.equal(r.roleChanged, true);
    assert.equal(r.branchChanged, false);
    assert.equal(r.billsRecalculated, 3, '2 approved + 1 pending');
    // 2 bills now 10 pts each (+16), spin 5 kept: 9 + 16 = 25.
    assert.equal(r.totalPoints, 25);
    const u = await get(`users/${id}`);
    assert.equal(u.role, 'carpenter');
    assert.equal(u.roleId, 'carpenter');
    assert.equal(u.roleName, 'Carpenter');
    assert.equal(u.totalPoints, 25);
    assert.equal(u.branchId, branchId);
    const p = await get(`user_points/${id}`);
    assert.equal(p.totalPoints, 25);
    assert.deepEqual(p.pointsHistory.map((h) => h.points), [10, 10, 5]);
    assert.equal((await get(`bills/${bills.a1}`)).pointsEarned, 10);
    assert.equal((await get(`bills/${bills.a1}`)).rupeesPerPoint, 1000);
    assert.equal((await get(`bills/${bills.p1}`)).expectedPoints, 2.5);
    assert.equal((await get(`bills/${bills.r1}`)).rupeesPerPoint, 5000, 'rejected untouched');
    const hist = (await db.collection('points_history').where('userId', '==', id).get()).docs.map((d) => d.data().points);
    assert.deepEqual(hist.sort(), [10, 10]);

    // And back again: architect gives 2 + 2 + 5 = 9.
    const back = await call('changeMemberBranchRole', { userId: id, branchId, role: 'architect' }, tokens[adminName]);
    assert.equal(back.totalPoints, 9);
    assert.equal((await get(`users/${id}`)).roleAbbreviation, 'Ar.');
  });

  test(`[${key}] branch change starts the member at 0 points`, async () => {
    const id = `move_${key}`;
    const bills = await seedMember(id, branchId, phone, 'carpenter');
    const r = await call('changeMemberBranchRole', { userId: id, branchId: otherBranch, role: 'carpenter' }, tokens[adminName]);
    assert.equal(r.branchChanged, true);
    assert.equal(r.roleChanged, false);
    assert.equal(r.totalPoints, 0);
    const u = await get(`users/${id}`);
    assert.equal(u.branchId, otherBranch);
    assert.equal(u.branchName, `${otherBranch} name`);
    assert.equal(u.branchCode, otherBranch.toUpperCase());
    assert.equal(u.totalPoints, 0);
    assert.equal(u.tier, 'Bronze');
    assert.equal(u.lastBranchRoleChange.previousPoints, 9);
    const p = await get(`user_points/${id}`);
    assert.equal(p.totalPoints, 0);
    assert.deepEqual(p.pointsHistory, []);
    assert.equal(p.branchId, otherBranch);
    assert.equal(p.previousBranchPoints.totalPoints, 9);
    assert.equal((await get(`bills/${bills.a1}`)).branchId, branchId, 'approved bill stays as old branch record');
    assert.equal((await get(`bills/${bills.r1}`)).branchId, branchId);
    assert.equal((await get(`bills/${bills.p1}`)).branchId, otherBranch, 'pending bill moves');
    const hist = (await db.collection('points_history').where('userId', '==', id).get()).docs.map((d) => d.data().branchId);
    assert.deepEqual(hist, [branchId, branchId], 'history stays with the old branch');
    // The old admin no longer manages this member.
    await assert.rejects(
      call('changeMemberBranchRole', { userId: id, branchId, role: 'carpenter' }, tokens[adminName]),
      (e) => e.status === 'PERMISSION_DENIED' && /another branch/.test(e.message));
  });
}

test('branch + role together: 0 points, pending bill at the new rate', async () => {
  const bills = await seedMember('both', 'erode_main', '9844444444');
  const r = await call('changeMemberBranchRole', { userId: 'both', branchId: 'karur_branch', role: 'carpenter' }, tokens.erodeAdmin);
  assert.equal(r.totalPoints, 0);
  const pending = await get(`bills/${bills.p1}`);
  assert.equal(pending.branchId, 'karur_branch');
  assert.equal(pending.rupeesPerPoint, 1000);
  assert.equal(pending.expectedPoints, 2.5);
  assert.equal((await get(`bills/${bills.a1}`)).pointsEarned, 2, 'old branch records unchanged');
  assert.equal((await get('users/both')).role, 'carpenter');
});

test('the super admin cannot change branch or role', async () => {
  await seedMember('sa_target', 'erode_main', '9855555555');
  await assert.rejects(
    call('changeMemberBranchRole', { userId: 'sa_target', branchId: 'karur_branch', role: 'carpenter' }, tokens.super),
    (e) => e.status === 'PERMISSION_DENIED');
  assert.equal((await get('users/sa_target')).branchId, 'erode_main');
});

test('another branch admin, a member, or signed-out cannot', async () => {
  const args = { userId: 'sa_target', branchId: 'erode_main', role: 'carpenter' };
  await assert.rejects(call('changeMemberBranchRole', args, tokens.karurAdmin),
    (e) => e.status === 'PERMISSION_DENIED' && /another branch/.test(e.message));
  await assert.rejects(call('changeMemberBranchRole', args, tokens.member), (e) => e.status === 'PERMISSION_DENIED');
  await assert.rejects(call('changeMemberBranchRole', args), (e) => e.status === 'UNAUTHENTICATED');
  assert.equal((await get('users/sa_target')).role, 'architect');
});

test('invalid targets: inactive branch, admin role, nothing to change', async () => {
  const base = { userId: 'sa_target' };
  await assert.rejects(call('changeMemberBranchRole', { ...base, branchId: 'closed_branch', role: 'architect' }, tokens.erodeAdmin),
    (e) => e.status === 'INVALID_ARGUMENT' && /not active/.test(e.message));
  await assert.rejects(call('changeMemberBranchRole', { ...base, branchId: 'erode_main', role: 'admin' }, tokens.erodeAdmin),
    (e) => e.status === 'INVALID_ARGUMENT');
  await assert.rejects(call('changeMemberBranchRole', { ...base, branchId: 'erode_main', role: 'architect' }, tokens.erodeAdmin),
    (e) => e.status === 'INVALID_ARGUMENT' && /Nothing/.test(e.message));
  await assert.rejects(call('changeMemberBranchRole', { userId: 'karurAdmin', branchId: 'karur_branch', role: 'carpenter' }, tokens.karurAdmin),
    (e) => e.status === 'PERMISSION_DENIED' && /Only member/.test(e.message));
});
