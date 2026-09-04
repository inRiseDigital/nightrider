import { describe, expect, it } from "vitest";
import { Timestamp } from "firebase/firestore";
import {
  parseBoostSlot,
  parsePromoCode,
  parsePromoState,
  parseRankPerks,
  pickCurrentBoost,
  toBoostCreateFields,
} from "./promotion";

describe("parsePromoState", () => {
  it("maps the seed fixture's {used, max} verbatim", () => {
    expect(parsePromoState({ used: 2, max: 4 })).toEqual({ used: 2, max: 4 });
  });

  it("defaults to zero for a missing document — no fake quota", () => {
    expect(parsePromoState(undefined)).toEqual({ used: 0, max: 0 });
  });
});

describe("parsePromoCode", () => {
  it("maps the seed fixture verbatim", () => {
    expect(parsePromoCode("promo-01", { code: "VIP-AUG-08", desc: "Guest list", maxUses: 50, used: 31 })).toEqual({
      id: "promo-01",
      code: "VIP-AUG-08",
      desc: "Guest list",
      maxUses: 50,
      used: 31,
    });
  });
});

describe("parseBoostSlot", () => {
  it("reads a legacy admin-seeded doc (no `status` field) via the `active` boolean", () => {
    const b = parseBoostSlot("boost-01", { active: false, night: "2026-08-15", price: 40 });
    expect(b).toEqual({ id: "boost-01", active: false, night: "2026-08-15", price: 40 });
  });

  it("treats a `status` of 'pending' as active", () => {
    const b = parseBoostSlot("boost-02", { status: "pending", night: "2026-09-01", price: 40 });
    expect(b.active).toBe(true);
  });

  it("treats a `status` of 'cancelled' or 'expired' as inactive", () => {
    expect(parseBoostSlot("b", { status: "cancelled", night: "", price: 0 }).active).toBe(false);
    expect(parseBoostSlot("b", { status: "expired", night: "", price: 0 }).active).toBe(false);
  });
});

describe("toBoostCreateFields", () => {
  it("always writes status: 'pending' — the only value firestore.rules accepts on create", () => {
    expect(toBoostCreateFields("2026-09-01", 40, "SENTINEL")).toEqual({
      status: "pending",
      night: "2026-09-01",
      price: 40,
      createdAt: "SENTINEL",
    });
  });
});

describe("pickCurrentBoost", () => {
  it("returns null for an empty collection", () => {
    expect(pickCurrentBoost([])).toBeNull();
  });

  it("picks the most recently created boost when createdAt is present (fix round 1)", () => {
    const older = { id: "boost-01", data: { createdAt: Timestamp.fromMillis(1000) } };
    const newer = { id: "boost-02", data: { createdAt: Timestamp.fromMillis(2000) } };
    // Deliberately out of order — Firestore doesn't guarantee snapshot order
    // without an explicit query, which is exactly the bug this fixes.
    expect(pickCurrentBoost([older, newer])).toEqual(newer);
    expect(pickCurrentBoost([newer, older])).toEqual(newer);
  });

  it("falls back to descending document id when createdAt is absent on every doc", () => {
    // The current seed fixture's shape: no `status`, no `createdAt` at all.
    const a = { id: "boost-01", data: { active: false, night: "2026-08-15", price: 40 } };
    const b = { id: "boost-02", data: { active: false, night: "2026-09-01", price: 40 } };
    expect(pickCurrentBoost([a, b])).toEqual(b);
  });

  it("prefers a doc with createdAt over one without, regardless of id ordering", () => {
    const noCreatedAt = { id: "boost-99", data: {} };
    const withCreatedAt = { id: "boost-01", data: { createdAt: Timestamp.fromMillis(500) } };
    expect(pickCurrentBoost([noCreatedAt, withCreatedAt])).toEqual(withCreatedAt);
  });
});

describe("parseRankPerks", () => {
  it("maps the seed fixture's perks array verbatim", () => {
    expect(
      parseRankPerks([
        { tier: "Gold", perk: "Skip-the-line + welcome shot" },
        { tier: "Silver", perk: "Priority guest list" },
      ])
    ).toEqual([
      { tier: "Gold", perk: "Skip-the-line + welcome shot" },
      { tier: "Silver", perk: "Priority guest list" },
    ]);
  });

  it("defaults to an empty list for a missing document", () => {
    expect(parseRankPerks(undefined)).toEqual([]);
  });
});
