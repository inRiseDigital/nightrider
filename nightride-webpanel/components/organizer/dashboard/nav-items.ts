/**
 * Sidebar nav, grouped exactly as the design's `navGroups`. Each entry also
 * carries the topbar title/subtitle for its route.
 */
export interface OrganizerNavItem {
  href: string;
  label: string;
  title: string;
  subtitle: string;
  /** Material Symbols icon name, used by the icon rail and drawer. */
  icon: string;
  /** Set on "My Events" — filled in at render time with the live event count. */
  badge?: "liveEvents";
}

export interface OrganizerNavGroup {
  label: string;
  /** Material Symbols icon name for this group's icon-rail entry (its first item). */
  icon: string;
  items: OrganizerNavItem[];
}

export const ORGANIZER_NAV_GROUPS: OrganizerNavGroup[] = [
  {
    label: "OVERVIEW",
    icon: "space_dashboard",
    items: [
      {
        href: "/organizer/dashboard",
        label: "Dashboard",
        title: "Dashboard",
        subtitle: "Your events and venues at a glance",
        icon: "space_dashboard",
      },
    ],
  },
  {
    label: "EVENTS",
    icon: "event",
    items: [
      {
        href: "/organizer/events",
        label: "My Events",
        title: "My Events",
        subtitle: "Drafts, submissions, and published events",
        icon: "event",
        badge: "liveEvents",
      },
      {
        href: "/organizer/calendar",
        label: "Calendar",
        title: "Calendar",
        subtitle: "Your month at a glance — conflicts and gaps visible",
        icon: "calendar_month",
      },
    ],
  },
  {
    label: "VENUES",
    icon: "storefront",
    items: [
      {
        href: "/organizer/venues",
        label: "My Venues",
        title: "My Venues",
        subtitle: "Gallery, attributes, hours & links — with a live app preview",
        icon: "storefront",
      },
    ],
  },
  {
    label: "TONIGHT",
    icon: "nightlife",
    items: [
      {
        href: "/organizer/tonight",
        label: "Tonight",
        title: "Tonight",
        subtitle: "Live door status, queue, and instant broadcasts",
        icon: "nightlife",
      },
    ],
  },
  {
    label: "PERFORMANCE",
    icon: "insights",
    items: [
      {
        href: "/organizer/performance",
        label: "Performance",
        title: "Performance",
        subtitle: "Per-event funnel and trend comparisons",
        icon: "insights",
      },
      {
        href: "/organizer/ai-visibility",
        label: "AI Visibility",
        title: "AI Visibility",
        subtitle: "How the AI companion discovers and recommends you",
        icon: "smart_toy",
      },
    ],
  },
  {
    label: "PROMOTION",
    icon: "campaign",
    items: [
      {
        href: "/organizer/promotion",
        label: "Promotion",
        title: "Promotion",
        subtitle: "Push, guest list, perks, and boosted placement",
        icon: "campaign",
      },
    ],
  },
  {
    label: "ACCOUNT",
    icon: "person",
    items: [
      {
        href: "/organizer/team",
        label: "Team & Access",
        title: "Team & Access",
        subtitle: "Scoped roles and an activity trail",
        icon: "group",
      },
      {
        href: "/organizer/reviews",
        label: "Reviews",
        title: "Reviews",
        subtitle: "Reply and flag from one place",
        icon: "reviews",
      },
      {
        href: "/organizer/inbox",
        label: "Inbox",
        title: "Inbox",
        subtitle: "Admin, policy, and appeal messages",
        icon: "inbox",
      },
      {
        href: "/organizer/settings",
        label: "Settings",
        title: "Settings",
        subtitle: "Organizer profile and preferences",
        icon: "settings",
      },
    ],
  },
];

export const ORGANIZER_NAV_ITEMS = ORGANIZER_NAV_GROUPS.flatMap((g) => g.items);

export function findNavItem(pathname: string | null): OrganizerNavItem | undefined {
  if (!pathname) return undefined;
  return ORGANIZER_NAV_ITEMS.find(
    (item) => pathname === item.href || pathname.startsWith(item.href + "/")
  );
}
