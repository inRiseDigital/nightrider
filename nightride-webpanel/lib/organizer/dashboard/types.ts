/**
 * Domain types for the organizer dashboard.
 *
 * These mirror the shapes authored in the `Organizer Dashboard.dc.html` design
 * source. They are deliberately separate from `lib/organizer/types.ts`, which
 * covers the *application* flow (how someone becomes an organizer) rather than
 * what an approved organizer manages day to day.
 */

export type DayName = "Mon" | "Tue" | "Wed" | "Thu" | "Fri" | "Sat" | "Sun";

export interface OpeningHours {
  day: DayName;
  closed: boolean;
  /** 24h "HH:mm". */
  open: string;
  /** 24h "HH:mm" — may wrap past midnight (e.g. open 22:00, close 04:00). */
  close: string;
}

export interface HoursException {
  label: string;
  /** ISO "YYYY-MM-DD", or "" while the row is still being filled in. */
  date: string;
  closed: boolean;
}

/** The three checks a newly added venue clears before its editor unlocks. */
export type VerifyStepId = "license" | "gps" | "video";
export type VerifyStepStatus = "active" | "done";

export interface SocialLink {
  network: string;
  value: string;
}

/** One line on a venue's food & drinks menu. */
export interface MenuItem {
  id: string;
  name: string;
  /** In the venue's `currency`. */
  price: number;
  desc: string;
  /** Free text serving size — "1.5L magnum", "75cl". */
  size: string;
  /** Free text head count — "6". */
  serves: string;
  /** Labels from `MENU_TAGS`. */
  tags: string[];
  /** Indices into `DAYS` (0 = Mon). Empty means available every night. */
  nights: number[];
  soldOut: boolean;
  /**
   * `https` download URL from Cloud Storage
   * (`venuePhotos/{venueId}/menu/{itemId}.jpg`). Optional — a sibling
   * addition per Global Constraint 7 rather than a required field, so the
   * existing mock fixtures and every other `MenuItem` literal keep compiling
   * untouched. Always concretely `""` (never absent) on anything this module
   * parses or constructs.
   */
  image?: string;
}

export interface MenuSection {
  id: string;
  name: string;
  items: MenuItem[];
}

export interface VenueProfile {
  /** False until an admin approves the venue; gates the editor and the app preview. */
  verified: boolean;
  name: string;
  city: string;
  address: string;
  about: string;
  socialLinks: SocialLink[];
  genres: string[];
  dressCode: string;
  agePolicy: string;
  coverMin: number;
  coverMax: number;
  currency: string;
  capacity: number;
  amenities: string[];
  hours: OpeningHours[];
  exceptions: HoursException[];
  /** Food & drinks, grouped into sections. Edits go live without review. */
  menu: MenuSection[];
  tableLink: string;
  /**
   * `https` download URLs from Cloud Storage. `[0]` is the hero
   * (`live_hub_service.dart:47` reads `photos.first` as the club-list
   * thumbnail); `[1..4]` are the gallery. A listing field like every other —
   * routes through `updateVenueListing`, reaches the app preview only once
   * the submitted `venueEdits` change is approved. Optional per Global
   * Constraint 7 (sibling addition, not a required rewrite of every existing
   * `VenueProfile` literal); always concretely `[]` (never absent) on
   * anything this module parses or constructs.
   */
  photos?: string[];
  /** Only present while `verified` is false. */
  verificationSteps?: Record<VerifyStepId, VerifyStepStatus>;
  /** Which verification accordion row is expanded, if any. */
  openVerifyStep?: VerifyStepId | null;
}

export interface VenueMeta {
  id: string;
  ownerUid: string;
  city: string;
  countryCode: string; // ISO-3166 alpha-2, uppercase
  timeZone: string; // IANA, e.g. "Asia/Dubai"
  geo: { latitude: number; longitude: number } | null;
  status: "active" | "closed";
  verified: boolean;
}

export interface OrganizerProfile {
  name: string;
  initials: string;
  email: string;
  phone: string;
}

export type EventStatus =
  | "draft"
  | "scheduled"
  | "in_review"
  | "published"
  | "cancelled"
  | "archived";

/** `"live"` and `"upcoming"` are derived at render time, never stored. */
export type EventDisplayStatus = EventStatus | "live" | "upcoming";

/** Result of the platform's automated content scan. "" means not yet scanned. */
export type ModerationFlag = "" | "pending" | "clean";

export interface TicketTier {
  name: string;
  price: number;
  qty: number;
}

export interface OrganizerEvent {
  id: string;
  name: string;
  /** Venue id — a key of the venue map, not a display name. */
  venue: string;
  /** ISO "YYYY-MM-DD". */
  date: string;
  startTime: string;
  endTime: string;
  lineup: string[];
  tiers: TicketTier[];
  status: EventStatus;
  recurring: boolean;
  recurrenceLabel: string;
  /** ISO "YYYY-MM-DDTHH:mm" — publishes without the organizer being online. */
  scheduledPublish: string;
  notifyOnChange: boolean;
  moderationFlag: ModerationFlag;
  moderationEta: string;
  cancelReason: string;
  /** Tickets sold so far. 0 for anything not on sale yet. */
  sold: number;
  /** Gross take in the venue's currency. 0 for anything not on sale yet. */
  revenue: number;
}

export type DoorStatus = "open" | "filling" | "capacity" | "guestlist" | "closed";

export interface TonightState {
  status: DoorStatus;
  /** Head count currently inside — shown against the venue's capacity. */
  inVenue: number;
  queueMinutes: number;
  emergencyActive: boolean;
  flashActive: boolean;
  flashText: string;
  /** 24h "HH:mm". */
  flashUntil: string;
}

export interface PushState {
  message: string;
  rateUsed: number;
  rateMax: number;
}

export interface PromoCode {
  code: string;
  desc: string;
  maxUses: number;
  used: number;
}

export interface RankPerk {
  tier: string;
  perk: string;
}

export interface BoostSlot {
  active: boolean;
  /** ISO "YYYY-MM-DD". */
  night: string;
  price: number;
}

export type TeamRole = "Owner" | "Manager" | "Door staff";

export interface TeamMember {
  /** Stable across role edits and removals, so rows keep their identity. */
  id: string;
  name: string;
  email: string;
  role: TeamRole;
}

export interface ActivityEntry {
  who: string;
  what: string;
  when: string;
}

export interface VenueReview {
  id: string;
  author: string;
  rating: number;
  text: string;
  /** Draft text in the composer — becomes `posted` when sent. */
  reply: string;
  /** The public reply guests see. Empty until one is sent. */
  posted: string;
  /** When `posted` was published, e.g. "Aug 6". Empty when nothing is posted. */
  postedWhen: string;
  flagged: boolean;
}

export type InboxType = "policy" | "violation" | "appeal";

export interface InboxMessage {
  id: string;
  subject: string;
  from: string;
  date: string;
  type: InboxType;
  body: string;
  /** Expanded in the inbox list; also doubles as the read marker. */
  open: boolean;
}

/** A translucent-fill / solid-text / subtle-ring chip, per the brand spec. */
export interface ChipTone {
  label: string;
  /** Tailwind classes for fill + text + ring. */
  className: string;
}
