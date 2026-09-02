/**
 * `venues/{venueId}/metrics/{periodId}` and `.../aiVisibility/current` <->
 * the Performance and AI Visibility tab shapes. The exported interfaces stay
 * in `mock-analytics.ts` per the task brief (they are the document-shape
 * contract shared with the seed script) — this module only adds the
 * Firestore-doc parsers and re-exports the types so callers have one import.
 */
export type { AttendanceBar, FunnelStage, TopNight, AiPrompt } from "../mock-analytics";
import type { AiPrompt, AttendanceBar, FunnelStage, TopNight } from "../mock-analytics";

export interface VenueMetrics {
  attendance: AttendanceBar[];
  attendanceCeiling: number;
  attendanceAvg: string;
  attendancePeak: string;
  funnel: FunnelStage[];
  topNights: TopNight[];
}

function parseAttendance(raw: unknown): AttendanceBar[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((x): x is Record<string, unknown> => !!x && typeof x === "object")
    .map((x) => ({ label: typeof x.label === "string" ? x.label : "", value: typeof x.value === "number" ? x.value : 0 }));
}

function parseFunnel(raw: unknown): FunnelStage[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((x): x is Record<string, unknown> => !!x && typeof x === "object")
    .map((x) => ({
      label: typeof x.label === "string" ? x.label : "",
      value: typeof x.value === "string" ? x.value : "0",
      width: typeof x.width === "string" ? x.width : "0%",
      tone: x.tone === "tertiary" ? "tertiary" : "primary",
    }));
}

function parseTopNights(raw: unknown): TopNight[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((x): x is Record<string, unknown> => !!x && typeof x === "object")
    .map((x, i) => ({
      rank: typeof x.rank === "number" ? x.rank : i + 1,
      name: typeof x.name === "string" ? x.name : "",
      date: typeof x.date === "string" ? x.date : "",
      value: typeof x.value === "string" ? x.value : "0",
    }));
}

/** Absent when no producer has ever run — the panel renders an empty state, not zeros. */
export function parseVenueMetrics(data: Record<string, unknown> | undefined): VenueMetrics | null {
  if (!data) return null;
  const attendance = (data.attendance ?? {}) as Record<string, unknown>;
  const funnel = (data.funnel ?? {}) as Record<string, unknown>;
  return {
    attendance: parseAttendance(attendance.bars),
    attendanceCeiling: typeof attendance.ceiling === "number" ? attendance.ceiling : 0,
    attendanceAvg: typeof attendance.avg === "string" ? attendance.avg : "0",
    attendancePeak: typeof attendance.peak === "string" ? attendance.peak : "0",
    funnel: parseFunnel(funnel.stages),
    topNights: parseTopNights(data.topNights),
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

function parsePrompts(raw: unknown): AiPrompt[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((x): x is Record<string, unknown> => !!x && typeof x === "object")
    .map((x) => {
      const rank = typeof x.rank === "number" ? `#${x.rank}` : "Not shown";
      return {
        prompt: typeof x.prompt === "string" ? x.prompt : "",
        volume: typeof x.weeklyAsks === "number" ? `${x.weeklyAsks.toLocaleString()} asks / week` : "0 asks / week",
        rank,
        band: bandFor(rank),
      };
    });
}

export function parseVenueAiVisibility(data: Record<string, unknown> | undefined): VenueAiVisibility | null {
  if (!data) return null;
  return {
    score: typeof data.score === "number" ? data.score : 0,
    prompts: parsePrompts(data.prompts),
    tips: Array.isArray(data.tips) ? data.tips.filter((t): t is string => typeof t === "string") : [],
  };
}
