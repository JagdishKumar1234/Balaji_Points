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
//   E Road architect  9000000005 / PIN 5555
//   E Road engineer   9000000006 / PIN 6666
//   E Road interior designer 9000000007 / PIN 7777
//   Karur architect   9000000010 / PIN 1010
//   Karur engineer    9000000011 / PIN 1111
//   Karur interior designer 9000000012 / PIN 1212
//   Waiting sign-ups (cannot sign in until approved):
//     E Road carpenter 9000000013 / PIN 1313, Karur architect 9000000014 / PIN 1414
//   Rejected sign-up: Karur carpenter 9000000015 / PIN 1515
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
    // One member of each role in E Road, for the per-role points rate test.
    {phone: "9000000005", first: "Erode", last: "Architect", role: "architect", branch: "erode_main", pin: "5555"},
    {phone: "9000000006", first: "Erode", last: "Engineer", role: "engineer", branch: "erode_main", pin: "6666"},
    {phone: "9000000007", first: "Erode", last: "Designer", role: "interior_designer", branch: "erode_main", pin: "7777"},
    // All four roles in Karur too, for the role-group boards and spins.
    {phone: "9000000010", first: "Karur", last: "Architect", role: "architect", branch: "karur_test", pin: "1010"},
    {phone: "9000000011", first: "Karur", last: "Engineer", role: "engineer", branch: "karur_test", pin: "1111"},
    {phone: "9000000012", first: "Karur", last: "Designer", role: "interior_designer", branch: "karur_test", pin: "1212"},
    // Account approval: waiting and rejected sign-ups.
    {phone: "9000000013", first: "Waiting", last: "Erode", role: "carpenter", branch: "erode_main", pin: "1313",
      approval: "pending"},
    {phone: "9000000014", first: "Waiting", last: "Karur", role: "architect", branch: "karur_test", pin: "1414",
      approval: "pending"},
    {phone: "9000000015", first: "Rejected", last: "Karur", role: "carpenter", branch: "karur_test", pin: "1515",
      approval: "rejected"},
  ];
  for (const u of pinUsers) {
    await db.doc(`users/${u.phone}`).set({
      phone: u.phone, firstName: u.first, lastName: u.last, role: u.role, roleId: u.role,
      branchId: u.branch, status: "verified", totalPoints: 0, tier: "Bronze",
      profileImage: "https://example.com/test.png", fcmToken: `test-token-${u.phone}`,
      createdAt: now, ...pinFields(u.pin),
      // Members are approved unless the seed says otherwise.
      ...(u.role === "admin" ? {} : {
        profile_verified: !u.approval,
        approvalStatus: u.approval || "approved",
        approvalNotifiedAt: now,
        ...(u.approval === "rejected" ? {rejectReason: "Wrong branch"} : {}),
      }),
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
