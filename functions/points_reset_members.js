/**
 * Who a branch points reset applies to: the four member roles that earn
 * points, plus older accounts with no role saved (the app counts those as
 * carpenters). Staff accounts are never touched.
 *
 * Kept in step with AppConstants.isMemberRole in the app.
 */
const MEMBER_ROLES = new Set([
  "carpenter",
  "architect",
  "engineer",
  "interior_designer",
]);

/**
 * @param {object} userData - A users document's data.
 * @return {boolean} Whether a branch points reset should include this user.
 */
function isPointsResetMember(userData) {
  const role = String((userData && (userData.role || userData.roleId)) || "")
      .trim()
      .toLowerCase();
  return role === "" || MEMBER_ROLES.has(role);
}

module.exports = {MEMBER_ROLES, isPointsResetMember};
