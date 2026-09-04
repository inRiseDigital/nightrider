import { describe, expect, it } from "vitest";
import { eventWindowToTimestamps, timestampsToEventWindow, zonedToUtc } from "./time";

describe("eventWindowToTimestamps / timestampsToEventWindow", () => {
  it("round-trips a same-day window", () => {
    const ui = { date: "2026-08-08", startTime: "18:00", endTime: "20:00" };
    const { startAt, endAt } = eventWindowToTimestamps(ui, "Asia/Dubai");
    expect(timestampsToEventWindow(startAt, endAt, "Asia/Dubai")).toEqual(ui);
  });

  it("rolls an overnight window onto the next calendar day", () => {
    const ui = { date: "2026-08-08", startTime: "22:00", endTime: "04:00" };
    const { startAt, endAt } = eventWindowToTimestamps(ui, "Asia/Dubai");
    expect(endAt).not.toBeNull();
    expect(endAt!.toMillis() - startAt.toMillis()).toBe(6 * 60 * 60 * 1000);
    expect(timestampsToEventWindow(startAt, endAt, "Asia/Dubai")).toEqual(ui);
  });

  it("tolerates a null endAt by returning an empty endTime", () => {
    const { startAt } = eventWindowToTimestamps(
      { date: "2026-08-08", startTime: "22:00", endTime: "04:00" },
      "Asia/Dubai"
    );
    expect(timestampsToEventWindow(startAt, null, "Asia/Dubai")).toEqual({
      date: "2026-08-08",
      startTime: "22:00",
      endTime: "",
    });
  });

  it("returns endAt: null for an empty endTime, rather than fabricating a midnight close (fix round 1)", () => {
    // `minutesOf("")` is `0`, which — without the empty-`endTime` branch —
    // reads as "ends at 00:00", makes the overnight bump unconditional, and
    // silently invents a real `endAt` (midnight the following day) out of
    // nothing. This is exactly the bug a duplicated admin/scraped event with
    // no close time would have hit.
    const ui = { date: "2026-08-08", startTime: "22:00", endTime: "" };
    const { startAt, endAt } = eventWindowToTimestamps(ui, "Asia/Dubai");
    expect(endAt).toBeNull();
    expect(timestampsToEventWindow(startAt, endAt, "Asia/Dubai")).toEqual({
      date: "2026-08-08",
      startTime: "22:00",
      endTime: "",
    });
  });

  it("two-pass corrects a DST spring-forward boundary (America/New_York)", () => {
    // 2026-03-08 is the US spring-forward date; 02:30 local does not exist.
    // A naive single-pass conversion using the pre-transition offset would be
    // off by an hour for a wall-clock time chosen either side of 02:00.
    const ui = { date: "2026-03-08", startTime: "01:30", endTime: "03:30" };
    const { startAt, endAt } = eventWindowToTimestamps(ui, "America/New_York");
    expect(timestampsToEventWindow(startAt, endAt, "America/New_York")).toEqual(ui);
  });

  it("two-pass corrects a DST fall-back boundary (Europe/London)", () => {
    const ui = { date: "2026-10-25", startTime: "01:30", endTime: "23:00" };
    const { startAt, endAt } = eventWindowToTimestamps(ui, "Europe/London");
    expect(timestampsToEventWindow(startAt, endAt, "Europe/London")).toEqual(ui);
  });

  it("zonedToUtc agrees with a known UTC offset", () => {
    const d = zonedToUtc("2026-01-15", "12:00", "Asia/Dubai"); // UTC+4, no DST
    expect(d.toISOString()).toBe("2026-01-15T08:00:00.000Z");
  });
});
