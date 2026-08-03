import {
  LayoutDashboard,
  Users,
  UserCog,
  ShieldCheck,
  KeyRound,
  Building2,
  CalendarDays,
  ScrollText,
} from "lucide-react";

export const ADMIN_NAV_ITEMS = [
  { href: "/admin/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/admin/users", label: "Users", icon: Users },
  { href: "/admin/organizers", label: "Organizers", icon: UserCog },
  { href: "/admin/admins", label: "Admins", icon: ShieldCheck },
  { href: "/admin/roles", label: "Roles & Permissions", icon: KeyRound },
  { href: "/admin/clubs", label: "Clubs", icon: Building2 },
  { href: "/admin/events", label: "Events", icon: CalendarDays },
  { href: "/admin/activity", label: "Activity Logs", icon: ScrollText },
];
