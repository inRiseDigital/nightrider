/**
 * `venues/{venueId}/metrics/{periodId}` and `.../aiVisibility/current` <->
 * the Performance and AI Visibility tab shapes. The exported interfaces stay
 * in `mock-analytics.ts` per the task brief (they are the document-shape
 * contract shared with the seed script) — this module only adds the
 * Firestore-doc parsers and re-exports the types so callers have one import.
 *
 * `periodId` is `"last30"` (a rolling 30-day aggregate — funnel + audience
 * breakdowns) or `"YYYY-Www"` (one ISO week — nightly attendance + top
 * nights), confirmed against `scripts/seed-emulator/seed-organizer-analytics.mjs`:
 * the two periods carry disjoint fields, so `parseVenueMetrics` takes both
 * docs and merges them rather than picking one.
 */
export type { AttendanceBar, FunnelStage, TopNight, AiPrompt } from "../mock-analytics";
import type { AiPrompt, AttendanceBar, FunnelStage, TopNight } from "../mock-analytics";

/** An audience-breakdown row — `venues/{id}/metrics/last30`'s `ageBands` / `localSplit` / `genreFollows`. */
export interface MetricBreakdown {
  label: string;
  /** Formatted, e.g. `"38%"` — the stored field is the raw number. */
  pct: string;
}

export interface VenueMetrics {
  attendance: AttendanceBar[];
  attendanceCeiling: number;
  attendanceAvg: string;
  attendancePeak: string;
  funnel: FunnelStage[];
  topNights: TopNight[];
  ageBands: MetricBreakdown[];
  localSplit: MetricBreakdown[];
  genreFollows: MetricBreakdown[];
}

/**
 * ISO-8601 week id, e.g. `"2026-W32"` — the Thursday-anchored algorithm
 * (move to the week's Thursday, compare against that ISO year's first
 * Thursday) so the week number never disagrees with the calendar's own
 * ISO week boundaries. No date library: this is the entire algorithm.
 */
export function isoWeekId(d: Date): string {
  const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
  const dayNum = (date.getUTCDay() + 6) % 7; // Mon=0 .. Sun=6
  date.setUTCDate(date.getUTCDate() - dayNum + 3); // nearest Thursday
  const firstThursday = new Date(Date.UTC(date.getUTCFullYear(), 0, 4));
  const firstDayNum = (firstThursday.getUTCDay() + 6) % 7;
  firstThursday.setUTCDate(firstThursday.getUTCDate() - firstDayNum + 3);
  const week = 1 + Math.round((date.getTime() - firstThursday.getTime()) / (7 * 86_400_000));
  return `${date.getUTCFullYear()}-W${String(week).padStart(2, "0")}`;
}

function parseAttendance(raw: unknown): AttendanceBar[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((x): x is Record<string, unknown> => !!x && typeof x === "object")
    .map((x) => ({ label: typeof x.label === "string" ? x.label : "", value: typeof x.value === "number" ? x.value : 0 }));
}

/**
 * The document stores absolute counts only (`{label, value, tone}`) —
 * `FunnelStage.width` and the `"14,300"`-style `value` string are
 * presentation this function derives, never stored, so a percentage or a
 * formatted string can never drift out of sync with the underlying count.
 */
function parseFunnel(raw: unknown): FunnelStage[] {
  if (!Array.isArray(raw)) return [];
  const rows = raw
    .filter((x): x is Record<string, unknown> => !!x && typeof x === "object")
    .map((x) => ({
      label: typeof x.label === "string" ? x.label : "",
      count: typeof x.value === "number" ? x.value : 0,
      tone: (x.tone === "tertiary" ? "tertiary" : "primary") as FunnelStage["tone"],
    }));
  const max = rows.reduce((m, r) => Math.max(m, r.count), 0);
  return rows.map((r) => ({
    label: r.label,
    value: r.count.toLocaleString("en-US"),
    width: max > 0 ? `${Math.round((r.count / max) * 100)}%` : "0%",
    tone: r.tone,
  }));
}

/**
 * `TopNight.date` (`"Aug 8"`) is derived here from the stored `at: Timestamp`.
 * Formatted in UTC, not the browser's local zone — there is no per-night
 * venue timezone available at this call site (only `metrics/{periodId}`,
 * not `venueMeta`), and UTC keeps the label deterministic across whichever
 * timezone the organizer or a test runner happens to be in.
 */
function dateLabel(raw: unknown): string {
  if (!raw || typeof raw !== "object" || typeof (raw as { toDate?: unknown }).toDate !== "function") return "";
  const d = (raw as { toDate: () => Date }).toDate();
  return d.toLocaleDateString("en-US", { month: "short", day: "numeric", timeZone: "UTC" });
}

function parseTopNights(raw: unknown): TopNight[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((x): x is Record<string, unknown> => !!x && typeof x === "object")
    .map((x, i) => ({
      rank: typeof x.rank === "number" ? x.rank : i + 1,
      name: typeof x.name === "string" ? x.name : "",
      date: dateLabel(x.at),
      value: typeof x.value === "number" ? x.value.toLocaleString("en-US") : "0",
    }));
}

function parseBreakdown(raw: unknown): MetricBreakdown[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((x): x is Record<string, unknown> => !!x && typeof x === "object")
    .map((x) => ({
      label: typeof x.label === "string" ? x.label : "",
      pct: `${typeof x.pct === "number" ? x.pct : 0}%`,
    }));
}

/**
 * `attendanceAvg`/`attendancePeak` are never stored (confirmed against the
 * seed fixture — the week doc carries `attendance`/`attendanceCeiling` only)
 * — both are derived from the same `attendance` bars the panel already
 * renders. Peak is the week's single busiest night; average is over nights
 * the venue was actually open (a closed night's `0` would otherwise drag a
 * "typical night" figure toward a number nobody who runs the door would
 * recognise).
 */
function deriveAvgPeak(attendance: AttendanceBar[]): { avg: string; peak: string } {
  const values = attendance.map((a) => a.value);
  const peak = values.length ? Math.max(...values) : 0;
  const open = values.filter((v) => v > 0);
  const avg = open.length ? Math.round(open.reduce((a, b) => a + b, 0) / open.length) : 0;
  return { avg: avg.toLocaleString("en-US"), peak: peak.toLocaleString("en-US") };
}

/**
 * Absent when no producer has ever run — the panel renders an empty state,
 * not zeros. `last30`/`week` are independent docs (see the module doc); either
 * may be missing on its own (a brand-new venue has neither), so this returns
 * `null` only when both are absent, and otherwise fills in whatever half it has.
 */
export function parseVenueMetrics(
  last30: Record<string, unknown> | undefined,
  week: Record<string, unknown> | undefined
): VenueMetrics | null {
  if (!last30 && !week) return null;
  const attendance = parseAttendance(week?.attendance);
  const { avg, peak } = deriveAvgPeak(attendance);
  return {
    attendance,
    attendanceCeiling: typeof week?.attendanceCeiling === "number" ? week.attendanceCeiling : 0,
    attendanceAvg: avg,
    attendancePeak: peak,
    funnel: parseFunnel(last30?.funnel),
    topNights: parseTopNights(week?.topNights),
    ageBands: parseBreakdown(last30?.ageBands),
    localSplit: parseBreakdown(last30?.localSplit),
    genreFollows: parseBreakdown(last30?.genreFollows),
  };
}

export interface VenueAiVisibility {
  score: number;
  prompts: AiPrompt[];
  tips: string[];
}

function bandFor(rank: string): AiPrompt["band"] {
  if (rank === "Not shown") return "absent";
  const n = Number(rank.replace("#", ""));
  if (!Number.isFinite(n)) return "absent";
  if (n <= 3) return "top";
  if (n <= 10) return "strong";
  return "weak";
}

/** `rank: null` means not shown — the `"#1"` / `"Not shown"` text is derived here, never stored. */
function parsePrompts(raw: unknown): AiPrompt[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((x): x is Record<string, unknown> => !!x && typeof x === "object")
    .map((x) => {
      const rank = typeof x.rank === "number" ? `#${x.rank}` : "Not shown";
      return {
        prompt: typeof x.prompt === "string" ? x.prompt : "",
        volume: typeof x.weeklyAsks === "number" ? `${x.weeklyAsks.toLocaleString("en-US")} asks / week` : "0 asks / week",
        rank,
        band: bandFor(rank),
      };
    });
}

/** Absent when no producer has ever run — the panel renders an honest empty state, not a score of 0. */
export function parseVenueAiVisibility(data: Record<string, unknown> | undefined): VenueAiVisibility | null {
  if (!data) return null;
  return {
    score: typeof data.score === "number" ? data.score : 0,
    prompts: parsePrompts(data.prompts),
    tips: Array.isArray(data.tips) ? data.tips.filter((t): t is string => typeof t === "string") : [],
  };
}
