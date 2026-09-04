import { describe, expect, it } from "vitest";
import {
  countOpenChecks,
  deriveVenueVerifyState,
  matchesVenueCity,
  matchesVenueSearch,
  matchesVenueVerifyFilter,
} from "./venues";
import type { VenueCheckState } from "../view-models";

describe("deriveVenueVerifyState", () => {
  it("all verified -> verified", () => {
    expect(deriveVenueVerifyState(["verified", "verified", "verified"])).toBe("verified");
  });

  it("any pending among otherwise-verified -> checksOpen", () => {
    expect(deriveVenueVerifyState(["verified", "pending", "verified"])).toBe("checksOpen");
  });

  it("any failed -> failed, even alongside verified and pending", () => {
    expect(deriveVenueVerifyState(["verified", "failed", "pending"])).toBe("failed");
  });

  it("failed takes priority over an all-verified-otherwise set", () => {
    expect(deriveVenueVerifyState(["verified", "verified", "failed"])).toBe("failed");
  });

  it("all pending -> checksOpen", () => {
    expect(deriveVenueVerifyState(["pending", "pending"])).toBe("checksOpen");
  });

  it("all failed -> failed", () => {
    expect(deriveVenueVerifyState(["failed", "failed"])).toBe("failed");
  });

  // A venue predating `verification` reaches us with an empty map — see the
  // trivial-pass path in firestore.rules' verificationStepOk. Reporting that
  // as "Verified" would put a green badge on a venue nobody has ever checked.
  it("empty checks list -> checksOpen, not verified", () => {
    expect(deriveVenueVerifyState([])).toBe("checksOpen");
  });

  it("single failed check -> failed", () => {
    expect(deriveVenueVerifyState(["failed"])).toBe("failed");
  });

  it("single pending check -> checksOpen", () => {
    expect(deriveVenueVerifyState(["pending"])).toBe("checksOpen");
  });
});

describe("countOpenChecks", () => {
  it("counts everything that isn't verified", () => {
    const checks: VenueCheckState[] = ["verified", "pending", "failed", "pending"];
    expect(countOpenChecks(checks)).toBe(3);
  });

  it("returns 0 when all verified", () => {
    expect(countOpenChecks(["verified", "verified"])).toBe(0);
  });

  it("returns 0 on an empty list", () => {
    expect(countOpenChecks([])).toBe(0);
  });
});

describe("matchesVenueSearch", () => {
  const row = { name: "Club Neon", organizerName: "Jamie Cho", address: "12 Marina Walk, Dubai" };

  it("empty/whitespace search matches everything", () => {
    expect(matchesVenueSearch(row, "")).toBe(true);
    expect(matchesVenueSearch(row, "   ")).toBe(true);
  });

  it("matches case-insensitively across name, organizer and address", () => {
    expect(matchesVenueSearch(row, "NEON")).toBe(true);
    expect(matchesVenueSearch(row, "jamie")).toBe(true);
    expect(matchesVenueSearch(row, "marina")).toBe(true);
  });

  it("no match returns false", () => {
    expect(matchesVenueSearch(row, "tokyo")).toBe(false);
  });
});

describe("matchesVenueCity", () => {
  it("'all' matches any city", () => {
    expect(matchesVenueCity("Dubai", "all")).toBe(true);
  });

  it("exact city match required otherwise", () => {
    expect(matchesVenueCity("Dubai", "Dubai")).toBe(true);
    expect(matchesVenueCity("Dubai", "Tokyo")).toBe(false);
  });
});

describe("matchesVenueVerifyFilter", () => {
  it("'all' matches regardless of state or suspension", () => {
    expect(matchesVenueVerifyFilter("verified", false, "all")).toBe(true);
    expect(matchesVenueVerifyFilter("failed", true, "all")).toBe(true);
  });

  it("'suspended' filter only matches suspended venues, regardless of verify state", () => {
    expect(matchesVenueVerifyFilter("verified", true, "suspended")).toBe(true);
    expect(matchesVenueVerifyFilter("failed", true, "suspended")).toBe(true);
    expect(matchesVenueVerifyFilter("verified", false, "suspended")).toBe(false);
  });

  it("a verify-state filter matches on state alone, suspended or not", () => {
    expect(matchesVenueVerifyFilter("checksOpen", false, "checksOpen")).toBe(true);
    expect(matchesVenueVerifyFilter("checksOpen", true, "checksOpen")).toBe(true);
    expect(matchesVenueVerifyFilter("verified", false, "checksOpen")).toBe(false);
  });
});
