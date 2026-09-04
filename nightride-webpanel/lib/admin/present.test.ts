import { Timestamp } from "firebase/firestore";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { badgeColors } from "./m3-data";
import {
  formatTimestamp,
  initialsFor,
  organizerStatusColors,
  organizerStatusLabel,
  stepStatusChrome,
  timeAgo,
} from "./present";
import type { OrganizerStatus, StepStatus } from "./schema";

describe("initialsFor", () => {
  it("uses the first letters of the first two words of the display name", () => {
    expect(initialsFor("Jamie Cho", "jamie@example.com")).toBe("JC");
  });

  it("falls back to email when display name is empty", () => {
    expect(initialsFor("", "jamie@example.com")).toBe("JA");
  });

  it("falls back to email when display name is only whitespace", () => {
    expect(initialsFor("   ", "jamie@example.com")).toBe("JA");
  });

  it("single-word display name uses its first two characters", () => {
    expect(initialsFor("madonna", "x@example.com")).toBe("MA");
  });

  it("returns '?' when both display name and email are empty", () => {
    expect(initialsFor("", "")).toBe("?");
    expect(initialsFor("  ", "  ")).toBe("?");
  });

  it("collapses extra whitespace between name parts", () => {
    expect(initialsFor("  Jamie   Cho  ", "")).toBe("JC");
  });
});

describe("timeAgo", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-09-04T12:00:00Z"));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("returns '—' for a null timestamp", () => {
    expect(timeAgo(null)).toBe("—");
  });

  it("returns 'just now' for under a minute", () => {
    const ts = Timestamp.fromDate(new Date("2026-09-04T11:59:30Z"));
    expect(timeAgo(ts)).toBe("just now");
  });

  it("returns minutes for under an hour", () => {
    const ts = Timestamp.fromDate(new Date("2026-09-04T11:45:00Z"));
    expect(timeAgo(ts)).toBe("15m ago");
  });

  it("returns hours for under a day", () => {
    const ts = Timestamp.fromDate(new Date("2026-09-04T09:00:00Z"));
    expect(timeAgo(ts)).toBe("3h ago");
  });

  it("returns days for under 30 days", () => {
    const ts = Timestamp.fromDate(new Date("2026-08-30T12:00:00Z"));
    expect(timeAgo(ts)).toBe("5d ago");
  });

  it("returns months for under 12 months", () => {
    const ts = Timestamp.fromDate(new Date("2026-06-01T12:00:00Z"));
    expect(timeAgo(ts)).toBe("3mo ago");
  });

  it("returns years for 12 months or more", () => {
    const ts = Timestamp.fromDate(new Date("2023-09-04T12:00:00Z"));
    expect(timeAgo(ts)).toBe("3y ago");
  });
});

describe("formatTimestamp", () => {
  it("returns '—' for a null timestamp", () => {
    expect(formatTimestamp(null)).toBe("—");
  });

  it("formats a real timestamp as month/day/year/time", () => {
    const ts = Timestamp.fromDate(new Date("2026-01-15T14:30:00"));
    const out = formatTimestamp(ts);
    expect(out).toContain("Jan");
    expect(out).toContain("15");
    expect(out).toContain("2026");
    expect(out).toContain("2:30");
  });
});

describe("organizerStatusLabel / organizerStatusColors", () => {
  it("maps every known status to its label", () => {
    expect(organizerStatusLabel("none")).toBe("Untriaged");
    expect(organizerStatusLabel("pending")).toBe("Pending");
    expect(organizerStatusLabel("approved")).toBe("Approved");
    expect(organizerStatusLabel("rejected")).toBe("Rejected");
    expect(organizerStatusLabel("revoked")).toBe("Revoked");
  });

  it("falls back to the raw status string for an unrecognized status", () => {
    expect(organizerStatusLabel("weird" as OrganizerStatus)).toBe("weird");
  });

  it("maps known statuses to the matching badge tone colors", () => {
    expect(organizerStatusColors("approved")).toEqual(badgeColors("success"));
    expect(organizerStatusColors("rejected")).toEqual(badgeColors("danger"));
    expect(organizerStatusColors("pending")).toEqual(badgeColors("info"));
    expect(organizerStatusColors("revoked")).toEqual(badgeColors("neutral"));
    expect(organizerStatusColors("none")).toEqual(badgeColors("warning"));
  });

  it("falls back to neutral colors for an unrecognized status", () => {
    expect(organizerStatusColors("weird" as OrganizerStatus)).toEqual(badgeColors("neutral"));
  });
});

describe("stepStatusChrome", () => {
  it("maps every known step status to label/icon/tone", () => {
    const cases: Array<[StepStatus, string]> = [
      ["pending", "Not started"],
      ["active", "Awaiting organizer"],
      ["submitted", "Needs review"],
      ["needs_info", "Re-submission requested"],
      ["accepted", "Verified"],
    ];
    for (const [status, label] of cases) {
      expect(stepStatusChrome(status).label).toBe(label);
    }
  });

  it("includes bg/fg colors matching the tone", () => {
    const chrome = stepStatusChrome("accepted");
    expect(chrome.bg).toBe(badgeColors("success").bg);
    expect(chrome.fg).toBe(badgeColors("success").fg);
  });

  it("falls back to the 'pending' chrome for an unrecognized status", () => {
    expect(stepStatusChrome("weird" as StepStatus)).toEqual(stepStatusChrome("pending"));
  });
});
