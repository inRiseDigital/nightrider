/**
 * `venues/{venueId}` <-> `VenueProfile` / `VenueMeta` / `TonightState`.
 *
 * `menu` lives in the `menuSections` subcollection in production (see
 * `docs/FIRESTORE_SCHEMA.md`); it is threaded in as a parameter here rather
 * than parsed from the venue doc, and `toVenueDocFields` deliberately does
 * not write it — same reasoning as `verified`/`verificationSteps` being live
 * fields the draft never touches.
 */
import { GeoPoint, Timestamp } from "firebase/firestore";
import {
  crowdLevelForDoorStatus,
  doorStatusFromLive,
  liveStatusFor,
  offerFor,
  queueStatusForDoorStatus,
  ticketsAvailableFor,
  type CrowdLevel,
  type LiveStatus,
  type QueueStatus,
} from "./enums";
import type {
  DoorStatus,
  HoursException,
  MenuItem,
  MenuSection,
  OpeningHours,
  SocialLink,
  TonightState,
  VenueMeta,
  VenueProfile,
  VerifyStepId,
  VerifyStepStatus,
} from "../types";
import { DAYS } from "../constants";

export function toTimestampOrNull(raw: unknown): Timestamp | null {
  return raw instanceof Timestamp ? raw : null;
}
export function toGeoOrNull(raw: unknown): { latitude: number; longitude: number } | null {
  return raw instanceof GeoPoint ? { latitude: raw.latitude, longitude: raw.longitude } : null;
}

function parseSocialLinks(raw: unknown): SocialLink[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((x): x is Record<string, unknown> => !!x && typeof x === "object")
    .map((x) => ({
      network: typeof x.network === "string" ? x.network : "",
      value: typeof x.value === "string" ? x.value : "",
    }));
}

function parseHours(raw: unknown): OpeningHours[] {
  const list = Array.isArray(raw) ? raw : [];
  return DAYS.map((day, i) => {
    const r = (list[i] ?? {}) as Record<string, unknown>;
    return {
      day,
      closed: r.closed === true,
      open: typeof r.open === "string" ? r.open : "22:00",
      close: typeof r.close === "string" ? r.close : "04:00",
    };
  });
}

function parseExceptions(raw: unknown): HoursException[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((x): x is Record<string, unknown> => !!x && typeof x === "object")
    .map((x) => ({
      label: typeof x.label === "string" ? x.label : "",
      date: typeof x.date === "string" ? x.date : "",
      closed: x.closed !== false,
    }));
}

function parseVerificationSteps(raw: unknown): Record<VerifyStepId, VerifyStepStatus> {
  const r = (raw ?? {}) as Record<string, unknown>;
  const stepStatus = (id: VerifyStepId): VerifyStepStatus => {
    const step = (r[id] ?? {}) as Record<string, unknown>;
    return step.status === "done" ? "done" : "active";
  };
  return { license: stepStatus("license"), gps: stepStatus("gps"), video: stepStatus("video") };
}

/**
 * The four launch markets (see root CLAUDE.md). `createVenue`'s "Add venue"
 * dialog has no address step and no geocoding service — this is the
 * required country selector's option list, and `cityCenter` is the fallback
 * `geo` when device geolocation is denied or unavailable. A launch-city
 * centre is an honest approximation flagged to the organizer; `(0, 0)` is a
 * silent lie only an admin could ever notice.
 */
export const LAUNCH_MARKETS: readonly {
  countryCode: string;
  label: string;
  cityCenter: { latitude: number; longitude: number };
}[] = [
  { countryCode: "AE", label: "Dubai, UAE", cityCenter: { latitude: 25.2048, longitude: 55.2708 } },
  { countryCode: "JP", label: "Tokyo, Japan", cityCenter: { latitude: 35.6762, longitude: 139.6503 } },
  { countryCode: "GB", label: "London, UK", cityCenter: { latitude: 51.5072, longitude: -0.1276 } },
  { countryCode: "AU", label: "Melbourne, Australia", cityCenter: { latitude: -37.8136, longitude: 144.9631 } },
];

export function parseVenueMeta(id: string, data: Record<string, unknown> | undefined): VenueMeta {
  const d = data ?? {};
  return {
    id,
    ownerUid: typeof d.ownerUid === "string" ? d.ownerUid : "",
    city: typeof d.city === "string" ? d.city : "",
    countryCode: typeof d.countryCode === "string" ? d.countryCode : "",
    timeZone: typeof d.timeZone === "string" ? d.timeZone : "",
    geo: toGeoOrNull(d.geo),
    status: d.status === "closed" ? "closed" : "active",
    verified: d.verified === true,
  };
}

export function parseVenueProfile(
  id: string,
  data: Record<string, unknown> | undefined,
  menu: MenuSection[]
): import("../types").VenueProfile {
  const d = data ?? {};
  const verified = d.verified === true;
  const cover = (d.cover ?? {}) as Record<string, unknown>;
  return {
    verified,
    name: typeof d.name === "string" ? d.name : "",
    city: typeof d.city === "string" ? d.city : "",
    address: typeof d.address === "string" ? d.address : "",
    about: typeof d.about === "string" ? d.about : "",
    socialLinks: parseSocialLinks(d.socialLinks),
    genres: Array.isArray(d.genres) ? d.genres.filter((g): g is string => typeof g === "string") : [],
    dressCode: typeof d.dressCode === "string" ? d.dressCode : "Casual",
    agePolicy: typeof d.agePolicy === "string" ? d.agePolicy : "18+",
    coverMin: typeof cover.min === "number" ? cover.min : 0,
    coverMax: typeof cover.max === "number" ? cover.max : 0,
    currency: typeof cover.currency === "string" ? cover.currency : "$",
    capacity: typeof d.capacity === "number" ? d.capacity : 0,
    amenities: Array.isArray(d.amenities) ? d.amenities.filter((a): a is string => typeof a === "string") : [],
    hours: parseHours(d.hours),
    exceptions: parseExceptions(d.exceptions),
    menu,
    tableLink: typeof d.tableLink === "string" ? d.tableLink : "",
    verificationSteps: verified ? undefined : parseVerificationSteps(d.verification),
    openVerifyStep: verified ? null : "license",
    photos: Array.isArray(d.photos) ? d.photos.filter((p): p is string => typeof p === "string") : [],
  };
}

/**
 * The reviewable listing fields only — `verified`, `verificationSteps` and
 * `menu` are never written from here. `verified` and `verificationSteps` are
 * admin-written and pinned by the rules against every organizer write, so
 * they are excluded from the dirty check and preserved when a draft commits.
 * `menu` lives in the `menuSections` subcollection and bypasses the draft
 * entirely. Spreads `ctx.raw` first so `editorUids`/`editors`/`live`/
 * `verification`/anything else the panel doesn't model survives the write.
 */
export function toVenueDocFields(
  ui: import("../types").VenueProfile,
  ctx: { raw: Record<string, unknown> }
): Record<string, unknown> {
  return {
    ...ctx.raw,
    name: ui.name,
    city: ui.city,
    address: ui.address,
    about: ui.about,
    socialLinks: ui.socialLinks,
    genres: ui.genres,
    dressCode: ui.dressCode,
    agePolicy: ui.agePolicy,
    cover: { min: ui.coverMin, max: ui.coverMax, currency: ui.currency },
    capacity: ui.capacity,
    amenities: ui.amenities,
    hours: ui.hours,
    exceptions: ui.exceptions,
    tableLink: ui.tableLink,
    photos: ui.photos ?? [],
  };
}

interface LiveDoc {
  status: LiveStatus;
  crowdLevel: CrowdLevel;
  queueStatus: QueueStatus;
  doorStatus?: unknown;
  ticketsAvailable: boolean;
  tablesAvailable: boolean;
  inVenue: number;
  queueMinutes: number;
  emergencyActive: boolean;
  offer: string;
}

/** `venues/{id}.live` -> `TonightState`. `capacity` comes from the venue doc. */
export function parseTonight(raw: Record<string, unknown> | undefined, capacity: number): TonightState {
  const d = (raw ?? {}) as Partial<LiveDoc> & Record<string, unknown>;
  const inVenue = typeof d.inVenue === "number" ? d.inVenue : 0;
  const status: LiveStatus =
    d.status === "closed" || d.status === "vipOnly" || d.status === "soldOut" ? d.status : "open";
  const doorStatus: DoorStatus = doorStatusFromLive({ doorStatus: d.doorStatus, status, inVenue, capacity });
  const flash = (d.flash ?? null) as { active?: boolean; text?: string; until?: string } | null;
  return {
    status: doorStatus,
    inVenue,
    queueMinutes: typeof d.queueMinutes === "number" ? d.queueMinutes : 0,
    emergencyActive: d.emergencyActive === true,
    flashActive: flash?.active === true,
    flashText: typeof flash?.text === "string" ? flash.text : "",
    flashUntil: typeof flash?.until === "string" ? flash.until : "",
  };
}

/**
 * `TonightState` -> `venues/{id}.live` fields. `updatedAt: serverTimestamp()`
 * is the caller's job (needs the live `serverTimestamp()` import at the write
 * site) — `liveOk()` requires `live.updatedAt == request.time`.
 * `tablesAvailable` has no UI control, so it round-trips from `raw` verbatim.
 */
export function toLiveFields(
  t: TonightState,
  ctx: { capacity: number; raw: Record<string, unknown> }
): Record<string, unknown> {
  const status = liveStatusFor(t.status);
  const crowdLevel = crowdLevelForDoorStatus(t.status, t.inVenue, ctx.capacity);
  const queueStatus = queueStatusForDoorStatus(t.status, t.queueMinutes);
  return {
    ...ctx.raw,
    status,
    crowdLevel,
    queueStatus,
    doorStatus: t.status,
    ticketsAvailable: ticketsAvailableFor(t.status),
    tablesAvailable: ctx.raw.tablesAvailable !== false,
    offer: offerFor(t.flashActive, t.flashText),
    inVenue: t.inVenue,
    queueMinutes: t.queueMinutes,
    emergencyActive: t.emergencyActive,
    flash: { active: t.flashActive, text: t.flashText.slice(0, 200), until: t.flashUntil },
  };
}

/**
 * A brand-new venue has no `live` map at all — `organizerCreateOk()` denies
 * writing one on create, and no admin flow writes one either. This is the
 * map `ensureLive()` backfills the first time an organizer touches door
 * status for a venue that has never had one, before any real value is known.
 */
export const DEFAULT_TONIGHT_STATE: TonightState = {
  status: "closed",
  inVenue: 0,
  queueMinutes: 0,
  emergencyActive: false,
  flashActive: false,
  flashText: "",
  flashUntil: "",
};

// ---------------------------------------------------------------------------
// The draft/published listing seam — pure and unit-testable on its own, so
// "a remote snapshot must never clobber an in-progress local edit" is a
// property of these functions rather than something only observable by
// rendering the hook.
// ---------------------------------------------------------------------------

/**
 * Fields that bypass the draft entirely and must keep flowing from the
 * latest snapshot even while a listing draft is open — none of them are
 * part of what the organizer is reviewing before Save.
 * `verified`/`verificationSteps` are admin-only verdicts; `openVerifyStep` is
 * pure client accordion state. `menu` is its own subcollection with its own
 * immediate-write, no-review path (see `parseMenuSection`/
 * `toMenuSectionFields` above) — a draft seeds `menu` once, from whatever the
 * snapshot held at draft-creation time, and never sees it again, so without
 * this overlay a menu edit made while a listing draft is open would write to
 * Firestore correctly but render as if it hadn't happened until the draft is
 * saved or discarded.
 */
const SNAPSHOT_ONLY_FIELDS = ["verified", "verificationSteps", "openVerifyStep", "menu"] as const;

/** Overlays `saved`'s snapshot-only fields onto `draft`'s listing fields. */
export function withLiveFields(draft: VenueProfile, saved: VenueProfile): VenueProfile {
  return {
    ...draft,
    verified: saved.verified,
    verificationSteps: saved.verificationSteps,
    openVerifyStep: saved.openVerifyStep,
    menu: saved.menu,
  };
}

/** `p` with the snapshot-only fields stripped — the subset that is ever reviewable/dirty. */
export function listingFieldsOf(p: VenueProfile): Partial<VenueProfile> {
  const listing: Partial<VenueProfile> = { ...p };
  for (const field of SNAPSHOT_ONLY_FIELDS) delete listing[field];
  return listing;
}

/**
 * What the editor renders: the in-progress draft with the latest snapshot's
 * live fields overlaid, or the plain snapshot when there is no draft. A new
 * `onSnapshot` delivery only ever changes `saved` — it can update `verified`
 * out from under an open draft, but never the listing fields the organizer is
 * mid-edit on.
 */
export function computeVenueProfile(draft: VenueProfile | undefined, saved: VenueProfile): VenueProfile {
  return draft ? withLiveFields(draft, saved) : saved;
}

/** True once the draft's listing fields differ from the saved listing fields. */
export function isVenueDirty(draft: VenueProfile | undefined, saved: VenueProfile): boolean {
  return !!draft && JSON.stringify(listingFieldsOf(draft)) !== JSON.stringify(listingFieldsOf(saved));
}

/**
 * True once `name` or `address` differ from saved — the only two fields that
 * require admin review (`venueReviewedFields()`, `firestore.rules`). Distinct
 * from `isVenueDirty`: the Save button gates on "anything changed", this
 * gates on "does saving also need a `venueEdits` submission".
 */
export function isVenueIdentityDirty(draft: VenueProfile | undefined, saved: VenueProfile): boolean {
  return !!draft && (draft.name !== saved.name || draft.address !== saved.address);
}

/**
 * Finding 4: nothing read `venueEdits/{venueId}` back, so Save appeared to
 * discard the organizer's work. This overlays a pending `venueEdits.listing`
 * onto the last-saved profile the same way `withLiveFields` overlays a local
 * draft — `name`/`address`/`menu`/verification stay from `saved` (they were
 * never part of the submission), the thirteen listing fields come from the
 * submitted draft. Reuses the same defensive per-field parsing as
 * `parseVenueProfile` so a malformed or partial `listing` map degrades to
 * `saved`'s values rather than throwing.
 */
export function applyPendingListing(saved: VenueProfile, listing: Record<string, unknown> | undefined): VenueProfile {
  const l = listing ?? {};
  return {
    ...saved,
    name: typeof l.name === "string" ? l.name : saved.name,
    address: typeof l.address === "string" ? l.address : saved.address,
  };
}

/**
 * The reviewable fields only, shaped for `venueEdits/{venueId}.listing` —
 * exactly `venueReviewedFields()` (`firestore.rules`): `name` and `address`.
 * Everything else the organizer edits is a direct write via
 * `toVenueDirectFields` below, no review.
 */
export function toVenueEditListing(p: VenueProfile): Record<string, unknown> {
  return { name: p.name, address: p.address };
}

/**
 * The direct-write profile fields, shaped for `venues/{id}` — exactly
 * `venueProfileFields()` (`firestore.rules`), in document shape
 * (`cover: { min, max, currency }`, never `coverMin`/`coverMax`/`currency`).
 * Deliberately NOT a raw-remainder spread of `ctx.raw` (unlike
 * `toVenueDocFields`, the create-path mapper): this is a targeted `updateDoc`
 * of exactly these keys, so it can't re-send `editors`/`geo`/`verification`/
 * `live` on every profile save.
 *
 * `timeZone` is one of these fields but is not part of `VenueProfile` — it
 * lives on `VenueMeta` and the editor has no control for it (Constraint 7:
 * `types.ts`'s UI shapes don't change for this). `ctx.timeZone` threads the
 * venue's current zone through unchanged.
 */
export function toVenueDirectFields(p: VenueProfile, ctx: { timeZone: string }): Record<string, unknown> {
  return {
    about: p.about,
    socialLinks: p.socialLinks,
    genres: p.genres,
    dressCode: p.dressCode,
    agePolicy: p.agePolicy,
    tableLink: p.tableLink,
    cover: { min: p.coverMin, max: p.coverMax, currency: p.currency },
    capacity: p.capacity,
    amenities: p.amenities,
    hours: p.hours,
    exceptions: p.exceptions,
    photos: p.photos ?? [],
    timeZone: ctx.timeZone,
  };
}

// ---------------------------------------------------------------------------
// `venues/{id}/menuSections/{sectionId}` <-> `MenuSection`. A subcollection,
// not the venue draft: menu edits publish immediately (see rules' `menuSections`
// match block), so there is no listing/live split here — one document, one
// read, one write.
// ---------------------------------------------------------------------------

function parseMenuItem(raw: unknown): MenuItem | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>;
  if (typeof r.id !== "string") return null;
  return {
    id: r.id,
    name: typeof r.name === "string" ? r.name : "",
    price: typeof r.price === "number" ? r.price : 0,
    desc: typeof r.desc === "string" ? r.desc : "",
    size: typeof r.size === "string" ? r.size : "",
    serves: typeof r.serves === "string" ? r.serves : "",
    tags: Array.isArray(r.tags) ? r.tags.filter((t): t is string => typeof t === "string") : [],
    nights: Array.isArray(r.nights) ? r.nights.filter((n): n is number => typeof n === "number") : [],
    soldOut: r.soldOut === true,
    image: typeof r.image === "string" ? r.image : "",
  };
}

export function parseMenuSection(id: string, data: Record<string, unknown> | undefined): MenuSection {
  const d = data ?? {};
  const items = Array.isArray(d.items) ? d.items : [];
  return {
    id,
    name: typeof d.name === "string" ? d.name : "",
    items: items.map(parseMenuItem).filter((i): i is MenuItem => i !== null),
  };
}

/** `MenuSection` -> the fields written to its own `menuSections/{id}` doc. */
export function toMenuSectionFields(s: MenuSection): Record<string, unknown> {
  return { name: s.name, items: s.items };
}

/**
 * `photos[index] = value` immutably, padding with `""` rather than leaving a
 * sparse-array hole. T12 fix round 1: the four gallery tiles
 * (`gallery~{venueId}~{i}` -> `photos[i+1]`) are independently droppable in
 * any order, so a brand-new venue's `photos` array can be shorter than
 * `index` when a slot lands — plain `photos[index] = value` on a short array
 * leaves a hole, and `[...sparse][0] === undefined` in that case.
 * `toVenueEditListing`'s bare `{ ...p }` spread would carry that `undefined`
 * straight into `saveVenue`'s batch write, which the Firestore SDK rejects
 * outright (no `ignoreUndefinedProperties` is set anywhere in
 * `lib/firebase.ts`) — a Storage upload that already succeeded would then
 * fail to save with an opaque error. Padding on every write means `photos`
 * is never sparse to begin with. Lives here (not `store.tsx`, where the two
 * callers are) because it's pure and this module is the one with unit
 * tests that don't transitively import Firebase — see `venues.test.ts`.
 */
export function setPhotoAt(photos: string[] | undefined, index: number, value: string): string[] {
  const next = [...(photos ?? [])];
  while (next.length <= index) next.push("");
  next[index] = value;
  return next;
}
