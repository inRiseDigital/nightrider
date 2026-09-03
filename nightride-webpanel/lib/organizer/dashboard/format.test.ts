import { describe, expect, it } from "vitest";
import { displayStatusOf, initialsOf, isEventLive, matchesFilter } from "./format";
import type { OrganizerEvent } from "./types";

// The runtime's own zone — passed explicitly everywhere below so these tests
// keep meaning "local wall-clock time" the way they did before finding 3's
// fix threaded a `timeZone` parameter through. See the "Dubai, not the
// runtime zone" describe block below for the actual regression test.
const LOCAL_TZ = Intl.DateTimeFormat().resolvedOptions().timeZone;

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
    expect(isEventLive(ev, now, LOCAL_TZ)).toBe(true);
  });

  it("is false before the window starts", () => {
    const ev = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "23:59" });
    const now = new Date(2026, 8, 2, 20, 0);
    expect(isEventLive(ev, now, LOCAL_TZ)).toBe(false);
  });

  it("is false after the window ends", () => {
    const ev = makeEvent({ date: "2026-09-02", startTime: "20:00", endTime: "21:00" });
    const now = new Date(2026, 8, 2, 22, 0);
    expect(isEventLive(ev, now, LOCAL_TZ)).toBe(false);
  });

  it("is false when now is null", () => {
    const ev = makeEvent();
    expect(isEventLive(ev, null, LOCAL_TZ)).toBe(false);
  });

  it("handles the overnight case: 22:00-04:00 is live at 01:00 the next day", () => {
    const ev = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "04:00" });
    const now = new Date(2026, 8, 3, 1, 0);
    expect(isEventLive(ev, now, LOCAL_TZ)).toBe(true);
  });

  it("is true indefinitely once started when endTime is '' (null stored endAt)", () => {
    const ev = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "" });
    expect(isEventLive(ev, new Date(2026, 8, 2, 22, 0), LOCAL_TZ)).toBe(true);
    expect(isEventLive(ev, new Date(2026, 8, 5, 12, 0), LOCAL_TZ)).toBe(true);
  });

  it("is false before the window starts when endTime is ''", () => {
    const ev = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "" });
    expect(isEventLive(ev, new Date(2026, 8, 2, 20, 0), LOCAL_TZ)).toBe(false);
  });

  it("is false for a non-published event even inside the window", () => {
    const ev = makeEvent({
      status: "scheduled",
      date: "2026-09-02",
      startTime: "22:00",
      endTime: "23:59",
    });
    const now = new Date(2026, 8, 2, 23, 0);
    expect(isEventLive(ev, now, LOCAL_TZ)).toBe(false);
  });
});

// Finding 3: `isEventLive` used to build its `Date`s with the local-time
// constructor, so it judged an event's live window in the *browser's* zone
// even though `date`/`startTime`/`endTime` are the venue's zoned wall-clock
// values (`parseOrganizerEvent`/`timestampsToEventWindow` produce them via
// `zonedToUtc`/venue `timeZone`). A London-based organizer managing a Dubai
// venue would see a four-hour-wrong live window. These fix the venue's zone
// to Asia/Dubai (UTC+4, no DST) and vary only the *runtime's* implicit
// assumption by passing a UTC instant that is unambiguous everywhere.
describe("isEventLive judges the venue's timezone, not the runtime's", () => {
  // 22:00 Dubai on 2026-09-02 is 18:00 UTC.
  const ev = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "23:59" });

  it("is live at 22:30 Dubai time (18:30 UTC) regardless of runtime zone", () => {
    const nowUtc = new Date(Date.UTC(2026, 8, 2, 18, 30));
    expect(isEventLive(ev, nowUtc, "Asia/Dubai")).toBe(true);
  });

  it("is not live yet at 21:00 Dubai time (17:00 UTC), even though it would already be", () => {
    // ...past a naive `new Date(y, mo, d, 22, 0)` build in a zone west of
    // Dubai, e.g. UTC or America/New_York, which the pre-fix code used.
    const nowUtc = new Date(Date.UTC(2026, 8, 2, 17, 0));
    expect(isEventLive(ev, nowUtc, "Asia/Dubai")).toBe(false);
  });

  it("has ended by 00:30 Dubai time the same UTC day it would still be running in UTC", () => {
    // 23:59 Dubai on 2026-09-02 is 19:59 UTC; 20:30 UTC is 00:30 Dubai the
    // next day — after the window, though still "the 2nd" if read as UTC.
    const nowUtc = new Date(Date.UTC(2026, 8, 2, 20, 30));
    expect(isEventLive(ev, nowUtc, "Asia/Dubai")).toBe(false);
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
    expect(displayStatusOf(ev, now, LOCAL_TZ)).toBe(status);
  });

  it("returns 'live' for a published event inside its window", () => {
    const ev = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "23:59" });
    const now = new Date(2026, 8, 2, 23, 0);
    expect(displayStatusOf(ev, now, LOCAL_TZ)).toBe("live");
  });

  it("returns 'upcoming' for a published event outside its window", () => {
    const ev = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "23:59" });
    const now = new Date(2026, 8, 2, 10, 0);
    expect(displayStatusOf(ev, now, LOCAL_TZ)).toBe("upcoming");
  });

  it("returns the stored status ('published') when now is null", () => {
    const ev = makeEvent();
    expect(displayStatusOf(ev, null, LOCAL_TZ)).toBe("published");
  });
});

describe("matchesFilter", () => {
  const now = new Date(2026, 8, 2, 23, 0);

  it("'all' matches every status", () => {
    expect(matchesFilter(makeEvent({ status: "archived" }), "all", now, LOCAL_TZ)).toBe(true);
  });

  it("'in_review' matches only in_review", () => {
    expect(matchesFilter(makeEvent({ status: "in_review" }), "in_review", now, LOCAL_TZ)).toBe(true);
    expect(matchesFilter(makeEvent({ status: "draft" }), "in_review", now, LOCAL_TZ)).toBe(false);
  });

  it("'scheduled' matches only scheduled", () => {
    expect(matchesFilter(makeEvent({ status: "scheduled" }), "scheduled", now, LOCAL_TZ)).toBe(true);
    expect(matchesFilter(makeEvent({ status: "draft" }), "scheduled", now, LOCAL_TZ)).toBe(false);
  });

  it("'live' consults the clock via isEventLive", () => {
    const liveEv = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "23:59" });
    const upcomingEv = makeEvent({ date: "2026-09-02", startTime: "22:00", endTime: "23:59" });
    expect(matchesFilter(liveEv, "live", now, LOCAL_TZ)).toBe(true);
    expect(matchesFilter(upcomingEv, "live", new Date(2026, 8, 2, 10, 0), LOCAL_TZ)).toBe(false);
  });

  it("'draft' matches only draft", () => {
    expect(matchesFilter(makeEvent({ status: "draft" }), "draft", now, LOCAL_TZ)).toBe(true);
    expect(matchesFilter(makeEvent({ status: "cancelled" }), "draft", now, LOCAL_TZ)).toBe(false);
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
