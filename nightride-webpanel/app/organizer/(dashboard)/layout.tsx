import type { ReactNode } from "react";
import { Roboto, Roboto_Mono } from "next/font/google";
import { DashboardShell } from "@/components/organizer/dashboard/DashboardShell";
import { OrganizerGate } from "@/components/organizer/dashboard/OrganizerGate";
import { OrganizerAuthProvider } from "@/lib/organizer/dashboard/auth";
import { OrganizerDashboardProvider } from "@/lib/organizer/dashboard/store";
import "./organizer-material.css";

/**
 * Route group for the approved-organizer dashboard.
 *
 * `(dashboard)` adds no URL segment, so these routes stay at /organizer/* while
 * keeping the apply flow (app/organizer/apply) out of this chrome. Both still
 * nest inside app/organizer/layout.tsx, which supplies the Anton display font
 * and the page background.
 *
 * Visually this route group runs its own Material Design 3 dark theme (see
 * `organizer-material.css`) rather than the NightRide brand tokens the rest
 * of the app uses — scoped to the `.organizer-m3` wrapper below.
 */
export const metadata = {
  title: "Organizer Panel — Night Ride",
  description: "Manage your venues, events, and tonight's door status on Night Ride.",
};

const roboto = Roboto({
  weight: ["400", "500", "700"],
  subsets: ["latin"],
  variable: "--font-m3-sans",
});

const robotoMono = Roboto_Mono({
  weight: ["400", "500"],
  subsets: ["latin"],
  variable: "--font-m3-mono",
});

export default function OrganizerDashboardLayout({ children }: { children: ReactNode }) {
  return (
    <OrganizerAuthProvider>
      <link
        href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0&display=swap"
        rel="stylesheet"
      />
      <div
        className={`organizer-m3 ${roboto.variable} ${robotoMono.variable} flex min-h-0 flex-1`}
        style={{ fontFamily: "var(--font-m3-sans), sans-serif" }}
      >
        {/*
         * OrganizerGate renders every non-"approved" auth state (loading,
         * unconfigured, signed-out, pending, rejected) inside this themed
         * wrapper so a gate card never loses the dashboard's M3 look. Only
         * once it reports "approved" does OrganizerDashboardProvider — and
         * therefore any real Firestore read — mount at all.
         */}
        <OrganizerGate>
          <OrganizerDashboardProvider>
            <DashboardShell>{children}</DashboardShell>
          </OrganizerDashboardProvider>
        </OrganizerGate>
      </div>
    </OrganizerAuthProvider>
  );
}
