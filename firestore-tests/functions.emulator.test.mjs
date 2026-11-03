// Integration tests for super-admin Cloud Functions (edit admin) and the
// rename-sync triggers, against the Auth + Firestore + Functions emulators.
// Run: npm run test:functions
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
let superToken;

async function call(name, data, token = superToken) {
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

const wait = (ms) => new Promise((r) => setTimeout(r, ms));
async function eventually(check, timeout = 15000) {
  const start = Date.now();
  for (;;) {
    try { return await check(); } catch (e) { if (Date.now() - start > timeout) throw e; await wait(400); }
  }
}

before(async () => {
  const sa = await admin.auth().createUser({ email: SUPER_EMAIL, password: 'super-secret-1', emailVerified: true });
  await db.doc(`users/${sa.uid}`).set({ role: 'super_admin', email: SUPER_EMAIL });
  superToken = await signIn(SUPER_EMAIL, 'super-secret-1');

  await db.doc('branches/b1').set({ name: 'Branch One', shortName: 'One', branchCode: 'B1', isActive: true });
  await db.doc('branches/b2').set({ name: 'Branch Two', shortName: 'Two', branchCode: 'B2', isActive: true });
  await db.doc('branches/b3').set({ name: 'Branch Three', shortName: 'Three', branchCode: 'B3', isActive: true });

  const a1 = await admin.auth().createUser({ uid: 'admin1', email: 'one@example.com', password: 'password-1' });
  await db.doc(`users/${a1.uid}`).set({
    role: 'admin', roleId: 'admin', email: 'one@example.com', firstName: 'Ravi', lastName: 'K',
    phone: '9000000001', branchId: 'b1', branchName: 'Branch One', branchCode: 'B1',
  });
  await db.doc('branches/b1').set({ adminUid: 'admin1' }, { merge: true });
  await admin.auth().createUser({ uid: 'admin2', email: 'two@example.com', password: 'password-2' });
  await db.doc('users/admin2').set({
    role: 'admin', roleId: 'admin', email: 'two@example.com', firstName: 'Priya', lastName: 'S',
    phone: '9000000002', branchId: 'b2', branchName: 'Branch Two', branchCode: 'B2',
  });
  await db.doc('branches/b2').set({ adminUid: 'admin2' }, { merge: true });

  await db.doc('users/c1').set({ role: 'mason', roleId: 'mason', roleName: 'Mason', branchId: 'b1', branchName: 'Branch One' });
  await db.doc('roles/mason').set({ roleId: 'mason', name: 'Mason', abbreviation: '', isActive: true, isBuiltIn: false });
});

const base = { uid: 'admin1', email: 'one@example.com', firstName: 'Ravi', lastName: 'Kumar', phone: '9000000011', branchId: 'b1' };

test('updateBranchAdmin requires the super admin', async () => {
  await assert.rejects(call('updateBranchAdmin', base, null), /Super admin access required/);
  const other = await signIn('two@example.com', 'password-2');
  await assert.rejects(call('updateBranchAdmin', base, other), /Super admin access required/);
});

test('edits name and phone', async () => {
  await call('updateBranchAdmin', base);
  const u = (await db.doc('users/admin1').get()).data();
  assert.equal(u.lastName, 'Kumar');
  assert.equal(u.phone, '9000000011');
  assert.equal((await admin.auth().getUser('admin1')).displayName, 'Ravi Kumar');
});

test('changes the sign-in email in Firebase Auth and the profile', async () => {
  await call('updateBranchAdmin', { ...base, email: 'ravi.new@example.com' });
  assert.equal((await admin.auth().getUser('admin1')).email, 'ravi.new@example.com');
  assert.equal((await db.doc('users/admin1').get()).data().email, 'ravi.new@example.com');
});

test('rejects an email that another account uses', async () => {
  await assert.rejects(call('updateBranchAdmin', { ...base, email: 'two@example.com' }), /already has an account/);
});

test('cannot move an admin into a branch that already has one', async () => {
  await assert.rejects(call('updateBranchAdmin', { ...base, email: 'ravi.new@example.com', branchId: 'b2' }),
    /already has an admin/);
  assert.equal((await db.doc('users/admin1').get()).data().branchId, 'b1');
});

test('moves an admin to a free branch and moves the branch link', async () => {
  const r = await call('updateBranchAdmin', { ...base, email: 'ravi.new@example.com', branchId: 'b3' });
  assert.equal(r.branchName, 'Branch Three');
  const u = (await db.doc('users/admin1').get()).data();
  assert.equal(u.branchId, 'b3');
  assert.equal(u.branchCode, 'B3');
  assert.equal(u.branchName, 'Branch Three');
  assert.equal((await db.doc('branches/b1').get()).data().adminUid, undefined);
  assert.equal((await db.doc('branches/b3').get()).data().adminUid, 'admin1');
});

test('rejects invalid details', async () => {
  await assert.rejects(call('updateBranchAdmin', { ...base, phone: '123' }), /Check the admin details/);
  await assert.rejects(call('updateBranchAdmin', { ...base, uid: 'c1' }), /not found/);
});

test('renaming a branch updates members’ stored branch name', async () => {
  await db.doc('branches/b1').update({ name: 'Branch One Renamed', shortName: 'One R' });
  await eventually(async () => {
    const c = (await db.doc('users/c1').get()).data();
    assert.equal(c.branchName, 'Branch One Renamed');
    assert.equal(c.branchShortName, 'One R');
  });
});

test('renaming a role updates users’ stored role name', async () => {
  await db.doc('roles/mason').update({ name: 'Master Mason', abbreviation: 'MM' });
  await eventually(async () => {
    const c = (await db.doc('users/c1').get()).data();
    assert.equal(c.roleName, 'Master Mason');
    assert.equal(c.roleAbbreviation, 'MM');
  });
});
