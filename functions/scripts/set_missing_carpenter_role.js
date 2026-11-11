// Saves role "carpenter" on member accounts in one branch that have no role.
// Default is a dry run that changes nothing; add --apply to write.
// Safe to run more than once: it only ever fills in a missing role.
//
//   node scripts/set_missing_carpenter_role.js erode_main           Report only
//   node scripts/set_missing_carpenter_role.js erode_main --apply   Make the changes
//
// Needs admin access, for example after `gcloud auth application-default login`.
//
// Only the four role fields are written. Points, names, PINs and bills are not
// touched. Accounts with any role already set, email accounts (which may be
// mid sign-up) and deleted accounts are skipped. Phone numbers are masked in
// the output.
const admin = require("firebase-admin");

admin.initializeApp({projectId: process.env.GCLOUD_PROJECT || "balajipoints"});
const db = admin.firestore();

const branchId = process.argv[2];
const apply = process.argv.includes("--apply");
const hasValue = (value) => typeof value === "string" && value.trim() !== "";
const masked = (phone) => phone ? `******${String(phone).slice(-4)}` : "-";

async function main() {
  if (!hasValue(branchId) || branchId.startsWith("--")) {
    throw new Error("Give the branch id first, for example: erode_main");
  }
  const users = await db.collection("users").where("branchId", "==", branchId).get();
  const toUpdate = [];
  const skipped = {existingRole: 0, email: 0, deleted: 0};

  for (const doc of users.docs) {
    const data = doc.data();
    if (hasValue(data.role) || hasValue(data.roleId) || hasValue(data.userRole)) {
      skipped.existingRole++;
    } else if (hasValue(data.email)) {
      skipped.email++;
    } else if (data.status === "deleted") {
      skipped.deleted++;
    } else {
      toUpdate.push(doc);
    }
  }

  console.log(apply ? "APPLYING CHANGES" : "DRY RUN: nothing will change");
  console.log(`Branch: ${branchId} | accounts checked: ${users.size}`);
  console.log(`Will set role to carpenter: ${toUpdate.length}`);
  for (const doc of toUpdate) {
    const d = doc.data();
    const name = `${d.firstName || ""} ${d.lastName || ""}`.trim() || "(no name)";
    const note = d.legacyAccount === true ? "  (old record, moved to a newer account)" : "";
    console.log(`  - ${name} ${masked(d.phone)}${note}`);
  }
  console.log(`Skipped: ${JSON.stringify(skipped)}`);

  if (!apply) return;
  const batch = db.batch(); // well under the 500-write limit for one branch
  for (const doc of toUpdate) {
    batch.update(doc.ref, {
      role: "carpenter",
      roleId: "carpenter",
      roleName: "Carpenter",
      roleAbbreviation: "",
    });
  }
  await batch.commit();
  console.log(`Updated: ${toUpdate.length}`);
}

main().then(() => process.exit(0)).catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
