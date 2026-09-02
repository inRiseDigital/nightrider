/**
 * Seed data for the Audience destination's Performance and AI Visibility tabs.
 *
 * Kept separate from `mock-data.ts` because these are presentational analytics
 * with no counterpart in the venue/event model — nothing here is derived from,
 * or feeds back into, the organizer's own records. Values mirror the
 * "Organizer Dashboard Material" design source.
 */

export interface AttendanceBar {
  label: string;
  /** Guests through the door. 0 means the venue was closed that night. */
  value: number;
}

export interface FunnelStage {
  label: string;
  value: string;
  /** Bar width as a percentage of the widest stage. */
  width: string;
  /** Which accent the bar uses — the funnel cools off after the top two stages. */
  tone: "primary" | "tertiary";
}

export interface TopNight {
  rank: number;
  name: string;
  date: string;
  value: string;
}

export interface AiPrompt {
  prompt: string;
  volume: string;
  rank: string;
  /** Ranking band, which picks the chip colour. */
  band: "top" | "strong" | "weak" | "absent";
}

/** Mon–Sun; the venue is dark Monday and Tuesday. */
export const MOCK_ATTENDANCE: AttendanceBar[] = [
  { label: "Mon", value: 0 },
  { label: "Tue", value: 0 },
  { label: "Wed", value: 180 },
  { label: "Thu", value: 340 },
  { label: "Fri", value: 520 },
  { label: "Sat", value: 585 },
  { label: "Sun", value: 240 },
];

/** Bars are drawn against a fixed ceiling, not the week's own peak. */
export const ATTENDANCE_CEILING = 600;
export const MOCK_ATTENDANCE_AVG = "415";
export const MOCK_ATTENDANCE_PEAK = "585";

export const MOCK_DISCOVERY_FUNNEL: FunnelStage[] = [
  { label: "Surfaced by the assistant", value: "14,300", width: "100%", tone: "primary" },
  { label: "Profile opened", value: "9,120", width: "64%", tone: "primary" },
  { label: "Added to a plan", value: "2,410", width: "17%", tone: "tertiary" },
  { label: "Checked in at the door", value: "1,865", width: "13%", tone: "tertiary" },
];

export const MOCK_TOP_NIGHTS: TopNight[] = [
  { rank: 1, name: "Full Moon Rooftop", date: "Aug 8", value: "585" },
  { rank: 2, name: "Techno Fridays", date: "Aug 1", value: "540" },
  { rank: 3, name: "Sunset to Sunrise", date: "Jul 26", value: "498" },
  { rank: 4, name: "Members Only: Vol. 2", date: "Jul 18", value: "312" },
];

export const MOCK_AI_SCORE = 74;

export const MOCK_AI_PROMPTS: AiPrompt[] = [
  {
    prompt: "rooftop with house music tonight",
    volume: "2,400 asks / week",
    rank: "#1",
    band: "top",
  },
  {
    prompt: "best view bar in Business Bay",
    volume: "1,150 asks / week",
    rank: "#3",
    band: "strong",
  },
  { prompt: "afrobeats night Dubai", volume: "980 asks / week", rank: "#8", band: "weak" },
  {
    prompt: "late night after 3am",
    volume: "640 asks / week",
    rank: "Not shown",
    band: "absent",
  },
];

export const MOCK_AI_TIPS = [
  "Publish next week's lineup at least 5 days ahead — early listings get recommended more often.",
  'Add "Amapiano" if you programme it; you rank for it organically but it is missing from your genres.',
  "Reply to reviews within 48 hours; response rate feeds directly into your score.",
];
