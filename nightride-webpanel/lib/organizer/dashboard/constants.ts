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
 * Status chip styling. Translucent fill + solid text + subtle ring, matching
 * `components/admin/ui/Badge.tsx` so admin and organizer chips read alike.
 */
export const EVENT_STATUS_STYLES: Record<EventStatus, { label: string; className: string }> = {
  draft: { label: "DRAFT", className: "bg-white/5 text-nr-text-secondary ring-white/10" },
  scheduled: {
    label: "SCHEDULED",
    className: "bg-nr-primary-light/10 text-nr-primary-light ring-nr-primary-light/30",
  },
  in_review: { label: "IN REVIEW", className: "bg-amber-500/10 text-amber-400 ring-amber-500/30" },
  live: { label: "LIVE", className: "bg-emerald-500/10 text-emerald-400 ring-emerald-500/30" },
  cancelled: { label: "CANCELLED", className: "bg-red-500/10 text-red-400 ring-red-500/30" },
};

/**
 * A `live` event that has not started yet reads as UPCOMING rather than LIVE —
 * see `deriveEventChip` in ./format.
 */
export const UPCOMING_STYLE = {
  label: "UPCOMING",
  className: "bg-nr-primary-light/10 text-nr-primary-light ring-nr-primary-light/30",
};

export const DOOR_STATUSES: { id: DoorStatus; label: string; className: string }[] = [
  { id: "open", label: "Open", className: "bg-emerald-500/10 text-emerald-400 ring-emerald-500/30" },
  { id: "filling", label: "Filling Up", className: "bg-nr-accent/10 text-nr-accent ring-nr-accent/30" },
  { id: "capacity", label: "At Capacity", className: "bg-amber-500/10 text-amber-400 ring-amber-500/30" },
  {
    id: "guestlist",
    label: "Guest List Only",
    className: "bg-nr-primary-light/10 text-nr-primary-light ring-nr-primary-light/30",
  },
  { id: "closed", label: "Closed", className: "bg-red-500/10 text-red-400 ring-red-500/30" },
];

export const INBOX_TYPE_STYLES: Record<InboxType, { label: string; className: string }> = {
  policy: {
    label: "POLICY",
    className: "bg-nr-primary-light/10 text-nr-primary-light ring-nr-primary-light/30",
  },
  violation: { label: "VIOLATION", className: "bg-amber-500/10 text-amber-400 ring-amber-500/30" },
  appeal: { label: "APPEAL", className: "bg-emerald-500/10 text-emerald-400 ring-emerald-500/30" },
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
