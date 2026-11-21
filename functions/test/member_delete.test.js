const {test} = require("node:test");
const assert = require("node:assert");
const m = require("../member_delete");

const admin = (branchId = "b1") => ({role: "admin", branchId});
const member = (over = {}) => ({role: "carpenter", branchId: "b1", ...over});

test("branch admin may delete a member of their own branch", () => {
  assert.strictEqual(m.deleteDenied(admin(), member(), false), null);
  for (const role of ["architect", "engineer", "interior_designer", ""]) {
    assert.strictEqual(m.deleteDenied(admin(), member({role}), false), null);
  }
});

test("another branch's admin may not", () => {
  assert.match(m.deleteDenied(admin("b2"), member(), false), /another branch/);
  assert.match(m.deleteDenied(admin(""), member(), false), /another branch/);
});

test("members and unknown callers may not", () => {
  assert.match(m.deleteDenied(member(), member(), false), /branch admin/);
  assert.match(m.deleteDenied(null, member(), false), /branch admin/);
});

test("admins and the super admin can never be deleted here", () => {
  assert.match(m.deleteDenied(admin(), admin(), false), /Only member/);
  assert.match(
      m.deleteDenied(admin(), {role: "super_admin"}, true), /Only member/);
});

test("super admin may delete any branch's member", () => {
  assert.strictEqual(m.deleteDenied(null, member({branchId: "b9"}), true), null);
});

test("missing account", () => {
  assert.match(m.deleteDenied(admin(), null, false), /no longer exists/);
});

test("member keys cover doc id, phone and uid", () => {
  assert.deepStrictEqual(
      m.memberKeys("abc", {phone: "+91 98765 43210", uid: "u1"}),
      ["abc", "9876543210", "u1"]);
  assert.deepStrictEqual(m.memberKeys("9876543210", {phone: "9876543210"}),
      ["9876543210"]);
  assert.deepStrictEqual(m.memberKeys("x", {}), ["x"]);
});

test("bills of another branch are kept", () => {
  assert.strictEqual(m.billBelongsToBranch({branchId: "b1"}, "b1"), true);
  assert.strictEqual(m.billBelongsToBranch({branchId: "b2"}, "b1"), false);
  assert.strictEqual(m.billBelongsToBranch({}, "b1"), true);
});
