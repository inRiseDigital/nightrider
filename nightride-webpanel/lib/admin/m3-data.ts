// Static UI data for the Material Design 3 admin console: nav structure,
// section titles, and the shared badge color palette. Application data
// (applicants, venues, logs, KPIs) is fetched live — see lib/admin/firestore.ts.

export type BadgeType = "success" | "warning" | "danger" | "info" | "neutral";

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

export const NAV_GROUPS_DEF = [
  { label: "Overview", items: [{ id: "overview", label: "Dashboard", icon: "space_dashboard" }] },
  {
    label: "Content review",
    items: [
      { id: "org-apps", label: "Organizer applications", icon: "how_to_reg", showsPendingCount: true },
      { id: "event-queue", label: "Event review queue", icon: "event_available", showsPendingCount: true },
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
    ],
  },
];

export const SECTION_TITLES: Record<string, [string, string]> = {
  overview: ["Dashboard", "Tonight's snapshot across all cities"],
  "org-apps": ["Organizer applications", "Review requests to become an organizer"],
  "event-queue": ["Event review queue", "Approve or reject submitted events"],
  venues: ["Venues", "All clubs and venues on the platform"],
  users: ["Users & organizers", "Party-goers and approved organizers"],
  roles: ["Roles & access", "Who holds admin access to the console"],
  audit: ["Audit log", "Who did what, and when"],
};
