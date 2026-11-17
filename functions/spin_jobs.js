/**
 * Daily spin pushes, shared by the Cloud Functions in index.js and the live
 * test script. Takes Firestore and Messaging so both can call it.
 */
const {FieldValue} = require("firebase-admin/firestore");
const spin = require("./spin_notify");
const {chunk} = require("./role_broadcast");

const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

/**
 * Sends one push to many phones and returns counts and dead tokens.
 * @param {object} messaging - firebase-admin Messaging.
 * @param {Array<string>} tokens - Push tokens.
 * @param {{title: string, body: string}} msg - Text.
 * @param {object} data - String data payload.
 * @return {Promise<{sent: number, failed: number, dead: Set<string>}>}
 */
async function pushAll(messaging, tokens, msg, data) {
  let sent = 0;
  let failed = 0;
  const dead = new Set();
  for (const group of chunk(tokens, 500)) {
    try {
      const res = await messaging.sendEachForMulticast({
        tokens: group,
        notification: msg,
        data,
        android: {
          priority: "high",
          notification: {channelId: "balaji_points_important",
            sound: "default"},
        },
        apns: {payload: {aps: {sound: "default"}}},
      });
      sent += res.successCount;
      failed += res.failureCount;
      res.responses.forEach((r, i) => {
        if (r.error && DEAD_TOKEN_CODES.has(r.error.code)) dead.add(group[i]);
      });
    } catch (err) {
      console.error("[spin push] multicast failed:", err.message);
      failed += group.length;
    }
  }
  return {sent, failed, dead};
}

/**
 * Forgets push tokens FCM reports as gone.
 * @param {object} db - Firestore.
 * @param {Array<object>} docs - User documents that may hold them.
 * @param {Set<string>} dead - Dead tokens.
 */
async function dropDeadTokens(db, docs, dead) {
  if (dead.size === 0) return;
  const batch = db.batch();
  for (const doc of docs) {
    if (dead.has(doc.data().fcmToken)) {
      batch.update(doc.ref, {fcmToken: FieldValue.delete()});
    }
  }
  await batch.commit();
}

/**
 * Creates [ref] with [data] unless it exists. Retries of a trigger must not
 * notify twice.
 * @param {object} ref - Document reference.
 * @param {object} data - Fields.
 * @return {Promise<boolean>} true when this call created it.
 */
async function createOnce(ref, data) {
  try {
    await ref.create(data);
    return true;
  } catch (err) {
    if (err.code === 6 || /already exists/i.test(err.message)) return false;
    throw err;
  }
}

/**
 * A daily draw was saved: the winner gets "You won", the rest of the
 * winner's group in the branch gets "Today's winner is ...". Both also
 * appear in the in-app notification list.
 * @param {object} db - Firestore.
 * @param {object} messaging - Messaging.
 * @param {string} docId - daily_winners document id.
 * @param {object} rec - The record.
 * @return {Promise<object>} What was sent (for logs and tests).
 */
async function notifySpinResult(db, messaging, docId, rec) {
  const branchId = String(rec.branchId || "").trim();
  const group = String(rec.group || "").trim();
  const winnerId = String(rec.carpenterId || "").trim();
  if (!branchId || !spin.GROUP_ROLES[group] || !winnerId) {
    return {skipped: "legacy or incomplete record"};
  }
  const texts = spin.winnerMessages(rec);
  const users = await db.collection("users")
      .where("branchId", "==", branchId).get();
  const audience = spin.splitAudience(
      users.docs.map((d) => ({id: d.id, data: d.data()})), group, winnerId);
  const data = {category: "dailySpin", screen: "/notifications",
    prizeId: String(rec.prizeId || ""), date: String(rec.date || "")};

  const result = {winner: 0, others: 0, otherMembers: audience.otherIds.length};
  const dead = new Set();

  // The winner: a personal notification.
  const winLog = db.collection("notification_logs").doc(`spinWin_${docId}`);
  if (await createOnce(winLog, {
    userId: winnerId, type: "spinWinner", category: "dailySpin",
    title: texts.winner.title, body: texts.winner.body, branchId,
    data, sentAt: FieldValue.serverTimestamp(),
    pushStatus: audience.winnerToken ? "sending" : "no_token",
  })) {
    if (audience.winnerToken) {
      const r = await pushAll(messaging, [audience.winnerToken], texts.winner,
          {...data, type: "spinWinner", logId: winLog.id});
      r.dead.forEach((t) => dead.add(t));
      result.winner = r.sent;
      await winLog.update({pushStatus: r.sent ? "sent" : "failed"});
    }
  } else {
    result.duplicate = true;
  }

  // Everyone else in the group: one shared record (not shown to the winner).
  const resultLog = db.collection("notification_logs")
      .doc(`spinResult_${docId}`);
  if (await createOnce(resultLog, {
    userId: null, isBroadcast: true, type: "spinResult", category: "dailySpin",
    title: texts.others.title, body: texts.others.body, branchId,
    targetRoles: spin.GROUP_ROLES[group], excludeUserIds: [winnerId],
    data, recipients: audience.otherIds.length,
    sentAt: FieldValue.serverTimestamp(), pushStatus: "sending",
  })) {
    const r = await pushAll(messaging, audience.otherTokens, texts.others,
        {...data, type: "spinResult", logId: resultLog.id});
    r.dead.forEach((t) => dead.add(t));
    result.others = r.sent;
    await resultLog.update({pushStatus: "sent", pushSent: r.sent,
      pushFailed: r.failed});
  }

  await dropDeadTokens(db, users.docs, dead);
  return result;
}

/**
 * Evening reminder: for each branch, the groups with qualified members but
 * no draw yet; their branch admins get one push (once per branch per day).
 * @param {object} db - Firestore.
 * @param {object} messaging - Messaging.
 * @param {object} opts - For tests: `now` (Date) and `branchIds` (which
 *   branches to check; default every active branch).
 * @return {Promise<Array<object>>} One entry per branch reminded.
 */
async function sendSpinReminders(db, messaging, opts = {}) {
  const day = spin.istDayKey(opts.now || new Date());
  let branchIds = opts.branchIds;
  if (!branchIds) {
    const branches = await db.collection("branches").get();
    branchIds = branches.docs
        .filter((b) => b.data().isActive !== false)
        .map((b) => b.id);
  }
  const out = [];
  for (const branchId of branchIds) {
    const [bills, users, winners] = await Promise.all([
      db.collection("bills").where("branchId", "==", branchId)
          .where("status", "==", "approved")
          .where("approvedDate", "==", day).get(),
      db.collection("users").where("branchId", "==", branchId).get(),
      db.collection("daily_winners").where("branchId", "==", branchId)
          .where("date", "==", day).get(),
    ]);
    const usersById = new Map(users.docs.map((d) => [d.id, d.data()]));
    const done = new Set(winners.docs.map((d) => d.data().group));
    const pending = spin.pendingDraws(bills.docs.map((d) => d.data()),
        usersById, done);
    if (pending.length === 0) continue;

    const msg = spin.reminderMessage(pending);
    const log = db.collection("notification_logs")
        .doc(`spinReminder_${branchId}_${day}`);
    const created = await createOnce(log, {
      type: "spinReminder", isBroadcast: true, branchId,
      title: msg.title, body: msg.body, status: "admin_broadcast",
      data: {section: "spin", date: day},
      pending: pending.map((p) => p.group),
      sentAt: FieldValue.serverTimestamp(),
    });
    if (!created) continue;

    const adminDocs = users.docs.filter((d) => d.data().role === "admin");
    const tokens = [...new Set(adminDocs.map((d) => d.data().fcmToken)
        .filter((t) => typeof t === "string" && t))];
    const r = await pushAll(messaging, tokens, msg,
        {type: "spinReminder", section: "spin", screen: "/notifications",
          logId: log.id});
    await log.update({adminsQueued: r.sent});
    await dropDeadTokens(db, adminDocs, r.dead);
    out.push({branchId, pending, admins: tokens.length, pushed: r.sent});
  }
  return out;
}

module.exports = {notifySpinResult, sendSpinReminders};
