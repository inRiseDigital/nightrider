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

/**
 * Fields for a brand-new boost request — `create`-only per rules, so there
 * is no update counterpart. `createdAt` (pass `serverTimestamp()`) is what
 * `pickCurrentBoost` below sorts on; the caller reloads from Firestore after
 * the write resolves, so the sentinel has already settled to a real
 * timestamp by the time it's read back.
 */
export function toBoostCreateFields(night: string, price: number, createdAt: unknown): Record<string, unknown> {
  return { status: "pending", night, price, createdAt };
}

/**
 * `boosts` is append-only — `firestore.rules:670-675` allows `create` only,
 * `update`/`delete` are `if false` unconditionally, so nothing ever prunes an
 * old or expired boost out of the collection. Fix round 1: `docs[0]` picked
 * whatever order Firestore happened to return, not "the current boost".
 *
 * There is no reliable `status` value to filter on here: every real create
 * writes `status: 'pending'` and nothing in this collection's rules ever
 * changes it, so filtering to `'pending'` can't distinguish "just bought" from
 * "bought months ago and never expired" without a backend job this task
 * doesn't own. The best available discriminator is recency — `createdAt`
 * descending, most-recently-bought wins — with the document id (descending)
 * as a fully deterministic tiebreak for documents that predate `createdAt`
 * (the current seed fixture: no `status`, no `createdAt` at all, confirmed
 * against `scripts/seed-emulator/seed-organizer-analytics.mjs`). With today's
 * seed (exactly one boost doc, no `createdAt`), the tiebreak alone decides —
 * deterministic, but only because there is nothing else to sort by. The seed
 * fixture should carry `createdAt` for full parity with real writes; that
 * script isn't owned by this task.
 */
export function pickCurrentBoost(
  docs: { id: string; data: Record<string, unknown> }[]
): { id: string; data: Record<string, unknown> } | null {
  if (docs.length === 0) return null;
  const createdAtMs = (data: Record<string, unknown>): number => {
    const v = data.createdAt as { toMillis?: () => number } | undefined;
    return typeof v?.toMillis === "function" ? v.toMillis() : -1;
  };
  return [...docs].sort((a, b) => {
    const diff = createdAtMs(b.data) - createdAtMs(a.data);
    return diff !== 0 ? diff : b.id.localeCompare(a.id);
  })[0];
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
