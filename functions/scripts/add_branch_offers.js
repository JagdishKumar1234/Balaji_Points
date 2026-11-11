// Adds a set of banner offers to one branch, the same way the admin Offers
// screen does (banner in Storage `offer_banners/<id>.jpg`, record in
// `offers` with the branch), and can send one "new offers" push to that
// branch's members only.
//
// Dry run by default: prints what it would do and changes nothing.
//
//   node scripts/add_branch_offers.js <offers.json> [--apply] [--notify]
//
// offers.json: {"branchId": "...", "images": "<folder>", "offers": [
//   {"file": "a.jpeg", "title": "...", "description": "...",
//    "points": 6000, "sortOrder": 1}, ...],
//   "push": {"title": "...", "body": "..."}}
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");
const {FieldValue} = require("firebase-admin/firestore");

const MEMBER_ROLES = new Set(["carpenter", "architect", "engineer", "interior_designer"]);

async function main() {
  const [configPath, ...flags] = process.argv.slice(2);
  if (!configPath) throw new Error("Usage: add_branch_offers.js <offers.json> [--apply] [--notify]");
  const apply = flags.includes("--apply");
  const notify = flags.includes("--notify");
  const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
  const {branchId, offers} = config;
  const imagesDir = path.resolve(path.dirname(configPath), config.images || ".");

  admin.initializeApp({projectId: "balajipoints", storageBucket: "balajipoints.firebasestorage.app"});
  const db = admin.firestore();
  const bucket = admin.storage().bucket();

  const branch = await db.doc(`branches/${branchId}`).get();
  if (!branch.exists) throw new Error(`Branch ${branchId} not found`);
  console.log(`Branch: ${branchId} (${branch.data().name})  mode: ${apply ? "APPLY" : "dry run"}`);

  const existing = await db.collection("offers").get();
  const titles = new Set(existing.docs.filter((d) => d.data().branchId === branchId).map((d) => d.data().title));

  for (const o of offers) {
    const file = path.join(imagesDir, o.file);
    const size = fs.statSync(file).size;
    if (size > 5 * 1024 * 1024) throw new Error(`${o.file} is over 5 MB`);
    if (titles.has(o.title)) {
      console.log(`  skip (already in this branch): ${o.title}`);
      continue;
    }
    console.log(`  ${o.sortOrder}. ${o.title}  target ${o.points}  ${Math.round(size / 1024)} KB`);
    if (!apply) continue;

    const ref = db.collection("offers").doc();
    const token = crypto.randomUUID();
    const dest = `offer_banners/${ref.id}.jpg`;
    await bucket.upload(file, {
      destination: dest,
      metadata: {
        contentType: "image/jpeg",
        metadata: {firebaseStorageDownloadTokens: token, offerId: ref.id, uploadedAt: new Date().toISOString()},
      },
    });
    const bannerUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/` +
      `${encodeURIComponent(dest)}?alt=media&token=${token}`;
    await ref.set({
      offerId: ref.id,
      title: o.title,
      description: o.description,
      points: o.points,
      sortOrder: o.sortOrder,
      bannerUrl,
      isActive: true,
      validUntil: null,
      branchId,
      createdBy: "admin_script",
      createdByPhone: "admin_script",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    console.log(`     added offers/${ref.id}`);
  }

  if (!notify) return;
  // One push per member of this branch, using the member's own settings.
  const users = await db.collection("users").where("branchId", "==", branchId).get();
  const targets = users.docs.filter((d) => {
    const u = d.data();
    const role = (u.role || "carpenter").trim();
    const prefs = u.notificationPreferences || {};
    return MEMBER_ROLES.has(role) && u.fcmToken && prefs.enabled !== false && prefs.newOffers !== false &&
      u.active !== false && !u.migratedToUid;
  });
  console.log(`Push "${config.push.title}" to ${targets.length} of ${users.size} ${branchId} accounts (members with a push token)`);
  if (!apply) return;
  let batch = db.batch();
  let n = 0;
  for (const d of targets) {
    batch.set(db.collection("notification_queue").doc(), {
      userId: d.id,
      fcmToken: d.data().fcmToken,
      type: "newOfferAvailable",
      title: config.push.title,
      body: config.push.body,
      data: {type: "newOfferAvailable", screen: "/notifications"},
      status: "pending",
      priority: "normal",
      branchId,
      createdAt: FieldValue.serverTimestamp(),
    });
    if (++n % 400 === 0) {
      await batch.commit(); batch = db.batch();
    }
  }
  await batch.commit();
  console.log(`Queued ${n} pushes`);
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
