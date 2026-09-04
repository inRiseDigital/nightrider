import { describe, expect, it } from "vitest";
import { Timestamp } from "firebase/firestore";
import { parseActivityEntry } from "./activity";

describe("parseActivityEntry", () => {
  it("maps a seeded entry and formats `at` as \"Mon D, HH:mm\"", () => {
    const e = parseActivityEntry({
      actorUid: "u1",
      actorName: "Marco Reyes",
      what: "Changed Sunset to Sunrise price tier",
      targetType: "event",
      targetId: "e3",
      at: Timestamp.fromDate(new Date("2026-08-05T14:02:00Z")),
    });
    expect(e.who).toBe("Marco Reyes");
    expect(e.what).toBe("Changed Sunset to Sunrise price tier");
    expect(e.when).toBe("Aug 5, 14:02");
  });

  it("defaults every field for a missing/legacy document — no fabricated activity", () => {
    expect(parseActivityEntry(undefined)).toEqual({ who: "", what: "", when: "" });
  });
});
