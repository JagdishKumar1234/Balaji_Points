// The stores are in India, so a bill's day is its day in India time.
const INDIA_OFFSET_MS = (5 * 60 + 30) * 60 * 1000;

/**
 * The calendar day of [date] in India time, as YYYY-MM-DD.
 * @param {Date} date - Any moment.
 * @return {string} The India-time day.
 */
function indiaDay(date) {
  return new Date(date.getTime() + INDIA_OFFSET_MS).toISOString().slice(0, 10);
}

/**
 * Whether a bill's date is after today (India time). A bill dated today, at
 * any time of day, is not in the future.
 * @param {Date} billDate - The bill's date.
 * @param {Date} now - The current time.
 * @return {boolean} True only for bills dated tomorrow or later.
 */
function isFutureBillDate(billDate, now) {
  if (!(billDate instanceof Date) || isNaN(billDate.getTime())) return false;
  return indiaDay(billDate) > indiaDay(now);
}

/**
 * The start (inclusive) and end (exclusive) of [date]'s day in India time.
 * @param {Date} date - Any moment in the day.
 * @return {{start: Date, end: Date}} The day's bounds.
 */
function indiaDayBounds(date) {
  const start = new Date(`${indiaDay(date)}T00:00:00+05:30`);
  return {start, end: new Date(start.getTime() + 24 * 60 * 60 * 1000)};
}

module.exports = {indiaDay, isFutureBillDate, indiaDayBounds};
