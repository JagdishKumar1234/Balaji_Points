/**
 * Daily spin live test (2026-11-18): a test branch with members of all 4
 * roles. Most have a bill approved today (so they qualify for the draw);
 * one per group has none (must never win). Plus a test branch admin.
 *   TEST_ADMIN_PASS=... node scripts/spin_test_setup.js   create
 *   node scripts/spin_test_setup.js --remove              delete everything
 * Members sign in with PIN 1234.
 */
const admin = require("firebase-admin");
const crypto = require("crypto");
admin.initializeApp({projectId: "balajipoints"});
const db = admin.firestore();
const {FieldValue, Timestamp} = require("firebase-admin/firestore");

const BRANCH = "test_branch_spin";
const BRANCH_NAME = "Test Branch (spin)";
const ADMIN_EMAIL = "spin.test.admin@balajipoints.test";
const ADMIN_PASS = process.env.TEST_ADMIN_PASS;

// [id, first, last, role, phone, bills approved today (₹ amounts)]
const MEMBERS = [
  ["spintest_c1", "Ravi", "Carpenter", "carpenter", "9000000201", [12000]],
  ["spintest_c2", "Mani", "Carpenter", "carpenter", "9000000202", [8000, 4000]],
  ["spintest_c3", "Selva", "Carpenter", "carpenter", "9000000203", [25000]],
  ["spintest_i1", "Divya", "Interior", "interior_designer", "9000000204", [30000]],
  ["spintest_i2", "Kavya", "Interior", "interior_designer", "9000000205", [15000]],
  ["spintest_c0", "NoBill", "Carpenter", "carpenter", "9000000206", []],
  ["spintest_a1", "Arun", "Architect", "architect", "9000000207", [60000]],
  ["spintest_a2", "Priya", "Architect", "architect", "9000000208", [45000]],
  ["spintest_e1", "Kumar", "Engineer", "engineer", "9000000209", [70000]],
  ["spintest_e2", "Lakshmi", "Engineer", "engineer", "9000000210", [52000]],
  ["spintest_a0", "NoBill", "Architect", "architect", "9000000211", []],
];
const RATE = {carpenter: 1000, interior_designer: 1000,
  architect: 5000, engineer: 5000};
const ROLE_NAME = {carpenter: "Carpenter", interior_designer: "Interior Designer",
  architect: "Architect", engineer: "Engineer"};

/** YYYY-MM-DD in India time, the same day key the app uses. */
function todayKey() {
  return new Intl.DateTimeFormat("en-CA", {timeZone: "Asia/Kolkata",
    year: "numeric", month: "2-digit", day: "2-digit"}).format(new Date());
}

async function deleteWhere(col, field, value) {
  const s = await db.collection(col).where(field, "==", value).get();
  for (const d of s.docs) await d.ref.delete();
  return s.size;
}

(async () => {
  if (process.argv.includes("--remove")) {
    const u = await admin.auth().getUserByEmail(ADMIN_EMAIL).catch(() => null);
    if (u) {
      await admin.auth().deleteUser(u.uid);
      await db.doc(`users/${u.uid}`).delete();
    }
    for (const [id] of MEMBERS) {
      await db.doc(`users/${id}`).delete();
      await db.doc(`user_points/${id}`).delete();
    }
    const n = {
      bills: await deleteWhere("bills", "branchId", BRANCH),
      winners: await deleteWhere("daily_winners", "branchId", BRANCH),
      history: await deleteWhere("daily_prize_winners", "branchId", BRANCH),
      logs: await deleteWhere("notification_logs", "branchId", BRANCH),
      queue: await deleteWhere("notification_queue", "branchId", BRANCH),
    };
    await db.doc(`branches/${BRANCH}`).delete();
    console.log("removed test branch, admin, members", JSON.stringify(n));
    process.exit(0);
  }
  if (!ADMIN_PASS) throw new Error("set TEST_ADMIN_PASS");

  for (const m of MEMBERS) {
    const clash = await db.collection("users").where("phone", "==", m[4]).get();
    if (clash.docs.some((d) => d.id !== m[0])) {
      throw new Error(`phone ${m[4]} in use`);
    }
  }

  // Active so the test admin can sign in; removed after the test.
  await db.doc(`branches/${BRANCH}`).set({
    name: BRANCH_NAME, shortName: "Test Spin", isActive: true,
    createdBy: "spin-test", createdAt: FieldValue.serverTimestamp(),
  });

  const today = todayKey();
  for (const [id, first, last, role, phone, bills] of MEMBERS) {
    const salt = crypto.randomBytes(16).toString("base64url");
    const pinHash = crypto.createHash("sha256").update(`1234::${salt}`)
        .digest("hex");
    const points = bills.reduce((t, a) => t + a / RATE[role], 0);
    await db.doc(`users/${id}`).set({
      uid: id, userId: id, phone, phoneNumber: phone,
      firstName: first, lastName: last, role, roleId: role,
      roleName: ROLE_NAME[role], branchId: BRANCH, branchName: BRANCH_NAME,
      branchShortName: "Test Spin", status: "active", tier: "Bronze",
      totalPoints: points, profile_verified: true, approvalStatus: "approved",
      createdByAdmin: true, pinHash, pinSalt: salt,
      createdAt: FieldValue.serverTimestamp(),
    });
    await db.doc(`user_points/${id}`).set({
      userId: id, branchId: BRANCH, totalPoints: points, tier: "Bronze",
    });
    for (const [i, amount] of bills.entries()) {
      const billId = `${id}_bill${i + 1}`;
      await db.doc(`bills/${billId}`).set({
        billId, billNumber: `SPIN-${id.slice(-2)}-${i + 1}`,
        carpenterId: id, carpenterPhone: phone, amount,
        siteName: "Spin test site", branchId: BRANCH, imageUrl: "",
        status: "approved", pointsEarned: amount / RATE[role],
        rupeesPerPoint: RATE[role], approvedBy: "spin-test",
        approvedAt: FieldValue.serverTimestamp(), approvedDate: today,
        billDate: Timestamp.now(), createdAt: FieldValue.serverTimestamp(),
      });
    }
  }

  let u = await admin.auth().getUserByEmail(ADMIN_EMAIL).catch(() => null);
  if (!u) {
    u = await admin.auth().createUser({email: ADMIN_EMAIL,
      password: ADMIN_PASS, emailVerified: true});
  } else {
    await admin.auth().updateUser(u.uid, {password: ADMIN_PASS});
  }
  await db.doc(`users/${u.uid}`).set({
    uid: u.uid, userId: u.uid, email: ADMIN_EMAIL, role: "admin",
    firstName: "Spin", lastName: "Admin", phone: "9000000200",
    branchId: BRANCH, branchName: BRANCH_NAME, status: "active",
    createdAt: FieldValue.serverTimestamp(),
  });
  console.log(`ready (${today}): branch ${BRANCH}, ${MEMBERS.length} members,`,
      `admin ${ADMIN_EMAIL}`);
  process.exit(0);
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
