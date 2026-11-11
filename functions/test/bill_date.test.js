const test = require("node:test");
const assert = require("node:assert");
const {isFutureBillDate} = require("../bill_date");

// 11 Nov 2026, 5:10 pm India time.
const now = new Date("2026-11-11T11:40:00Z");

test("a bill dated today is accepted, at any time of day", () => {
  assert.strictEqual(isFutureBillDate(new Date("2026-11-11T17:09:00+05:30"), now), false);
  assert.strictEqual(isFutureBillDate(new Date("2026-11-11T23:59:00+05:30"), now), false);
  assert.strictEqual(isFutureBillDate(new Date("2026-11-11T00:00:00+05:30"), now), false);
});

test("past bills are accepted", () => {
  assert.strictEqual(isFutureBillDate(new Date("2026-11-10T12:00:00+05:30"), now), false);
});

test("bills dated tomorrow or later are rejected", () => {
  assert.strictEqual(isFutureBillDate(new Date("2026-11-12T00:00:00+05:30"), now), true);
  assert.strictEqual(isFutureBillDate(new Date("2026-12-01T09:00:00+05:30"), now), true);
});

test("just after midnight in India, today's bills are still accepted", () => {
  const earlyMorning = new Date("2026-11-11T18:40:00Z"); // 12:10 am, 12 Nov IST
  assert.strictEqual(isFutureBillDate(new Date("2026-11-12T00:05:00+05:30"), earlyMorning), false);
});

test("a missing or broken date is not called future", () => {
  assert.strictEqual(isFutureBillDate(new Date("nope"), now), false);
  assert.strictEqual(isFutureBillDate(undefined, now), false);
});

test("duplicate search covers the bill's whole India day", () => {
  const {indiaDayBounds} = require("../bill_date");
  const {start, end} = indiaDayBounds(new Date("2026-11-11T23:30:00+05:30"));
  assert.strictEqual(start.toISOString(), "2026-11-10T18:30:00.000Z");
  assert.strictEqual(end.toISOString(), "2026-11-11T18:30:00.000Z");
});
