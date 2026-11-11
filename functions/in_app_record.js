/**
 * The `notification_logs` record the app shows on its Notifications screen
 * for one queued notification. Saved whether or not the push was delivered,
 * so a member with no working push token still sees it in the app.
 * @param {string} queueId - The notification_queue document ID.
 * @param {object} doc - The queued notification.
 * @param {string} pushStatus - "sent", "failed" or "no_token".
 * @param {*} sentAt - The time to store (a server timestamp in production).
 * @return {object} The record to add to notification_logs.
 */
function inAppRecordFor(queueId, doc, pushStatus, sentAt) {
  return {
    userId: doc.userId || null,
    type: doc.type || "notification",
    title: doc.title || "Balaji Points",
    body: doc.body || "",
    data: doc.data || {},
    sentAt,
    // A queued notification with no userId is meant for everyone.
    isBroadcast: !doc.userId,
    // Keeps each branch's inbox to its own notifications.
    branchId: doc.branchId || null,
    queueId,
    pushStatus,
  };
}

module.exports = {inAppRecordFor};
