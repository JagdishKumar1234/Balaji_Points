/**
 * Balaji Points - Cloud Functions
 *
 * Triggers:
 *  1. processNotificationQueue   – FCM push on notification_queue create
 *  1b. onBillCreated             – validate bill (siteName, amount, date) + detect duplicates
 *  2. onBillStatusChanged        – points + tier + history on bill approval/rejection
 *  3. onPointsChanged            – tier recalculation safety-net on user_points write
 *  4. onUserDeleted              – cascade-delete user_points / bills / points_history
 *
 * Branch-isolation contract (applied in every trigger that touches user data):
 *   bill.branchId  must equal  user.branchId
 *   If they differ the trigger logs an error and aborts — no cross-store writes.
 */

const {onDocumentCreated, onDocumentWritten, onDocumentDeleted} =
  require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

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
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`[notifQueue/${queueId}] FCM sent`);
        return null;
      } catch (err) {
        console.error(`[notifQueue/${queueId}] FCM error:`, err.message);
        await snap.ref.update({
          status: "failed",
          error: err.message || String(err),
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
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
            validatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          return null;
        }

        if (!bill.amount || typeof bill.amount !== "number" || bill.amount <= 0) {
          console.error(`[bill/${billId}] validation failed: invalid amount`);
          await event.data.ref.update({
            validationError: "Bill amount must be greater than 0",
            validatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          return null;
        }

        // 2. Validate bill date not in future
        if (bill.billDate) {
          const billDate = bill.billDate.toDate ? bill.billDate.toDate() : new Date(bill.billDate);
          const today = new Date();
          today.setHours(0, 0, 0, 0);

          if (billDate > today) {
            console.error(`[bill/${billId}] validation failed: bill date is in future`);
            await event.data.ref.update({
              validationError: "Bill date cannot be in the future",
              validatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            return null;
          }
        }

        // 3. Check for duplicate bill
        const billDateOnly = bill.billDate ?
          new Date(bill.billDate.toDate ? bill.billDate.toDate() : bill.billDate) :
          new Date();
        billDateOnly.setHours(0, 0, 0, 0);

        const billDateEndOfDay = new Date(billDateOnly);
        billDateEndOfDay.setDate(billDateEndOfDay.getDate() + 1);

        const carpenterId = bill.carpenterId || bill.carpenterPhone;
        const siteName = bill.siteName.trim();
        const amount = bill.amount;

        const duplicateQuery = await db.collection("bills")
            .where("carpenterId", "==", carpenterId)
            .where("siteName", "==", siteName)
            .where("amount", "==", amount)
            .where("billDate", ">=", admin.firestore.Timestamp.fromDate(billDateOnly))
            .where("billDate", "<", admin.firestore.Timestamp.fromDate(billDateEndOfDay))
            .where("status", "!=", "withdrawn")
            .get();

        if (!duplicateQuery.empty) {
          // Found a duplicate
          const duplicateBill = duplicateQuery.docs[0];
          console.warn(
              `[bill/${billId}] duplicate detected: matches bill ${duplicateBill.id} ` +
              `(site: ${siteName}, amount: ${amount})`,
          );

          // Mark bill as having a duplicate (but still allow it)
          await event.data.ref.update({
            isDuplicate: true,
            duplicateOf: duplicateBill.id,
            duplicateDetectedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          return null;
        }

        // 4. All validations passed
        console.log(`[bill/${billId}] validation passed ✓`);
        await event.data.ref.update({
          validatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return null;
      } catch (err) {
        console.error(`[bill/${billId}] validation error:`, err.message);
        await event.data.ref.update({
          validationError: err.message || "Validation failed",
          validatedAt: admin.firestore.FieldValue.serverTimestamp(),
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

        // 1 point per ₹1000 (supports decimals, e.g. ₹2500 → 2.5 pts).
        const pointsEarned = after.pointsEarned != null ?
          Number(after.pointsEarned) :
          amount / 1000;
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
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});

        // 2. Update user_points doc
        const historyEntry = {
          points: pointsEarned,
          reason: "Bill approval",
          date: admin.firestore.Timestamp.now(),
          billId,
          amount,
          branchId: billBranchId || userBranchId || null,
        };

        if (pointsSnap.exists) {
          batch.update(pointsRef, {
            totalPoints: newTotalPoints,
            tier: newTier,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            pointsHistory: admin.firestore.FieldValue.arrayUnion(historyEntry),
          });
        } else {
          batch.set(pointsRef, {
            userId: uid,
            branchId: userBranchId || billBranchId || null,
            totalPoints: newTotalPoints,
            tier: newTier,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
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
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
          {tier: correctTier, lastUpdated: admin.firestore.FieldValue.serverTimestamp()},
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
