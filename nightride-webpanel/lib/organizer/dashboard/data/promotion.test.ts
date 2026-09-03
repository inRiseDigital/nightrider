import { describe, expect, it } from "vitest";
import { parseBoostSlot, parsePromoCode, parsePromoState, parseRankPerks, toBoostCreateFields } from "./promotion";

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
    expect(toBoostCreateFields("2026-09-01", 40)).toEqual({ status: "pending", night: "2026-09-01", price: 40 });
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
