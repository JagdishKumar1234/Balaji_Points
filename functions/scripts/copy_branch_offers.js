// Copies one branch's offers to another branch, so both branches' members
// see them and each branch admin can edit or delete their own copy.
//
// Each copy gets its own banner file in Storage (offer_banners/<newId>.jpg):
// the admin app deletes an offer's banner when the offer is deleted, so a
// shared file would vanish from the other branch too.
//
// Dry run by default. An offer whose title the target branch already has is
// skipped, so the script is safe to run again.
//
//   node scripts/copy_branch_offers.js <fromBranchId> <toBranchId> [--apply]
const crypto = require("crypto");
const admin = require("firebase-admin");
const {FieldValue} = require("firebase-admin/firestore");

/**
 * Storage path inside a Firebase download URL, or null.
 * @param {string} url download URL
 * @return {?string} object path
 */
function storagePath(url) {
  const m = /\/o\/([^?]+)/.exec(url || "");
  return m ? decodeURIComponent(m[1]) : null;
}

async function main() {
  const [from, to, ...flags] = process.argv.slice(2);
  if (!from || !to) {
    throw new Error("Usage: copy_branch_offers.js <fromBranchId> <toBranchId> [--apply]");
  }
  const apply = flags.includes("--apply");

  admin.initializeApp({projectId: "balajipoints", storageBucket: "balajipoints.firebasestorage.app"});
  const db = admin.firestore();
  const bucket = admin.storage().bucket();

  for (const id of [from, to]) {
    const b = await db.doc(`branches/${id}`).get();
    if (!b.exists) throw new Error(`Branch ${id} not found`);
  }
  const fromName = (await db.doc(`branches/${from}`).get()).data().name;
  const toName = (await db.doc(`branches/${to}`).get()).data().name;
  console.log(`From: ${fromName} (${from})\nTo:   ${toName} (${to})`);
  console.log(`Mode: ${apply ? "APPLY" : "dry run (add --apply to copy)"}\n`);

  const source = (await db.collection("offers").where("branchId", "==", from).get()).docs
      .map((d) => d.data())
      .sort((a, b) => (a.sortOrder || 0) - (b.sortOrder || 0));
  const target = await db.collection("offers").where("branchId", "==", to).get();
  const have = new Set(target.docs.map((d) => String(d.data().title || "").trim().toLowerCase()));

  let copied = 0;
  let skipped = 0;
  for (const o of source) {
    const title = String(o.title || "").trim();
    if (have.has(title.toLowerCase())) {
      console.log(`  skip (already in ${to}): ${title}`);
      skipped++;
      continue;
    }
    console.log(`  ${apply ? "copy" : "would copy"}: ${o.sortOrder}. ${title}  ` +
      `target ${o.points}  ${o.isActive === false ? "(inactive)" : ""}`);
    copied++;
    if (!apply) continue;

    const ref = db.collection("offers").doc();
    let bannerUrl = o.bannerUrl || "";
    const src = storagePath(bannerUrl);
    if (src) {
      const token = crypto.randomUUID();
      const dest = `offer_banners/${ref.id}.jpg`;
      await bucket.file(src).copy(bucket.file(dest));
      await bucket.file(dest).setMetadata({
        metadata: {firebaseStorageDownloadTokens: token, offerId: ref.id,
          copiedFrom: src, uploadedAt: new Date().toISOString()},
      });
      bannerUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/` +
        `${encodeURIComponent(dest)}?alt=media&token=${token}`;
    }
    await ref.set({
      ...o,
      offerId: ref.id,
      branchId: to,
      bannerUrl,
      createdBy: "copy_script",
      createdByPhone: "copy_script",
      copiedFromOfferId: o.offerId || null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    console.log(`     added offers/${ref.id}`);
  }
  console.log(`\n${apply ? "Copied" : "Would copy"} ${copied}; skipped ${skipped}.`);
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
