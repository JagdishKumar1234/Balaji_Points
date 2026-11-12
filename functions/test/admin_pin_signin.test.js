const {test} = require("node:test");
const assert = require("node:assert");
const p = require("../admin_pin_signin");

const salt = "c2FsdHNhbHQ";
const admin = (over = {}) => ({
  id: "9600609121",
  data: {role: "admin", branchId: "erode_main", pinSalt: salt,
    pinHash: p.hashPin("1008", salt), ...over},
});

test("phone is digits only, last 10", () => {
  assert.strictEqual(p.normalizePhone("+91 96006-09121"), "9600609121");
  assert.strictEqual(p.normalizePhone("9600609121"), "9600609121");
});

test("hash matches the app (sha256 of pin::salt)", () => {
  assert.strictEqual(p.hashPin("1234", "abc"),
      require("crypto").createHash("sha256").update("1234::abc").digest("hex"));
});

test("right PIN for a branch admin signs in", () => {
  assert.deepStrictEqual(p.matchAdmin([admin()], "1008"),
      {id: "9600609121", branchId: "erode_main"});
});

test("wrong PIN, member, inactive or no PIN is refused", () => {
  assert.strictEqual(p.matchAdmin([admin()], "1009"), null);
  assert.strictEqual(p.matchAdmin([admin({role: "carpenter"})], "1008"), null);
  assert.strictEqual(p.matchAdmin([admin({role: "super_admin"})], "1008"), null);
  assert.strictEqual(p.matchAdmin([admin({pinHash: undefined})], "1008"), null);
  assert.strictEqual(p.matchAdmin([admin()], "abc"), null);
  assert.strictEqual(p.matchAdmin([], "1008"), null);
});

test("old inactive admin record (as the app uses it) still signs in", () => {
  // Erode's admin: the only record is legacy + inactive, and its
  // migratedToUid wrongly points at the super admin. Sign in as the record
  // itself, never the migration target.
  const erode = admin({legacyAccount: true, active: false,
    migratedToUid: "SUPER_ADMIN_UID"});
  erode.id = "B8Q69u09NUyXq5nsBDjw";
  assert.deepStrictEqual(p.matchAdmin([erode], "1008"),
      {id: "B8Q69u09NUyXq5nsBDjw", branchId: "erode_main"});
});

test("picks the same account as the app: first non-legacy", () => {
  const legacy = admin({legacyAccount: true});
  legacy.id = "old";
  const current = admin();
  assert.strictEqual(p.matchAdmin([legacy, current], "1008").id, "9600609121");
  // A legacy admin doc is not used when a current carpenter doc exists.
  const carpenter = {id: "c1", data: {role: "carpenter"}};
  assert.strictEqual(p.matchAdmin([legacy, carpenter], "1008"), null);
});

test("five wrong PINs lock for 15 minutes", () => {
  let a;
  const now = 1_000_000;
  for (let i = 0; i < p.MAX_FAILURES - 1; i++) a = p.afterFailure(a, now);
  assert.strictEqual(p.isLocked(a, now), false);
  a = p.afterFailure(a, now);
  assert.strictEqual(p.isLocked(a, now), true);
  assert.strictEqual(p.isLocked(a, now + p.LOCK_MINUTES * 60 * 1000 + 1), false);
});
