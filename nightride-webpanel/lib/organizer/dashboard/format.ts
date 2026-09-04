import { EVENT_STATUS_STYLES } from "./constants";
import type { EventDisplayStatus, OrganizerEvent, VenueProfile } from "./types";
import type { EventFilter } from "./store";
import { zonedToUtc } from "./data/time";

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
 * `ev.date` ("YYYY-MM-DD") + a "HH:mm" time, as the UTC instant it names in
 * `timeZone` — the venue's IANA zone, since `parseOrganizerEvent` produced
 * `date`/`startTime`/`endTime` from `startAt`/`endAt` via
 * `timestampsToEventWindow(startAt, endAt, timeZone)`, i.e. already
 * venue-zoned. Comparing that against `now` (a real UTC instant) in the
 * *browser's* local zone — which a plain `new Date(y, mo, d, h, mi)`
 * constructor does — is wrong by the offset between the two zones (finding
 * 3: a London-based organizer sees a Dubai venue's live window four hours
 * off). `zonedToUtc` is the same DST-correct conversion `data/time.ts`
 * already uses for every write of these fields, so this made the same
 * assumption `eventWindowToTimestamps` makes rather than a new one.
 */
function dateTimeOf(dateISO: string, time: string, timeZone: string): Date {
  return zonedToUtc(dateISO, time, timeZone);
}

/**
 * Is `ev` actually running right now?
 *
 * `status == 'published' && startAt <= now && (endAt == null || now <= endAt)`,
 * expressed here against the event's own `date` + `startTime`/`endTime`
 * fields rather than a stored `startAt`/`endAt` timestamp pair. Handles the
 * overnight case (e.g. 22:00-04:00) by rolling the end instant onto the
 * following calendar day whenever it is not after the start instant — so an
 * event that starts one night and ends the next morning is still live after
 * midnight. `now` is null until the client has mounted (the server has no
 * meaningful clock for the organizer's timezone) — in that case the event is
 * never live.
 *
 * `timeZone` is the venue's IANA zone (`venueMeta[ev.venue].timeZone`,
 * resolved via `resolveTimeZone` at the call site) — see `dateTimeOf`.
 *
 * `ev.endTime === ""` means the stored `endAt` is null — only possible for an
 * admin- or scraper-written event, since every organizer-authored event has
 * a required, non-null `endAt`. Per the stored formula
 * (`endAt == null || now <= endAt`), that is open-ended, not "ends at
 * midnight" — treating an empty `endTime` as `00:00` would make the event
 * live for at most an instant instead of indefinitely once started.
 */
export function isEventLive(ev: OrganizerEvent, now: Date | null, timeZone: string): boolean {
  if (!now) return false;
  if (ev.status !== "published") return false;

  const start = dateTimeOf(ev.date, ev.startTime, timeZone);
  if (now.getTime() < start.getTime()) return false;
  if (!ev.endTime) return true;

  let end = dateTimeOf(ev.date, ev.endTime, timeZone);
  if (end.getTime() <= start.getTime()) {
    end = new Date(end.getTime() + 24 * 60 * 60 * 1000); // closing time is after midnight
  }

  return now.getTime() <= end.getTime();
}

/**
 * The chip status to render for an event. `'live'` and `'upcoming'` are
 * derived, never stored — a `published` event reads `'live'` while it is
 * actually running (see `isEventLive`) and `'upcoming'` otherwise. Every
 * other stored status passes through unchanged. When `now` is null, a
 * `published` event falls back to its stored status (`'published'`) rather
 * than guessing live/upcoming.
 */
export function displayStatusOf(ev: OrganizerEvent, now: Date | null, timeZone: string): EventDisplayStatus {
  if (ev.status !== "published") return ev.status;
  if (!now) return ev.status;
  return isEventLive(ev, now, timeZone) ? "live" : "upcoming";
}

/** The chip shown for an event in a list. */
export function deriveEventChip(ev: OrganizerEvent, now: Date | null, timeZone: string) {
  return EVENT_STATUS_STYLES[displayStatusOf(ev, now, timeZone)];
}

/**
 * The events-table filter predicate. `filter === "live"` consults the clock
 * via `isEventLive`; every other filter id matches on the stored status.
 */
export function matchesFilter(ev: OrganizerEvent, filter: EventFilter, now: Date | null, timeZone: string): boolean {
  switch (filter) {
    case "all":
      return true;
    case "live":
      return isEventLive(ev, now, timeZone);
    default:
      return ev.status === filter;
  }
}

/**
 * "Neon Fox Collective" -> "NF". Initials are always derived, never stored.
 * Uses the first letter of up to the first two words; empty input yields "".
 */
export function initialsOf(name: string): string {
  return name
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((word) => word[0]!.toUpperCase())
    .join("");
}

export function venueName(venues: Record<string, VenueProfile>, id: string): string {
  return venues[id]?.name ?? id;
}

/**
 * The accent a venue is drawn in wherever venues sit side by side — the
 * calendar's event bars and the day dialog. First venue takes the primary
 * accent, second the tertiary, and any further ones alternate.
 */
export function venueAccent(venueOrder: string[], id: string): string {
  const idx = venueOrder.indexOf(id);
  return idx % 2 === 1 ? "var(--m3-ter)" : "var(--m3-pri)";
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
  /** "Aug 14" — the heading the day dialog opens with. */
  label: string;
  events: { id: string; name: string; venue: string }[];
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
      label: "",
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
      label: `${first.toLocaleString("en-US", { month: "short" })} ${d}`,
      events: dayEvents.map((e) => ({ id: e.id, name: e.name, venue: e.venue })),
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
