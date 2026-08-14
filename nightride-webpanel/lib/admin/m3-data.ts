// Mock data + pure presentation helpers for the Material Design 3 admin console.
// Ported from the "Admin Dashboard v3" design (Overview + Organizer Applications).
// UI-only mock data — no Firestore wiring yet.

export type OrgGroup = "recent" | "approved" | "pending";
export type OrgStatus = "Approved" | "Pending" | "Rejected" | "Banned" | "Deactivated" | "Info requested";
export type NicStatus = "matched" | "mismatch";
export type BadgeType = "success" | "warning" | "danger" | "info" | "neutral";

export interface OrgBase {
  id: string;
  initials: string;
  name: string;
  email: string;
  address: string;
  group: OrgGroup;
  status: OrgStatus;
  nicStatus: NicStatus;
  submitted: string;
}

export interface VenueBase {
  id: string;
  name: string;
  city: string;
  address: string;
  capacity: number;
  licence: string;
  licenceExpiry: string;
  hours: string;
  events: number;
  assigned: string;
  gps: boolean;
  phone: string;
}

export interface DetailExtra {
  nicNameOnId: string;
  nicNumber: string;
  nicSubmittedDate: string;
  nicOtherNames?: string;
  nicDob?: string;
  nicSex?: string;
  nicAddress?: string;
  nicIssued?: string;
  nicSerial?: string;
  nicDocType?: string;
  ip?: string;
  device?: string;
  accountAge?: string;
  signupDate?: string;
  club?: string;
  clubLocation?: string;
  eventsCreated?: number;
  phone?: string;
  venueName?: string;
  address?: string;
  videoState: "before" | "after";
  videoSentAgo: string | null;
}

export const BADGE_COLORS: Record<BadgeType, { bg: string; fg: string }> = {
  success: { bg: "#0F3D28", fg: "#7BE0A8" },
  warning: { bg: "#42320A", fg: "#F5C452" },
  danger: { bg: "#5C1218", fg: "#FFB4AB" },
  info: { bg: "#1F4F49", fg: "#A5F2E5" },
  neutral: { bg: "#2A252A", fg: "#CFC0C5" },
};

export function badgeColors(type: BadgeType) {
  return BADGE_COLORS[type] ?? BADGE_COLORS.neutral;
}

const CITY_TILES: Record<string, string> = {
  Dubai: "12/2676/1751",
  Tokyo: "12/3636/1612",
  London: "12/2046/1362",
  Melbourne: "12/3697/2513",
};

export function cityTile(city: string): string {
  return "https://tile.openstreetmap.org/" + (CITY_TILES[city] ?? CITY_TILES.Dubai) + ".png";
}

export function getOrgs(): OrgBase[] {
  return [
    { id: "kenji-yamamoto", initials: "KY", name: "Kenji Yamamoto", email: "kenji.yamamoto@mail.com", address: "26 Al Fahidi St, Melbourne", group: "recent", status: "Approved", nicStatus: "matched", submitted: "3w ago" },
    { id: "casey-alfarsi", initials: "CA", name: "Casey Al-Farsi", email: "casey.al-farsi@mail.com", address: "53 Collins St, Tokyo", group: "recent", status: "Approved", nicStatus: "matched", submitted: "5w ago" },
    { id: "sara-whitfield", initials: "SW", name: "Sara Whitfield", email: "sara.whitfield@mail.com", address: "77 Shibuya Crossing, Melbourne", group: "recent", status: "Approved", nicStatus: "matched", submitted: "6w ago" },
    { id: "riley-khan", initials: "RK", name: "Riley Khan", email: "riley.khan@mail.com", address: "2 Brick Lane, Melbourne", group: "recent", status: "Approved", nicStatus: "matched", submitted: "9w ago" },
    { id: "yuki-walker", initials: "YW", name: "Yuki Walker", email: "yuki.walker@mail.com", address: "43 Chapel St, Tokyo", group: "approved", status: "Approved", nicStatus: "mismatch", submitted: "4mo ago" },
    { id: "haruto-kobayashi", initials: "HK", name: "Haruto Kobayashi", email: "haruto.kobayashi@mail.com", address: "81 Al Fahidi St, London", group: "approved", status: "Approved", nicStatus: "matched", submitted: "5mo ago" },
    { id: "layla-osman", initials: "LO", name: "Layla Osman", email: "layla.osman@mail.com", address: "9 Dundas St, Dubai", group: "pending", status: "Pending", nicStatus: "mismatch", submitted: "2h ago" },
    { id: "jamie-reyes", initials: "JR", name: "Jamie Reyes", email: "jamie.reyes@mail.com", address: "12 Roppongi Hills Ave, Tokyo", group: "pending", status: "Pending", nicStatus: "mismatch", submitted: "1d ago" },
  ];
}

export function getVenues(): Record<string, VenueBase[]> {
  return {
    "kenji-yamamoto": [
      { id: "neon-fox", name: "Neon Fox", city: "Melbourne", address: "26 Al Fahidi St, Melbourne", capacity: 420, licence: "VIC-LIQ-88214", licenceExpiry: "31 Mar 2027", hours: "Wed–Sun · 21:00–04:00", events: 38, assigned: "22 Jul 2026", gps: true, phone: "+61 3 8765 4321" },
      { id: "fox-annex", name: "Fox Annex", city: "Melbourne", address: "30 Al Fahidi St, Melbourne", capacity: 140, licence: "VIC-LIQ-88219", licenceExpiry: "31 Mar 2027", hours: "Fri–Sat · 22:00–03:00", events: 14, assigned: "04 Aug 2026", gps: false, phone: "+61 3 8765 4399" },
    ],
    "casey-alfarsi": [
      { id: "warehouse-9", name: "Warehouse 9", city: "Tokyo", address: "53 Collins St, Tokyo", capacity: 900, licence: "TYO-NC-40127", licenceExpiry: "12 Dec 2026", hours: "Fri–Sun · 22:00–05:00", events: 41, assigned: "08 Jul 2026", gps: true, phone: "+81 3 4567 8901" },
    ],
    "sara-whitfield": [
      { id: "full-moon", name: "Full Moon Rooftop", city: "Melbourne", address: "77 Shibuya Crossing, Melbourne", capacity: 310, licence: "VIC-LIQ-77032", licenceExpiry: "30 Jun 2027", hours: "Thu–Sat · 20:00–02:00", events: 29, assigned: "01 Jul 2026", gps: true, phone: "+61 3 9012 3456" },
    ],
    "riley-khan": [
      { id: "brick-lane", name: "Brick Lane Social", city: "Melbourne", address: "2 Brick Lane, Melbourne", capacity: 260, licence: "VIC-LIQ-51188", licenceExpiry: "28 Feb 2027", hours: "Wed–Sat · 19:00–01:00", events: 18, assigned: "09 Jun 2026", gps: true, phone: "+61 3 2345 6789" },
    ],
    "yuki-walker": [
      { id: "chapel-underground", name: "Chapel Underground", city: "Tokyo", address: "43 Chapel St, Tokyo", capacity: 480, licence: "TYO-NC-31904", licenceExpiry: "09 Sep 2026", hours: "Fri–Sat · 23:00–05:00", events: 7, assigned: "15 Apr 2026", gps: false, phone: "+81 3 5678 1234" },
    ],
    "haruto-kobayashi": [
      { id: "fahidi-social", name: "Fahidi Social Club", city: "London", address: "81 Al Fahidi St, London", capacity: 350, licence: "LDN-PRM-20447", licenceExpiry: "31 Jan 2027", hours: "Tue–Sun · 20:00–03:00", events: 44, assigned: "20 Mar 2026", gps: true, phone: "+44 20 7946 0958" },
      { id: "fahidi-basement", name: "The Basement", city: "London", address: "81a Al Fahidi St, London", capacity: 180, licence: "LDN-PRM-20448", licenceExpiry: "31 Jan 2027", hours: "Fri–Sat · 22:00–04:00", events: 19, assigned: "02 May 2026", gps: true, phone: "+44 20 7946 0960" },
    ],
  };
}

export function getDetailExtra(): Record<string, DetailExtra> {
  return {
    "kenji-yamamoto": { nicNameOnId: "Kenji Yamamoto", nicNumber: "198821400339", nicSubmittedDate: "Jul 22, 2026, 2:15 PM", club: "Neon Fox", clubLocation: "Melbourne", eventsCreated: 52, phone: "+61 3 8765 4321", videoState: "after", videoSentAgo: "3w ago" },
    "casey-alfarsi": { nicNameOnId: "Casey Al-Farsi", nicNumber: "199133100714", nicSubmittedDate: "Jul 8, 2026, 11:02 AM", club: "Warehouse 9", clubLocation: "Tokyo", eventsCreated: 41, phone: "+81 3 4567 8901", videoState: "after", videoSentAgo: "5w ago" },
    "sara-whitfield": { nicNameOnId: "Sara Whitfield", nicNumber: "198964201192", nicSubmittedDate: "Jul 1, 2026, 4:30 PM", club: "Full Moon Rooftop", clubLocation: "Melbourne", eventsCreated: 29, phone: "+61 3 9012 3456", videoState: "after", videoSentAgo: "6w ago" },
    "riley-khan": { nicNameOnId: "Riley Khan", nicNumber: "199510800256", nicSubmittedDate: "Jun 9, 2026, 9:12 AM", club: "Brick Lane Social", clubLocation: "Melbourne", eventsCreated: 18, phone: "+61 3 2345 6789", videoState: "after", videoSentAgo: "9w ago" },
    "yuki-walker": { nicNameOnId: "Yuki Sato", nicNumber: "199371500481", nicSubmittedDate: "Apr 15, 2026, 1:45 PM", club: "Chapel Underground", clubLocation: "Tokyo", eventsCreated: 7, phone: "+81 3 5678 1234", videoState: "after", videoSentAgo: "4mo ago" },
    "haruto-kobayashi": { nicNameOnId: "Haruto Kobayashi", nicNumber: "198709600137", nicSubmittedDate: "Mar 20, 2026, 10:00 AM", club: "Fahidi Social Club", clubLocation: "London", eventsCreated: 63, phone: "+44 20 7946 0958", videoState: "after", videoSentAgo: "5mo ago" },
    "layla-osman": { nicNameOnId: "Layla Osman", nicNumber: "199457300128", nicOtherNames: "L. Osman", nicDob: "14 Mar 1994", nicSex: "Female", nicAddress: "42/3 Galle Rd, Colombo 06", nicIssued: "02 Jun 2019", nicSerial: "SLN-0447 2210", ip: "94.204.11.83", device: "iPhone 15 · iOS 19.2", accountAge: "2 hours", signupDate: "13 Aug 2026 · 04:58", nicSubmittedDate: "Aug 12, 2026, 7:05 AM", venueName: "Dune & Dial", address: "42/3 Galle Rd, Colombo 06", clubLocation: "Dubai", phone: "+971 50 123 4567", videoState: "before", videoSentAgo: null },
    "jamie-reyes": { nicNameOnId: "Jameson Reyes", nicNumber: "199026304417", nicOtherNames: "J. Reyes", nicDob: "20 Sep 1990", nicSex: "Male", nicAddress: "118 Hill St, Kandy", nicIssued: "17 Nov 2021", nicSerial: "SLN-1902 8871", ip: "133.106.44.19", device: "Pixel 9 · Android 17", accountAge: "1 day", signupDate: "12 Aug 2026 · 09:40", nicSubmittedDate: "Aug 11, 2026, 9:40 AM", venueName: "Roppongi Late Room", address: "118 Hill St, Kandy", clubLocation: "Tokyo", phone: "+81 90 1234 5678", videoState: "after", videoSentAgo: "6d ago" },
  };
}

export const KPIS = [
  { label: "Pending applications", value: "12", delta: "+3 today", icon: "how_to_reg", cardBg: "#2A1A22", iconColor: "#FFB1C4", deltaColor: "#7BE0A8" },
  { label: "Events in review", value: "27", delta: "+8 today", icon: "event_available", cardBg: "#1B181B", iconColor: "#A5F2E5", deltaColor: "#7BE0A8" },
  { label: "Active venues", value: "184", delta: "4 cities", icon: "storefront", cardBg: "#1B181B", iconColor: "#A5F2E5", deltaColor: "#CFC0C5" },
  { label: "Active organizers", value: "96", delta: "+2 this week", icon: "group", cardBg: "#1B181B", iconColor: "#A5F2E5", deltaColor: "#7BE0A8" },
];

export const ACTIVITY = [
  { status: "Pending review", icon: "how_to_reg", color: "#F5C452", fill: "#42320A", text: "Warehouse 9 (Tokyo) applied to become an organizer", time: "4m ago" },
  { status: "Approved", icon: "check_circle", color: "#7BE0A8", fill: "#0F3D28", text: 'Neon Fox submitted "Full Moon Rooftop" — approved', time: "18m ago" },
  { status: "Flagged", icon: "content_copy", color: "#FFB4AB", fill: "#5C1218", text: 'Duplicate venue detected: "Club Sirens" vs "Sirens Dubai"', time: "41m ago" },
  { status: "Rejected", icon: "cancel", color: "#FFB4AB", fill: "#5C1218", text: 'Event "VIP Boat Party" rejected — missing venue details', time: "1h ago" },
  { status: "Access change", icon: "admin_panel_settings", color: "#A5F2E5", fill: "#1F4F49", text: "Admin @lena granted moderator scope to @marco", time: "2h ago" },
];

export const INSTRUCTION_PRESETS = [
  { label: "Standard walkthrough", text: "Please record a short video walkthrough of your venue (entrance, main floor, and bar/DJ booth) and send it back here so we can complete your verification." },
  { label: "Fire exits & safety", text: "Please record a walkthrough showing all fire exits, extinguishers, and posted occupancy limits, in addition to the main floor." },
  { label: "Capacity & seating", text: "Please record a walkthrough showing the seating layout, bar area, and any VIP or reserved sections so we can confirm your listed capacity." },
];

export const NAV_GROUPS_DEF = [
  { label: "Overview", items: [{ id: "overview", label: "Dashboard", icon: "space_dashboard" }] },
  {
    label: "Content review",
    items: [
      { id: "org-apps", label: "Organizer applications", icon: "how_to_reg", showsPendingCount: true },
      { id: "event-queue", label: "Event review queue", icon: "event_available", count: 27 },
    ],
  },
  {
    label: "Directory",
    items: [
      { id: "venues", label: "Venues", icon: "storefront" },
      { id: "users", label: "Users & organizers", icon: "group" },
    ],
  },
  {
    label: "System",
    items: [
      { id: "roles", label: "Roles & access", icon: "admin_panel_settings" },
      { id: "audit", label: "Audit log", icon: "history" },
      { id: "settings", label: "Settings", icon: "settings" },
    ],
  },
];

export const SECTION_TITLES: Record<string, [string, string]> = {
  overview: ["Dashboard", "Tonight's snapshot across all cities"],
  "org-apps": ["Organizer applications", "Review requests to become an organizer"],
  "event-queue": ["Event review queue", "Approve or reject submitted events"],
  venues: ["Venues", "All clubs and venues on the platform"],
  users: ["Users & organizers", "Party-goers and approved organizers"],
  roles: ["Roles & access", "Admin permissions and scopes"],
  audit: ["Audit log", "Who did what, and when"],
  settings: ["Settings", "Platform configuration"],
};

export type StepStatusValue = "verified" | "failed" | "review" | "awaiting" | "resubmit";

export function stepChrome(status: StepStatusValue) {
  const map: Record<StepStatusValue, { statusLabel: string; statusIcon: string; type: BadgeType }> = {
    verified: { statusLabel: "Verified", statusIcon: "check_circle", type: "success" },
    failed: { statusLabel: "Failed", statusIcon: "cancel", type: "danger" },
    review: { statusLabel: "Needs review", statusIcon: "error", type: "warning" },
    awaiting: { statusLabel: "Awaiting organizer", statusIcon: "schedule", type: "neutral" },
    resubmit: { statusLabel: "Re-submission requested", statusIcon: "refresh", type: "info" },
  };
  const m = map[status] ?? map.review;
  const c = badgeColors(m.type);
  return { ...m, bg: c.bg, fg: c.fg };
}
