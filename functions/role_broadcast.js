/**
 * Pure helpers for sendRoleBroadcast (see index.js): an admin sends one
 * notification to the approved members of a branch, picked by role.
 * Kept free of Firebase so they can be unit-tested.
 */

const MEMBER_ROLES = ["carpenter", "interior_designer", "architect",
  "engineer"];

/** Category ids the app knows; each opens its own screen in the app. */
const CATEGORIES = ["general", "offer", "catalog", "dailySpin", "addBill",
  "wallet", "festival", "branch"];

const MAX_TITLE = 80;
const MAX_BODY = 500;

/**
 * The member role of a profile. Older accounts with no role are carpenters;
 * admins and unknown roles return null.
 * @param {*} role - Stored role.
 * @return {?string} One of MEMBER_ROLES, or null.
 */
function memberRoleOf(role) {
  const id = String(role || "").trim().toLowerCase();
  if (id === "") return "carpenter";
  return MEMBER_ROLES.includes(id) ? id : null;
}

/**
 * Checks and cleans what the admin sent.
 * @param {object} data - Callable request data.
 * @return {{error: ?string, value: ?object}} A message, or the clean input.
 */
function parseRequest(data) {
  const d = data || {};
  const branchId = String(d.branchId || "").trim();
  const title = String(d.title || "").trim();
  const body = String(d.body || "").trim();
  const category = String(d.category || "general").trim();
  const roles = Array.isArray(d.roles) ?
    [...new Set(d.roles.map((r) => String(r).trim().toLowerCase()))] : [];

  if (!branchId) return {error: "Choose a branch.", value: null};
  if (!title) return {error: "Enter a title.", value: null};
  if (title.length > MAX_TITLE) {
    return {error: `Title can be up to ${MAX_TITLE} characters.`, value: null};
  }
  if (!body) return {error: "Enter a message.", value: null};
  if (body.length > MAX_BODY) {
    return {error: `Message can be up to ${MAX_BODY} characters.`,
      value: null};
  }
  if (roles.length === 0 || roles.some((r) => !MEMBER_ROLES.includes(r))) {
    return {error: "Choose who gets it.", value: null};
  }
  if (!CATEGORIES.includes(category)) {
    return {error: "Choose a category.", value: null};
  }
  return {error: null, value: {branchId, title, body, category, roles}};
}

/**
 * Whether [caller] may send to [branchId]: the branch's own admin, or the
 * super admin for any branch.
 * @param {?object} callerData - The caller's users/{uid} profile.
 * @param {?object} token - The caller's auth token claims.
 * @param {string} branchId - Target branch.
 * @return {?string} An error message, or null when allowed.
 */
function sendDenied(callerData, token, branchId) {
  const role = String(callerData && callerData.role || "").toLowerCase();
  if (role === "super_admin") return null;
  const claimRole = String(token && token.role || "").toLowerCase();
  const isAdmin = role === "admin" || claimRole === "admin";
  if (!isAdmin) return "Only an admin can send notifications.";
  const myBranch = String(callerData && callerData.branchId ||
    token && token.branchId || "").trim();
  if (myBranch !== branchId) {
    return "You can send only to your own branch.";
  }
  return null;
}

/**
 * The members who get it: approved, not deleted, in one of [roles].
 * @param {Array<{id: string, data: object}>} users - Users of the branch.
 * @param {Array<string>} roles - Chosen member roles.
 * @return {{userIds: Array<string>, tokens: Array<string>}} Recipients and
 *   their unique push tokens.
 */
function pickRecipients(users, roles) {
  const wanted = new Set(roles);
  const userIds = [];
  const tokens = new Set();
  for (const u of users) {
    const d = u.data || {};
    const role = memberRoleOf(d.role);
    if (!role || !wanted.has(role)) continue;
    if (d.status === "deleted") continue;
    if (d.profile_verified !== true) continue;
    userIds.push(u.id);
    if (typeof d.fcmToken === "string" && d.fcmToken) tokens.add(d.fcmToken);
  }
  return {userIds, tokens: [...tokens]};
}

/**
 * Splits [list] into groups of [size] (FCM multicast takes up to 500).
 * @param {Array} list - Items.
 * @param {number} size - Group size.
 * @return {Array<Array>} Groups.
 */
function chunk(list, size) {
  const out = [];
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
  return out;
}

module.exports = {MEMBER_ROLES, CATEGORIES, MAX_TITLE, MAX_BODY, memberRoleOf,
  parseRequest, sendDenied, pickRecipients, chunk};
