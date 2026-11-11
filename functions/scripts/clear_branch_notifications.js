// Deletes one branch's notifications (what members see in the Notifications
// screen). Notifications that may belong to another branch, and offer
// announcements meant for everyone, are kept.
//
//   node scripts/clear_branch_notifications.js erode_main <backupDir> <billsBackup.json> <otherBranchOpened YYYY-MM-DD>
//   ...same... --apply
//
// A notification is cleared when any of these is true:
//   - it is tagged with the branch;
//   - it was sent to a person in the branch;
//   - it is about one of the branch's bills (from the bills backup or live);
//   - it has no branch and no recipient, and was sent before another branch
//     existed (so it can only have been this branch's).
// A JSON backup is written first; the run stops if it cannot be written.
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

admin.initializeApp({projectId: process.env.GCLOUD_PROJECT || "balajipoints"});
const db = admin.firestore();
const {Timestamp} = admin.firestore;

const [branchId, backupDir, billsBackup, otherOpened] = process.argv.slice(2);
const apply = process.argv.includes("--apply");
const plain = (value) => JSON.parse(JSON.stringify(value, (key, v) =>
  v instanceof Timestamp ? {_timestamp: v.toDate().toISOString()} : v));
const day = (ts) => (ts && ts.toDate ? ts.toDate().toISOString().slice(0, 10) : "");

async function main() {
  if (!branchId || !backupDir || !billsBackup || !/^\d{4}-\d{2}-\d{2}$/.test(otherOpened || "")) {
    throw new Error("Usage: <branchId> <backupDir> <billsBackup.json> <YYYY-MM-DD> [--apply]");
  }
  const keys = new Set();
  for (const u of (await db.collection("users").where("branchId", "==", branchId).get()).docs) {
    keys.add(u.id);
    const d = u.data();
    if (d.phone) keys.add(String(d.phone));
    if (d.uid) keys.add(String(d.uid));
  }
  const branchBills = new Set(JSON.parse(fs.readFileSync(billsBackup, "utf8")).bills.map((b) => b.id));
  const liveBills = new Map((await db.collection("bills").get()).docs.map((b) => [b.id, b.data().branchId || ""]));
  for (const [id, b] of liveBills) if (b === branchId) branchBills.add(id);

  const logs = (await db.collection("notification_logs").get()).docs;
  const remove = [];
  const kept = {otherBranch: 0, offers: 0, maybeOtherBranch: 0};
  const why = {tagged: 0, person: 0, bill: 0, beforeOtherBranch: 0};
  for (const n of logs) {
    const d = n.data();
    const data = d.data && typeof d.data === "object" ? d.data : {};
    const billId = String(d.billId || data.billId || "");
    const person = String(d.userId || d.carpenterId || data.carpenterId || d.carpenterPhone || data.carpenterPhone || "");
    if (d.branchId && d.branchId !== branchId) kept.otherBranch++;
    else if (d.branchId === branchId) { why.tagged++; remove.push(n); }
    else if (billId && liveBills.has(billId) && liveBills.get(billId) && liveBills.get(billId) !== branchId) kept.otherBranch++;
    else if (person && keys.has(person)) { why.person++; remove.push(n); }
    else if (billId && branchBills.has(billId)) { why.bill++; remove.push(n); }
    else if (d.type === "newOfferAvailable") kept.offers++;
    else if (day(d.sentAt || d.createdAt) && day(d.sentAt || d.createdAt) < otherOpened) { why.beforeOtherBranch++; remove.push(n); }
    else kept.maybeOtherBranch++;
  }

  fs.mkdirSync(backupDir, {recursive: true, mode: 0o700});
  const stamp = new Date().toISOString().replace(/[:.]/g, "-");
  const file = path.join(backupDir, `${branchId}_notifications_before_clear_${stamp}.json`);
  fs.writeFileSync(file, JSON.stringify(remove.map((s) => ({id: s.id, data: plain(s.data())}))), {mode: 0o600});
  if (JSON.parse(fs.readFileSync(file, "utf8")).length !== remove.length) {
    throw new Error("Backup check failed; nothing was changed.");
  }

  console.log(apply ? "APPLYING CHANGES" : "DRY RUN: nothing will change");
  console.log(`Notifications checked: ${logs.length}`);
  console.log(`Will delete: ${remove.length} ${JSON.stringify(why)}`);
  console.log(`Kept: ${JSON.stringify(kept)}`);
  console.log(`Backup: ${file}`);
  if (!apply) return;

  const writer = db.bulkWriter();
  let failed = 0;
  writer.onWriteError((error) => {
    if (error.failedAttempts < 3) return true;
    failed++;
    return false;
  });
  for (const n of remove) writer.delete(n.ref);
  await writer.close();
  if (failed) throw new Error(`${failed} deletes failed; restore or retry from ${file}`);
  console.log("Done.");
}

main().then(() => process.exit(0)).catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
