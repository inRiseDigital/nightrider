/**
 * Timezone-aware conversions between the UI's local "YYYY-MM-DD" + "HH:mm"
 * event window and Firestore's `startAt`/`endAt` Timestamps.
 *
 * No new dependency — there is no `date-fns-tz` or luxon in `package.json`
 * and adding one for ~30 lines of `Intl` is not warranted.
 */
import { Timestamp } from "firebase/firestore";
import type { OrganizerEvent } from "../types";

/** The UTC offset (ms) of `timeZone` at the instant `utcMs`. */
function zoneOffsetMs(utcMs: number, timeZone: string): number {
  const dtf = new Intl.DateTimeFormat("en-US", { timeZone, timeZoneName: "longOffset" });
  const parts = dtf.formatToParts(new Date(utcMs));
  const raw = parts.find((p) => p.type === "timeZoneName")?.value ?? "GMT+00:00";
  const m = raw.match(/GMT([+-])(\d{2}):(\d{2})/);
  if (!m) return 0;
  const sign = m[1] === "-" ? -1 : 1;
  return sign * (Number(m[2]) * 60 + Number(m[3])) * 60_000;
}

function minutesOf(time: string): number {
  const [h, m] = time.split(":").map(Number);
  return (h || 0) * 60 + (m || 0);
}

function addDaysISO(dateISO: string, days: number): string {
  const [y, mo, d] = dateISO.split("-").map(Number);
  const dt = new Date(Date.UTC(y || 0, (mo || 1) - 1, (d || 1) + days));
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${dt.getUTCFullYear()}-${pad(dt.getUTCMonth() + 1)}-${pad(dt.getUTCDate())}`;
}

/**
 * Naive local wall-clock time in `timeZone`, as a UTC instant. Two-pass: guess
 * the offset at the naive instant, then re-derive the offset at the guessed
 * instant and correct — the standard DST-boundary fix. A single-pass version
 * is wrong twice a year, at both DST transitions.
 */
export function zonedToUtc(dateISO: string, time: string, timeZone: string): Date {
  const [y, mo, d] = dateISO.split("-").map(Number);
  const [h, mi] = time.split(":").map(Number);
  const naiveMs = Date.UTC(y || 0, (mo || 1) - 1, d || 1, h || 0, mi || 0);
  const guessOffset = zoneOffsetMs(naiveMs, timeZone);
  const guessUtcMs = naiveMs - guessOffset;
  const correctedOffset = zoneOffsetMs(guessUtcMs, timeZone);
  return new Date(naiveMs - correctedOffset);
}

export function utcToZonedParts(d: Date, timeZone: string): { dateISO: string; time: string } {
  const dtf = new Intl.DateTimeFormat("en-US", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  });
  const parts = dtf.formatToParts(d);
  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "00";
  return { dateISO: `${get("year")}-${get("month")}-${get("day")}`, time: `${get("hour")}:${get("minute")}` };
}

/**
 * `date`/`startTime`/`endTime` -> `startAt`/`endAt`. Overnight windows (e.g.
 * 22:00 -> 04:00) roll `endAt` onto `date + 1`, matching `format.ts:36`'s
 * `endMins <= startMins` bump and `blankEventDraft`'s 22:00/04:00 default.
 *
 * `ui.endTime === ""` means "no end time" (an admin- or scraper-written
 * document `parseOrganizerEvent` tolerated as `endTime: ""`, being edited or
 * duplicated by an organizer rather than freshly authored by one) and
 * returns `endAt: null` — never a fabricated close time. `minutesOf("")` is
 * `0`, which without this branch reads as "ends at 00:00", makes `overnight`
 * true unconditionally, and silently produces `endAt` at midnight the next
 * day: a real close time invented from nothing. Every genuinely
 * organizer-authored event has a non-empty `endTime` in the UI (`shapeOk()`
 * requires it whenever the written `source` is `'organizer'`); that
 * requirement belongs at the call site, which knows whether the document
 * it's about to write is organizer-sourced, not here.
 */
export function eventWindowToTimestamps(
  ui: Pick<OrganizerEvent, "date" | "startTime" | "endTime">,
  timeZone: string
): { startAt: Timestamp; endAt: Timestamp | null } {
  const start = zonedToUtc(ui.date, ui.startTime, timeZone);
  if (!ui.endTime) return { startAt: Timestamp.fromDate(start), endAt: null };
  const overnight = minutesOf(ui.endTime) <= minutesOf(ui.startTime);
  const endDateISO = overnight ? addDaysISO(ui.date, 1) : ui.date;
  const end = zonedToUtc(endDateISO, ui.endTime, timeZone);
  return { startAt: Timestamp.fromDate(start), endAt: Timestamp.fromDate(end) };
}

/**
 * `startAt`/`endAt` -> `date`/`startTime`/`endTime`. `date`/`startTime` come
 * from `startAt`. `endAt === null` (admin- and scraper-written events) is
 * tolerated by returning `endTime: ""` rather than guessing — the panel
 * always writes a non-null `endAt` itself, but must not assume one on read.
 */
export function timestampsToEventWindow(
  startAt: Timestamp,
  endAt: Timestamp | null,
  timeZone: string
): { date: string; startTime: string; endTime: string } {
  const { dateISO, time: startTime } = utcToZonedParts(startAt.toDate(), timeZone);
  if (!endAt) return { date: dateISO, startTime, endTime: "" };
  const { time: endTime } = utcToZonedParts(endAt.toDate(), timeZone);
  return { date: dateISO, startTime, endTime };
}

/**
 * `meta[venueId].timeZone`, falling back to the browser's zone. The fallback
 * is only correct for an organizer physically in that zone, so it is logged
 * every time it fires rather than silently accepted.
 */
export function resolveTimeZone(timeZone: string | undefined): string {
  if (timeZone) return timeZone;
  const fallback = Intl.DateTimeFormat().resolvedOptions().timeZone;
  console.warn(
    `[organizer] No venue timeZone on record — falling back to the browser's zone ("${fallback}"). ` +
      "This is only correct for an organizer physically in that timezone."
  );
  return fallback;
}
