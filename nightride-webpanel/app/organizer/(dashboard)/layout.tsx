import type { ReactNode } from "react";
import { DashboardShell } from "@/components/organizer/dashboard/DashboardShell";
import { OrganizerDashboardProvider } from "@/lib/organizer/dashboard/store";

/**
 * Route group for the approved-organizer dashboard.
 *
 * `(dashboard)` adds no URL segment, so these routes stay at /organizer/* while
 * keeping the apply flow (app/organizer/apply) out of this chrome. Both still
 * nest inside app/organizer/layout.tsx, which supplies the Anton display font
 * and the page background.
 */
export const metadata = {
  title: "Organizer Panel — Night Ride",
  description: "Manage your venues, events, and tonight's door status on Night Ride.",
};

export default function OrganizerDashboardLayout({ children }: { children: ReactNode }) {
  return (
    <OrganizerDashboardProvider>
      <div className="flex min-h-0 flex-1">
        <DashboardShell>{children}</DashboardShell>
      </div>
    </OrganizerDashboardProvider>
  );
}
