import { EVENT_STATUS_STYLES, UPCOMING_STYLE } from "./constants";
import type { OrganizerEvent, VenueProfile } from "./types";

/** ISO "YYYY-MM-DD" in local time — `toISOString` would shift across the date line. */
export function toISODate(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

/** Monday-first weekday index, matching the `hours` array and the calendar grid. */
export function mondayFirstIndex(d: Date): number {
  return (d.getDay() + 6) % 7;
}

export function minutesOf(time: string): number {
  const [h, m] = time.split(":").map(Number);
  return (h || 0) * 60 + (m || 0);
}

/**
 * The chip shown for an event in a list.
 *
 * A `live` event is only labelled LIVE while it is actually running tonight;
 * outside that window it reads UPCOMING. `now` is null until the client has
 * mounted (the server has no meaningful clock for the organizer's timezone),
 * in which case a `live` event falls back to UPCOMING.
 */
export function deriveEventChip(ev: OrganizerEvent, now: Date | null) {
  if (ev.status !== "live") return EVENT_STATUS_STYLES[ev.status];
  if (!now) return UPCOMING_STYLE;
  if (ev.date !== toISODate(now)) return UPCOMING_STYLE;

  const startMins = minutesOf(ev.startTime);
  let endMins = minutesOf(ev.endTime);
  if (endMins <= startMins) endMins += 24 * 60; // closing time is after midnight
  const nowMins = now.getHours() * 60 + now.getMinutes();

  return nowMins >= startMins && nowMins <= endMins
    ? EVENT_STATUS_STYLES.live
    : UPCOMING_STYLE;
}

export function venueName(venues: Record<string, VenueProfile>, id: string): string {
  return venues[id]?.name ?? id;
}

export function coverText(profile: VenueProfile): string {
  return `${profile.currency}${profile.coverMin}–${profile.currency}${profile.coverMax}`;
}

export function capacityText(profile: VenueProfile): string {
  return `${profile.capacity} capacity`;
}

/** Is the venue open on `dateISO`? An exception for that date overrides regular hours. */
export function isOpenOn(profile: VenueProfile, dateISO: string, dayIdx: number): boolean {
  const exception = profile.exceptions.find((e) => e.date === dateISO);
  if (exception) return !exception.closed;
  return !profile.hours[dayIdx].closed;
}

export function hoursTextFor(profile: VenueProfile, dayIdx: number): string {
  const h = profile.hours[dayIdx];
  return h.closed ? "Closed" : `${h.open} – ${h.close}`;
}

export interface CalendarCell {
  key: string;
  /** Empty string for the leading blanks before the 1st. */
  dayNum: number | "";
  dateISO: string;
  events: { id: string; name: string }[];
  /** Venue is shut that day — only knowable when a single venue is selected. */
  isClosed: boolean;
  closedLabel: string;
}

/**
 * Month grid for `monthOffset` months from `base`, Monday-first.
 *
 * Closed-day shading needs a specific venue's hours, so it only applies when
 * `profile` is given (i.e. the venue filter is not "All Venues").
 */
export function buildCalendar(
  base: Date,
  monthOffset: number,
  events: OrganizerEvent[],
  venueFilter: string,
  profile: VenueProfile | null
): { label: string; cells: CalendarCell[] } {
  const first = new Date(base.getFullYear(), base.getMonth() + monthOffset, 1);
  const year = first.getFullYear();
  const month = first.getMonth();
  const label = first.toLocaleString("en-US", { month: "long", year: "numeric" });

  const startOffset = mondayFirstIndex(first);
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const cells: CalendarCell[] = [];

  for (let i = 0; i < startOffset; i++) {
    cells.push({
      key: `blank-${i}`,
      dayNum: "",
      dateISO: "",
      events: [],
      isClosed: false,
      closedLabel: "",
    });
  }

  for (let d = 1; d <= daysInMonth; d++) {
    const dateISO = toISODate(new Date(year, month, d));
    const dayIdx = mondayFirstIndex(new Date(year, month, d));
    const dayEvents = events.filter(
      (e) =>
        e.date === dateISO &&
        e.status !== "cancelled" &&
        (venueFilter === "all" || e.venue === venueFilter)
    );
    const exception = profile ? profile.exceptions.find((e) => e.date === dateISO) : undefined;
    const isClosed = profile ? !isOpenOn(profile, dateISO, dayIdx) : false;

    cells.push({
      key: dateISO,
      dayNum: d,
      dateISO,
      events: dayEvents.map((e) => ({ id: e.id, name: e.name })),
      isClosed,
      closedLabel: exception ? exception.label : "closed",
    });
  }

  return { label, cells };
}

export function pct(part: number, whole: number): string {
  if (!whole) return "0%";
  return `${Math.round((part / whole) * 100)}%`;
}

export function starsFor(rating: number): string {
  return "★".repeat(rating) + "☆".repeat(Math.max(0, 5 - rating));
}
