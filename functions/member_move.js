/**
 * Rules for changing a member's branch and/or role (pure, so they can be
 * tested without Firestore). Used by the changeMemberBranchRole callable.
 *
 * - Only the admin of the member's own branch may do it. The super admin may
 *   not (user decision, 2026-11-21): members fix a wrong sign-up choice with
 *   their branch admin.
 * - New role: one of the four member roles. Points are recalculated at the
 *   new role's rate (rupees per point) for every bill: approved bills get new
 *   points, pending bills a new locked rate and expected points.
 * - New branch: an active branch. The member starts there at 0 points;
 *   approved/rejected bills and history stay with the old branch, pending
 *   bills move (user decision, 2026-11-21).
 */

const {isMemberRole} = require("./account_approval");

const MEMBER_ROLES = ["carpenter", "interior_designer", "architect",
  "engineer"];

/**
 * Lower-case, trimmed string.
 * @param {*} v - Value.
 * @return {string} Normalised id.
 */
function norm(v) {
  return String(v || "").trim().toLowerCase();
}

/**
 * Whether [caller] may change [target]'s branch or role.
 * @param {object|null} caller - The caller's users/{uid} data, or null.
 * @param {object|null} target - The member's users/{id} data, or null.
 * @return {string|null} An error message, or null when allowed.
 */
function changeDenied(caller, target) {
  if (!target) return "This account no longer exists.";
  if (!isMemberRole(target.role)) {
    return "Only member accounts can be changed here.";
  }
  if (!caller || norm(caller.role) !== "admin") {
    return "Only the member's branch admin can change branch or role.";
  }
  const callerBranch = String(caller.branchId || "").trim();
  const targetBranch = String(target.branchId || "").trim();
  if (!callerBranch || callerBranch !== targetBranch) {
    return "This account belongs to another branch.";
  }
  return null;
}

/**
 * Validates the requested change against the member's current values.
 * @param {object} target - The member's data.
 * @param {string} newBranchId - Requested branch (may equal the current).
 * @param {string} newRole - Requested role (may equal the current).
 * @return {{error: (string|null), branchChanged: boolean,
 *   roleChanged: boolean}} Result.
 */
function planChange(target, newBranchId, newRole) {
  const branch = String(newBranchId || "").trim();
  const role = norm(newRole);
  const result = {error: null, branchChanged: false, roleChanged: false};
  if (!branch || branch.includes("/")) {
    result.error = "Choose a branch.";
    return result;
  }
  if (!MEMBER_ROLES.includes(role)) {
    result.error = "Choose one of the four member roles.";
    return result;
  }
  // Older accounts with no role are carpenters.
  const currentRole = norm(target.role) || "carpenter";
  result.branchChanged = branch !== String(target.branchId || "").trim();
  result.roleChanged = role !== currentRole || norm(target.role) === "";
  if (!result.branchChanged && !result.roleChanged) {
    result.error = "Nothing to change.";
  }
  return result;
}

/**
 * The fields to write on a bill when the member's rate changes, and the
 * change in credited points. Rejected bills are left alone.
 * @param {object} bill - Bill data.
 * @param {number} rate - New rupees per point (>= 1).
 * @return {{fields: (object|null), delta: number, points: number}} What
 *   to write (null = nothing), the points difference, and the new points.
 */
function billForRate(bill, rate) {
  const amount = Number(bill && bill.amount) || 0;
  const status = norm(bill && bill.status) || "pending";
  const points = amount > 0 ? amount / rate : 0;
  if (status === "approved") {
    const old = Number(bill.pointsEarned) || 0;
    return {
      fields: {pointsEarned: points, rupeesPerPoint: rate},
      delta: points - old,
      points,
    };
  }
  if (status === "pending") {
    return {
      fields: {rupeesPerPoint: rate, expectedPoints: points},
      delta: 0,
      points,
    };
  }
  return {fields: null, delta: 0, points: 0};
}

/**
 * A user_points pointsHistory array with bill entries re-pointed, and the
 * total change for this document.
 * @param {Array<object>} history - pointsHistory entries.
 * @param {Map<string, number>} newPointsByBill - billId -> new points, for
 *   approved bills only.
 * @param {string|null} branchId - New branch for every entry, or null to
 *   keep each entry's branch.
 * @return {{history: Array<object>, delta: number}} Updated array + delta.
 */
function rewriteHistory(history, newPointsByBill, branchId) {
  let delta = 0;
  const out = (Array.isArray(history) ? history : []).map((entry) => {
    const next = {...entry};
    const id = entry && entry.billId;
    if (id && newPointsByBill.has(id)) {
      const pts = newPointsByBill.get(id);
      delta += pts - (Number(entry.points) || 0);
      next.points = pts;
    }
    if (branchId && entry && "branchId" in entry) next.branchId = branchId;
    return next;
  });
  return {history: out, delta};
}

/**
 * Tier for a points total (same thresholds as the app and calculateTier).
 * @param {number} points - Total points.
 * @return {string} Tier name.
 */
function tierFor(points) {
  if (points >= 10000) return "Platinum";
  if (points >= 5000) return "Gold";
  if (points >= 2000) return "Silver";
  return "Bronze";
}

/**
 * New total after a change, never below 0 (redeemed points stay redeemed).
 * @param {number} current - Current total.
 * @param {number} delta - Change.
 * @return {number} New total (unrounded, like bill approval writes it;
 *   tiny float noise below 1e-9 is dropped).
 */
function newTotal(current, delta) {
  const n = (Number(current) || 0) + delta;
  return n < 1e-9 ? 0 : Math.round(n * 1e9) / 1e9;
}

module.exports = {
  MEMBER_ROLES,
  changeDenied,
  planChange,
  billForRate,
  rewriteHistory,
  tierFor,
  newTotal,
};
