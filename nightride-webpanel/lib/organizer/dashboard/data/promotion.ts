/**
 * `venues/{venueId}/{promotions,pushCampaigns,promoState,boosts,rankPerks}`
 * <-> `PromoCode` / `PushState` / `BoostSlot` / `RankPerk`.
 */
import type { BoostSlot, PromoCode, PushState, RankPerk } from "../types";

export function parsePromoCode(data: Record<string, unknown> | undefined): PromoCode {
  const d = data ?? {};
  return {
    code: typeof d.code === "string" ? d.code : "",
    desc: typeof d.desc === "string" ? d.desc : "",
    maxUses: typeof d.maxUses === "number" ? d.maxUses : 0,
    used: typeof d.used === "number" ? d.used : 0,
  };
}

/** `used` is pinned server-side on every update after create — never write it back. */
export function toPromoCodeFields(ui: PromoCode, ctx: { raw: Record<string, unknown> }): Record<string, unknown> {
  return { ...ctx.raw, code: ui.code, desc: ui.desc, maxUses: ui.maxUses };
}

export function parsePushState(data: Record<string, unknown> | undefined): PushState {
  const d = data ?? {};
  return {
    message: typeof d.message === "string" ? d.message : "",
    rateUsed: typeof d.rateUsed === "number" ? d.rateUsed : 0,
    rateMax: typeof d.rateMax === "number" ? d.rateMax : 4,
  };
}

export function parseBoostSlot(data: Record<string, unknown> | undefined): BoostSlot {
  const d = data ?? {};
  return {
    active: d.active === true,
    night: typeof d.night === "string" ? d.night : "",
    price: typeof d.price === "number" ? d.price : 0,
  };
}

export function toBoostSlotFields(ui: BoostSlot, ctx: { raw: Record<string, unknown> }): Record<string, unknown> {
  return { ...ctx.raw, active: ui.active, night: ui.night, price: ui.price };
}

export function parseRankPerk(tier: string, perk: unknown): RankPerk {
  return { tier, perk: typeof perk === "string" ? perk : "" };
}
