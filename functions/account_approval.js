/**
 * Account approval rules for member sign-ups (pure, so they can be tested
 * without Firestore). A member who signs up themselves cannot sign in until
 * the admin of their branch (or the super admin) approves the account.
 */

const MEMBER_ROLES = ["carpenter", "interior_designer", "architect",
  "engineer"];

/**
 * True for the four member roles. Older accounts with no role are carpenters.
 * @param {*} role - Stored role.
 * @return {boolean} Whether the role is a member role.
 */
function isMemberRole(role) {
  const id = String(role || "").trim().toLowerCase();
  return id === "" || MEMBER_ROLES.includes(id);
}

/**
 * Whether a users/{id} write is a new member sign-up that should be marked
 * pending and announced to the branch admin: the profile just became a
 * member profile (created, or a role/branch was filled in for the first
 * time) and it is not already approved or announced.
 * @param {object|undefined} before - Data before the write.
 * @param {object|undefined} after - Data after the write.
 * @return {boolean} Whether to mark it pending and notify.
 */
function isNewMemberSignUp(before, after) {
  if (!after) return false;
  const role = String(after.role || "").trim();
  if (!role || !isMemberRole(role)) return false;
  if (!String(after.branchId || "").trim()) return false;
  if (after.profile_verified === true) return false;
  if (after.approvalNotifiedAt) return false;
  if (after.createdByAdmin === true) return false;
  // Only at the sign-up moment, never for an existing member's later edits
  // (live accounts with no profile_verified before the migration).
  if (!before) return true;
  const hadRole = String(before.role || "").trim() !== "";
  const hadBranch = String(before.branchId || "").trim() !== "";
  return !(hadRole && hadBranch);
}

/**
 * Whether [caller] (their users/{uid} data) may review [target]. Only the
 * admin of the member's own branch may; the super admin may not.
 * @param {object|null} caller - The caller's profile, or null.
 * @param {object|null} target - The member's profile.
 * @return {string|null} An error message, or null when allowed.
 */
function reviewDenied(caller, target) {
  if (!target) return "This account no longer exists.";
  if (!isMemberRole(target.role)) {
    return "Only member accounts can be approved or rejected.";
  }
  if (!caller || String(caller.role || "").trim().toLowerCase() !== "admin") {
    return "Only a branch admin can review account requests.";
  }
  const callerBranch = String(caller.branchId || "").trim();
  const targetBranch = String(target.branchId || "").trim();
  if (!callerBranch || callerBranch !== targetBranch) {
    return "This account belongs to another branch.";
  }
  return null;
}

/**
 * The fields to write for an approve or reject.
 * @param {string} action - "approve" or "reject".
 * @param {object} by - {uid, name}.
 * @param {string} reason - Optional reject reason.
 * @param {*} now - Timestamp value to store.
 * @return {object} Fields to merge onto users/{id}.
 */
function reviewFields(action, by, reason, now) {
  if (action === "approve") {
    return {
      profile_verified: true,
      approvalStatus: "approved",
      approvedBy: by.uid,
      approvedByName: by.name || "",
      approvedAt: now,
    };
  }
  return {
    profile_verified: false,
    approvalStatus: "rejected",
    rejectedBy: by.uid,
    rejectedByName: by.name || "",
    rejectedAt: now,
    rejectReason: String(reason || "").trim().slice(0, 200),
  };
}

module.exports = {isMemberRole, isNewMemberSignUp, reviewDenied, reviewFields};
