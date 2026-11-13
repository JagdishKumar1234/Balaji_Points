// Storage rules tests for catalog uploads (run inside the emulators).
// Run: npx firebase emulators:exec --only firestore,storage --project demo-balaji-rules "node --test storage.rules.test.mjs"
import { readFileSync } from 'node:fs';
import { test, before, after } from 'node:test';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import { doc, setDoc } from 'firebase/firestore';
import { ref, uploadBytes } from 'firebase/storage';

let env;
const img = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]);
const pdf = new TextEncoder().encode('%PDF-1.4 test');

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-balaji-rules',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
    storage: { rules: readFileSync('../storage.rules', 'utf8') },
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/emailAdmin'), { role: 'admin', branchId: 'b1' });
    await setDoc(doc(db, 'users/member1'), { role: 'carpenter', branchId: 'b1' });
  });
});
after(async () => env.cleanup());

const upload = (ctx, path, bytes, type) =>
  uploadBytes(ref(ctx.storage(), path), bytes, { contentType: type });

test('PIN admin (role in sign-in) can upload catalog files', async () => {
  const pinAdmin = env.authenticatedContext('pinAdminDoc', { role: 'admin', branchId: 'b1' });
  await assertSucceeds(upload(pinAdmin, 'catalogs/c1/cover_1.jpg', img, 'image/jpeg'));
  await assertSucceeds(upload(pinAdmin, 'catalogs/c1/v1.pdf', pdf, 'application/pdf'));
});

test('super admin by verified email can upload', async () => {
  const sa = env.authenticatedContext('sa', {
    email: 'aaijitechstudio@gmail.com', email_verified: true,
  });
  await assertSucceeds(upload(sa, 'catalogs/c2/cover_1.jpg', img, 'image/jpeg'));
});

test('email admin found in Firestore can upload', async () => {
  const emailAdmin = env.authenticatedContext('emailAdmin', { email: 'a@b.test' });
  await assertSucceeds(upload(emailAdmin, 'catalogs/c3/cover_1.jpg', img, 'image/jpeg'));
});

test('members and guests cannot upload; covers must be images', async () => {
  const member = env.authenticatedContext('member1');
  await assertFails(upload(member, 'catalogs/c4/cover_1.jpg', img, 'image/jpeg'));
  await assertFails(upload(env.unauthenticatedContext(), 'catalogs/c4/cover_1.jpg', img, 'image/jpeg'));
  // A claim of some other role does not help.
  const fake = env.authenticatedContext('x', { role: 'carpenter' });
  await assertFails(upload(fake, 'catalogs/c4/cover_1.jpg', img, 'image/jpeg'));
  const pinAdmin = env.authenticatedContext('pinAdminDoc', { role: 'admin' });
  await assertFails(upload(pinAdmin, 'catalogs/c4/cover_1.jpg', img, 'text/html'));
});
