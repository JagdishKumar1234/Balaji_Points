const test = require("node:test");
const assert = require("node:assert");
const {inAppRecordFor} = require("../in_app_record");

const approved = {
  userId: "9000000001", type: "billApproved", title: "Bill Approved!",
  body: "12.5 points added", data: {billId: "b1"}, branchId: "erode_main",
};

test("a failed push still gives the member an in-app record", () => {
  const r = inAppRecordFor("q1", approved, "failed", "now");
  assert.strictEqual(r.userId, "9000000001");
  assert.strictEqual(r.isBroadcast, false);
  assert.strictEqual(r.pushStatus, "failed");
  assert.strictEqual(r.branchId, "erode_main");
  assert.strictEqual(r.type, "billApproved");
  assert.deepStrictEqual(r.data, {billId: "b1"});
});

test("a notification with no member is a broadcast", () => {
  const r = inAppRecordFor("q2", {type: "announcement"}, "sent", "now");
  assert.strictEqual(r.userId, null);
  assert.strictEqual(r.isBroadcast, true);
  assert.strictEqual(r.branchId, null);
  assert.strictEqual(r.title, "Balaji Points");
});
