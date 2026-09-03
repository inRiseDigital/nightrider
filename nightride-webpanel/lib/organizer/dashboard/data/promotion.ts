/**
 * `venues/{venueId}/{promotions,pushCampaigns,promoState,boosts,rankPerks}`
 * <-> `PromoCode` / `PushState` / `BoostSlot` / `RankPerk`.
 *
 * `promoState/current` and `pushCampaigns/{id}` are two different documents
 * that the mock's single `PushState` object papered over: `promoState` is
 * the read-only rate counter (`{used, max}`), `pushCampaigns` is the append-only
 * log of sends. `PushState.message` is the compose box's own draft text and
 * is never persisted until a send creates a campaign doc — see `usePromotion`.
 */
import type { BoostSlot, PromoCode, RankPerk } from "../types";

export function parsePromoCode(id: string, data: Record<string, unknown> | undefined): PromoCode & { id: string } {
  const d = data ?? {};
  return {
    id,
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

/**
 * `venues/{venueId}/promoState/current` — `{used, max}`. Display state the
 * organizer cannot write at all; the real weekly cap is enforced server-side
 * by the FCM fanout function, not by rules (rules cannot count documents),
 * so this is shown as information, never as a client-verified guarantee.
 */
export interface PromoState {
  used: number;
  max: number;
}

export function parsePromoState(data: Record<string, unknown> | undefined): PromoState {
  const d = data ?? {};
  return {
    used: typeof d.used === "number" ? d.used : 0,
    max: typeof d.max === "number" ? d.max : 0,
  };
}

/**
 * `venues/{venueId}/boosts/{boostId}`. `firestore.rules` allows `create`
 * only (`status == 'pending'`) and forbids `update`/`delete` outright — a
 * boost, once bought, cannot be edited or cancelled from the client. `active`
 * is derived from `status` where present (anything but `'cancelled'` /
 * `'expired'` reads as active); the seed fixture predates the `status` field
 * (admin-seeded, so it bypasses rules) and falls back to a legacy `active`
 * boolean so an existing seeded doc still renders sensibly.
 */
export function parseBoostSlot(id: string, data: Record<string, unknown> | undefined): BoostSlot & { id: string } {
  const d = data ?? {};
  const active =
    typeof d.status === "string" ? d.status !== "cancelled" && d.status !== "expired" : d.active === true;
  return {
    id,
    active,
    night: typeof d.night === "string" ? d.night : "",
    price: typeof d.price === "number" ? d.price : 0,
  };
}

/** Fields for a brand-new boost request — `create`-only per rules, so there is no update counterpart. */
export function toBoostCreateFields(night: string, price: number): Record<string, unknown> {
  return { status: "pending", night, price };
}

export function parseRankPerk(tier: string, perk: unknown): RankPerk {
  return { tier, perk: typeof perk === "string" ? perk : "" };
}

export function parseRankPerks(raw: unknown): RankPerk[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((x): x is Record<string, unknown> => !!x && typeof x === "object")
    .map((x) => parseRankPerk(typeof x.tier === "string" ? x.tier : "", x.perk));
}
