const {test} = require("node:test");
const assert = require("node:assert");
const s = require("../spin_notify");

const member = (role, token, extra = {}) => ({role, fcmToken: token,
  profile_verified: true, ...extra});

test("roles map to groups; old accounts with no role are carpenters", () => {
  assert.strictEqual(s.groupOfRole("carpenter"), "trade");
  assert.strictEqual(s.groupOfRole("interior_designer"), "trade");
  assert.strictEqual(s.groupOfRole(""), "trade");
  assert.strictEqual(s.groupOfRole("Architect"), "professional");
  assert.strictEqual(s.groupOfRole("engineer"), "professional");
  assert.strictEqual(s.groupOfRole("admin"), null);
});

test("winner and others get different texts with the prize", () => {
  const m = s.winnerMessages({carpenterName: "Kavya", prizeName: "Hammer"});
  assert.match(m.winner.title, /You won today's spin/);
  assert.match(m.winner.body, /Hammer/);
  assert.match(m.others.title, /Today's winner: Kavya/);
  assert.match(m.others.body, /Kavya won Hammer/);
  // Old records without a prize still read well.
  const old = s.winnerMessages({carpenterName: "Ravi"});
  assert.doesNotMatch(old.others.body, /undefined/);
});

test("audience: winner apart; only approved members of the group", () => {
  const users = [
    {id: "w", data: member("interior_designer", "tW")},
    {id: "c1", data: member("carpenter", "t1")},
    {id: "c2", data: member("", "t2")}, // old account = carpenter
    {id: "c3", data: member("carpenter", null)}, // no phone token
    {id: "pend", data: member("carpenter", "tp", {profile_verified: false})},
    {id: "del", data: member("carpenter", "td", {status: "deleted"})},
    {id: "a1", data: member("architect", "ta")}, // other group
    {id: "adm", data: member("admin", "tadm")},
    {id: "share", data: member("carpenter", "tW")}, // same phone as winner
  ];
  const a = s.splitAudience(users, "trade", "w");
  assert.strictEqual(a.winnerToken, "tW");
  assert.deepStrictEqual(a.otherIds.sort(), ["c1", "c2", "c3", "share"]);
  assert.deepStrictEqual(a.otherTokens.sort(), ["t1", "t2"]);
});

test("reminder only for groups with qualified members and no draw", () => {
  const users = new Map([
    ["c1", member("carpenter")], ["c2", member("interior_designer")],
    ["a1", member("architect")], ["p", member("carpenter",
        null, {profile_verified: false})],
  ]);
  const bills = [{carpenterId: "c1"}, {carpenterId: "c1"},
    {carpenterId: "c2"}, {carpenterId: "a1"}, {carpenterId: "p"},
    {carpenterId: "gone"}];
  assert.deepStrictEqual(s.pendingDraws(bills, users, new Set()), [
    {group: "trade", qualified: 2}, {group: "professional", qualified: 1}]);
  assert.deepStrictEqual(s.pendingDraws(bills, users, new Set(["trade"])),
      [{group: "professional", qualified: 1}]);
  assert.deepStrictEqual(
      s.pendingDraws([], users, new Set()), []);
  const msg = s.reminderMessage([{group: "trade", qualified: 2}]);
  assert.match(msg.body, /Carpenter & Interior \(2 qualified\)/);
});

test("day key is India time", () => {
  // 20:00 UTC on 18 Nov = 01:30 on 19 Nov in India.
  assert.strictEqual(s.istDayKey(new Date("2026-11-18T20:00:00Z")),
      "2026-11-19");
});
