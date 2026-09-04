import { describe, expect, it } from "vitest";
import { Timestamp } from "firebase/firestore";
import { isoWeekId, parseVenueAiVisibility, parseVenueMetrics } from "./analytics";

const ts = (iso: string) => Timestamp.fromDate(new Date(iso));

describe("isoWeekId", () => {
  it("matches the seeded week for the seed fixture's top night", () => {
    // scripts/seed-emulator/seed-organizer-analytics.mjs seeds the weekly
    // metrics doc under "2026-W32" — the ISO week (Mon-Sun) containing
    // 2026-08-08, the fixture's #1 top night.
    expect(isoWeekId(new Date("2026-08-08T12:00:00Z"))).toBe("2026-W32");
  });

  it("rolls over at a year boundary (ISO week, not calendar week)", () => {
    // 2027-01-01 is a Friday, which ISO-8601 assigns to week 53 of 2026.
    expect(isoWeekId(new Date("2027-01-01T12:00:00Z"))).toBe("2026-W53");
  });
});

describe("parseVenueMetrics", () => {
  const last30 = {
    funnel: [
      { label: "Surfaced by the assistant", value: 14300, tone: "primary" },
      { label: "Profile opened", value: 9120, tone: "primary" },
      { label: "Added to a plan", value: 2410, tone: "tertiary" },
      { label: "Checked in at the door", value: 1865, tone: "tertiary" },
    ],
    ageBands: [
      { label: "18–24", pct: 38 },
      { label: "25–34", pct: 44 },
    ],
    localSplit: [{ label: "Local", pct: 61 }],
    genreFollows: [{ label: "Techno", pct: 52 }],
  };

  const week = {
    attendance: [
      { label: "Mon", value: 0 },
      { label: "Tue", value: 0 },
      { label: "Wed", value: 180 },
      { label: "Thu", value: 340 },
      { label: "Fri", value: 520 },
      { label: "Sat", value: 585 },
      { label: "Sun", value: 240 },
    ],
    attendanceCeiling: 600,
    topNights: [
      { rank: 1, name: "Full Moon Rooftop", at: ts("2026-08-08T18:00:00Z"), value: 585 },
      { rank: 4, name: "Members Only: Vol. 2", at: ts("2026-07-18T13:00:00Z"), value: 312 },
    ],
  };

  it("derives FunnelStage.width as a percentage of the widest stage", () => {
    const m = parseVenueMetrics(last30, undefined);
    expect(m?.funnel.map((f) => f.width)).toEqual(["100%", "64%", "17%", "13%"]);
  });

  it("formats FunnelStage.value with thousands separators", () => {
    const m = parseVenueMetrics(last30, undefined);
    expect(m?.funnel.map((f) => f.value)).toEqual(["14,300", "9,120", "2,410", "1,865"]);
  });

  it("derives TopNight.date from the stored Timestamp", () => {
    const m = parseVenueMetrics(undefined, week);
    expect(m?.topNights.map((n) => n.date)).toEqual(["Aug 8", "Jul 18"]);
  });

  it("formats audience breakdowns as percentage strings", () => {
    const m = parseVenueMetrics(last30, undefined);
    expect(m?.ageBands).toEqual([
      { label: "18–24", pct: "38%" },
      { label: "25–34", pct: "44%" },
    ]);
  });

  it("derives attendance peak as the max bar and avg over open nights only", () => {
    const m = parseVenueMetrics(undefined, week);
    expect(m?.attendancePeak).toBe("585");
    // (180 + 340 + 520 + 585 + 240) / 5 = 373
    expect(m?.attendanceAvg).toBe("373");
  });

  it("returns null when neither period doc exists — an honest empty state, not zeros", () => {
    expect(parseVenueMetrics(undefined, undefined)).toBeNull();
  });

  it("fills in whichever half it has when only one doc exists", () => {
    const m = parseVenueMetrics(last30, undefined);
    expect(m?.funnel.length).toBe(4);
    expect(m?.attendance).toEqual([]);
    expect(m?.topNights).toEqual([]);
  });
});

describe("parseVenueAiVisibility", () => {
  it('renders "#1" for a ranked prompt and "Not shown" for rank: null', () => {
    const v = parseVenueAiVisibility({
      score: 74,
      prompts: [
        { prompt: "rooftop with house music tonight", weeklyAsks: 2400, rank: 1 },
        { prompt: "late night after 3am", weeklyAsks: 640, rank: null },
      ],
      tips: [],
    });
    expect(v?.prompts.map((p) => p.rank)).toEqual(["#1", "Not shown"]);
    expect(v?.prompts.map((p) => p.band)).toEqual(["top", "absent"]);
  });

  it("formats weekly ask volume with thousands separators", () => {
    const v = parseVenueAiVisibility({ score: 0, prompts: [{ prompt: "x", weeklyAsks: 2400, rank: 1 }], tips: [] });
    expect(v?.prompts[0].volume).toBe("2,400 asks / week");
  });

  it("returns null when the document is absent — an honest empty state, not a score of 0", () => {
    expect(parseVenueAiVisibility(undefined)).toBeNull();
  });
});
