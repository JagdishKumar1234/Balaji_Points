// Marks every existing member account as approved (profile_verified = true),
// before account approval goes live, so no live user is locked out.
// Default is a dry run that changes nothing; add --apply to write.
// Safe to run more than once: accounts that already have profile_verified
// (true or false) are never changed.
//
//   node scripts/set_profile_verified.js                Report only (all branches)
//   node scripts/set_profile_verified.js --apply        Make the changes
//   node scripts/set_profile_verified.js --report-only  List members still
//                                                       without the field
//
// Needs admin access, for example after `gcloud auth application-default login`.
//
// Only the approval fields are written. Points, names, PINs, roles, branches
// and bills are not touched. Admin and super admin accounts are skipped.
// Phone numbers are masked in the output.
const admin = require("firebase-admin");
const {isMemberRole} = require("../account_approval");

admin.initializeApp({projectId: process.env.GCLOUD_PROJECT || "balajipoints"});
const db = admin.firestore();
const {FieldValue} = require("firebase-admin/firestore");

const apply = process.argv.includes("--apply");
const reportOnly = process.argv.includes("--report-only");
const masked = (phone) => phone ? `******${String(phone).slice(-4)}` : "-";

async function main() {
  const users = await db.collection("users").get();
  const toUpdate = [];
  const skipped = {staff: 0, alreadySet: 0};
  const byBranchRole = {};

  for (const doc of users.docs) {
    const d = doc.data();
    if (!isMemberRole(d.role || d.roleId)) {
      skipped.staff++;
      continue;
    }
    if (typeof d.profile_verified === "boolean") {
      skipped.alreadySet++;
      continue;
    }
    toUpdate.push(doc);
    const key = `${d.branchId || "(no branch)"} / ${d.role || "(no role)"}`;
    byBranchRole[key] = (byBranchRole[key] || 0) + 1;
  }

  console.log(apply ? "APPLYING CHANGES" :
    reportOnly ? "REPORT: members with no profile_verified" :
    "DRY RUN: nothing will change");
  console.log(`Accounts checked: ${users.size}`);
  console.log(`Members to mark approved: ${toUpdate.length}`);
  for (const [key, n] of Object.entries(byBranchRole).sort()) {
    console.log(`  ${key}: ${n}`);
  }
  console.log(`Skipped: ${JSON.stringify(skipped)}`);
  if (reportOnly) {
    for (const doc of toUpdate) {
      const d = doc.data();
      const name = `${d.firstName || ""} ${d.lastName || ""}`.trim() || "(no name)";
      console.log(`  - ${name} ${masked(d.phone)} ${d.branchId || ""}`);
    }
    return;
  }
  if (!apply) return;

  // Batches of 400 (Firestore allows 500 writes per batch).
  for (let i = 0; i < toUpdate.length; i += 400) {
    const batch = db.batch();
    for (const doc of toUpdate.slice(i, i + 400)) {
      batch.update(doc.ref, {
        profile_verified: true,
        approvalStatus: "approved",
        approvedAt: FieldValue.serverTimestamp(),
        approvedBy: "migration-2026-11",
        // Never announce these existing accounts as new requests.
        approvalNotifiedAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    console.log(`  written ${Math.min(i + 400, toUpdate.length)} / ${toUpdate.length}`);
  }
  console.log("Done.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
