// End-to-end server test for deleteMemberAccount (admin deletes a member),
// for BOTH branches. Local emulators only.
// Run (needs Java 21+ and Node 22):
//   npx -y firebase-tools@15 emulators:exec --only auth,firestore,functions \
//     --project demo-balaji-rules --config ../firebase.emulators.test.json \
//     "node --test --test-force-exit member_delete.emulator.test.mjs"
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

/** A member with points, history, bills (own branch + another), redemption. */
async function seedMember(id, branchId, phone, { authUser = false } = {}) {
  if (authUser) {
    await admin.auth().createUser({ uid: id, email: `${id}@test.local`, password: 'password-1' });
  }
  await db.doc(`users/${id}`).set({
    uid: id, firstName: 'Test', lastName: 'Member', role: 'carpenter', branchId, phone,
    profile_verified: true, totalPoints: 12,
  });
  await db.doc(`user_points/${id}`).set({ userId: id, totalPoints: 12 });
  await db.doc(`user_points/${phone}`).set({ userId: phone, totalPoints: 3 });
  await db.collection('points_history').add({ userId: id, points: 12 });
  await db.collection('points_history').add({ carpenterId: phone, points: 3 });
  await db.collection('bills').add({ carpenterId: id, carpenterPhone: phone, branchId, amount: 1000 });
  await db.collection('bills').add({ carpenterId: 'legacy', carpenterPhone: phone, branchId, amount: 500 });
  await db.collection('bills').add({ carpenterId: 'other', carpenterPhone: phone, branchId: 'some_other_branch', amount: 9 });
  await db.collection('offer_redemptions').add({ carpenterId: id, offerId: 'o1' });
  await db.doc(`pending_users/${phone}`).set({ phone });
}

before(async () => {
  for (const [name, branchId] of [['erodeAdmin', 'erode_main'], ['karurAdmin', 'karur_branch']]) {
    await db.doc(`branches/${branchId}`).set({ name: branchId, isActive: true });
    await db.doc(`users/${name}`).set({ role: 'admin', roleId: 'admin', branchId, phone: name === 'erodeAdmin' ? '9100000001' : '9100000002' });
    tokens[name] = await pinAdminToken(name, branchId);
  }
  await admin.auth().createUser({ uid: 'superAdmin', email: SUPER_EMAIL, password: 'password-1', emailVerified: true });
  await db.doc('users/superAdmin').set({ role: 'super_admin', email: SUPER_EMAIL });
  tokens.super = await signIn(SUPER_EMAIL, 'password-1');
  await admin.auth().createUser({ uid: 'plainMember', email: 'plain@test.local', password: 'password-1' });
  await db.doc('users/plainMember').set({ role: 'carpenter', branchId: 'erode_main', phone: '9100000009' });
  tokens.member = await signIn('plain@test.local', 'password-1');
});

for (const [key, adminName, branchId, phone] of [
  ['erode', 'erodeAdmin', 'erode_main', '9811111111'],
  ['karur', 'karurAdmin', 'karur_branch', '9822222222'],
]) {
  test(`[${key}] branch admin (PIN sign-in) deletes a member and all their data`, async () => {
    const id = `del_${key}`;
    await seedMember(id, branchId, phone, { authUser: true });
    const r = await call('deleteMemberAccount', { userId: id }, tokens[adminName]);
    assert.equal(r.ok, true);
    assert.equal(r.bills, 2, 'own-branch bills by id and by phone');
    assert.equal(r.points, 2);
    assert.equal(r.history, 2);
    assert.equal(r.redemptions, 1);
    assert.equal(r.signIns, 1);
    assert.equal(await exists(`users/${id}`), false);
    assert.equal(await exists(`user_points/${id}`), false);
    assert.equal(await exists(`user_points/${phone}`), false);
    assert.equal(await exists(`pending_users/${phone}`), false);
    assert.equal(await count('points_history', 'userId', id), 0);
    assert.equal(await count('offer_redemptions', 'carpenterId', id), 0);
    const left = (await db.collection('bills').where('carpenterPhone', '==', phone).get()).docs.map((d) => d.data().branchId);
    assert.deepEqual(left, ['some_other_branch'], 'another branch\'s bill is kept');
    await assert.rejects(admin.auth().getUser(id), /no user record/i);
  });
}

test('the other branch\'s admin cannot delete', async () => {
  await seedMember('cross_member', 'erode_main', '9833333333');
  await assert.rejects(
    call('deleteMemberAccount', { userId: 'cross_member' }, tokens.karurAdmin),
    (e) => e.status === 'PERMISSION_DENIED' && /another branch/.test(e.message));
  assert.equal(await exists('users/cross_member'), true, 'nothing deleted');
  assert.equal(await count('bills', 'carpenterId', 'cross_member'), 1);
});

test('a member cannot delete anyone; signed-out calls are refused', async () => {
  await assert.rejects(call('deleteMemberAccount', { userId: 'cross_member' }, tokens.member),
    (e) => e.status === 'PERMISSION_DENIED');
  await assert.rejects(call('deleteMemberAccount', { userId: 'cross_member' }),
    (e) => e.status === 'UNAUTHENTICATED');
  assert.equal(await exists('users/cross_member'), true);
});

test('admins cannot be deleted through this function', async () => {
  await assert.rejects(call('deleteMemberAccount', { userId: 'karurAdmin' }, tokens.karurAdmin),
    (e) => e.status === 'PERMISSION_DENIED' && /Only member/.test(e.message));
  assert.equal(await exists('users/karurAdmin'), true);
});

test('super admin may delete a member of any branch', async () => {
  const r = await call('deleteMemberAccount', { userId: 'cross_member' }, tokens.super);
  assert.equal(r.ok, true);
  assert.equal(await exists('users/cross_member'), false);
});

test('deleting again says the account no longer exists', async () => {
  await assert.rejects(call('deleteMemberAccount', { userId: 'cross_member' }, tokens.erodeAdmin),
    (e) => e.status === 'NOT_FOUND');
});
