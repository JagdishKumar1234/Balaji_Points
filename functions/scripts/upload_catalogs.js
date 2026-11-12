// Uploads product catalogs one by one, category by category, writing exactly
// what the admin Catalogs screen writes (CatalogAdminService.saveCatalog):
//   Storage  catalogs/{catalogId}/v1.pdf and catalogs/{catalogId}/cover_{stamp}.jpg
//   Firestore catalog_categories/{slug} and catalogs/{catalogId}
// and keeps each category's catalogCount and coverUrl in step.
//
// Catalogs are shared by every branch (no branchId), so they show for all
// members and in every admin's Catalogs screen, Erode included.
//
// Dry run by default. A catalog whose title already exists in its category is
// skipped, so the script is safe to run again.
//
//   node scripts/upload_catalogs.js scripts/catalogs.json [--apply]
//
// Files: "<file>.pdf" (max 25 MB, same limit as the admin form) and an
// optional "<file>.jpg" cover in the "files" folder.
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const {execFileSync} = require("child_process");
const admin = require("firebase-admin");
const {FieldValue} = require("firebase-admin/firestore");
const {getDownloadURL} = require("firebase-admin/storage");

const MAX_PDF = 25 * 1024 * 1024;

function slug(name, taken) {
  let base = name.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "") || "category";
  base = base.slice(0, 40);
  let s = base;
  let n = 2;
  while (taken.has(s)) s = `${base}_${n++}`;
  return s;
}

function safeFileName(title) {
  const s = title.replace(/[^A-Za-z0-9 ._-]/g, "").replace(/\s+/g, " ").trim();
  return s || "catalog";
}

function pageCount(file) {
  try {
    const out = execFileSync("pdfinfo", [file], {encoding: "utf8"});
    const m = out.match(/^Pages:\s+(\d+)/m);
    return m ? Number(m[1]) : 0;
  } catch (_) {
    return 0;
  }
}

async function upload(bucket, dest, bytes, metadata) {
  const file = bucket.file(dest);
  await file.save(bytes, {resumable: bytes.length > 5 * 1024 * 1024, metadata});
  return getDownloadURL(file);
}

async function recount(db, categoryId) {
  const snap = await db.collection("catalogs").where("categoryId", "==", categoryId).get();
  const active = snap.docs.map((d) => d.data())
      .filter((c) => c.active !== false && c.pdfUrl)
      .sort((a, b) => (a.sortOrder || 0) - (b.sortOrder || 0));
  await db.doc(`catalog_categories/${categoryId}`).update({
    catalogCount: active.length,
    coverUrl: active.length ? active[0].coverUrl || "" : "",
    updatedAt: FieldValue.serverTimestamp(),
  });
}

async function main() {
  const [configPath, ...flags] = process.argv.slice(2);
  if (!configPath) throw new Error("Usage: upload_catalogs.js <catalogs.json> [--apply]");
  const apply = flags.includes("--apply");
  const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
  const dir = path.resolve(path.dirname(configPath), config.files);

  // Check every file before touching anything.
  for (const cat of config.categories) {
    for (const c of cat.catalogs) {
      const pdf = path.join(dir, `${c.file}.pdf`);
      if (!fs.existsSync(pdf)) throw new Error(`Missing ${pdf}`);
      const size = fs.statSync(pdf).size;
      if (size > MAX_PDF) throw new Error(`${pdf} is ${(size / 1048576).toFixed(1)} MB (max 25 MB)`);
      if (fs.readFileSync(pdf).subarray(0, 4).toString() !== "%PDF") throw new Error(`${pdf} is not a PDF`);
    }
  }

  admin.initializeApp({projectId: "balajipoints", storageBucket: "balajipoints.firebasestorage.app"});
  const db = admin.firestore();
  const bucket = admin.storage().bucket();
  console.log(`Mode: ${apply ? "APPLY" : "dry run (add --apply to upload)"}\n`);

  const catSnap = await db.collection("catalog_categories").get();
  const taken = new Set(catSnap.docs.map((d) => d.id));
  const byName = new Map(catSnap.docs.map((d) => [String(d.data().name || "").toLowerCase(), d]));
  let maxOrder = catSnap.docs.reduce((m, d) => Math.max(m, d.data().sortOrder || 0), 0);
  let uploaded = 0;
  let skipped = 0;

  for (const cat of config.categories) {
    let categoryId;
    const found = byName.get(cat.name.toLowerCase());
    if (found) {
      categoryId = found.id;
      console.log(`== ${cat.name} (existing: ${categoryId})`);
    } else {
      categoryId = slug(cat.name, taken);
      taken.add(categoryId);
      maxOrder += 1;
      console.log(`== ${cat.name} (new: ${categoryId}, order ${maxOrder})`);
      if (apply) {
        await db.doc(`catalog_categories/${categoryId}`).set({
          categoryId,
          name: cat.name,
          description: cat.description || "",
          sortOrder: maxOrder,
          catalogCount: 0,
          coverUrl: "",
          active: true,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    }

    const existing = found ?
      (await db.collection("catalogs").where("categoryId", "==", categoryId).get()).docs.map((d) => d.data()) :
      [];
    const titles = new Set(existing.map((c) => String(c.title || "").toLowerCase()));
    let order = existing.length;

    for (const c of cat.catalogs) {
      const pdfFile = path.join(dir, `${c.file}.pdf`);
      const coverFile = path.join(dir, `${c.file}.jpg`);
      const pdf = fs.readFileSync(pdfFile);
      const pages = pageCount(pdfFile);
      const mb = (pdf.length / 1048576).toFixed(1);
      if (titles.has(c.title.toLowerCase())) {
        console.log(`   skip  ${c.title} (already uploaded)`);
        skipped++;
        continue;
      }
      order += 1;
      console.log(`   ${apply ? "upload" : "would upload"}  ${c.title}  [${pages} pages, ${mb} MB${fs.existsSync(coverFile) ? ", cover" : ""}]`);
      if (!apply) {
        uploaded++;
        continue;
      }

      const id = db.collection("catalogs").doc().id;
      const stamp = Date.now();
      const fileName = `${safeFileName(c.title)}.pdf`;
      const pdfPath = `catalogs/${id}/v1.pdf`;
      const data = {
        catalogId: id,
        categoryId,
        title: c.title,
        brand: c.brand || "",
        description: c.description || "",
        year: c.year || 0,
        version: 1,
        sortOrder: order,
        active: true,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        pdfUrl: await upload(bucket, pdfPath, pdf, {
          contentType: "application/pdf",
          contentDisposition: `attachment; filename="${fileName}"`,
          cacheControl: "public, max-age=86400",
          metadata: {firebaseStorageDownloadTokens: crypto.randomUUID()},
        }),
        pdfPath,
        fileName,
        sizeBytes: pdf.length,
        pages,
        coverUrl: "",
        coverPath: "",
      };
      if (fs.existsSync(coverFile)) {
        const coverPath = `catalogs/${id}/cover_${stamp}.jpg`;
        data.coverUrl = await upload(bucket, coverPath, fs.readFileSync(coverFile), {
          contentType: "image/jpeg",
          cacheControl: "public, max-age=86400",
          metadata: {firebaseStorageDownloadTokens: crypto.randomUUID()},
        });
        data.coverPath = coverPath;
      }
      await db.doc(`catalogs/${id}`).set(data);
      await recount(db, categoryId);
      uploaded++;
      console.log(`          done  (${id})`);
    }
  }

  console.log(`\n${apply ? "Uploaded" : "Would upload"} ${uploaded} catalog(s); skipped ${skipped}.`);
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
