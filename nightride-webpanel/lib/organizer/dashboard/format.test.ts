import { describe, expect, it } from "vitest";
import { displayStatusOf, initialsOf, isEventLive, matchesFilter } from "./format";
import type { OrganizerEvent } from "./types";

function makeEvent(overrides: Partial<OrganizerEvent> = {}): OrganizerEvent {
  return {
    id: "ev1",
    name: "Test Night",
    venue: "venue1",
    date: "2026-09-02",
    startTime: "22:00",
    endTime: "04:00",
    lineup: [],
    tiers: [],
    status: "published",
    recurring: false,
    recurrenceLabel: "",
    scheduledPublish: "",
    notifyOnChange: false,
    moderationFlag: "",
    moderationEta: "",
    cancelReason: "",
    sold: 0,
    revenue: 0,
    ...overrides,
  };
}

describe("isEventLive", () => {
  it("is true inside the window", () => {
    const ev = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "23:59" });
    const now = new Date(2026, 8, 2, 23, 0);
    expect(isEventLive(ev, now)).toBe(true);
  });

  it("is false before the window starts", () => {
    const ev = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "23:59" });
    const now = new Date(2026, 8, 2, 20, 0);
    expect(isEventLive(ev, now)).toBe(false);
  });

  it("is false after the window ends", () => {
    const ev = makeEvent({ date: "2026-09-02", startTime: "20:00", endTime: "21:00" });
    const now = new Date(2026, 8, 2, 22, 0);
    expect(isEventLive(ev, now)).toBe(false);
  });

  it("is false when now is null", () => {
    const ev = makeEvent();
    expect(isEventLive(ev, null)).toBe(false);
  });

  it("handles the overnight case: 22:00-04:00 is live at 01:00 the next day", () => {
    const ev = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "04:00" });
    const now = new Date(2026, 8, 3, 1, 0);
    expect(isEventLive(ev, now)).toBe(true);
  });

  it("is false for a non-published event even inside the window", () => {
    const ev = makeEvent({
      status: "scheduled",
      date: "2026-09-02",
      startTime: "22:00",
      endTime: "23:59",
    });
    const now = new Date(2026, 8, 2, 23, 0);
    expect(isEventLive(ev, now)).toBe(false);
  });
});

describe("displayStatusOf", () => {
  it.each([
    ["draft"],
    ["scheduled"],
    ["in_review"],
    ["cancelled"],
    ["archived"],
  ] as const)("returns the stored status for %s", (status) => {
    const ev = makeEvent({ status });
    const now = new Date(2026, 8, 2, 23, 0);
    expect(displayStatusOf(ev, now)).toBe(status);
  });

  it("returns 'live' for a published event inside its window", () => {
    const ev = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "23:59" });
    const now = new Date(2026, 8, 2, 23, 0);
    expect(displayStatusOf(ev, now)).toBe("live");
  });

  it("returns 'upcoming' for a published event outside its window", () => {
    const ev = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "23:59" });
    const now = new Date(2026, 8, 2, 10, 0);
    expect(displayStatusOf(ev, now)).toBe("upcoming");
  });

  it("returns the stored status ('published') when now is null", () => {
    const ev = makeEvent();
    expect(displayStatusOf(ev, null)).toBe("published");
  });
});

describe("matchesFilter", () => {
  const now = new Date(2026, 8, 2, 23, 0);

  it("'all' matches every status", () => {
    expect(matchesFilter(makeEvent({ status: "archived" }), "all", now)).toBe(true);
  });

  it("'in_review' matches only in_review", () => {
    expect(matchesFilter(makeEvent({ status: "in_review" }), "in_review", now)).toBe(true);
    expect(matchesFilter(makeEvent({ status: "draft" }), "in_review", now)).toBe(false);
  });

  it("'scheduled' matches only scheduled", () => {
    expect(matchesFilter(makeEvent({ status: "scheduled" }), "scheduled", now)).toBe(true);
    expect(matchesFilter(makeEvent({ status: "draft" }), "scheduled", now)).toBe(false);
  });

  it("'live' consults the clock via isEventLive", () => {
    const liveEv = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "23:59" });
    const upcomingEv = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "23:59" });
    expect(matchesFilter(liveEv, "live", now)).toBe(true);
    expect(matchesFilter(upcomingEv, "live", new Date(2026, 8, 2, 10, 0))).toBe(false);
  });

  it("'draft' matches only draft", () => {
    expect(matchesFilter(makeEvent({ status: "draft" }), "draft", now)).toBe(true);
    expect(matchesFilter(makeEvent({ status: "cancelled" }), "draft", now)).toBe(false);
  });
});

describe("initialsOf", () => {
  it("one word", () => {
    expect(initialsOf("Madonna")).toBe("M");
  });

  it("two words", () => {
    expect(initialsOf("Neon Fox")).toBe("NF");
  });

  it("three words", () => {
    expect(initialsOf("Neon Fox Collective")).toBe("NF");
  });

  it("empty string", () => {
    expect(initialsOf("")).toBe("");
  });
});
