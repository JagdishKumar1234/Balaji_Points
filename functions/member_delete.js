/**
 * Rules for an admin deleting a member account (pure, so they can be tested
 * without Firestore). Only member accounts can be deleted this way, never an
 * admin or the super admin. A branch admin may delete members of their own
 * branch; the super admin may delete any member.
 */

const {isMemberRole} = require("./account_approval");

/**
 * Whether [caller] may delete [target].
 * @param {object|null} caller - The caller's users/{uid} data, or null.
 * @param {object|null} target - The member's users/{id} data, or null.
 * @param {boolean} isSuperAdmin - Whether the caller is the super admin.
 * @return {string|null} An error message, or null when allowed.
 */
function deleteDenied(caller, target, isSuperAdmin) {
  if (!target) return "This account no longer exists.";
  if (!isMemberRole(target.role)) {
    return "Only member accounts can be deleted here.";
  }
  if (isSuperAdmin) return null;
  if (!caller || String(caller.role || "").trim().toLowerCase() !== "admin") {
    return "Only a branch admin can delete member accounts.";
  }
  const callerBranch = String(caller.branchId || "").trim();
  const targetBranch = String(target.branchId || "").trim();
  if (!callerBranch || callerBranch !== targetBranch) {
    return "This account belongs to another branch.";
  }
  return null;
}

/**
 * Every id the member's points, history, bills and redemptions may be
 * stored under: the document id, the 10-digit phone (older documents were
 * keyed by phone) and the Firebase sign-in uid.
 * @param {string} docId - users/{docId}.
 * @param {object} data - The member's data.
 * @return {Array<string>} Unique, non-empty keys.
 */
function memberKeys(docId, data) {
  const keys = new Set([String(docId || "").trim()]);
  const phone = normalizePhone(data && data.phone);
  if (phone) keys.add(phone);
  const uid = String((data && data.uid) || "").trim();
  if (uid) keys.add(uid);
  keys.delete("");
  return [...keys];
}

/**
 * Last 10 digits of a phone number, or "".
 * @param {*} value - Stored phone.
 * @return {string} 10 digits or "".
 */
function normalizePhone(value) {
  const digits = String(value || "").replace(/\D/g, "");
  return digits.length >= 10 ? digits.slice(-10) : "";
}

/**
 * Whether a bill may be deleted with the member: bills of another branch
 * are kept (the same phone may be registered there).
 * @param {object} bill - Bill data.
 * @param {string} branchId - The member's branch.
 * @return {boolean} Whether to delete.
 */
function billBelongsToBranch(bill, branchId) {
  const billBranch = String((bill && bill.branchId) || "").trim();
  return !branchId || !billBranch || billBranch === branchId;
}

module.exports = {deleteDenied, memberKeys, normalizePhone, billBelongsToBranch};
