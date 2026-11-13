/**
 * Balaji Points - Cloud Functions
 *
 * Triggers:
 *  1. processNotificationQueue   – FCM push on notification_queue create
 *  1b. onBillCreated             – validate bill (siteName, amount, date) + detect duplicates
 *  2. onBillStatusChanged        – points + tier + history on bill approval/rejection
 *  3. onPointsChanged            – tier recalculation safety-net on user_points write
 *  4. onUserDeleted              – cascade-delete user_points / bills / points_history
 *  5. onBranchRenamed / onRoleRenamed – copy renamed branch / role names onto users
 *  6. onMemberSignUp             – mark a new member sign-up pending + push the branch admin
 *  7. reviewMemberAccount        – the member's branch admin approves or rejects a sign-up
 *
 * Branch-isolation contract (applied in every trigger that touches user data):
 *   bill.branchId  must equal  user.branchId
 *   If they differ the trigger logs an error and aborts — no cross-store writes.
 */

const {onDocumentCreated, onDocumentWritten, onDocumentDeleted} =
  require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
// Modular import: `admin.firestore.FieldValue` is undefined in the local
// Functions emulator, which made every write with a timestamp crash there.
const {FieldValue, Timestamp} = require("firebase-admin/firestore");

admin.initializeApp();

const db = admin.firestore();
const SUPER_ADMIN_EMAIL = "aaijitechstudio@gmail.com";
const {isPointsResetMember} = require("./points_reset_members");
const {inAppRecordFor} = require("./in_app_record");
const {isFutureBillDate, indiaDayBounds} = require("./bill_date");
const pinSignIn = require("./admin_pin_signin");
const approval = require("./account_approval");

/**
 * Verifies the authenticated caller against the configured super-admin profile.
 * @param {object} request - Callable request containing auth claims and data.
 * @return {Promise<string>} The verified super-admin UID.
 */
async function requireSuperAdmin(request) {
  const caller = request.auth;
  const email = (caller && caller.token.email || "").trim().toLowerCase();
  if (!caller || email !== SUPER_ADMIN_EMAIL ||
      caller.token.email_verified !== true) {
    throw new HttpsError("permission-denied", "Super admin access required.");
  }

  const profile = await db.collection("users").doc(caller.uid).get();
  const data = profile.data() || {};
  if (!profile.exists || data.role !== "super_admin" ||
      String(data.email || "").toLowerCase() !== SUPER_ADMIN_EMAIL) {
    throw new HttpsError("permission-denied", "Super admin access required.");
  }
  return caller.uid;
}

/**
 * Loads a branch and its point-bearing member profiles.
 * @param {string} branchId - Branch document ID.
 * @return {Promise<object>} Branch references and eligible user snapshots.
 */
async function getBranchAndMembers(branchId) {
  if (typeof branchId !== "string" || !branchId.trim()) {
    throw new HttpsError("invalid-argument", "Choose a valid branch.");
  }
  const branchRef = db.collection("branches").doc(branchId.trim());
  const branch = await branchRef.get();
  if (!branch.exists) {
    throw new HttpsError("not-found", "The selected branch no longer exists.");
  }
  const users = await db.collection("users")
      .where("branchId", "==", branchRef.id).get();
  // All member roles, including engineers and older accounts with no role.
  const members = users.docs.filter((doc) => isPointsResetMember(doc.data()));
  return {branchRef, branch: branch.data(), members};
}

/**
 * Returns canonical and legacy points-document keys for the given users.
 * @param {Array<object>} members - Branch member document snapshots.
 * @return {Array<string>} Unique user or legacy phone document IDs.
 */
function pointsUserKeys(members) {
  const keys = new Set();
  for (const member of members) {
    keys.add(member.id);
    const phone = String(member.data().phone || "").replace(/\D/g, "");
    if (phone) keys.add(phone);
  }
  return [...keys];
}

/**
 * Loads external point-history documents linked to the supplied user keys.
 * @param {Array<string>} userKeys - User UIDs and legacy phone document IDs.
 * @return {Promise<Array<object>>} Unique history document snapshots.
 */
async function getHistoryDocs(userKeys) {
  const docs = new Map();
  for (let i = 0; i < userKeys.length; i += 30) {
    const group = userKeys.slice(i, i + 30);
    for (const field of ["userId", "carpenterId"]) {
      const snapshot = await db.collection("points_history")
          .where(field, "in", group).get();
      for (const doc of snapshot.docs) docs.set(doc.ref.path, doc);
    }
  }
  return [...docs.values()];
}

exports.createBranchAdmin = onCall(async (request) => {
  const creatorId = await requireSuperAdmin(request);
  const data = request.data || {};
  const email = String(data.email || "").trim().toLowerCase();
  const password = String(data.password || "");
  const firstName = String(data.firstName || "").trim();
  const lastName = String(data.lastName || "").trim();
  const phone = String(data.phone || "").replace(/\D/g, "");
  const branchId = String(data.branchId || "").trim();

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ||
      password.length < 8 || !firstName || !/^\d{10}$/.test(phone)) {
    throw new HttpsError("invalid-argument", "Check the admin details.");
  }
  const branchRef = db.collection("branches").doc(branchId);
  const branch = await branchRef.get();
  if (!branch.exists || branch.data().isActive !== true) {
    throw new HttpsError("failed-precondition", "Choose an active branch.");
  }
  let authUser;
  try {
    authUser = await admin.auth().createUser({
      email,
      password,
      displayName: `${firstName} ${lastName}`.trim(),
      emailVerified: false,
      disabled: false,
    });
    const userRef = db.collection("users").doc(authUser.uid);
    await db.runTransaction(async (transaction) => {
      const currentBranch = await transaction.get(branchRef);
      const currentAdmins = await transaction.get(
          db.collection("users").where("branchId", "==", branchId));
      const alreadyAssigned = currentAdmins.docs.some((doc) =>
        (doc.data().role || doc.data().roleId) === "admin");
      if (!currentBranch.exists || currentBranch.data().isActive !== true) {
        throw new HttpsError("failed-precondition", "Choose an active branch.");
      }
      if (alreadyAssigned) {
        throw new HttpsError(
            "already-exists", "This branch already has an admin.");
      }
      transaction.create(userRef, {
        uid: authUser.uid,
        userId: authUser.uid,
        email,
        firstName,
        lastName,
        phone,
        branchCode: branch.data().branchCode || branchId,
        branchName: branch.data().name || branchId,
        branchShortName: branch.data().shortName || branch.data().name || branchId,
        role: "admin",
        roleId: "admin",
        roleName: "Branch admin",
        roleAbbreviation: "",
        branchId,
        status: "active",
        totalPoints: 0,
        tier: "Bronze",
        createdAt: FieldValue.serverTimestamp(),
        createdBy: creatorId,
        authProvider: "password",
      });
      transaction.set(branchRef, {
        adminUid: authUser.uid,
        adminAssignedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    });
  } catch (error) {
    if (authUser) await admin.auth().deleteUser(authUser.uid).catch(() => {});
    if (error instanceof HttpsError) throw error;
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "That email already has an account.");
    }
    console.error("createBranchAdmin failed", error);
    throw new HttpsError("internal", "Unable to create the branch admin.");
  }

  return {
    uid: authUser.uid,
    email,
    branchName: branch.data().name || branchId,
  };
});

exports.updateBranchAdminPassword = onCall(async (request) => {
  await requireSuperAdmin(request);
  const uid = String(request.data && request.data.uid || "").trim();
  const password = String(request.data && request.data.password || "");
  if (!uid || password.length < 8) {
    throw new HttpsError(
        "invalid-argument", "Enter a valid admin and a password of at least 8 characters.");
  }
  const profile = await db.collection("users").doc(uid).get();
  if (!profile.exists || profile.data().role !== "admin") {
    throw new HttpsError("not-found", "Branch admin account was not found.");
  }
  try {
    await admin.auth().updateUser(uid, {password});
    await profile.ref.update({
      passwordUpdatedAt: FieldValue.serverTimestamp(),
      passwordUpdatedBy: request.auth.uid,
    });
  } catch (error) {
    console.error("updateBranchAdminPassword failed", error);
    throw new HttpsError("internal", "Unable to update the admin password.");
  }
  return {success: true};
});

exports.updateBranchAdmin = onCall(async (request) => {
  const editorId = await requireSuperAdmin(request);
  const data = request.data || {};
  const uid = String(data.uid || "").trim();
  const email = String(data.email || "").trim().toLowerCase();
  const firstName = String(data.firstName || "").trim();
  const lastName = String(data.lastName || "").trim();
  const phone = String(data.phone || "").replace(/\D/g, "");
  const branchId = String(data.branchId || "").trim();

  if (!uid || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || !firstName ||
      firstName.length > 60 || lastName.length > 60 || !/^\d{10}$/.test(phone) || !branchId) {
    throw new HttpsError("invalid-argument", "Check the admin details.");
  }
  const userRef = db.collection("users").doc(uid);
  const profile = await userRef.get();
  if (!profile.exists || profile.data().role !== "admin") {
    throw new HttpsError("not-found", "Branch admin account was not found.");
  }
  const before = profile.data();
  const previousEmail = String(before.email || "").toLowerCase();
  const displayName = `${firstName} ${lastName}`.trim();

  // 1. Firebase Auth (sign-in email + display name).
  try {
    const authUpdate = {displayName};
    if (email !== previousEmail) authUpdate.email = email;
    await admin.auth().updateUser(uid, authUpdate);
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "That email already has an account.");
    }
    if (error.code !== "auth/user-not-found") {
      console.error("updateBranchAdmin auth update failed", error);
      throw new HttpsError("internal", "Unable to update the admin account.");
    }
  }

  // 2. Profile + branch assignment, atomically. One admin per branch.
  let branchName = before.branchName || branchId;
  try {
    await db.runTransaction(async (transaction) => {
      const current = await transaction.get(userRef);
      if (!current.exists || current.data().role !== "admin") {
        throw new HttpsError("failed-precondition", "Admin account changed during update.");
      }
      const oldBranchId = String(current.data().branchId || "");
      const newBranchRef = db.collection("branches").doc(branchId);
      const newBranch = await transaction.get(newBranchRef);
      if (!newBranch.exists) {
        throw new HttpsError("failed-precondition", "Choose an existing branch.");
      }
      const update = {
        firstName,
        lastName,
        phone,
        email,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: editorId,
      };
      const branch = newBranch.data();
      branchName = branch.name || branchId;
      if (branchId !== oldBranchId) {
        if (branch.isActive !== true) {
          throw new HttpsError("failed-precondition", "Choose an active branch.");
        }
        const members = await transaction.get(
            db.collection("users").where("branchId", "==", branchId));
        const taken = members.docs.some((doc) => doc.id !== uid &&
          (doc.data().role || doc.data().roleId) === "admin");
        if (taken) {
          throw new HttpsError("already-exists", "This branch already has an admin.");
        }
        let oldBranch;
        const oldBranchRef = oldBranchId ? db.collection("branches").doc(oldBranchId) : null;
        if (oldBranchRef) oldBranch = await transaction.get(oldBranchRef);
        Object.assign(update, {
          branchId,
          branchCode: branch.branchCode || branchId,
          branchName,
          branchShortName: branch.shortName || branch.name || branchId,
        });
        if (oldBranch && oldBranch.exists && oldBranch.data().adminUid === uid) {
          transaction.update(oldBranchRef, {
            adminUid: FieldValue.delete(),
            adminAssignedAt: FieldValue.delete(),
          });
        }
        transaction.set(newBranchRef, {
          adminUid: uid,
          adminAssignedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      }
      transaction.update(userRef, update);
    });
  } catch (error) {
    // Keep Auth and Firestore consistent: undo the email change.
    if (email !== previousEmail && previousEmail) {
      await admin.auth().updateUser(uid, {email: previousEmail}).catch(() => {});
    }
    if (error instanceof HttpsError) throw error;
    console.error("updateBranchAdmin failed", error);
    throw new HttpsError("internal", "Unable to update the admin account.");
  }
  return {uid, email, branchName};
});

/**
 * Writes the same field values to every user matching a query, in batches.
 * @param {object} query - Firestore query selecting the users.
 * @param {object} values - Field values to set.
 * @return {Promise<number>} Number of updated documents.
 */
async function updateUsersWhere(query, values) {
  const snapshot = await query.get();
  let count = 0;
  for (let i = 0; i < snapshot.docs.length; i += 450) {
    const batch = db.batch();
    for (const doc of snapshot.docs.slice(i, i + 450)) {
      batch.update(doc.ref, values);
      count++;
    }
    await batch.commit();
  }
  return count;
}

// Users keep a copy of their branch name for fast display. When a super admin
// renames a branch, copy the new name onto every member of that branch.
exports.onBranchRenamed = onDocumentWritten("branches/{branchId}", async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : null;
  const after = event.data.after.exists ? event.data.after.data() : null;
  if (!before || !after) return;
  if (before.name === after.name && before.shortName === after.shortName) return;
  const branchId = event.params.branchId;
  const count = await updateUsersWhere(
      db.collection("users").where("branchId", "==", branchId), {
        branchName: after.name || branchId,
        branchShortName: after.shortName || after.name || branchId,
      });
  console.log(`onBranchRenamed: ${branchId} → updated ${count} users`);
});

// Users keep a copy of their role name. When a role is renamed, copy it.
exports.onRoleRenamed = onDocumentWritten("roles/{roleId}", async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : null;
  const after = event.data.after.exists ? event.data.after.data() : null;
  if (!after) return;
  if (before && before.name === after.name &&
      (before.abbreviation || "") === (after.abbreviation || "")) return;
  const roleId = event.params.roleId;
  if (roleId === "admin" || roleId === "super_admin") return;
  const count = await updateUsersWhere(
      db.collection("users").where("roleId", "==", roleId), {
        roleName: after.name,
        roleAbbreviation: after.abbreviation || "",
      });
  console.log(`onRoleRenamed: ${roleId} → updated ${count} users`);
});

exports.deleteBranchAdmin = onCall(async (request) => {
  await requireSuperAdmin(request);
  const uid = String(request.data && request.data.uid || "").trim();
  if (!uid) throw new HttpsError("invalid-argument", "Admin UID is required.");
  const userRef = db.collection("users").doc(uid);
  const profile = await userRef.get();
  if (!profile.exists || profile.data().role !== "admin") {
    throw new HttpsError("not-found", "Branch admin account was not found.");
  }
  const branchId = String(profile.data().branchId || "");
  try {
    try {
      await admin.auth().deleteUser(uid);
    } catch (error) {
      if (error.code !== "auth/user-not-found") throw error;
    }
    await db.runTransaction(async (transaction) => {
      const currentProfile = await transaction.get(userRef);
      if (!currentProfile.exists || currentProfile.data().role !== "admin") {
        throw new HttpsError("failed-precondition", "Admin account changed during deletion.");
      }
      let branchRef;
      let branch;
      if (branchId) {
        branchRef = db.collection("branches").doc(branchId);
        branch = await transaction.get(branchRef);
      }
      transaction.delete(userRef);
      if (branch && branch.exists && branch.data().adminUid === uid) {
        transaction.update(branchRef, {
          adminUid: FieldValue.delete(),
          adminAssignedAt: FieldValue.delete(),
        });
      }
    });
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("deleteBranchAdmin failed", error);
    throw new HttpsError("internal", "Unable to delete the admin account.");
  }
  return {success: true};
});

exports.previewBranchPointsReset = onCall({
  timeoutSeconds: 180,
  memory: "512MiB",
}, async (request) => {
  await requireSuperAdmin(request);
  const branchId = String((request.data || {}).branchId || "").trim();
  const {branchRef, branch, members} = await getBranchAndMembers(branchId);
  const keys = pointsUserKeys(members);
  const historyDocs = await getHistoryDocs(keys);
  let currentPoints = 0;
  let embeddedHistoryEntries = 0;
  const pointsRefs = keys.map((key) => db.collection("user_points").doc(key));
  const pointsById = new Map();
  for (let i = 0; i < pointsRefs.length; i += 300) {
    const snapshots = await db.getAll(...pointsRefs.slice(i, i + 300));
    for (const snapshot of snapshots) {
      if (snapshot.exists) pointsById.set(snapshot.id, snapshot.data());
    }
  }
  for (const member of members) {
    const userData = member.data();
    const phone = String(userData.phone || "").replace(/\D/g, "");
    const pointsData = pointsById.get(member.id) || pointsById.get(phone);
    currentPoints += Math.max(
        Number(userData.totalPoints || 0),
        Number(pointsData ? pointsData.totalPoints || 0 : 0));
    embeddedHistoryEntries += Array.isArray(userData.pointsHistory) ?
      userData.pointsHistory.length : 0;
    embeddedHistoryEntries += pointsData &&
        Array.isArray(pointsData.pointsHistory) ?
      pointsData.pointsHistory.length : 0;
  }
  return {
    branchId: branchRef.id,
    branchName: branch.name || branchRef.id,
    eligibleUsers: members.length,
    pointsDocuments: pointsById.size,
    historyDocuments: historyDocs.length,
    embeddedHistoryEntries,
    currentPoints,
  };
});

exports.clearBranchPoints = onCall({
  timeoutSeconds: 540,
  memory: "1GiB",
}, async (request) => {
  const creatorId = await requireSuperAdmin(request);
  const data = request.data || {};
  const branchId = String(data.branchId || "").trim();
  if (data.confirmBranchId !== branchId || !branchId) {
    throw new HttpsError("failed-precondition", "Branch confirmation did not match.");
  }

  const {branchRef, branch, members} = await getBranchAndMembers(branchId);
  if (Number(data.expectedUsers) !== members.length) {
    throw new HttpsError(
        "aborted", "Branch users changed. Preview the cleanup again.");
  }

  const keys = pointsUserKeys(members);
  const historyDocs = await getHistoryDocs(keys);
  const now = FieldValue.serverTimestamp();
  const writer = db.bulkWriter();
  writer.onWriteError((error) => error.failedAttempts < 3);

  for (const member of members) {
    const userData = member.data();
    const update = {totalPoints: 0, tier: "Bronze", lastUpdated: now};
    if (Array.isArray(userData.pointsHistory)) update.pointsHistory = [];
    writer.set(member.ref, update, {merge: true});
  }
  let pointsDocumentsReset = 0;
  const pointsRefs = keys.map((key) => db.collection("user_points").doc(key));
  for (let i = 0; i < pointsRefs.length; i += 300) {
    const snapshots = await db.getAll(...pointsRefs.slice(i, i + 300));
    for (const pointsDoc of snapshots) {
      if (pointsDoc.exists) {
        pointsDocumentsReset++;
        const pointsRef = pointsDoc.ref;
        writer.set(pointsRef, {
          totalPoints: 0,
          tier: "Bronze",
          pointsHistory: [],
          lastUpdated: now,
        }, {merge: true});
      }
    }
  }
  for (const history of historyDocs) writer.delete(history.ref);

  try {
    await writer.close();
  } catch (error) {
    console.error("clearBranchPoints had write failures", error);
    throw new HttpsError(
        "internal", "Cleanup was incomplete. Review the branch before retrying.");
  }

  const summary = {
    branchId: branchRef.id,
    branchName: branch.name || branchRef.id,
    usersReset: members.length,
    pointsDocumentsReset,
    historyDocumentsDeleted: historyDocs.length,
    completedAt: FieldValue.serverTimestamp(),
    createdBy: creatorId,
    usersDeleted: 0,
    billsDeleted: 0,
  };
  try {
    await db.collection("branch_points_cleanup_logs").add(summary);
  } catch (error) {
    console.error("Unable to write branch points cleanup audit log", error);
  }
  return {
    branchId: summary.branchId,
    branchName: summary.branchName,
    usersReset: summary.usersReset,
    pointsDocumentsReset: summary.pointsDocumentsReset,
    historyDocumentsDeleted: summary.historyDocumentsDeleted,
    usersDeleted: 0,
    billsDeleted: 0,
  };
});

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Return loyalty tier name for a given points total.
 * @param {number} points - Total accumulated points.
 * @return {string} Tier name.
 */
function calculateTier(points) {
  if (points >= 10000) return "Platinum";
  if (points >= 5000) return "Gold";
  if (points >= 2000) return "Silver";
  return "Bronze";
}

const DEFAULT_RUPEES_PER_POINT = {
  carpenter: 1000, interior_designer: 1000, architect: 5000, engineer: 5000,
};

/**
 * Rupees of approved purchases per point for a role: the role record's
 * `rupeesPerPoint`, else the built-in default for that role, else 1000.
 * @param {string|undefined} role - The member's role ID.
 * @return {Promise<number>} Rupees per point.
 */
async function rupeesPerPointForRole(role) {
  const id = String(role || "").trim().toLowerCase();
  const fallback = DEFAULT_RUPEES_PER_POINT[id] || 1000;
  if (!id) return fallback;
  try {
    const doc = await db.collection("roles").doc(id).get();
    const n = Number(doc.exists ? doc.data().rupeesPerPoint : NaN);
    return Number.isFinite(n) && n >= 1 && n <= 1000000 ? n : fallback;
  } catch (e) {
    return fallback;
  }
}

/**
 * Resolve the canonical user document for a carpenterId.
 * carpenterId may be a UID or a phone number (legacy).
 * Returns { ref, data } or null.
 * @param {string} carpenterId - UID or phone number of the carpenter.
 * @return {Promise<{ref: FirebaseFirestore.DocumentReference, data: object}|null>}
 */
async function resolveUserDoc(carpenterId) {
  // Try direct doc lookup first (UID-based)
  const direct = await db.collection("users").doc(carpenterId).get();
  if (direct.exists) return {ref: direct.ref, data: direct.data()};

  // Fall back to phone query
  const q = await db.collection("users")
      .where("phone", "==", carpenterId)
      .limit(1)
      .get();
  if (!q.empty) return {ref: q.docs[0].ref, data: q.docs[0].data()};

  return null;
}

/**
 * Saves a queued notification to `notification_logs`, the list the app shows
 * on the Notifications screen, whether or not the push was delivered.
 * @param {string} queueId - The notification_queue document ID.
 * @param {object} doc - The queued notification.
 * @param {string} pushStatus - "sent", "failed" or "no_token".
 * @return {Promise<void>}
 */
async function saveInAppRecord(queueId, doc, pushStatus) {
  try {
    await db.collection("notification_logs").add(
        inAppRecordFor(queueId, doc, pushStatus, FieldValue.serverTimestamp()));
  } catch (err) {
    console.error(`[notifQueue/${queueId}] in-app log failed:`, err.message);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. processNotificationQueue
// ─────────────────────────────────────────────────────────────────────────────

exports.processNotificationQueue = onDocumentCreated(
    "notification_queue/{queueId}",
    async (event) => {
      const queueId = event.params.queueId;
      const snap = event.data;
      const doc = snap.data();

      const {fcmToken, title, body, status, type} = doc;
      const rawData = doc.data || {};

      if (status !== "pending") {
        console.log(`[notifQueue/${queueId}] skip – status: ${status}`);
        return null;
      }

      if (!fcmToken || typeof fcmToken !== "string" || fcmToken.length === 0) {
        console.error(`[notifQueue/${queueId}] no fcmToken – marking failed`);
        await snap.ref.update({status: "failed", error: "Missing fcmToken"});
        await saveInAppRecord(queueId, doc, "no_token");
        return null;
      }

      try {
        const dataPayload = {type: type || ""};
        if (rawData && typeof rawData === "object") {
          for (const [k, v] of Object.entries(rawData)) {
            if (v === null || v === undefined) continue;
            if (typeof v === "object" && typeof v.toDate === "function") {
              dataPayload[k] = v.toDate().toISOString();
            } else {
              dataPayload[k] = String(v);
            }
          }
        }

        const isHighPriority = type === "billApproved" ||
          type === "pointsWithdrawn" || type === "tierUpgraded";
        const channelId = isHighPriority ?
          "balaji_points_important" : "balaji_points_default";

        await admin.messaging().send({
          token: fcmToken,
          notification: {title: title || "Balaji Points", body: body || ""},
          data: dataPayload,
          android: {
            priority: doc.priority === "high" ? "high" : "normal",
            notification: {channelId, sound: "default"},
          },
          apns: {
            payload: {aps: {sound: "default"}},
            fcmOptions: {},
          },
        });

        await snap.ref.update({
          status: "sent",
          sentAt: FieldValue.serverTimestamp(),
        });
        await saveInAppRecord(queueId, doc, "sent");
        console.log(`[notifQueue/${queueId}] FCM sent + logged`);
        return null;
      } catch (err) {
        console.error(`[notifQueue/${queueId}] FCM error:`, err.message);
        await snap.ref.update({
          status: "failed",
          error: err.message || String(err),
          failedAt: FieldValue.serverTimestamp(),
        });
        // The push failed (e.g. an old or missing token), but the member
        // still sees the notification in the app.
        await saveInAppRecord(queueId, doc, "failed");
        return null;
      }
    },
);

// ─────────────────────────────────────────────────────────────────────────────
// 1b. onBillCreated  –  validate bill on creation (siteName, amount, date)
//                     –  check for duplicates
// ─────────────────────────────────────────────────────────────────────────────

exports.onBillCreated = onDocumentCreated(
    "bills/{billId}",
    async (event) => {
      const billId = event.params.billId;
      const bill = event.data.data();

      console.log(`[bill/${billId}] created – validating...`);

      try {
        // 1. Validate required fields
        if (!bill.siteName || typeof bill.siteName !== "string" || bill.siteName.trim() === "") {
          console.error(`[bill/${billId}] validation failed: siteName is required`);
          await event.data.ref.update({
            validationError: "Site name is required",
            validatedAt: FieldValue.serverTimestamp(),
          });
          return null;
        }

        if (!bill.amount || typeof bill.amount !== "number" || bill.amount <= 0) {
          console.error(`[bill/${billId}] validation failed: invalid amount`);
          await event.data.ref.update({
            validationError: "Bill amount must be greater than 0",
            validatedAt: FieldValue.serverTimestamp(),
          });
          return null;
        }

        // 2. Validate bill date not in future
        if (bill.billDate) {
          const billDate = bill.billDate.toDate ? bill.billDate.toDate() : new Date(bill.billDate);

          // Compares calendar days in India time, so a bill dated today
          // is accepted whatever its time of day.
          if (isFutureBillDate(billDate, new Date())) {
            console.error(`[bill/${billId}] validation failed: bill date is in future`);
            await event.data.ref.update({
              validationError: "Bill date cannot be in the future",
              validatedAt: FieldValue.serverTimestamp(),
            });
            return null;
          }
        }

        // 3. Check for duplicate bill
        const {start, end} = indiaDayBounds(bill.billDate ?
          (bill.billDate.toDate ? bill.billDate.toDate() : new Date(bill.billDate)) :
          new Date());

        const carpenterId = bill.carpenterId || bill.carpenterPhone;
        const siteName = bill.siteName.trim();
        const amount = bill.amount;

        const duplicateQuery = await db.collection("bills")
            .where("carpenterId", "==", carpenterId)
            .where("siteName", "==", siteName)
            .where("amount", "==", amount)
            .where("billDate", ">=", Timestamp.fromDate(start))
            .where("billDate", "<", Timestamp.fromDate(end))
            .get();

        // The new bill matches its own search, so it is left out.
        const duplicates = duplicateQuery.docs.filter((d) =>
          d.id !== billId && d.data().status !== "withdrawn");

        if (duplicates.length > 0) {
          // Found a duplicate
          const duplicateBill = duplicates[0];
          console.warn(
              `[bill/${billId}] duplicate detected: matches bill ${duplicateBill.id} ` +
              `(site: ${siteName}, amount: ${amount})`,
          );

          // Mark bill as having a duplicate (but still allow it)
          await event.data.ref.update({
            isDuplicate: true,
            duplicateOf: duplicateBill.id,
            duplicateDetectedAt: FieldValue.serverTimestamp(),
          });
          return null;
        }

        // 4. All validations passed
        console.log(`[bill/${billId}] validation passed ✓`);
        await event.data.ref.update({
          validatedAt: FieldValue.serverTimestamp(),
        });

        return null;
      } catch (err) {
        console.error(`[bill/${billId}] validation error:`, err.message);
        await event.data.ref.update({
          validationError: err.message || "Validation failed",
          validatedAt: FieldValue.serverTimestamp(),
        }).catch(() => {});
        return null;
      }
    },
);

// ─────────────────────────────────────────────────────────────────────────────
// 2. onBillStatusChanged  –  bill approved → points + tier + history
//                          –  bill rejected → FCM to carpenter
// ─────────────────────────────────────────────────────────────────────────────

exports.onBillStatusChanged = onDocumentWritten(
    "bills/{billId}",
    async (event) => {
      const billId = event.params.billId;
      const before = event.data.before.data();
      const after = event.data.after.data();

      // Only react to status transitions
      if (!before || !after) return null;
      if (before.status === after.status) return null;

      const newStatus = after.status;

      // ── APPROVED ──────────────────────────────────────────────────────────
      if (newStatus === "approved" && before.status === "pending") {
        const billBranchId = after.branchId;
        const carpenterId = after.carpenterId;
        const amount = after.amount;

        if (!carpenterId || !amount) {
          console.error(`[bill/${billId}] approved – missing carpenterId or amount`);
          return null;
        }

        // Client-side BillService.approveBill() already credits points, writes
        // history, and queues notifications in one Firestore transaction.
        // Skip server-side credit to avoid duplicate history / wrong totals.
        if (after.approvedBy) {
          console.log(
              `[bill/${billId}] approved – client handled points/notifications, skipping`,
          );
          return null;
        }

        const user = await resolveUserDoc(carpenterId);
        if (!user) {
          console.error(`[bill/${billId}] user not found for carpenter ${carpenterId}`);
          return null;
        }

        // ── Branch isolation check ──────────────────────────────────────────
        const userBranchId = user.data.branchId;
        if (billBranchId && userBranchId && billBranchId !== userBranchId) {
          console.error(
              `[bill/${billId}] BRANCH MISMATCH – ` +
              `bill.branchId=${billBranchId} vs user.branchId=${userBranchId}. ` +
              `Aborting to prevent cross-store data corruption.`,
          );
          return null;
        }

        const uid = user.ref.id;
        const pointsRef = db.collection("user_points").doc(uid);
        const pointsSnap = await pointsRef.get();

        // Idempotency: bill may already be credited via another path.
        if (pointsSnap.exists) {
          const history = pointsSnap.data().pointsHistory || [];
          if (history.some((entry) => entry.billId === billId)) {
            console.log(`[bill/${billId}] already in pointsHistory – skipping`);
            return null;
          }
        }

        // Points at the member's role rate (rupees per point, set per role
        // by the super admin), with decimals (₹2500 at 1000 → 2.5 pts).
        // Rate locked at submission (bill.rupeesPerPoint), else role rate.
        const savedRate = Number(after.rupeesPerPoint);
        const rate = Number.isFinite(savedRate) && savedRate >= 1 && savedRate <= 1000000 ?
          savedRate :
          await rupeesPerPointForRole(user.data.role);
        const pointsEarned = Number(after.pointsEarned) > 0 ?
          Number(after.pointsEarned) :
          amount / rate;
        const currentPoints = pointsSnap.exists ?
          (pointsSnap.data().totalPoints || 0) :
          (user.data.totalPoints || 0);
        const newTotalPoints = currentPoints + pointsEarned;
        const oldTier = user.data.tier || "Bronze";
        const newTier = calculateTier(newTotalPoints);

        const batch = db.batch();

        // 1. Update users doc
        batch.set(user.ref, {
          totalPoints: newTotalPoints,
          tier: newTier,
          lastUpdated: FieldValue.serverTimestamp(),
        }, {merge: true});

        // 2. Update user_points doc
        const historyEntry = {
          points: pointsEarned,
          reason: "Bill approval",
          date: Timestamp.now(),
          billId,
          amount,
          branchId: billBranchId || userBranchId || null,
        };

        if (pointsSnap.exists) {
          batch.update(pointsRef, {
            totalPoints: newTotalPoints,
            tier: newTier,
            lastUpdated: FieldValue.serverTimestamp(),
            pointsHistory: FieldValue.arrayUnion(historyEntry),
          });
        } else {
          batch.set(pointsRef, {
            userId: uid,
            branchId: userBranchId || billBranchId || null,
            totalPoints: newTotalPoints,
            tier: newTier,
            lastUpdated: FieldValue.serverTimestamp(),
            pointsHistory: [historyEntry],
          });
        }

        // 3. Write points_history doc
        const histRef = db.collection("points_history").doc();
        batch.set(histRef, {
          userId: uid,
          carpenterId,
          branchId: billBranchId || userBranchId || null,
          points: pointsEarned,
          reason: "Bill approval",
          billId,
          amount,
          createdAt: FieldValue.serverTimestamp(),
        });

        await batch.commit();
        console.log(`[bill/${billId}] approved – +${pointsEarned} pts → ${uid} (${newTier})`);

        // 4. Tier upgrade notification
        if (newTier !== oldTier) {
          const fcmToken = user.data.fcmToken;
          if (fcmToken) {
            await db.collection("notification_queue").add({
              userId: uid,
              fcmToken,
              type: "tierUpgraded",
              title: "Tier Upgraded! 🎉",
              body: `Congratulations! You've reached ${newTier} tier.`,
              data: {oldTier, newTier, totalPoints: String(newTotalPoints)},
              status: "pending",
              priority: "high",
              branchId: userBranchId || billBranchId || null,
              createdAt: FieldValue.serverTimestamp(),
            });
          }
        }

        // 5. Bill approved notification
        const fcmToken = user.data.fcmToken;
        if (fcmToken) {
          await db.collection("notification_queue").add({
            userId: uid,
            fcmToken,
            type: "billApproved",
            title: "Bill Approved ✅",
            body: `Your bill of ₹${amount} has been approved. +${pointsEarned} points added!`,
            data: {billId, points: String(pointsEarned), totalPoints: String(newTotalPoints)},
            status: "pending",
            priority: "high",
            branchId: userBranchId || billBranchId || null,
            createdAt: FieldValue.serverTimestamp(),
          });
        }

        return null;
      }

      // ── REJECTED ──────────────────────────────────────────────────────────
      if (newStatus === "rejected" && before.status === "pending") {
        const billBranchId = after.branchId;
        const carpenterId = after.carpenterId;
        const amount = after.amount;

        if (!carpenterId) return null;

        // Like approvals: the app already notified the member when it
        // rejected the bill, so a second push would be a duplicate.
        if (after.rejectedBy) {
          console.log(
              `[bill/${billId}] rejected – client handled notification, skipping`,
          );
          return null;
        }

        const user = await resolveUserDoc(carpenterId);
        if (!user) return null;

        // Branch isolation check
        const userBranchId = user.data.branchId;
        if (billBranchId && userBranchId && billBranchId !== userBranchId) {
          console.error(
              `[bill/${billId}] BRANCH MISMATCH on reject – aborting notification`,
          );
          return null;
        }

        const fcmToken = user.data.fcmToken;
        if (fcmToken) {
          await db.collection("notification_queue").add({
            userId: user.ref.id,
            fcmToken,
            type: "billRejected",
            title: "Bill Rejected",
            body: `Your bill of ₹${amount} was rejected. Contact your branch admin for details.`,
            data: {billId, amount: String(amount)},
            status: "pending",
            priority: "normal",
            branchId: userBranchId || billBranchId || null,
            createdAt: FieldValue.serverTimestamp(),
          });
        }

        console.log(`[bill/${billId}] rejected – notification queued for ${carpenterId}`);
        return null;
      }

      return null;
    },
);

// ─────────────────────────────────────────────────────────────────────────────
// 3. onPointsChanged  –  tier recalculation safety-net
//    Runs whenever user_points is written.  If the tier stored doesn't match
//    the tier computed from totalPoints, it corrects it.
//    This catches any client-side write that updates points but forgets tier.
// ─────────────────────────────────────────────────────────────────────────────

exports.onPointsChanged = onDocumentWritten(
    "user_points/{userId}",
    async (event) => {
      const userId = event.params.userId;
      const after = event.data.after.data();
      if (!after) return null; // deleted

      const totalPoints = after.totalPoints || 0;
      const storedTier = after.tier;
      const correctTier = calculateTier(totalPoints);

      if (storedTier === correctTier) return null; // already consistent

      // Verify user exists and branchId matches
      const userSnap = await db.collection("users").doc(userId).get();
      if (!userSnap.exists) {
        console.warn(`[userPoints/${userId}] user doc not found – skipping tier fix`);
        return null;
      }

      const userBranchId = userSnap.data().branchId;
      const pointsBranchId = after.branchId;

      if (userBranchId && pointsBranchId && userBranchId !== pointsBranchId) {
        console.error(
            `[userPoints/${userId}] BRANCH MISMATCH – ` +
            `user.branchId=${userBranchId} vs user_points.branchId=${pointsBranchId}. ` +
            `Skipping tier correction.`,
        );
        return null;
      }

      await event.data.after.ref.update({tier: correctTier});
      await db.collection("users").doc(userId).set(
          {tier: correctTier, lastUpdated: FieldValue.serverTimestamp()},
          {merge: true},
      );

      console.log(`[userPoints/${userId}] tier corrected: ${storedTier} → ${correctTier}`);
      return null;
    },
);

// ─────────────────────────────────────────────────────────────────────────────
// 4. onUserDeleted  –  cascade-delete related data when a user doc is deleted
// ─────────────────────────────────────────────────────────────────────────────

exports.onUserDeleted = onDocumentDeleted(
    "users/{userId}",
    async (event) => {
      const userId = event.params.userId;
      const userData = event.data.data();
      const branchId = userData ? userData.branchId : null;
      const phone = userData ? userData.phone : null;

      if (userData && userData.role === "admin" && branchId) {
        const branchRef = db.collection("branches").doc(branchId);
        await db.runTransaction(async (transaction) => {
          const branch = await transaction.get(branchRef);
          if (branch.exists && branch.data().adminUid === userId) {
            transaction.update(branchRef, {
              adminUid: FieldValue.delete(),
              adminAssignedAt: FieldValue.delete(),
            });
          }
        });
      }

      // Removing a branch admin must not run member cleanup by phone number.
      // Their account is administrative and does not own carpenter points or bills.
      if (userData && userData.role === "admin") {
        console.log(`[admin/${userId}] deleted – skipped member data cleanup`);
        return null;
      }

      console.log(`[user/${userId}] deleted – cascading cleanup (branch: ${branchId})`);

      // 1. Delete user_points
      await db.collection("user_points").doc(userId).delete().catch(() => {});

      // 2. Delete points_history docs for this user
      const histSnap = await db.collection("points_history")
          .where("userId", "==", userId)
          .get();
      const histBatch = db.batch();
      histSnap.docs.forEach((d) => histBatch.delete(d.ref));
      if (!histSnap.empty) await histBatch.commit();

      // 3. Delete bills – verify branchId to avoid touching other stores
      const billsQuery = phone ?
        db.collection("bills").where("carpenterPhone", "==", phone) :
        db.collection("bills").where("carpenterId", "==", userId);

      const billsSnap = await billsQuery.get();
      const billsBatch = db.batch();
      let billCount = 0;
      billsSnap.docs.forEach((d) => {
        const billBranch = d.data().branchId;
        // Only delete bills that belong to the same branch as the user
        if (!branchId || !billBranch || branchId === billBranch) {
          billsBatch.delete(d.ref);
          billCount++;
        } else {
          console.warn(
              `[user/${userId}] skipping bill ${d.id} – ` +
              `bill.branchId=${billBranch} != user.branchId=${branchId}`,
          );
        }
      });
      if (billCount > 0) await billsBatch.commit();

      console.log(
          `[user/${userId}] cleanup done – ` +
          `${histSnap.size} history, ${billCount} bills deleted`,
      );
      return null;
    },
);

/**
 * PIN login for branch admins. A PIN login has no Firebase sign-in, so the
 * security rules cannot tell an admin from anyone else and admin-only data
 * (enquiries, catalog editing) is refused. The app calls this once during
 * an admin's PIN login with the PIN just typed; the PIN is checked here on
 * the server (never a hash from the phone, since user records are public)
 * and a Firebase sign-in token for the admin's own user document is
 * returned. Five wrong PINs lock the phone for 15 minutes.
 */
exports.adminPinSignIn = onCall({
  // Runs as the Firebase Admin SDK service account, which can sign custom
  // tokens (the default compute account cannot: signBlob was denied).
  serviceAccount: "firebase-adminsdk-fbsvc@balajipoints.iam.gserviceaccount.com",
}, async (request) => {
  const phone = pinSignIn.normalizePhone(request.data && request.data.phone);
  const pin = String((request.data && request.data.pin) || "");
  if (phone.length !== 10 || !/^\d{4,6}$/.test(pin)) {
    throw new HttpsError("invalid-argument", "Phone and PIN are required.");
  }

  const attemptsRef = db.doc(`pin_signin_attempts/${phone}`);
  const now = Date.now();
  const attempts = (await attemptsRef.get()).data();
  if (pinSignIn.isLocked(attempts, now)) {
    throw new HttpsError("resource-exhausted",
        "Too many wrong PINs. Try again in 15 minutes.");
  }

  const byField = await db.collection("users")
      .where("phone", "==", phone).get();
  let docs = byField.docs.map((d) => ({id: d.id, data: d.data()}));
  if (docs.length === 0) {
    const byId = await db.doc(`users/${phone}`).get();
    if (byId.exists) docs = [{id: byId.id, data: byId.data()}];
  }

  const match = pinSignIn.matchAdmin(docs, pin);
  if (!match) {
    await attemptsRef.set(pinSignIn.afterFailure(attempts, now));
    throw new HttpsError("permission-denied", "Not a branch admin PIN.");
  }

  await attemptsRef.delete();
  const token = await admin.auth().createCustomToken(match.id, {
    role: "admin",
    branchId: match.branchId,
    loginMethod: "pin",
  });
  return {token, uid: match.id};
});

// ─────────────────────────────────────────────────────────────────────────────
// 6. onMemberSignUp  –  a member who signs up themselves waits for approval
// ─────────────────────────────────────────────────────────────────────────────

exports.onMemberSignUp = onDocumentWritten("users/{userId}", async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : undefined;
  const after = event.data.after.exists ? event.data.after.data() : undefined;
  if (!approval.isNewMemberSignUp(before, after)) return null;

  const userId = event.params.userId;
  const branchId = String(after.branchId).trim();
  await event.data.after.ref.set({
    profile_verified: false,
    approvalStatus: after.approvalStatus === "rejected" ? "rejected" : "pending",
    approvalRequestedAt: after.approvalRequestedAt ||
      FieldValue.serverTimestamp(),
    approvalNotifiedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  // Push every admin of this branch (the in-app record is saved by
  // processNotificationQueue even when a push cannot be delivered).
  const name = `${after.firstName || ""} ${after.lastName || ""}`.trim() ||
    after.displayName || after.phone || "New member";
  const roleName = after.roleName || after.role || "Member";
  const admins = await db.collection("users")
      .where("branchId", "==", branchId).where("role", "==", "admin").get();
  const batch = db.batch();
  let queued = 0;
  for (const adminDoc of admins.docs) {
    const token = adminDoc.data().fcmToken;
    batch.set(db.collection("notification_queue").doc(), {
      userId: adminDoc.id,
      fcmToken: typeof token === "string" ? token : "",
      branchId,
      type: "newUserRegistered",
      title: "New account request",
      body: `${name} · ${roleName}`,
      data: {
        userId,
        userPhone: after.phone || "",
        screen: "/account-requests",
      },
      priority: "high",
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
    });
    queued++;
  }
  if (queued > 0) await batch.commit();
  console.log(`[onMemberSignUp/${userId}] pending; ${queued} admin(s) notified`);
  return null;
});

// ─────────────────────────────────────────────────────────────────────────────
// 7. reviewMemberAccount  –  approve or reject a member sign-up
// ─────────────────────────────────────────────────────────────────────────────

exports.reviewMemberAccount = onCall(async (request) => {
  const caller = request.auth;
  if (!caller) {
    throw new HttpsError("unauthenticated", "Please sign in again.");
  }
  const data = request.data || {};
  const userId = String(data.userId || "").trim();
  const action = data.action;
  if (!userId || (action !== "approve" && action !== "reject")) {
    throw new HttpsError("invalid-argument", "Choose an account and action.");
  }

  // Only the admin of the member's own branch (never the super admin).
  const callerSnap = await db.collection("users").doc(caller.uid).get();
  const callerData = callerSnap.exists ? callerSnap.data() : null;
  const targetRef = db.collection("users").doc(userId);
  const targetSnap = await targetRef.get();
  const target = targetSnap.exists ? targetSnap.data() : null;

  const denied = approval.reviewDenied(callerData, target);
  if (denied) throw new HttpsError("permission-denied", denied);

  const name = callerData ?
    `${callerData.firstName || ""} ${callerData.lastName || ""}`.trim() : "";
  const fields = approval.reviewFields(action,
      {uid: caller.uid, name: name || "Branch admin"},
      data.reason, FieldValue.serverTimestamp());
  await targetRef.set(fields, {merge: true});

  // Tell the member when they are approved and have a push token.
  if (action === "approve" && typeof target.fcmToken === "string" &&
      target.fcmToken) {
    await db.collection("notification_queue").add({
      userId,
      fcmToken: target.fcmToken,
      branchId: target.branchId || null,
      type: "accountApproved",
      title: "Account approved",
      body: "Your Balaji Points account is approved. You can sign in now.",
      data: {screen: "/login"},
      priority: "high",
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  console.log(`[reviewMemberAccount] ${caller.uid} ${action}d ${userId}`);
  return {ok: true, status: fields.approvalStatus};
});
