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
  };
}

/**
 * The reviewable listing fields only — `verified`, `verificationSteps` and
 * `menu` are live fields that bypass the draft and are never written from
 * here, matching `store.tsx`'s `LIVE_VENUE_FIELDS`. Spreads `ctx.raw` first
 * so `editorUids`/`editors`/`live`/`verification`/anything else the panel
 * doesn't model survives the write.
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
 * Fields that bypass the draft entirely. `verified`/`verificationSteps` are
 * admin-only verdicts; `openVerifyStep` is pure client accordion state. All
 * three must keep flowing from the latest snapshot even while a listing draft
 * is open, so a draft never goes stale on the one thing an admin can change
 * out from under the organizer mid-edit.
 */
const LIVE_VENUE_FIELDS = ["verified", "verificationSteps", "openVerifyStep"] as const;

/** Overlays `saved`'s live fields onto `draft`'s listing fields. */
export function withLiveFields(draft: VenueProfile, saved: VenueProfile): VenueProfile {
  return {
    ...draft,
    verified: saved.verified,
    verificationSteps: saved.verificationSteps,
    openVerifyStep: saved.openVerifyStep,
  };
}

/** `p` with the live fields stripped — the subset that is ever reviewable/dirty. */
export function listingFieldsOf(p: VenueProfile): Partial<VenueProfile> {
  const listing: Partial<VenueProfile> = { ...p };
  for (const field of LIVE_VENUE_FIELDS) delete listing[field];
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
 * The reviewable listing fields only, shaped for `venueEdits/{venueId}.listing`
 * — the same fields `listingFieldsOf` strips down to, just spread into a plain
 * object rather than `Partial<VenueProfile>` so it writes cleanly.
 */
export function toVenueEditListing(p: VenueProfile): Record<string, unknown> {
  return listingFieldsOf(p);
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
