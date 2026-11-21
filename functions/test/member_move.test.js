const {test} = require("node:test");
const assert = require("node:assert");
const m = require("../member_move");

const admin = (branchId = "b1") => ({role: "admin", branchId});
const member = (over = {}) => ({role: "carpenter", branchId: "b1", ...over});

test("only the member's own branch admin may change branch or role", () => {
  for (const role of ["carpenter", "architect", "engineer",
    "interior_designer", ""]) {
    assert.strictEqual(m.changeDenied(admin(), member({role})), null);
  }
  assert.match(m.changeDenied(admin("b2"), member()), /another branch/);
  assert.match(m.changeDenied(admin(""), member()), /another branch/);
});

test("the super admin, members and unknown callers may not", () => {
  assert.match(m.changeDenied({role: "super_admin", branchId: ""}, member()),
      /branch admin/);
  assert.match(m.changeDenied(member(), member()), /branch admin/);
  assert.match(m.changeDenied(null, member()), /branch admin/);
});

test("admin accounts and missing accounts cannot be changed", () => {
  assert.match(m.changeDenied(admin(), admin()), /Only member/);
  assert.match(m.changeDenied(admin(), null), /no longer exists/);
});

test("plan: role, branch, both, nothing, invalid", () => {
  const t = member();
  assert.deepStrictEqual(m.planChange(t, "b1", "architect"),
      {error: null, branchChanged: false, roleChanged: true});
  assert.deepStrictEqual(m.planChange(t, "b2", "carpenter"),
      {error: null, branchChanged: true, roleChanged: false});
  assert.deepStrictEqual(m.planChange(t, "b2", "Engineer"),
      {error: null, branchChanged: true, roleChanged: true});
  assert.match(m.planChange(t, "b1", "carpenter").error, /Nothing/);
  assert.match(m.planChange(t, "", "carpenter").error, /branch/);
  assert.match(m.planChange(t, "a/b", "carpenter").error, /branch/);
  assert.match(m.planChange(t, "b1", "admin").error, /four member roles/);
  assert.match(m.planChange(t, "b1", "super_admin").error, /four member/);
  // No stored role: saving "carpenter" writes the role.
  assert.strictEqual(
      m.planChange(member({role: ""}), "b1", "carpenter").roleChanged, true);
});

test("approved bill gets new points at the new rate", () => {
  const r = m.billForRate(
      {status: "approved", amount: 10000, pointsEarned: 2}, 1000);
  assert.deepStrictEqual(r.fields, {pointsEarned: 10, rupeesPerPoint: 1000});
  assert.strictEqual(r.delta, 8);
  const down = m.billForRate(
      {status: "approved", amount: 10000, pointsEarned: 10}, 5000);
  assert.strictEqual(down.delta, -8);
});

test("pending bill gets a new locked rate; rejected bill is untouched", () => {
  const p = m.billForRate({status: "pending", amount: 2500}, 1000);
  assert.deepStrictEqual(p.fields, {rupeesPerPoint: 1000, expectedPoints: 2.5});
  assert.strictEqual(p.delta, 0);
  assert.strictEqual(
      m.billForRate({status: "rejected", amount: 2500}, 1000).fields, null);
});

test("history: bill entries re-pointed, other entries kept", () => {
  const history = [
    {billId: "a", points: 2, branchId: "b1"},
    {reason: "Daily spin", points: 5, branchId: "b1"},
    {billId: "rejected", points: 1},
  ];
  const r = m.rewriteHistory(history, new Map([["a", 10]]), "b2");
  assert.strictEqual(r.delta, 8);
  assert.deepStrictEqual(r.history, [
    {billId: "a", points: 10, branchId: "b2"},
    {reason: "Daily spin", points: 5, branchId: "b2"},
    {billId: "rejected", points: 1},
  ]);
  // Repeating the same change adds nothing more.
  assert.strictEqual(
      m.rewriteHistory(r.history, new Map([["a", 10]]), null).delta, 0);
});

test("totals never go below zero; tiers", () => {
  assert.strictEqual(m.newTotal(10, -12), 0);
  assert.strictEqual(m.newTotal(0.1, 0.2), 0.3);
  assert.strictEqual(m.tierFor(1999), "Bronze");
  assert.strictEqual(m.tierFor(2000), "Silver");
  assert.strictEqual(m.tierFor(5000), "Gold");
  assert.strictEqual(m.tierFor(10000), "Platinum");
});
