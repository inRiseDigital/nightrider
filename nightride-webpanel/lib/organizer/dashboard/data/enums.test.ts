import { describe, expect, it } from "vitest";
import { crowdLevelFor, queueStatusFor } from "./enums";

describe("crowdLevelFor", () => {
  it("returns moderate when capacity is 0 (unknown), never dividing by zero", () => {
    expect(crowdLevelFor(0, 0)).toBe("moderate");
    expect(crowdLevelFor(50, 0)).toBe("moderate");
  });
  it("returns empty at 0 in-venue with known capacity", () => {
    expect(crowdLevelFor(0, 100)).toBe("empty");
  });
  it("buckets at each threshold boundary", () => {
    expect(crowdLevelFor(24, 100)).toBe("quiet"); // 0.24 < 0.25
    expect(crowdLevelFor(25, 100)).toBe("moderate"); // 0.25 -> moderate
    expect(crowdLevelFor(59, 100)).toBe("moderate");
    expect(crowdLevelFor(60, 100)).toBe("busy"); // 0.60 -> busy
    expect(crowdLevelFor(89, 100)).toBe("busy");
    expect(crowdLevelFor(90, 100)).toBe("packed"); // 0.90 -> packed
    expect(crowdLevelFor(100, 100)).toBe("packed");
  });
});

describe("queueStatusFor", () => {
  it("buckets at 0, 10, 11, 30, 31", () => {
    expect(queueStatusFor(0)).toBe("noQueue");
    expect(queueStatusFor(10)).toBe("short");
    expect(queueStatusFor(11)).toBe("moderate");
    expect(queueStatusFor(30)).toBe("moderate");
    expect(queueStatusFor(31)).toBe("long");
  });
});
