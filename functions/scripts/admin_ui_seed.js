/**
 * Admin UI live check (2026-11-18): sample data in the inactive test branch
 * from notif_test_setup.js, so every admin screen has something to show.
 *   node scripts/admin_ui_seed.js           add members, a request, a bill
 *   node scripts/admin_ui_seed.js --remove  delete everything it added
 * Run notif_test_setup.js first (branch + test admin) and --remove both.
 */
const admin = require("firebase-admin");
admin.initializeApp({projectId: "balajipoints"});
const db = admin.firestore();
const {FieldValue, Timestamp} = require("firebase-admin/firestore");

const BRANCH = "test_branch_notif";
const MEMBERS = [
  {id: "uiseed_m1", first: "Ravi", last: "Kumar", role: "carpenter",
    phone: "9000000011", points: 42.5, tier: "Silver"},
  {id: "uiseed_m2", first: "Priya", last: "Sundaram", role: "architect",
    phone: "9000000012", points: 8, tier: "Bronze"},
  {id: "uiseed_m3", first: "", last: "", role: "interior_designer",
    phone: "9000000013", points: 0, tier: "Bronze"},
  {id: "uiseed_m4", first: "Arunachalam Venkatesan", last: "Subramaniyan",
    role: "engineer", phone: "9000000014", points: 1250, tier: "Gold"},
];
const REQUEST = {id: "uiseed_req", first: "Suresh", last: "M",
  role: "carpenter", phone: "9000000015"};
const BILL = "uiseed_bill1";

(async () => {
  if (process.argv.includes("--remove")) {
    for (const m of [...MEMBERS, REQUEST]) {
      await db.doc(`users/${m.id}`).delete();
      await db.doc(`user_points/${m.id}`).delete();
    }
    await db.doc(`bills/${BILL}`).delete();
    const logs = await db.collection("notification_logs")
        .where("branchId", "==", BRANCH).get();
    for (const d of logs.docs) await d.ref.delete();
    const q = await db.collection("notification_queue")
        .where("branchId", "==", BRANCH).get();
    for (const d of q.docs) await d.ref.delete();
    console.log(`removed seed data (+${logs.size} logs, ${q.size} queued)`);
    process.exit(0);
  }
  const now = Date.now();
  for (const [i, m] of MEMBERS.entries()) {
    await db.doc(`users/${m.id}`).set({
      uid: m.id, userId: m.id, firstName: m.first, lastName: m.last,
      phone: m.phone, role: m.role, branchId: BRANCH,
      branchName: "Test Branch (notifications)", status: "active",
      tier: m.tier, totalPoints: m.points, profile_verified: true,
      approvalStatus: "approved", createdByAdmin: true,
      createdAt: Timestamp.fromMillis(now - (i + 1) * 86400000 * 9),
    });
    await db.doc(`user_points/${m.id}`).set({
      userId: m.id, branchId: BRANCH, totalPoints: m.points, tier: m.tier,
    });
  }
  // A self sign-up waiting for approval (the server notifies the admin).
  await db.doc(`users/${REQUEST.id}`).set({
    uid: REQUEST.id, userId: REQUEST.id, firstName: REQUEST.first,
    lastName: REQUEST.last, phone: REQUEST.phone, role: REQUEST.role,
    branchId: BRANCH, status: "active",
    createdAt: FieldValue.serverTimestamp(),
  });
  // A bill waiting for review (the server notifies the admin).
  await db.doc(`bills/${BILL}`).set({
    billId: BILL, billNumber: "UI-001", carpenterId: "uiseed_m1",
    carpenterPhone: "9000000011", amount: 24500, siteName: "Gandhi Nagar",
    billDate: Timestamp.fromMillis(now - 86400000), status: "pending",
    branchId: BRANCH, imageUrl: "", createdAt: FieldValue.serverTimestamp(),
  });
  console.log("seeded: 4 members, 1 request, 1 pending bill");
  process.exit(0);
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
