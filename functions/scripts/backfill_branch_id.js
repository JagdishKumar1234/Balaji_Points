const admin = require("firebase-admin");

admin.initializeApp({ projectId: "balajipoints" });
const db = admin.firestore();

const acceptedRoles = new Set([
  "super_admin",
  "admin",
  "carpenter",
  "architect",
  "interior_designer",
]);
const applyChanges = process.argv.includes("--apply");
const batchSize = 400;

function normalizedText(value) {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

function resolveRole(data) {
  const currentRole = normalizedText(data.role);
  if (currentRole) return acceptedRoles.has(currentRole) ? currentRole : null;
  const legacyRole = normalizedText(data.userRole);
  return acceptedRoles.has(legacyRole) ? legacyRole : null;
}

function resolveBranchId(data, activeBranches) {
  const existing =
    typeof data.branchId === "string" ? data.branchId.trim() : "";
  if (existing) {
    return activeBranches.has(existing) ? existing : null;
  }

  const branchCandidates = [data.branch, data.branchName, data.branch_id]
    .filter((value) => typeof value === "string")
    .map((value) => value.trim().toLowerCase());

  for (const branch of activeBranches.values()) {
    const aliases = [branch.id, branch.name, branch.shortName]
      .filter((value) => typeof value === "string")
      .map((value) => value.trim().toLowerCase());
    if (branchCandidates.some((candidate) => aliases.includes(candidate))) {
      return branch.id;
    }
  }

  // It is safe to infer the branch only when the database has exactly one
  // active branch. With multiple branches, leave ambiguous accounts untouched.
  return activeBranches.size === 1
    ? activeBranches.values().next().value.id
    : null;
}

async function main() {
  const branchesSnapshot = await db
    .collection("branches")
    .where("isActive", "==", true)
    .get();
  const activeBranches = new Map(
    branchesSnapshot.docs.map((doc) => [doc.id, { id: doc.id, ...doc.data() }]),
  );
  if (activeBranches.size === 0) {
    throw new Error("No active branches found; no user records were changed.");
  }

  const users = db.collection("users");
  let lastDocument;
  let scanned = 0;
  let complete = 0;
  let missingRole = 0;
  let missingBranch = 0;
  let ambiguousRole = 0;
  let ambiguousBranch = 0;
  let writes = 0;
  let batch = db.batch();
  let batchWrites = 0;

  console.log(
    applyChanges
      ? "Applying only safely resolved missing user fields. No user documents will be deleted."
      : "DRY RUN: auditing user role and branchId. No database changes will be made.",
  );

  while (true) {
    let query = users
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(batchSize);
    if (lastDocument) query = query.startAfter(lastDocument);
    const snapshot = await query.get();
    if (snapshot.empty) break;

    for (const document of snapshot.docs) {
      scanned++;
      const data = document.data();
      const patch = {};
      const role = resolveRole(data);
      const isGlobalSuperAdmin = role === "super_admin";
      const branchId = isGlobalSuperAdmin
        ? null
        : resolveBranchId(data, activeBranches);

      if (!role) {
        if (data.role == null || normalizedText(data.role) === "") {
          missingRole++;
          const legacyRole = normalizedText(data.userRole);
          if (acceptedRoles.has(legacyRole)) patch.role = legacyRole;
        } else {
          ambiguousRole++;
        }
      } else if (data.role == null || normalizedText(data.role) === "") {
        // Migrate a valid legacy userRole without overwriting an existing role.
        patch.role = role;
      }

      if (!branchId && !isGlobalSuperAdmin) {
        if (data.branchId == null || normalizedText(data.branchId) === "") {
          missingBranch++;
        } else {
          ambiguousBranch++;
        }
      } else if (
        !isGlobalSuperAdmin &&
        (data.branchId == null || normalizedText(data.branchId) === "")
      ) {
        patch.branchId = branchId;
      }

      const resultingRole = role || patch.role;
      const resultingBranch = isGlobalSuperAdmin
        ? "global"
        : branchId || patch.branchId;
      if (resultingRole && resultingBranch) complete++;

      if (Object.keys(patch).length > 0) {
        if (applyChanges) {
          batch.update(document.ref, patch);
          batchWrites++;
          writes++;
          if (batchWrites >= 400) {
            await batch.commit();
            batch = db.batch();
            batchWrites = 0;
          }
        } else {
          writes++;
        }
      }
    }

    lastDocument = snapshot.docs[snapshot.docs.length - 1];
    if (snapshot.size < batchSize) break;
  }

  if (applyChanges && batchWrites > 0) await batch.commit();

  console.log(
    JSON.stringify(
      {
        mode: applyChanges ? "apply" : "dry-run",
        activeBranches: [...activeBranches.keys()],
        scannedUsers: scanned,
        usersWithResolvedRoleAndBranch: complete,
        missingRoleAtStart: missingRole,
        missingOrInvalidRoleUnresolved: ambiguousRole,
        missingBranchAtStart: missingBranch,
        missingOrInvalidBranchUnresolved: ambiguousBranch,
        userDocumentsUpdated: writes,
        userDocumentsDeleted: 0,
      },
      null,
      2,
    ),
  );

  if (!applyChanges) {
    console.log(
      "Review the report, then run with --apply only after confirming unresolved users manually.",
    );
  }
}

main()
  .catch((error) => {
    console.error("User role/branch audit failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await admin.app().delete();
  });
