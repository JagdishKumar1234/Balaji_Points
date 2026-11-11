const test = require("node:test");
const assert = require("node:assert");
const {isPointsResetMember} = require("../points_reset_members");

test("all four member roles are reset", () => {
  for (const role of ["carpenter", "architect", "engineer", "interior_designer"]) {
    assert.ok(isPointsResetMember({role}), role);
  }
});

test("older accounts with no role are reset, like the app treats them", () => {
  assert.ok(isPointsResetMember({}));
  assert.ok(isPointsResetMember({role: ""}));
  assert.ok(isPointsResetMember({role: null}));
});

test("the role is matched regardless of case and spaces", () => {
  assert.ok(isPointsResetMember({role: " Engineer "}));
  assert.ok(isPointsResetMember({roleId: "architect"}));
});

test("staff and unknown roles are never reset", () => {
  for (const role of ["admin", "super_admin", "dealer"]) {
    assert.strictEqual(isPointsResetMember({role}), false, role);
  }
});

test("the Erode mix: only the 2 admins are left out", () => {
  const erode = [
    ...Array(173).fill({role: "carpenter"}),
    ...Array(20).fill({}),
    ...Array(4).fill({role: "interior_designer"}),
    {role: "engineer"},
    {role: "architect"},
    ...Array(2).fill({role: "admin"}),
  ];
  assert.strictEqual(erode.filter(isPointsResetMember).length, 199);
});
