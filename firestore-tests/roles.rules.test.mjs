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
  doc, getDoc, getDocs, collection, setDoc, updateDoc, deleteDoc, query, where,
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

// ── Points rate per role ────────────────────────────────────────────────────
test('super admin can set rupees per point on a role', async () => {
  await assertSucceeds(setDoc(doc(superAdmin(), 'roles/plumber'), customRole({ rupeesPerPoint: 2000 })));
  await assertSucceeds(updateDoc(doc(superAdmin(), 'roles/mason'), {
    rupeesPerPoint: 5000, updatedAt: serverTimestamp(),
  }));
});

test('rupees per point must be a number from 1 to 10,00,000', async () => {
  await assertFails(setDoc(doc(superAdmin(), 'roles/plumber'), customRole({ rupeesPerPoint: 0 })));
  await assertFails(setDoc(doc(superAdmin(), 'roles/plumber'), customRole({ rupeesPerPoint: 2000000 })));
  await assertFails(setDoc(doc(superAdmin(), 'roles/plumber'), customRole({ rupeesPerPoint: '1000' })));
});

test('a built-in role can carry its own rate', async () => {
  await assertSucceeds(setDoc(doc(superAdmin(), 'roles/engineer'), {
    roleId: 'engineer', name: 'Engineer', abbreviation: 'Er.', isActive: true, isBuiltIn: true,
    rupeesPerPoint: 5000, createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
});

test('other users cannot change a role rate', async () => {
  await assertFails(updateDoc(doc(otherUser(), 'roles/mason'), {
    rupeesPerPoint: 1, updatedAt: serverTimestamp(),
  }));
});

// ── Product catalogs ────────────────────────────────────────────────────────
const seedCatalogs = () => env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, 'users/adm'), { role: 'admin', branchId: 'b1' });
  await setDoc(doc(db, 'users/mem'), { role: 'carpenter', branchId: 'b1' });
  await setDoc(doc(db, 'catalog_categories/doors'), { name: 'Doors' });
  await setDoc(doc(db, 'catalogs/kanb'), { categoryId: 'doors', title: 'Kan-B' });
});
const branchAdmin = () =>
  env.authenticatedContext('adm', { email: 'a@test.local', email_verified: false }).firestore();
const member = () => env.authenticatedContext('mem').firestore();

test('anyone can read catalogs and categories', async () => {
  await seedCatalogs();
  await assertSucceeds(getDocs(collection(guest(), 'catalog_categories')));
  await assertSucceeds(getDoc(doc(member(), 'catalogs/kanb')));
});
test('branch admin and super admin can manage catalogs', async () => {
  await seedCatalogs();
  for (const db of [branchAdmin(), superAdmin()]) {
    await assertSucceeds(setDoc(doc(db, 'catalog_categories/plywood'), { name: 'Plywood' }));
    await assertSucceeds(setDoc(doc(db, 'catalogs/saburi'), { categoryId: 'plywood', title: 'Saburi' }));
    await assertSucceeds(updateDoc(doc(db, 'catalogs/saburi'), { active: false }));
    await assertSucceeds(deleteDoc(doc(db, 'catalogs/saburi')));
  }
});
test('members, guests and unknown users cannot change catalogs', async () => {
  await seedCatalogs();
  for (const db of [guest(), member(), otherUser()]) {
    await assertFails(setDoc(doc(db, 'catalogs/x'), { categoryId: 'doors', title: 'X' }));
    await assertFails(updateDoc(doc(db, 'catalogs/kanb'), { active: false }));
    await assertFails(deleteDoc(doc(db, 'catalogs/kanb')));
    await assertFails(setDoc(doc(db, 'catalog_categories/x'), { name: 'Xyz' }));
  }
});
test('catalog must point at an existing category and have a title', async () => {
  await seedCatalogs();
  await assertFails(setDoc(doc(branchAdmin(), 'catalogs/y'), { categoryId: 'nope', title: 'Y' }));
  await assertFails(setDoc(doc(branchAdmin(), 'catalogs/y'), { categoryId: 'doors' }));
  await assertFails(setDoc(doc(branchAdmin(), 'catalog_categories/z'), { name: 'Z' }));
});

// ── Contact Us enquiries ───────────────────────────────────────────────────
async function seedEnquiryUsers() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/adm'), { role: 'admin', branchId: 'b1' });
    await setDoc(doc(db, 'users/adm2'), { role: 'admin', branchId: 'b2' });
    await setDoc(doc(db, 'branches/b2'), { isActive: true, branchCode: 'B2', name: 'Branch 2' });
    await setDoc(doc(db, 'enquiries/m1'), {
      type: 'product', name: 'Ravi', phone: '9876543210', message: 'Need plywood rates',
      source: 'member', status: 'new', userId: 'u9', branchId: 'b1', role: 'carpenter',
    });
    await setDoc(doc(db, 'enquiries/g1'), {
      type: 'membership', name: 'Guest', phone: '9876543211', message: 'How do I join?',
      source: 'guest', status: 'new',
    });
  });
}
const memberEnquiry = (over = {}) => ({
  type: 'points_bills', name: 'Ravi Kumar', phone: '9876543210',
  message: 'My bill is still pending since Monday', source: 'member',
  status: 'new', createdAt: serverTimestamp(), platform: 'android', appVersion: '1.1.2',
  userId: 'u9', branchId: 'b1', branchName: 'Branch 1', role: 'architect', ...over,
});
const guestEnquiry = (over = {}) => ({
  type: 'quotation', name: 'Suresh', phone: '9123456780',
  message: 'Need a quote for 40 doors', source: 'guest', status: 'new',
  createdAt: serverTimestamp(), city: 'Erode', ...over,
});
const branchAdmin2 = () =>
  env.authenticatedContext('adm2', { email: 'b@test.local' }).firestore();

test('a PIN member (no sign-in) and a guest can send an enquiry', async () => {
  await seedEnquiryUsers();
  await assertSucceeds(setDoc(doc(guest(), 'enquiries/new1'), memberEnquiry()));
  await assertSucceeds(setDoc(doc(guest(), 'enquiries/new2'), guestEnquiry()));
});

test('enquiries with bad or extra fields are refused', async () => {
  await seedEnquiryUsers();
  const db = guest();
  await assertFails(setDoc(doc(db, 'enquiries/x1'), memberEnquiry({ phone: '12345' })));
  await assertFails(setDoc(doc(db, 'enquiries/x2'), memberEnquiry({ message: 'hi' })));
  await assertFails(setDoc(doc(db, 'enquiries/x3'), memberEnquiry({ type: 'spam' })));
  await assertFails(setDoc(doc(db, 'enquiries/x4'), memberEnquiry({ status: 'resolved' })));
  await assertFails(setDoc(doc(db, 'enquiries/x5'), memberEnquiry({ isAdmin: true })));
  await assertFails(setDoc(doc(db, 'enquiries/x6'), memberEnquiry({ branchId: 'nope' })));
  await assertFails(setDoc(doc(db, 'enquiries/x7'), memberEnquiry({ role: 'admin' })));
  await assertFails(setDoc(doc(db, 'enquiries/x8'), memberEnquiry({ createdAt: new Date(0) })));
  // A guest cannot claim a role or user, nor pick an unknown branch.
  await assertFails(setDoc(doc(db, 'enquiries/x9'), guestEnquiry({ branchId: 'nope' })));
  await assertFails(setDoc(doc(db, 'enquiries/x10'), guestEnquiry({ role: 'carpenter' })));
  await assertFails(setDoc(doc(db, 'enquiries/x11'), guestEnquiry({ userId: 'u1' })));
  await assertFails(setDoc(doc(db, 'enquiries/x12'), guestEnquiry({ type: 'career', position: 'x'.repeat(61) })));
});

test('a branch admin reads only their own branch; guests go to super admin', async () => {
  await seedEnquiryUsers();
  await assertSucceeds(getDoc(doc(branchAdmin(), 'enquiries/m1')));
  await assertSucceeds(getDocs(query(collection(branchAdmin(), 'enquiries'), where('branchId', '==', 'b1'))));
  await assertFails(getDoc(doc(branchAdmin2(), 'enquiries/m1')));
  await assertFails(getDoc(doc(branchAdmin(), 'enquiries/g1')));
  await assertFails(getDocs(collection(branchAdmin(), 'enquiries')));
  await assertSucceeds(getDocs(collection(superAdmin(), 'enquiries')));
  await assertFails(getDoc(doc(guest(), 'enquiries/m1')));
  await assertFails(getDocs(collection(guest(), 'enquiries')));
});

test('admins can only mark an enquiry resolved or open again', async () => {
  await seedEnquiryUsers();
  await assertSucceeds(updateDoc(doc(branchAdmin(), 'enquiries/m1'),
    { status: 'resolved', resolvedAt: serverTimestamp(), resolvedBy: 'adm' }));
  await assertFails(updateDoc(doc(branchAdmin(), 'enquiries/m1'), { message: 'edited' }));
  await assertFails(updateDoc(doc(branchAdmin2(), 'enquiries/m1'), { status: 'resolved' }));
  await assertFails(updateDoc(doc(guest(), 'enquiries/m1'), { status: 'resolved' }));
  await assertSucceeds(updateDoc(doc(superAdmin(), 'enquiries/g1'), { status: 'resolved' }));
  await assertFails(deleteDoc(doc(branchAdmin(), 'enquiries/m1')));
  await assertSucceeds(deleteDoc(doc(superAdmin(), 'enquiries/g1')));
});

test('a guest can pick a branch; that branch admin reads it, others cannot', async () => {
  await seedEnquiryUsers();
  await assertSucceeds(setDoc(doc(guest(), 'enquiries/gb'),
    guestEnquiry({ branchId: 'b1', branchName: 'Branch 1' })));
  await assertSucceeds(setDoc(doc(guest(), 'enquiries/gc'),
    guestEnquiry({ type: 'career', branchId: 'b2', position: 'Sales executive',
      experience: '3 years', message: 'I have worked in a hardware store' })));
  await assertSucceeds(setDoc(doc(guest(), 'enquiries/gs'),
    guestEnquiry({ type: 'service', branchId: 'b1' })));
  // A store owner asking to partner: no branch, super admin reads it.
  await assertSucceeds(setDoc(doc(guest(), 'enquiries/gp'),
    guestEnquiry({ type: 'partner' })));
  await assertSucceeds(getDoc(doc(superAdmin(), 'enquiries/gp')));
  await assertFails(getDoc(doc(branchAdmin(), 'enquiries/gp')));
  await assertSucceeds(getDoc(doc(branchAdmin(), 'enquiries/gb')));
  await assertFails(getDoc(doc(branchAdmin(), 'enquiries/gc')));
  await assertSucceeds(getDoc(doc(branchAdmin2(), 'enquiries/gc')));
  await assertSucceeds(getDocs(query(collection(superAdmin(), 'enquiries'), where('source', '==', 'guest'))));
});

test('every member role can send to its own branch; that admin reads it', async () => {
  await seedEnquiryUsers();
  for (const role of ['carpenter', 'architect', 'engineer', 'interior_designer', 'mason']) {
    await assertSucceeds(setDoc(doc(guest(), `enquiries/r_${role}`),
      memberEnquiry({ role, branchId: 'b1' })));
    await assertSucceeds(getDoc(doc(branchAdmin(), `enquiries/r_${role}`)));
    await assertFails(getDoc(doc(branchAdmin2(), `enquiries/r_${role}`)));
  }
});
