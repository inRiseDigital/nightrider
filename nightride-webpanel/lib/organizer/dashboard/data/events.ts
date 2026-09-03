/**
 * `events/{eventId}` <-> `OrganizerEvent`.
 *
 * `OrganizerEvent` covers roughly 40% of the stored fields, and
 * `shapeOk()` validates the whole document on update, so `toEventDocFields`
 * is the highest-risk mapper in the plan: `description`, `policies`,
 * `performers[].bio`, `genre`, `category`, `vibe`, `language` and `ticketUrl`
 * are read only by the Flutter app and would be blanked by a naive write.
 * `ctx.raw` is spread FIRST, then only the keys this module maps are
 * overwritten — the same technique carries `interestedCount` and
 * `popularityScore` past `producerFieldsPinned()` untouched.
 */
import { GeoPoint, Timestamp } from "firebase/firestore";
import { eventWindowToTimestamps, timestampsToEventWindow, zonedToUtc, utcToZonedParts } from "./time";
import { toGeoOrNull, toTimestampOrNull } from "./venues";
import type { EventStatus, ModerationFlag, OrganizerEvent, TicketTier, VenueMeta } from "../types";

const EVENT_STATUSES: readonly EventStatus[] = [
  "draft",
  "scheduled",
  "in_review",
  "published",
  "cancelled",
  "archived",
];

function parseEventStatus(raw: unknown): EventStatus {
  return typeof raw === "string" && (EVENT_STATUSES as readonly string[]).includes(raw)
    ? (raw as EventStatus)
    : "draft";
}

function parseModerationFlag(raw: unknown): ModerationFlag {
  return raw === "pending" || raw === "clean" ? raw : "";
}

function parseTiers(raw: unknown): TicketTier[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((x): x is Record<string, unknown> => !!x && typeof x === "object")
    .map((x) => ({
      name: typeof x.name === "string" ? x.name : "",
      price: typeof x.price === "number" ? x.price : 0,
      qty: typeof x.qty === "number" ? x.qty : 0,
    }));
}

/** `moderation.eta` is a Timestamp; the UI only ever renders it as elapsed text. */
function etaToText(raw: unknown): string {
  const ts = toTimestampOrNull(raw);
  if (!ts) return "";
  const ms = ts.toMillis() - Date.now();
  if (ms <= 0) return "Review overdue";
  return `~${Math.max(1, Math.round(ms / 3_600_000))}h remaining`;
}

function scheduledPublishToLocal(raw: unknown, timeZone: string): string {
  const ts = toTimestampOrNull(raw);
  if (!ts) return "";
  const { dateISO, time } = utcToZonedParts(ts.toDate(), timeZone);
  return `${dateISO}T${time}`;
}

function localToScheduledPublish(value: string, timeZone: string): Timestamp | null {
  const [dateISO, time] = value.split("T");
  if (!dateISO || !time) return null;
  return Timestamp.fromDate(zonedToUtc(dateISO, time, timeZone));
}

/** `price.min`/`max`/`isFree` are derived from `tickets.tiers` on every write — see module doc. */
function priceFromTiers(tiers: TicketTier[], currency: string) {
  if (tiers.length === 0) return { min: 0, max: 0, currency, isFree: true };
  const prices = tiers.map((t) => t.price);
  const min = Math.min(...prices);
  const max = Math.max(...prices);
  return { min, max, currency, isFree: min === 0 && max === 0 };
}

/**
 * Inbound. Tolerates `endAt === null` (admin- and scraper-written events) by
 * returning `endTime: ""` — the panel always writes a non-null `endAt`
 * itself, but must not assume one on read.
 */
export function parseOrganizerEvent(
  id: string,
  data: Record<string, unknown> | undefined,
  timeZone: string
): OrganizerEvent {
  const d = data ?? {};
  const startAt = toTimestampOrNull(d.startAt);
  const endAt = toTimestampOrNull(d.endAt);
  const window = startAt
    ? timestampsToEventWindow(startAt, endAt, timeZone)
    : { date: "", startTime: "", endTime: "" };
  const tickets = (d.tickets ?? {}) as Record<string, unknown>;
  const performers = Array.isArray(d.performers) ? (d.performers as Record<string, unknown>[]) : [];
  const moderation = (d.moderation ?? {}) as Record<string, unknown>;
  const sales = (d.sales ?? {}) as Record<string, unknown>;

  return {
    id,
    name: typeof d.name === "string" ? d.name : "",
    venue: typeof d.venueId === "string" ? d.venueId : "",
    date: window.date,
    startTime: window.startTime,
    endTime: window.endTime,
    lineup: performers.map((p) => (typeof p.name === "string" ? p.name : "")).filter(Boolean),
    tiers: parseTiers(tickets.tiers),
    status: parseEventStatus(d.status),
    recurring: d.recurring === true,
    recurrenceLabel: typeof d.recurrenceLabel === "string" ? d.recurrenceLabel : "",
    scheduledPublish: scheduledPublishToLocal(d.scheduledPublish, timeZone),
    notifyOnChange: d.notifyOnChange !== false,
    moderationFlag: parseModerationFlag(moderation.flag),
    moderationEta: etaToText(moderation.eta),
    cancelReason: typeof d.cancelReason === "string" ? d.cancelReason : "",
    sold: typeof sales.sold === "number" ? sales.sold : 0,
    revenue: typeof sales.gross === "number" ? sales.gross : 0,
  };
}

/**
 * Outbound. Two rules besides the raw-remainder merge (see module doc):
 * no `lineup` field is written — `lineup[i]` maps to `performers[i].name`
 * with `type: 'DJ'`, preserving an existing performer's `bio` by index where
 * the counts still line up; and `price` is always re-derived from `tiers`.
 */
export function toEventDocFields(
  ui: OrganizerEvent,
  ctx: { meta: VenueMeta; venueName: string; raw: Record<string, unknown> }
): Record<string, unknown> {
  const window = ui.startTime ? eventWindowToTimestamps(ui, ctx.meta.timeZone) : null;
  const existingPerformers = Array.isArray(ctx.raw.performers)
    ? (ctx.raw.performers as Record<string, unknown>[])
    : [];
  const performers = ui.lineup.map((name, i) => ({
    name,
    type: "DJ" as const,
    bio: typeof existingPerformers[i]?.bio === "string" ? existingPerformers[i].bio : "",
  }));
  const existingPrice = (ctx.raw.price ?? {}) as Record<string, unknown>;
  const currency = typeof existingPrice.currency === "string" ? existingPrice.currency : "";

  return {
    ...ctx.raw,
    name: ui.name,
    venueId: ui.venue,
    // Re-derived on every write from the venue's current profile — never
    // carried forward from `ctx.raw.venueName`, which goes stale the moment
    // an event's venue changes (or the venue itself is renamed).
    venueName: ctx.venueName,
    city: ctx.meta.city,
    countryCode: ctx.meta.countryCode,
    geo: ctx.meta.geo ? new GeoPoint(ctx.meta.geo.latitude, ctx.meta.geo.longitude) : toGeoOrNull(ctx.raw.geo),
    startAt: window?.startAt ?? toTimestampOrNull(ctx.raw.startAt),
    endAt: window?.endAt ?? toTimestampOrNull(ctx.raw.endAt),
    performers,
    price: priceFromTiers(ui.tiers, currency),
    tickets: { ...(ctx.raw.tickets as Record<string, unknown> | undefined), currency, tiers: ui.tiers },
    status: ui.status,
    recurring: ui.recurring,
    recurrenceLabel: ui.recurrenceLabel,
    scheduledPublish: localToScheduledPublish(ui.scheduledPublish, ctx.meta.timeZone),
    notifyOnChange: ui.notifyOnChange,
    cancelReason: ui.cancelReason,
    // `moderation` and `sales` are producer-owned: `producerFieldsPinned()` in
    // firestore.rules requires an organizer update to leave both byte-identical
    // to the stored document. Never map either outbound — the raw-remainder
    // merge above (`...ctx.raw`) already carries the stored values through
    // untouched, which is exactly right for a field this panel cannot own.
    // (`moderationFlag`/`moderationEta` are still parsed inbound, above, so
    // the panel can display review state — just never write it back.)
  };
}
