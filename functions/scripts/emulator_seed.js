// Fills the LOCAL Firebase emulators with test branches and test accounts for
// end-to-end flow tests. Refuses to run unless pointed at the emulators, so it
// can never write to live data.
//
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
//     node scripts/emulator_seed.js
//
// Test logins created (local only):
//   E Road carpenter  9000000001 / PIN 1111
//   Karur carpenter   9000000002 / PIN 2222
//   E Road admin      9000000003 / PIN 3333
//   Karur admin       karur.admin@test.local / Test@12345
//   Super admin       aaijitechstudio@gmail.com / TestSuper@123
const crypto = require("crypto");
const admin = require("firebase-admin");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error("Refusing to run: FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST must point at the emulators.");
  process.exit(1);
}

admin.initializeApp({projectId: process.env.GCLOUD_PROJECT || "balajipoints"});
const db = admin.firestore();
const auth = admin.auth();
const now = admin.firestore.FieldValue.serverTimestamp();

const pinFields = (pin) => {
  const salt = crypto.randomBytes(16).toString("hex");
  const hash = crypto.createHash("sha256").update(`${pin}::${salt}`).digest("hex");
  return {pinHash: hash, pinSalt: salt};
};

async function authUser(email, password, name) {
  try {
    return (await auth.getUserByEmail(email)).uid;
  } catch (_) {
    return (await auth.createUser({email, password, displayName: name, emailVerified: true})).uid;
  }
}

async function main() {
  await db.doc("app_config/version").set({
    androidLatestVersion: "1.0.19", androidMinimumVersion: "1.0.19", androidForceUpdate: true,
    androidUpdateUrl: "https://play.google.com/store/apps/details?id=com.balaji.points",
    iosLatestVersion: "1.0.12", iosMinimumVersion: "1.0.12", iosForceUpdate: false, iosUpdateUrl: "",
  });
  await db.doc("branches/erode_main").set({
    name: "TEST E Road", shortName: "TEST E Road", branchCode: "erode_main",
    address: "Test address", phone: "9000000000", isActive: true, diwaliCelebrationEnabled: false, createdAt: now,
  });
  await db.doc("branches/karur_test").set({
    name: "TEST Karur", shortName: "TEST Karur", branchCode: "karur_test",
    address: "Test address", phone: "9000000009", isActive: true, diwaliCelebrationEnabled: false, createdAt: now,
  });

  const pinUsers = [
    {phone: "9000000001", first: "Erode", last: "Carpenter", role: "carpenter", branch: "erode_main", pin: "1111"},
    {phone: "9000000002", first: "Karur", last: "Carpenter", role: "carpenter", branch: "karur_test", pin: "2222"},
    {phone: "9000000003", first: "Erode", last: "Admin", role: "admin", branch: "erode_main", pin: "3333"},
  ];
  for (const u of pinUsers) {
    await db.doc(`users/${u.phone}`).set({
      phone: u.phone, firstName: u.first, lastName: u.last, role: u.role, roleId: u.role,
      branchId: u.branch, status: "verified", totalPoints: 0, tier: "Bronze",
      profileImage: "https://example.com/test.png", fcmToken: `test-token-${u.phone}`,
      createdAt: now, ...pinFields(u.pin),
    });
    if (u.role !== "admin") {
      await db.doc(`user_points/${u.phone}`).set({
        userId: u.phone, branchId: u.branch, totalPoints: 0, tier: "Bronze", pointsHistory: [], lastUpdated: now,
      });
    }
  }

  const karurAdmin = await authUser("karur.admin@test.local", "Test@12345", "Karur Admin");
  await db.doc(`users/${karurAdmin}`).set({
    uid: karurAdmin, email: "karur.admin@test.local", firstName: "Karur", lastName: "Admin",
    phone: "9000000004", role: "admin", roleId: "admin", branchId: "karur_test", status: "verified",
    fcmToken: "test-token-karur-admin", createdAt: now,
  });
  await db.doc("branches/karur_test").set({adminUid: karurAdmin}, {merge: true});
  await authUser("aaijitechstudio@gmail.com", "TestSuper@123", "Super Admin");

  const counts = {};
  for (const c of ["branches", "users", "user_points"]) counts[c] = (await db.collection(c).get()).size;
  console.log("Seeded emulators:", JSON.stringify(counts));
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
