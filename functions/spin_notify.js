/**
 * Pure helpers for the daily spin pushes (see index.js):
 *  - onDailyWinnerCreated: the winner gets "You won", the rest of the
 *    winner's group in that branch get "Today's winner is ...".
 *  - spinReminder: each evening, branch admins hear about groups that have
 *    qualified members but no draw yet.
 * Kept free of Firebase so they can be unit-tested.
 */
const {memberRoleOf} = require("./role_broadcast");

const GROUP_ROLES = {
  trade: ["carpenter", "interior_designer"],
  professional: ["architect", "engineer"],
};

const GROUP_LABEL = {
  trade: "Carpenter & Interior",
  professional: "Architect & Engineer",
};

/**
 * The member group of a role, or null for admins and unknown roles.
 * @param {*} role - Stored role (empty = carpenter).
 * @return {?string} "trade", "professional" or null.
 */
function groupOfRole(role) {
  const r = memberRoleOf(role);
  if (!r) return null;
  return GROUP_ROLES.trade.includes(r) ? "trade" : "professional";
}

/**
 * The texts for one draw.
 * @param {object} rec - The daily_winners record.
 * @return {{winner: {title: string, body: string},
 *   others: {title: string, body: string}}} Push texts.
 */
function winnerMessages(rec) {
  const name = String(rec.carpenterName || "").trim() || "A member";
  const prize = String(rec.prizeName || "").trim();
  return {
    winner: {
      title: "🎉 You won today's spin!",
      body: prize ?
        `Congratulations! You won ${prize} in today's Daily Buy Daily Win ` +
          "draw. Collect it at your branch." :
        "Congratulations! You won today's Daily Buy Daily Win draw.",
    },
    others: {
      title: `🏆 Today's winner: ${name}`,
      body: prize ?
        `${name} won ${prize} in today's Daily Buy Daily Win draw. ` +
          "Add a bill today for your chance tomorrow!" :
        `${name} won today's Daily Buy Daily Win draw. ` +
          "Add a bill today for your chance tomorrow!",
    },
  };
}

/**
 * Splits the branch's members into the winner and the rest of the group.
 * Everyone must be an approved, non-deleted member of [group].
 * @param {Array<{id: string, data: object}>} users - Users of the branch.
 * @param {string} group - "trade" or "professional".
 * @param {string} winnerId - The winner's user id.
 * @return {{winnerToken: ?string, otherIds: Array<string>,
 *   otherTokens: Array<string>}} Who gets which push.
 */
function splitAudience(users, group, winnerId) {
  let winnerToken = null;
  const otherIds = [];
  const tokens = new Set();
  for (const u of users) {
    const d = u.data || {};
    const token = typeof d.fcmToken === "string" && d.fcmToken ?
      d.fcmToken : null;
    if (u.id === winnerId) {
      winnerToken = token;
      continue;
    }
    if (groupOfRole(d.role) !== group) continue;
    if (d.status === "deleted" || d.profile_verified !== true) continue;
    otherIds.push(u.id);
    if (token) tokens.add(token);
  }
  // A phone shared with the winner gets only the winner's message.
  if (winnerToken) tokens.delete(winnerToken);
  return {winnerToken, otherIds, otherTokens: [...tokens]};
}

/**
 * Groups of a branch that still need today's draw: at least one qualified
 * member (a bill approved today) and no winner yet.
 * @param {Array<object>} bills - Today's approved bills of the branch.
 * @param {Map<string, object>} usersById - Branch users by id.
 * @param {Set<string>} doneGroups - Groups already drawn today.
 * @return {Array<{group: string, qualified: number}>} Pending draws.
 */
function pendingDraws(bills, usersById, doneGroups) {
  const qualified = {trade: new Set(), professional: new Set()};
  for (const b of bills) {
    const id = String(b.carpenterId || b.userId || "").trim();
    const u = id && usersById.get(id);
    if (!u) continue;
    if (u.status === "deleted" || u.profile_verified !== true) continue;
    const g = groupOfRole(u.role);
    if (g) qualified[g].add(id);
  }
  return ["trade", "professional"]
      .filter((g) => !doneGroups.has(g) && qualified[g].size > 0)
      .map((g) => ({group: g, qualified: qualified[g].size}));
}

/**
 * Reminder text for a branch admin.
 * @param {Array<{group: string, qualified: number}>} pending - Pending draws.
 * @return {{title: string, body: string}} Push text.
 */
function reminderMessage(pending) {
  const parts = pending.map((p) =>
    `${GROUP_LABEL[p.group]} (${p.qualified} qualified)`);
  return {
    title: "🎡 Spin reminder",
    body: `Today's draw is not done yet: ${parts.join(", ")}. ` +
      "Open Spin to pick the winners.",
  };
}

/**
 * YYYY-MM-DD in India time: the day key the app uses.
 * @param {Date} date - The moment.
 * @return {string} Day key.
 */
function istDayKey(date) {
  return new Intl.DateTimeFormat("en-CA", {timeZone: "Asia/Kolkata",
    year: "numeric", month: "2-digit", day: "2-digit"}).format(date);
}

module.exports = {GROUP_ROLES, GROUP_LABEL, groupOfRole, winnerMessages,
  splitAudience, pendingDraws, reminderMessage, istDayKey};
