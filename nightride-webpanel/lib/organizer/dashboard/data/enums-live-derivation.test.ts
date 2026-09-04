import { describe, expect, it } from "vitest";
import { crowdLevelForDoorStatus, queueStatusForDoorStatus } from "./enums";

/**
 * Supplements `enums.test.ts`'s `crowdLevelFor`/`queueStatusFor` boundary
 * coverage with the two door-status-forced overrides task-8-brief.md's table
 * calls out ("capacity" forces packed regardless of the ratio; "closed"
 * forces the queue to "closed" regardless of the wait) and the queue-minute
 * boundary the brief lists that the existing suite doesn't hit: 1 minute.
 */
describe("crowdLevelForDoorStatus", () => {
  it('forces "packed" for doorStatus "capacity" even at low occupancy', () => {
    expect(crowdLevelForDoorStatus("capacity", 5, 100)).toBe("packed");
    expect(crowdLevelForDoorStatus("capacity", 0, 0)).toBe("packed");
  });

  it("derives normally from occupancy for every other doorStatus", () => {
    expect(crowdLevelForDoorStatus("open", 10, 100)).toBe("quiet");
    expect(crowdLevelForDoorStatus("filling", 95, 100)).toBe("packed");
    expect(crowdLevelForDoorStatus("guestlist", 20, 100)).toBe("quiet");
    expect(crowdLevelForDoorStatus("closed", 0, 100)).toBe("empty");
  });
});

describe("queueStatusForDoorStatus", () => {
  it('forces "closed" for doorStatus "closed" even with a nonzero wait', () => {
    expect(queueStatusForDoorStatus("closed", 45)).toBe("closed");
    expect(queueStatusForDoorStatus("closed", 0)).toBe("closed");
  });

  it("buckets normally for every other doorStatus, including the 1-minute edge", () => {
    expect(queueStatusForDoorStatus("open", 0)).toBe("noQueue");
    expect(queueStatusForDoorStatus("open", 1)).toBe("short");
    expect(queueStatusForDoorStatus("filling", 10)).toBe("short");
    expect(queueStatusForDoorStatus("guestlist", 11)).toBe("moderate");
    expect(queueStatusForDoorStatus("open", 30)).toBe("moderate");
    expect(queueStatusForDoorStatus("open", 31)).toBe("long");
  });
});
