/**
 * Live push test setup (2026-11-17): an inactive Test Branch, one test member
 * (phone 9000000001, PIN 1234) and one test branch admin (email/password).
 *   node scripts/notif_test_setup.js          create
 *   node scripts/notif_test_setup.js --remove delete all of it
 */
const admin = require("firebase-admin");
const crypto = require("crypto");
admin.initializeApp({projectId: "balajipoints"});
const db = admin.firestore();
const {FieldValue} = require("firebase-admin/firestore");

const BRANCH = "test_branch_notif";
const PHONE = "9000000001";
const MEMBER = "test_member_notif";
const ADMIN_EMAIL = "notif.test.admin@balajipoints.test";
const ADMIN_PASS = process.env.TEST_ADMIN_PASS;

(async () => {
  if (process.argv.includes("--remove")) {
    const u = await admin.auth().getUserByEmail(ADMIN_EMAIL).catch(() => null);
    if (u) {
      await admin.auth().deleteUser(u.uid);
      await db.doc(`users/${u.uid}`).delete();
    }
    await db.doc(`users/${MEMBER}`).delete();
    await db.doc(`user_points/${MEMBER}`).delete();
    await db.doc(`branches/${BRANCH}`).delete();
    const logs = await db.collection("notification_logs")
        .where("branchId", "==", BRANCH).get();
    for (const d of logs.docs) await d.ref.delete();
    console.log(`removed (and ${logs.size} test notification records)`);
    process.exit(0);
  }
  const clash = await db.collection("users").where("phone", "==", PHONE).get();
  if (clash.docs.some((d) => d.id !== MEMBER)) throw new Error("phone in use");

  await db.doc(`branches/${BRANCH}`).set({
    name: "Test Branch (notifications)", shortName: "Test Branch",
    isActive: false, createdBy: "notif-test", createdAt: FieldValue.serverTimestamp(),
  });
  const salt = crypto.randomBytes(16).toString("base64url");
  const pinHash = crypto.createHash("sha256").update(`1234::${salt}`)
      .digest("hex");
  await db.doc(`users/${MEMBER}`).set({
    uid: MEMBER, userId: MEMBER, phone: PHONE, phoneNumber: PHONE,
    firstName: "Test", lastName: "Member", role: "carpenter",
    roleId: "carpenter", roleName: "Carpenter",
    branchId: BRANCH, branchName: "Test Branch (notifications)",
    branchShortName: "Test Branch", status: "active", tier: "Bronze",
    totalPoints: 0, profile_verified: true, approvalStatus: "approved",
    createdByAdmin: true, pinHash, pinSalt: salt,
    createdAt: FieldValue.serverTimestamp(),
  });
  await db.doc(`user_points/${MEMBER}`).set({totalPoints: 0}, {merge: true});

  let u = await admin.auth().getUserByEmail(ADMIN_EMAIL).catch(() => null);
  if (!u) {
    u = await admin.auth().createUser({email: ADMIN_EMAIL,
      password: ADMIN_PASS, emailVerified: true});
  } else {
    await admin.auth().updateUser(u.uid, {password: ADMIN_PASS});
  }
  await db.doc(`users/${u.uid}`).set({
    uid: u.uid, userId: u.uid, email: ADMIN_EMAIL, role: "admin",
    firstName: "Test", lastName: "Admin", branchId: BRANCH, status: "active",
    createdAt: FieldValue.serverTimestamp(),
  });
  console.log("ready: branch", BRANCH, "member", PHONE, "admin", u.uid);
  process.exit(0);
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
