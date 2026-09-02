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
  tableLink: string;
  /** Only present while `verified` is false. */
  verificationSteps?: Record<VerifyStepId, VerifyStepStatus>;
  /** Which verification accordion row is expanded, if any. */
  openVerifyStep?: VerifyStepId | null;
}

export type EventStatus = "draft" | "scheduled" | "in_review" | "live" | "cancelled";

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

export type TeamRole = "Marketing" | "Manager";

export interface TeamMember {
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
  reply: string;
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
