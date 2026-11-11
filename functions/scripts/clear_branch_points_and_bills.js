// New-year reset for one branch: every account's points go to 0 (Bronze),
// points history is removed, and every bill of the branch is deleted.
// Accounts themselves are kept: logins, PINs, names, phones and profiles are
// never changed.
//
//   node scripts/clear_branch_points_and_bills.js erode_main <backupDir>           Report + backup
//   node scripts/clear_branch_points_and_bills.js erode_main <backupDir> --apply   Make the changes
//
// A full JSON backup of everything touched is always written first, and the
// run stops if the backup cannot be written. Needs admin access, for example
// after `gcloud auth application-default login`.
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

admin.initializeApp({projectId: process.env.GCLOUD_PROJECT || "balajipoints"});
const db = admin.firestore();
const {FieldValue, Timestamp} = admin.firestore;

const [branchId, backupDir] = process.argv.slice(2);
const apply = process.argv.includes("--apply");
// Bills still waiting for approval stay, so admins can approve them later.
const keepPending = process.argv.includes("--keep-pending");
// Only this branch's data, or data with no branch that belongs to its people.
const inBranch = (data) => !data.branchId || data.branchId === branchId;

const chunk = (list, size) => {
  const out = [];
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
  return out;
};
const plain = (value) => JSON.parse(JSON.stringify(value, (key, v) =>
  v instanceof Timestamp ? {_timestamp: v.toDate().toISOString()} : v));

async function main() {
  if (!branchId || branchId.startsWith("--") || !backupDir || backupDir.startsWith("--")) {
    throw new Error("Usage: <branchId> <backupDir> [--apply]");
  }
  const branch = await db.collection("branches").doc(branchId).get();
  if (!branch.exists) throw new Error(`Branch ${branchId} not found`);

  // 1. Everyone in the branch (members and admins): accounts are kept.
  const users = (await db.collection("users").where("branchId", "==", branchId).get()).docs;
  const keys = new Set();
  for (const u of users) {
    keys.add(u.id);
    const d = u.data();
    const phone = String(d.phone || "").replace(/\D/g, "");
    if (phone) keys.add(phone);
    if (d.uid) keys.add(String(d.uid));
  }
  const keyList = [...keys];

  // 2. Points records.
  const pointsDocs = [];
  for (const group of chunk(keyList.map((k) => db.collection("user_points").doc(k)), 300)) {
    for (const snap of await db.getAll(...group)) if (snap.exists) pointsDocs.push(snap);
  }

  // 3. Separate points history entries.
  const history = new Map();
  for (const snap of (await db.collection("points_history").where("branchId", "==", branchId).get()).docs) {
    history.set(snap.ref.path, snap);
  }
  for (const group of chunk(keyList, 30)) {
    for (const field of ["userId", "carpenterId"]) {
      for (const snap of (await db.collection("points_history").where(field, "in", group).get()).docs) {
        if (inBranch(snap.data())) history.set(snap.ref.path, snap);
      }
    }
  }

  // 4. Bills: the branch's own, plus older bills of these people with no branch.
  const bills = new Map();
  for (const snap of (await db.collection("bills").where("branchId", "==", branchId).get()).docs) {
    bills.set(snap.ref.path, snap);
  }
  for (const group of chunk(keyList, 30)) {
    for (const field of ["carpenterId", "carpenterPhone"]) {
      for (const snap of (await db.collection("bills").where(field, "in", group).get()).docs) {
        if (inBranch(snap.data())) bills.set(snap.ref.path, snap);
      }
    }
  }
  const keptPending = [];
  if (keepPending) {
    for (const [key, snap] of bills) {
      if (snap.data().status === "pending") {
        keptPending.push(snap);
        bills.delete(key);
      }
    }
  }

  // Backup first, always.
  fs.mkdirSync(backupDir, {recursive: true, mode: 0o700});
  const stamp = new Date().toISOString().replace(/[:.]/g, "-");
  const file = path.join(backupDir, `${branchId}_before_reset_${stamp}.json`);
  const backup = {
    branchId,
    takenAt: new Date().toISOString(),
    users: users.map((s) => ({id: s.id, data: plain(s.data())})),
    user_points: pointsDocs.map((s) => ({id: s.id, data: plain(s.data())})),
    points_history: [...history.values()].map((s) => ({id: s.id, data: plain(s.data())})),
    bills: [...bills.values()].map((s) => ({id: s.id, data: plain(s.data())})),
  };
  fs.writeFileSync(file, JSON.stringify(backup), {mode: 0o600});
  const check = JSON.parse(fs.readFileSync(file, "utf8"));
  if (check.users.length !== users.length || check.bills.length !== bills.size) {
    throw new Error("Backup check failed; nothing was changed.");
  }

  const roles = {};
  for (const u of users) {
    const r = u.data().role || "(none)";
    roles[r] = (roles[r] || 0) + 1;
  }
  const billStatus = {};
  for (const b of bills.values()) {
    const s = b.data().status || "(none)";
    billStatus[s] = (billStatus[s] || 0) + 1;
  }
  const pointsTotal = pointsDocs.reduce((t, s) => t + Number(s.data().totalPoints || 0), 0);

  console.log(apply ? "APPLYING CHANGES" : "DRY RUN: nothing will change");
  console.log(`Branch: ${branch.data().name || branchId}`);
  console.log(`Backup: ${file} (${(fs.statSync(file).size / 1024).toFixed(0)} KB)`);
  console.log(`Accounts kept, points set to 0: ${users.length} ${JSON.stringify(roles)}`);
  console.log(`Points records reset: ${pointsDocs.length} (total now ${pointsTotal.toFixed(2)})`);
  console.log(`Points history entries deleted: ${history.size}`);
  console.log(`Bills deleted: ${bills.size} ${JSON.stringify(billStatus)}`);
  if (keepPending) console.log(`Pending bills kept for admins: ${keptPending.length}`);
  const outside = [...bills.values(), ...history.values()]
      .filter((s) => !inBranch(s.data())).length;
  if (outside) throw new Error(`${outside} items from another branch were selected; nothing was changed.`);

  if (!apply) return;

  const writer = db.bulkWriter();
  let failed = 0;
  writer.onWriteError((error) => {
    if (error.failedAttempts < 3) return true;
    failed++;
    return false;
  });
  const now = FieldValue.serverTimestamp();
  for (const u of users) {
    const update = {totalPoints: 0, tier: "Bronze", lastUpdated: now};
    if (Array.isArray(u.data().pointsHistory)) update.pointsHistory = [];
    writer.set(u.ref, update, {merge: true});
  }
  for (const p of pointsDocs) {
    writer.set(p.ref, {totalPoints: 0, tier: "Bronze", pointsHistory: [], lastUpdated: now}, {merge: true});
  }
  for (const h of history.values()) writer.delete(h.ref);
  for (const b of bills.values()) writer.delete(b.ref);
  await writer.close();
  if (failed) throw new Error(`${failed} writes failed. Restore or retry from the backup: ${file}`);

  await db.collection("branch_points_cleanup_logs").add({
    branchId,
    usersReset: users.length,
    pointsDocumentsReset: pointsDocs.length,
    historyDocumentsDeleted: history.size,
    billsDeleted: bills.size,
    pendingBillsKept: keptPending.length,
    usersDeleted: 0,
    backupFile: path.basename(file),
    completedAt: now,
    createdBy: "admin script",
  });
  console.log("Done.");
}

main().then(() => process.exit(0)).catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
