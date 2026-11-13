// End-to-end server tests for the 2026-11-13 release (account approval,
// new-bill checks), run for BOTH branches: E Road and Karur.
// Run (needs Java 21+ and Node 22):
//   npx -y firebase-tools@15 emulators:exec --only auth,firestore,functions \
//     --project demo-balaji-rules --config ../firebase.emulators.test.json \
//     "node --test --test-force-exit role_groups.emulator.test.mjs"
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
const { Timestamp } = require('firebase-admin/firestore');

const BRANCHES = {
  erode: { id: 'erode_main', name: 'Sri Balaji - E Road', admin: 'erodeAdmin' },
  karur: { id: 'karur_branch', name: 'Sri Balaji - Karur', admin: 'karurAdmin' },
};
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

const wait = (ms) => new Promise((r) => setTimeout(r, ms));
async function eventually(check, timeout = 20000) {
  const start = Date.now();
  for (;;) {
    try { return await check(); } catch (e) { if (Date.now() - start > timeout) throw e; await wait(400); }
  }
}

async function makeUser(uid, email, profile) {
  await admin.auth().createUser({ uid, email, password: 'password-1', emailVerified: true });
  await db.doc(`users/${uid}`).set(profile);
  return signIn(email, 'password-1');
}

before(async () => {
  for (const b of Object.values(BRANCHES)) {
    await db.doc(`branches/${b.id}`).set({ name: b.name, branchCode: b.id, isActive: true, phone: '9000000000' });
    tokens[b.admin] = await makeUser(b.admin, `${b.admin}@test.local`, {
      role: 'admin', roleId: 'admin', firstName: b.admin, branchId: b.id,
      phone: b.id === 'erode_main' ? '9100000001' : '9100000002',
      fcmToken: `token-${b.admin}`,
    });
  }
  tokens.super = await makeUser('superAdmin', SUPER_EMAIL, { role: 'super_admin', email: SUPER_EMAIL });
  tokens.member = await makeUser('approvedMember', 'member@test.local', {
    role: 'carpenter', branchId: 'erode_main', phone: '9100000003', profile_verified: true,
  });
});

// A self sign-up, as the app writes it (pending fields included).
async function signUp(uid, branchId, role, extra = {}) {
  await db.doc(`users/${uid}`).set({
    uid, firstName: `New ${role}`, role, roleId: role, roleName: role,
    branchId, phone: `98${Math.floor(Math.random() * 1e8).toString().padStart(8, '0')}`,
    profile_verified: false, approvalStatus: 'pending',
    approvalRequestedAt: Timestamp.now(), fcmToken: `token-${uid}`, ...extra,
  });
}

const queueFor = async (userId, type) =>
  (await db.collection('notification_queue').where('userId', '==', userId).get())
    .docs.map((d) => d.data()).filter((d) => !type || d.type === type);

for (const [key, branch] of Object.entries(BRANCHES)) {
  const other = key === 'erode' ? BRANCHES.karur : BRANCHES.erode;

  test(`[${key}] a new sign-up is marked pending and only this branch's admin is pushed`, async () => {
    const uid = `signup_${key}`;
    await signUp(uid, branch.id, 'architect');
    await eventually(async () => {
      const d = (await db.doc(`users/${uid}`).get()).data();
      assert.equal(d.approvalStatus, 'pending');
      assert.equal(d.profile_verified, false);
      assert.ok(d.approvalNotifiedAt, 'announced once');
    });
    const mine = await eventually(async () => {
      const q = (await queueFor(branch.admin, 'newUserRegistered')).filter((n) => n.data.userId === uid);
      assert.equal(q.length, 1);
      return q[0];
    });
    assert.equal(mine.title, 'New account request');
    assert.match(mine.body, /New architect · architect/);
    assert.equal(mine.data.screen, '/account-requests');
    assert.equal(mine.branchId, branch.id);
    const leaked = (await queueFor(other.admin, 'newUserRegistered')).filter((n) => n.data.userId === uid);
    assert.equal(leaked.length, 0, 'the other branch admin is never told');
  });

  test(`[${key}] this branch's admin approves all four roles; member is pushed`, async () => {
    for (const role of ['carpenter', 'interior_designer', 'architect', 'engineer']) {
      const uid = `approve_${key}_${role}`;
      await signUp(uid, branch.id, role);
      const r = await call('reviewMemberAccount', { userId: uid, action: 'approve' }, tokens[branch.admin]);
      assert.equal(r.status, 'approved');
      const d = (await db.doc(`users/${uid}`).get()).data();
      assert.equal(d.profile_verified, true, role);
      assert.equal(d.approvalStatus, 'approved');
      assert.equal(d.approvedBy, branch.admin);
      const push = await eventually(async () => {
        const q = await queueFor(uid, 'accountApproved');
        assert.equal(q.length, 1);
        return q[0];
      });
      assert.match(push.body, /approved/);
    }
  });

  test(`[${key}] reject keeps the account blocked and stores the reason`, async () => {
    const uid = `reject_${key}`;
    await signUp(uid, branch.id, 'engineer');
    await call('reviewMemberAccount', { userId: uid, action: 'reject', reason: 'Wrong branch' }, tokens[branch.admin]);
    const d = (await db.doc(`users/${uid}`).get()).data();
    assert.equal(d.profile_verified, false);
    assert.equal(d.approvalStatus, 'rejected');
    assert.equal(d.rejectReason, 'Wrong branch');
    assert.equal((await queueFor(uid, 'accountApproved')).length, 0, 'no approved push on reject');
    // A rejected account can still be approved later by its branch admin.
    await call('reviewMemberAccount', { userId: uid, action: 'approve' }, tokens[branch.admin]);
    assert.equal((await db.doc(`users/${uid}`).get()).data().profile_verified, true);
  });

  test(`[${key}] the other branch's admin, the super admin and members are refused`, async () => {
    const uid = `guarded_${key}`;
    await signUp(uid, branch.id, 'carpenter');
    for (const [who, token] of [
      ['other branch admin', tokens[other.admin]],
      ['super admin', tokens.super],
      ['a member', tokens.member],
      ['nobody', undefined],
    ]) {
      await assert.rejects(
        call('reviewMemberAccount', { userId: uid, action: 'approve' }, token),
        (e) => ['PERMISSION_DENIED', 'UNAUTHENTICATED'].includes(e.status),
        who,
      );
    }
    assert.equal((await db.doc(`users/${uid}`).get()).data().profile_verified, false);
  });

  test(`[${key}] admin accounts can never be approved or rejected`, async () => {
    await assert.rejects(
      call('reviewMemberAccount', { userId: branch.admin, action: 'reject' }, tokens[branch.admin]),
      /Only member/,
    );
  });

  test(`[${key}] an admin-added member is not announced as a request`, async () => {
    const uid = `added_${key}`;
    await signUp(uid, branch.id, 'carpenter', { createdByAdmin: true });
    await wait(3000);
    assert.equal((await queueFor(branch.admin, 'newUserRegistered')).filter((n) => n.data.userId === uid).length, 0);
  });

  test(`[${key}] live members' later edits never turn into requests`, async () => {
    const uid = `live_${key}`;
    await db.doc(`users/${uid}`).set({ role: 'carpenter', branchId: branch.id, profile_verified: true, phone: '9555555555' });
    await db.doc(`users/${uid}`).set({ tier: 'Gold' }, { merge: true });
    await wait(3000);
    const d = (await db.doc(`users/${uid}`).get()).data();
    assert.equal(d.profile_verified, true);
    assert.equal(d.approvalStatus, undefined);
  });

  test(`[${key}] new bill: a same-day duplicate is flagged, a normal bill is validated`, async () => {
    const member = `billmember_${key}`;
    const bill = (id, extra = {}) => db.doc(`bills/${id}_${key}`).set({
      carpenterId: member, branchId: branch.id, siteName: 'Site A', amount: 15000,
      billDate: Timestamp.now(), status: 'pending', createdAt: Timestamp.now(), ...extra,
    });
    await bill('first');
    await eventually(async () => {
      const d = (await db.doc(`bills/first_${key}`).get()).data();
      assert.ok(d.validatedAt);
      assert.equal(d.validationError, undefined);
      assert.equal(d.isDuplicate, undefined);
    });
    await bill('second');
    await eventually(async () => {
      const d = (await db.doc(`bills/second_${key}`).get()).data();
      assert.equal(d.isDuplicate, true);
      assert.equal(d.duplicateOf, `first_${key}`);
    });
  });
}
