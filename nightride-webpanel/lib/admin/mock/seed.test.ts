import { describe, expect, it } from "vitest";
import { dateAt, daysBeforeNow, hashString, minutesBeforeNow, mulberry32, pick, rngFor } from "./seed";

describe("mulberry32", () => {
  it("is deterministic — same seed produces the same sequence", () => {
    const a = mulberry32(42);
    const b = mulberry32(42);
    const seqA = [a(), a(), a(), a()];
    const seqB = [b(), b(), b(), b()];
    expect(seqA).toEqual(seqB);
  });

  it("different seeds diverge", () => {
    const a = mulberry32(1);
    const b = mulberry32(2);
    expect(a()).not.toBe(b());
  });

  it("always produces values in [0, 1)", () => {
    const rng = mulberry32(123456);
    for (let i = 0; i < 100; i++) {
      const v = rng();
      expect(v).toBeGreaterThanOrEqual(0);
      expect(v).toBeLessThan(1);
    }
  });

  it("a fresh generator from the same seed restarts the same sequence", () => {
    const first = mulberry32(7);
    const firstThree = [first(), first(), first()];
    const second = mulberry32(7);
    expect([second(), second(), second()]).toEqual(firstThree);
  });
});

describe("hashString", () => {
  it("is deterministic for the same input", () => {
    expect(hashString("venue-001")).toBe(hashString("venue-001"));
  });

  it("differs for different inputs (no trivial collision on similar keys)", () => {
    expect(hashString("venue-001")).not.toBe(hashString("venue-002"));
  });

  it("is always non-negative", () => {
    expect(hashString("")).toBeGreaterThanOrEqual(0);
    expect(hashString("x".repeat(500))).toBeGreaterThanOrEqual(0);
    expect(hashString("negative-prone-key-!@#$%^&*()")).toBeGreaterThanOrEqual(0);
  });

  it("handles the empty string", () => {
    expect(hashString("")).toBe(0);
  });
});

describe("rngFor", () => {
  it("is deterministic across calls for the same key", () => {
    const seqA = (() => {
      const rng = rngFor("user-42");
      return [rng(), rng(), rng()];
    })();
    const seqB = (() => {
      const rng = rngFor("user-42");
      return [rng(), rng(), rng()];
    })();
    expect(seqA).toEqual(seqB);
  });

  it("different keys diverge", () => {
    const rngA = rngFor("user-42");
    const rngB = rngFor("user-43");
    expect(rngA()).not.toBe(rngB());
  });
});

describe("pick", () => {
  it("is deterministic — same rng sequence yields the same picks", () => {
    const items = ["a", "b", "c", "d", "e"] as const;
    const pickedA = (() => {
      const rng = mulberry32(99);
      return [pick(rng, items), pick(rng, items), pick(rng, items)];
    })();
    const pickedB = (() => {
      const rng = mulberry32(99);
      return [pick(rng, items), pick(rng, items), pick(rng, items)];
    })();
    expect(pickedA).toEqual(pickedB);
  });

  it("always returns an item from the given list", () => {
    const items = ["a", "b", "c"] as const;
    const rng = mulberry32(5);
    for (let i = 0; i < 50; i++) {
      expect(items).toContain(pick(rng, items));
    }
  });

  it("returns the only element for a single-item list", () => {
    const rng = mulberry32(1);
    expect(pick(rng, ["only"])).toBe("only");
  });
});

describe("date helpers anchor to MOCK_NOW (2026-09-04 local)", () => {
  it("dateAt builds a timestamp for the given calendar date/time", () => {
    const ts = dateAt(2026, 8, 15, 20, 30);
    const d = ts.toDate();
    expect(d.getFullYear()).toBe(2026);
    expect(d.getMonth()).toBe(8);
    expect(d.getDate()).toBe(15);
    expect(d.getHours()).toBe(20);
    expect(d.getMinutes()).toBe(30);
  });

  it("minutesBeforeNow(0) equals MOCK_NOW", () => {
    expect(minutesBeforeNow(0).toDate()).toEqual(new Date(2026, 8, 4));
  });

  it("minutesBeforeNow subtracts minutes from MOCK_NOW", () => {
    const ts = minutesBeforeNow(90);
    expect(new Date(2026, 8, 4).getTime() - ts.toDate().getTime()).toBe(90 * 60_000);
  });

  it("daysBeforeNow subtracts whole days from MOCK_NOW", () => {
    const ts = daysBeforeNow(10);
    expect(new Date(2026, 8, 4).getTime() - ts.toDate().getTime()).toBe(10 * 86_400_000);
  });

  it("daysBeforeNow(0) equals MOCK_NOW", () => {
    expect(daysBeforeNow(0).toDate()).toEqual(new Date(2026, 8, 4));
  });
});
