// Pure helpers for adminPinSignIn (see index.js), kept separate so they can
// be unit-tested without Firebase.
const crypto = require("crypto");

const MAX_FAILURES = 5;
const LOCK_MINUTES = 15;

/**
 * Digits only, last 10 ("+91 96006-09121" -> "9600609121").
 * @param {string} phone phone as typed or stored
 * @return {string} 10-digit phone
 */
function normalizePhone(phone) {
  const d = String(phone || "").replace(/\D/g, "");
  return d.length > 10 ? d.slice(-10) : d;
}

/**
 * Same salted hash the app uses: sha256("<pin>::<salt>") as hex.
 * @param {string} pin the PIN
 * @param {string} salt the stored salt
 * @return {string} hex digest
 */
function hashPin(pin, salt) {
  return crypto.createHash("sha256").update(`${pin}::${salt}`).digest("hex");
}

/**
 * Picks the account the app's PIN login would pick for this phone (the
 * first non-legacy one, else the first), and accepts it only if it is a
 * branch admin with a PIN that matches. Returns {id, branchId} or null.
 *
 * @param {Array<{id: string, data: Object}>} docs users with this phone
 * @param {string} pin the PIN typed at login
 * @return {?{id: string, branchId: ?string}} the admin, or null
 */
function matchAdmin(docs, pin) {
  if (!/^\d{4,6}$/.test(String(pin || ""))) return null;
  const chosen = docs.find((d) => d.data.legacyAccount !== true) || docs[0];
  if (!chosen) return null;
  const d = chosen.data;
  if (String(d.role || "").trim().toLowerCase() !== "admin") return null;
  // No `active` check: the app's PIN login accepts the same record even
  // when an old migration marked it inactive (Erode's admin is one), and
  // the rules only look at role and branch. `migratedToUid` is never
  // followed: some point at the wrong account.
  if (!d.pinSalt || !d.pinHash) return null;
  const a = Buffer.from(hashPin(pin, d.pinSalt));
  const b = Buffer.from(String(d.pinHash));
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return null;
  return {id: chosen.id, branchId: d.branchId || null};
}

/**
 * Whether the phone is locked after too many wrong PINs.
 * @param {?{lockedUntil: number}} attempts stored attempts record
 * @param {number} now current time in ms
 * @return {boolean} locked
 */
function isLocked(attempts, now) {
  const until = attempts && attempts.lockedUntil;
  return Boolean(until && until > now);
}

/**
 * The attempts record after one more wrong PIN.
 * @param {?{fails: number}} attempts stored attempts record
 * @param {number} now current time in ms
 * @return {{fails: number, lockedUntil: number}} new record
 */
function afterFailure(attempts, now) {
  const fails = ((attempts && attempts.fails) || 0) + 1;
  return fails >= MAX_FAILURES ?
    {fails: 0, lockedUntil: now + LOCK_MINUTES * 60 * 1000} :
    {fails, lockedUntil: 0};
}

module.exports = {
  normalizePhone, hashPin, matchAdmin, isLocked, afterFailure,
  MAX_FAILURES, LOCK_MINUTES,
};
