/**
 * Sidebar nav — 5 flat destinations, matching the design's rail (Home, Events,
 * Venue, Audience, Account). Each destination is a single route; sub-views
 * within it are switched by an in-page tab strip (see each destination's
 * `page.tsx` and the corresponding `*Tab` state in the dashboard store), not
 * by separate nav entries.
 */
export interface OrganizerNavItem {
  href: string;
  label: string;
  title: string;
  subtitle: string;
  /** Material Symbols icon name, used by the icon rail and drawer. */
  icon: string;
  /** Set on "Events" — filled in at render time with the live event count. */
  badge?: "liveEvents";
}

export const ORGANIZER_NAV_ITEMS: OrganizerNavItem[] = [
  {
    href: "/organizer/dashboard",
    label: "Home",
    title: "Home",
    subtitle: "Tonight's live ops and your events at a glance",
    icon: "space_dashboard",
  },
  {
    href: "/organizer/events",
    label: "Events",
    title: "Events",
    subtitle: "Drafts, submissions, published events, and your calendar",
    icon: "event",
    badge: "liveEvents",
  },
  {
    href: "/organizer/venues",
    label: "Venue",
    title: "Venue",
    subtitle: "Gallery, attributes, hours & links — with a live app preview",
    icon: "storefront",
  },
  {
    href: "/organizer/performance",
    label: "Audience",
    title: "Audience",
    subtitle: "Funnel, reviews, and AI visibility",
    icon: "insights",
  },
  {
    href: "/organizer/account",
    label: "Account",
    title: "Account",
    subtitle: "Team, inbox, promotion, and settings",
    icon: "manage_accounts",
  },
];

export function findNavItem(pathname: string | null): OrganizerNavItem | undefined {
  if (!pathname) return undefined;
  return ORGANIZER_NAV_ITEMS.find(
    (item) => pathname === item.href || pathname.startsWith(item.href + "/")
  );
}
