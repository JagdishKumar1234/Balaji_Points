// Firestore rules tests for the `roles` collection and role-based signup.
// Run:  cd firestore-tests && npm test   (starts the Firestore emulator)
import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, getDocs, collection, setDoc, updateDoc, deleteDoc,
  serverTimestamp,
} from 'firebase/firestore';

const SUPER_EMAIL = 'aaijitechstudio@gmail.com';
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
    await setDoc(doc(db, 'users/sa'), { role: 'super_admin', email: SUPER_EMAIL });
    await setDoc(doc(db, 'branches/b1'), { isActive: true, branchCode: 'B1', name: 'Branch 1' });
    await setDoc(doc(db, 'roles/mason'), {
      roleId: 'mason', name: 'Mason', abbreviation: '', isActive: true, isBuiltIn: false,
    });
    await setDoc(doc(db, 'roles/painter'), {
      roleId: 'painter', name: 'Painter', abbreviation: '', isActive: false, isBuiltIn: false,
    });
  });
});

const superAdmin = () =>
  env.authenticatedContext('sa', { email: SUPER_EMAIL, email_verified: true }).firestore();
const otherUser = (uid = 'u1') =>
  env.authenticatedContext(uid, { email: 'someone@example.com', email_verified: true }).firestore();
const guest = () => env.unauthenticatedContext().firestore();

const customRole = (over = {}) => ({
  roleId: 'plumber', name: 'Plumber', abbreviation: 'Pl.', isActive: true, isBuiltIn: false,
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...over,
});

// ── Reading ─────────────────────────────────────────────────────────────────
test('anyone (even before sign-in) can list roles for registration', async () => {
  await assertSucceeds(getDocs(collection(guest(), 'roles')));
  await assertSucceeds(getDoc(doc(guest(), 'roles/mason')));
});

// ── Creating ────────────────────────────────────────────────────────────────
test('super admin can create a valid custom role', async () => {
  await assertSucceeds(setDoc(doc(superAdmin(), 'roles/plumber'), customRole()));
});
test('non super admin cannot create roles', async () => {
  await assertFails(setDoc(doc(otherUser(), 'roles/plumber'), customRole()));
  await assertFails(setDoc(doc(guest(), 'roles/plumber'), customRole()));
});
test('custom role cannot pretend to be built-in', async () => {
  await assertFails(setDoc(doc(superAdmin(), 'roles/plumber'), customRole({ isBuiltIn: true })));
});
test('built-in role override must be marked built-in', async () => {
  await assertFails(setDoc(doc(superAdmin(), 'roles/architect'),
    customRole({ roleId: 'architect', name: 'Architect', isBuiltIn: false })));
  await assertSucceeds(setDoc(doc(superAdmin(), 'roles/architect'),
    customRole({ roleId: 'architect', name: 'Architect', isBuiltIn: true, isActive: false })));
});
test('unknown fields are rejected', async () => {
  await assertFails(setDoc(doc(superAdmin(), 'roles/plumber'), customRole({ points: 999 })));
});
test('length limits: name 2–40, short form ≤ 10', async () => {
  await assertFails(setDoc(doc(superAdmin(), 'roles/plumber'), customRole({ name: 'P' })));
  await assertFails(setDoc(doc(superAdmin(), 'roles/plumber'), customRole({ name: 'x'.repeat(41) })));
  await assertFails(setDoc(doc(superAdmin(), 'roles/plumber'), customRole({ abbreviation: 'x'.repeat(11) })));
  await assertSucceeds(setDoc(doc(superAdmin(), 'roles/plumber'), customRole({ name: 'x'.repeat(40), abbreviation: 'x'.repeat(10) })));
});
test('reserved and malformed role IDs are rejected', async () => {
  for (const id of ['admin', 'super_admin', 'Bad-ID', 'trailing_', '_x']) {
    await assertFails(setDoc(doc(superAdmin(), `roles/${id}`), customRole({ roleId: id })));
  }
});
test('roleId must match the document ID', async () => {
  await assertFails(setDoc(doc(superAdmin(), 'roles/plumber'), customRole({ roleId: 'other' })));
});
test('a new custom role must start active', async () => {
  await assertFails(setDoc(doc(superAdmin(), 'roles/plumber'), customRole({ isActive: false })));
});
test('timestamps must be server time', async () => {
  await assertFails(setDoc(doc(superAdmin(), 'roles/plumber'), customRole({ createdAt: new Date(2000, 1, 1) })));
});

// ── Updating (soft delete / restore) ────────────────────────────────────────
test('super admin can soft-delete and restore a custom role', async () => {
  await assertSucceeds(updateDoc(doc(superAdmin(), 'roles/mason'), { isActive: false, updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(superAdmin(), 'roles/painter'), { isActive: true, updatedAt: serverTimestamp() }));
});
test('other users cannot change roles', async () => {
  await assertFails(updateDoc(doc(otherUser(), 'roles/mason'), { isActive: false }));
});
test('carpenter can never be deactivated', async () => {
  await assertFails(setDoc(doc(superAdmin(), 'roles/carpenter'),
    customRole({ roleId: 'carpenter', name: 'Carpenter', isBuiltIn: true, isActive: false })));
});
test('update cannot flip isBuiltIn or add fields', async () => {
  await assertFails(updateDoc(doc(superAdmin(), 'roles/mason'), { isBuiltIn: true }));
  await assertFails(updateDoc(doc(superAdmin(), 'roles/mason'), { extra: 1 }));
});
test('roles can never be hard-deleted', async () => {
  await assertFails(deleteDoc(doc(superAdmin(), 'roles/mason')));
});

// ── Registration uses the live role list ────────────────────────────────────
const registration = (uid, role) => ({
  uid, role, roleId: role, roleName: role, roleAbbreviation: '',
  branchId: 'b1', branchCode: 'B1', phone: '9876543210',
});
test('a user can register with an active custom role', async () => {
  await assertSucceeds(setDoc(doc(otherUser('u2'), 'users/u2'), registration('u2', 'mason')));
});
test('a user cannot register with a deleted role', async () => {
  await assertFails(setDoc(doc(otherUser('u3'), 'users/u3'), registration('u3', 'painter')));
});
test('a user can register as a built-in role without a role document', async () => {
  await assertSucceeds(setDoc(doc(otherUser('u4'), 'users/u4'), registration('u4', 'engineer')));
});
test('nobody can self-register as admin or super admin', async () => {
  await assertFails(setDoc(doc(otherUser('u5'), 'users/u5'), registration('u5', 'admin')));
  await assertFails(setDoc(doc(otherUser('u6'), 'users/u6'), registration('u6', 'super_admin')));
});

// ── Editing ─────────────────────────────────────────────────────────────────
test('super admin can rename a role and its short form (ID unchanged)', async () => {
  await assertSucceeds(updateDoc(doc(superAdmin(), 'roles/mason'),
    { name: 'मिस्त्री', abbreviation: 'Mi.', updatedAt: serverTimestamp() }));
});
test('renaming the protected carpenter role is allowed (it stays active)', async () => {
  await assertSucceeds(setDoc(doc(superAdmin(), 'roles/carpenter'),
    customRole({ roleId: 'carpenter', name: 'Carpenter / Woodworker', isBuiltIn: true })));
});
test('role rename still enforces length limits', async () => {
  await assertFails(updateDoc(doc(superAdmin(), 'roles/mason'), { name: 'x'.repeat(41) }));
});

test('super admin can edit branch details but not the branch code', async () => {
  await assertSucceeds(updateDoc(doc(superAdmin(), 'branches/b1'),
    { name: 'Branch One (Renamed)', shortName: 'B-One', address: 'New road', phone: '9000000000' }));
  await assertFails(updateDoc(doc(superAdmin(), 'branches/b1'), { branchCode: 'NEW-1' }));
  await assertFails(updateDoc(doc(superAdmin(), 'branches/b1'), { name: 'X' }));
});
test('other users cannot edit branches', async () => {
  await assertFails(updateDoc(doc(otherUser(), 'branches/b1'), { name: 'Hacked' }));
});
