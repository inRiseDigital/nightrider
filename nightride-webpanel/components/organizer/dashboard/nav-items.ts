/**
 * Sidebar nav, grouped exactly as the design's `navGroups`. Each entry also
 * carries the topbar title/subtitle for its route.
 */
export interface OrganizerNavItem {
  href: string;
  label: string;
  title: string;
  subtitle: string;
  /** Set on "My Events" — filled in at render time with the live event count. */
  badge?: "liveEvents";
}

export interface OrganizerNavGroup {
  label: string;
  items: OrganizerNavItem[];
}

export const ORGANIZER_NAV_GROUPS: OrganizerNavGroup[] = [
  {
    label: "OVERVIEW",
    items: [
      {
        href: "/organizer/dashboard",
        label: "Dashboard",
        title: "Dashboard",
        subtitle: "Your events and venues at a glance",
      },
    ],
  },
  {
    label: "EVENTS",
    items: [
      {
        href: "/organizer/events",
        label: "My Events",
        title: "My Events",
        subtitle: "Drafts, submissions, and published events",
        badge: "liveEvents",
      },
      {
        href: "/organizer/calendar",
        label: "Calendar",
        title: "Calendar",
        subtitle: "Your month at a glance — conflicts and gaps visible",
      },
    ],
  },
  {
    label: "VENUES",
    items: [
      {
        href: "/organizer/venues",
        label: "My Venues",
        title: "My Venues",
        subtitle: "Gallery, attributes, hours & links — with a live app preview",
      },
    ],
  },
  {
    label: "TONIGHT",
    items: [
      {
        href: "/organizer/tonight",
        label: "Tonight",
        title: "Tonight",
        subtitle: "Live door status, queue, and instant broadcasts",
      },
    ],
  },
  {
    label: "PERFORMANCE",
    items: [
      {
        href: "/organizer/performance",
        label: "Performance",
        title: "Performance",
        subtitle: "Per-event funnel and trend comparisons",
      },
      {
        href: "/organizer/ai-visibility",
        label: "AI Visibility",
        title: "AI Visibility",
        subtitle: "How the AI companion discovers and recommends you",
      },
    ],
  },
  {
    label: "PROMOTION",
    items: [
      {
        href: "/organizer/promotion",
        label: "Promotion",
        title: "Promotion",
        subtitle: "Push, guest list, perks, and boosted placement",
      },
    ],
  },
  {
    label: "ACCOUNT",
    items: [
      {
        href: "/organizer/team",
        label: "Team & Access",
        title: "Team & Access",
        subtitle: "Scoped roles and an activity trail",
      },
      {
        href: "/organizer/reviews",
        label: "Reviews",
        title: "Reviews",
        subtitle: "Reply and flag from one place",
      },
      {
        href: "/organizer/inbox",
        label: "Inbox",
        title: "Inbox",
        subtitle: "Admin, policy, and appeal messages",
      },
      {
        href: "/organizer/settings",
        label: "Settings",
        title: "Settings",
        subtitle: "Organizer profile and preferences",
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
