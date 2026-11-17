const {test} = require("node:test");
const assert = require("node:assert");
const r = require("../role_broadcast");

const ok = {branchId: "b1", title: "Hi", body: "Msg", category: "offer",
  roles: ["carpenter", "architect"]};

test("valid request is cleaned", () => {
  const {error, value} = r.parseRequest({...ok, title: "  Hi  ",
    roles: ["Carpenter", "carpenter", "architect"]});
  assert.strictEqual(error, null);
  assert.strictEqual(value.title, "Hi");
  assert.deepStrictEqual(value.roles, ["carpenter", "architect"]);
});

test("bad requests are refused", () => {
  assert.ok(r.parseRequest({...ok, branchId: ""}).error);
  assert.ok(r.parseRequest({...ok, title: ""}).error);
  assert.ok(r.parseRequest({...ok, body: " "}).error);
  assert.ok(r.parseRequest({...ok, roles: []}).error);
  assert.ok(r.parseRequest({...ok, roles: ["admin"]}).error);
  assert.ok(r.parseRequest({...ok, category: "hack"}).error);
  assert.ok(r.parseRequest({...ok, title: "x".repeat(81)}).error);
  assert.ok(r.parseRequest({...ok, body: "x".repeat(501)}).error);
});

test("missing category means general", () => {
  const {value} = r.parseRequest({...ok, category: undefined});
  assert.strictEqual(value.category, "general");
});

test("only the branch's admin or the super admin may send", () => {
  assert.strictEqual(r.sendDenied({role: "admin", branchId: "b1"}, {}, "b1"),
      null);
  assert.ok(r.sendDenied({role: "admin", branchId: "b2"}, {}, "b1"));
  assert.strictEqual(r.sendDenied({role: "super_admin"}, {}, "b9"), null);
  assert.ok(r.sendDenied({role: "carpenter", branchId: "b1"}, {}, "b1"));
  assert.ok(r.sendDenied(null, {}, "b1"));
  // PIN admin: role and branch come from the sign-in token.
  assert.strictEqual(
      r.sendDenied(null, {role: "admin", branchId: "b1"}, "b1"), null);
  assert.ok(r.sendDenied(null, {role: "admin", branchId: "b2"}, "b1"));
});

test("recipients: approved members of the chosen roles only", () => {
  const users = [
    {id: "a", data: {role: "carpenter", profile_verified: true,
      fcmToken: "t1"}},
    {id: "b", data: {role: "", profile_verified: true, fcmToken: "t2"}},
    {id: "c", data: {role: "architect", profile_verified: true,
      fcmToken: "t1"}},
    {id: "d", data: {role: "engineer", profile_verified: true,
      fcmToken: "t4"}},
    {id: "e", data: {role: "carpenter", profile_verified: false,
      fcmToken: "t5"}},
    {id: "f", data: {role: "carpenter", profile_verified: true,
      status: "deleted", fcmToken: "t6"}},
    {id: "g", data: {role: "admin", profile_verified: true, fcmToken: "t7"}},
    {id: "h", data: {role: "carpenter", profile_verified: true}},
  ];
  const {userIds, tokens} = r.pickRecipients(users, ["carpenter",
    "architect"]);
  assert.deepStrictEqual(userIds, ["a", "b", "c", "h"]);
  assert.deepStrictEqual(tokens, ["t1", "t2"]);
});

test("chunk splits for multicast", () => {
  assert.deepStrictEqual(r.chunk([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
  assert.deepStrictEqual(r.chunk([], 500), []);
});
