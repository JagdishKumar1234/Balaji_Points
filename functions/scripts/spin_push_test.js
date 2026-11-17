/**
 * Live test of the spin pushes on test_branch_spin only (2026-11-18).
 *   node scripts/spin_push_test.js reset
 *       delete today's test draws and their notifications
 *   node scripts/spin_push_test.js remind <tokenFromUserId>
 *       put that user's phone token on the test admin, then run the same
 *       reminder code as the 6 PM job, for the test branch only
 *   node scripts/spin_push_test.js draw <trade|professional> [notWinner]
 *       [tokenToWinnerFrom]
 *       save a draw like the app does (random qualified member + random
 *       prize); the deployed onDailyWinnerCreated sends the pushes.
 *       notWinner: a user who must not win (so they get "Today's winner").
 *       tokenToWinnerFrom: copy that user's phone token to the winner first
 *       (so the phone gets "You won").
 */
const admin = require("firebase-admin");
admin.initializeApp({projectId: "balajipoints"});
const db = admin.firestore();
const {FieldValue} = require("firebase-admin/firestore");
const spin = require("../spin_notify");
const {sendSpinReminders} = require("../spin_jobs");

const BRANCH = "test_branch_spin";
const PRIZES = [
  ["power_drill", "Power Drill Machine"], ["circular_saw", "Circular Saw Machine"],
  ["tool_box", "Tool Box"], ["hammer", "Hammer"],
  ["screwdriver_kit", "Screwdriver / Tool Kit"],
  ["measuring_tape", "Measuring Tape"], ["aluminium_ladder", "Aluminium Ladder"],
  ["hand_planer", "Hand Planer"], ["drill_bit_set", "Drill Bit Set"],
  ["tool_accessory_kit", "Tool Accessory Kit"],
];
const pick = (list) => list[Math.floor(Math.random() * list.length)];

async function tokenOf(userId) {
  const t = (await db.doc(`users/${userId}`).get()).get("fcmToken");
  if (!t) throw new Error(`${userId} has no phone token`);
  return t;
}

(async () => {
  const [cmd, a1, a2, a3] = process.argv.slice(2);
  const day = spin.istDayKey(new Date());

  if (cmd === "reset") {
    let n = 0;
    for (const col of ["daily_winners", "daily_prize_winners"]) {
      const s = await db.collection(col).where("branchId", "==", BRANCH).get();
      for (const d of s.docs) {
        if (d.get("date") === day) {
          await d.ref.delete();
          n++;
        }
      }
    }
    const logs = await db.collection("notification_logs")
        .where("branchId", "==", BRANCH).get();
    let l = 0;
    for (const d of logs.docs) {
      if (/^(spinWin_|spinResult_|spinReminder_)/.test(d.id)) {
        await d.ref.delete();
        l++;
      }
    }
    const notices = await db.collection("spin_notices")
        .where("branchId", "==", BRANCH).get();
    for (const d of notices.docs) await d.ref.delete();
    console.log(`reset ${day}: ${n} draw records, ${l} spin notifications`);
  } else if (cmd === "remind") {
    const admins = await db.collection("users").where("branchId", "==", BRANCH)
        .where("role", "==", "admin").get();
    const token = await tokenOf(a1);
    for (const d of admins.docs) await d.ref.update({fcmToken: token});
    const res = await sendSpinReminders(db, admin.messaging(),
        {branchIds: [BRANCH]});
    console.log("reminder:", JSON.stringify(res));
  } else if (cmd === "draw") {
    const group = a1;
    if (!spin.GROUP_ROLES[group]) throw new Error("group: trade|professional");
    const bills = await db.collection("bills").where("branchId", "==", BRANCH)
        .where("status", "==", "approved").where("approvedDate", "==", day)
        .get();
    const users = await db.collection("users").where("branchId", "==", BRANCH)
        .get();
    const byId = new Map(users.docs.map((d) => [d.id, d.data()]));
    const qualified = [...new Set(bills.docs.map((d) => d.get("carpenterId")))]
        .filter((id) => byId.has(id) &&
          spin.groupOfRole(byId.get(id).role) === group &&
          byId.get(id).profile_verified === true)
        .sort();
    const pool = qualified.filter((id) => id !== a2);
    if (pool.length === 0) throw new Error("nobody qualified");
    const winnerId = pick(pool);
    const [prizeId, prizeName] = pick(PRIZES);
    if (a3) {
      await db.doc(`users/${winnerId}`).update({fcmToken: await tokenOf(a3)});
    }
    const u = byId.get(winnerId);
    const sales = bills.docs.filter((d) => d.get("carpenterId") === winnerId);
    const rec = {
      branchId: BRANCH, group, role: u.role, carpenterId: winnerId,
      carpenterName: `${u.firstName} ${u.lastName}`.trim(),
      carpenterPhoto: "", billsCount: sales.length,
      todaySales: sales.reduce((t, d) => t + d.get("amount"), 0),
      eligibleCount: qualified.length, prizeId, prizeName, date: day,
      timestamp: FieldValue.serverTimestamp(),
    };
    await db.doc(`daily_winners/${BRANCH}_${group}_${day}`).create(rec);
    await db.collection("daily_prize_winners").add(rec);
    console.log(`draw ${group}: ${rec.carpenterName} (${winnerId}) won ` +
      `${prizeName}; ${qualified.length} qualified`);
  } else {
    throw new Error("command: reset | remind | draw");
  }
  process.exit(0);
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
