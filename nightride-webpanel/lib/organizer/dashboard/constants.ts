import type {
  DayName,
  DoorStatus,
  EventStatus,
  InboxType,
  TeamRole,
  VerifyStepId,
} from "./types";

export const GENRES = [
  "Techno",
  "House",
  "Deep House",
  "Hip-Hop",
  "R&B",
  "Afrobeats",
  "Commercial",
  "Live Band",
];

export const AMENITIES = [
  "Rooftop",
  "Smoking Area",
  "Cloakroom",
  "VIP Tables",
  "Outdoor Terrace",
  "Parking",
];

export const DRESS_CODES = ["Casual", "Smart Casual", "Dress to Impress", "No Sportswear"];

export const AGE_POLICIES = ["18+", "21+", "25+ Mature Crowd"];

/** Week starts Monday — the calendar grid and `hours` arrays both rely on this order. */
export const DAYS: DayName[] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

export const TEAM_ROLES: TeamRole[] = ["Marketing", "Manager"];

/**
 * Status chip styling — M3 tone containers (solid container + on-container
 * text), matching the "Organizer Dashboard Material.dc.html" design source.
 */
export const EVENT_STATUS_STYLES: Record<EventStatus, { label: string; className: string }> = {
  draft: { label: "DRAFT", className: "bg-[var(--m3-surf3)] text-[var(--m3-onv)] ring-white/5" },
  scheduled: {
    label: "SCHEDULED",
    className: "bg-[var(--m3-terc)] text-[var(--m3-onterc)] ring-white/5",
  },
  in_review: {
    label: "IN REVIEW",
    className: "bg-[var(--m3-warnc)] text-[var(--m3-onwarnc)] ring-white/5",
  },
  live: { label: "LIVE", className: "bg-[var(--m3-succ)] text-[var(--m3-onsucc)] ring-white/5" },
  cancelled: {
    label: "CANCELLED",
    className: "bg-[var(--m3-errc)] text-[var(--m3-onerrc)] ring-white/5",
  },
};

/**
 * A `live` event that has not started yet reads as UPCOMING rather than LIVE —
 * see `deriveEventChip` in ./format.
 */
export const UPCOMING_STYLE = {
  label: "UPCOMING",
  className: "bg-[var(--m3-terc)] text-[var(--m3-onterc)] ring-white/5",
};

export const DOOR_STATUSES: { id: DoorStatus; label: string; className: string }[] = [
  { id: "open", label: "Open", className: "bg-[var(--m3-succ)] text-[var(--m3-onsucc)] ring-white/5" },
  {
    id: "filling",
    label: "Filling Up",
    className: "bg-[var(--m3-pric)] text-[var(--m3-onpric)] ring-white/5",
  },
  {
    id: "capacity",
    label: "At Capacity",
    className: "bg-[var(--m3-warnc)] text-[var(--m3-onwarnc)] ring-white/5",
  },
  {
    id: "guestlist",
    label: "Guest List Only",
    className: "bg-[var(--m3-terc)] text-[var(--m3-onterc)] ring-white/5",
  },
  { id: "closed", label: "Closed", className: "bg-[var(--m3-errc)] text-[var(--m3-onerrc)] ring-white/5" },
];

export const INBOX_TYPE_STYLES: Record<InboxType, { label: string; className: string }> = {
  policy: {
    label: "POLICY",
    className: "bg-[var(--m3-terc)] text-[var(--m3-onterc)] ring-white/5",
  },
  violation: {
    label: "VIOLATION",
    className: "bg-[var(--m3-warnc)] text-[var(--m3-onwarnc)] ring-white/5",
  },
  appeal: { label: "APPEAL", className: "bg-[var(--m3-succ)] text-[var(--m3-onsucc)] ring-white/5" },
};

export const VERIFY_STEPS: { id: VerifyStepId; label: string; detail: string }[] = [
  {
    id: "license",
    label: "Business License / Ownership Doc",
    detail:
      "Upload a photo of your business license or venue ownership document from the mobile app.",
  },
  {
    id: "gps",
    label: "On-Site GPS Check",
    detail: "Open the app while standing at the venue so we can confirm the location.",
  },
  {
    id: "video",
    label: "Video Walkthrough",
    detail: "Record a walkthrough showing the entrance, bar, and main floor.",
  },
];

/** Number of gallery slots beside the hero image on the venue profile. */
export const GALLERY_SLOT_COUNT = 4;

/** Any code of at least this length is accepted — no SMS is actually sent. */
export const OTP_MIN_LENGTH = 4;
