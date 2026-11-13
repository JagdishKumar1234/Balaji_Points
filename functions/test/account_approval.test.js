const {test} = require("node:test");
const assert = require("node:assert");
const a = require("../account_approval");

const member = (over = {}) => ({role: "carpenter", branchId: "b1", ...over});

test("new member sign-up is detected on create", () => {
  assert.strictEqual(a.isNewMemberSignUp(undefined, member()), true);
  assert.strictEqual(
      a.isNewMemberSignUp(undefined, member({role: "architect"})), true);
});

test("Google profile completion (role/branch filled in) counts", () => {
  assert.strictEqual(a.isNewMemberSignUp({email: "x"}, member()), true);
  assert.strictEqual(a.isNewMemberSignUp({role: "carpenter"}, member()), true);
});

test("existing members' later edits never trigger it", () => {
  assert.strictEqual(a.isNewMemberSignUp(member(), member({tier: "Gold"})),
      false);
});

test("approved, already notified, admin-made, staff, no branch: no", () => {
  assert.strictEqual(
      a.isNewMemberSignUp(undefined, member({profile_verified: true})), false);
  assert.strictEqual(
      a.isNewMemberSignUp(undefined, member({approvalNotifiedAt: 1})), false);
  assert.strictEqual(
      a.isNewMemberSignUp(undefined, member({createdByAdmin: true})), false);
  assert.strictEqual(
      a.isNewMemberSignUp(undefined, member({role: "admin"})), false);
  assert.strictEqual(
      a.isNewMemberSignUp(undefined, member({branchId: ""})), false);
  assert.strictEqual(a.isNewMemberSignUp(member(), undefined), false);
});

test("only the member's own branch admin may review", () => {
  const admin = {role: "admin", branchId: "b1"};
  for (const role of ["carpenter", "interior_designer", "architect",
    "engineer", ""]) {
    assert.strictEqual(a.reviewDenied(admin, member({role})), null, role);
  }
  assert.match(a.reviewDenied({role: "admin", branchId: "b2"}, member()),
      /another branch/);
  assert.match(a.reviewDenied({role: "carpenter", branchId: "b1"}, member()),
      /branch admin/);
  assert.match(a.reviewDenied(null, member()), /branch admin/);
});

test("the super admin may not review any branch", () => {
  const sa = {role: "super_admin", branchId: ""};
  assert.match(a.reviewDenied(sa, member()), /branch admin/);
  assert.match(a.reviewDenied({role: "super_admin", branchId: "b1"},
      member()), /branch admin/);
});

test("staff accounts and missing accounts are never reviewed", () => {
  const admin = {role: "admin", branchId: "b1"};
  assert.match(a.reviewDenied(admin, {role: "admin", branchId: "b1"}),
      /Only member/);
  assert.match(a.reviewDenied(admin, null), /no longer exists/);
});

test("approve and reject fields", () => {
  const by = {uid: "adm", name: "Ravi"};
  assert.deepStrictEqual(a.reviewFields("approve", by, "", 5), {
    profile_verified: true, approvalStatus: "approved", approvedBy: "adm",
    approvedByName: "Ravi", approvedAt: 5,
  });
  const r = a.reviewFields("reject", by, "  Wrong branch ", 6);
  assert.strictEqual(r.profile_verified, false);
  assert.strictEqual(r.approvalStatus, "rejected");
  assert.strictEqual(r.rejectReason, "Wrong branch");
});
