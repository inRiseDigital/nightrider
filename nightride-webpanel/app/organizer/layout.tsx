import type { CSSProperties, ReactNode } from "react";
import { Anton } from "next/font/google";
import { ACCENT_THEMES, ACTIVE_ACCENT } from "@/lib/organizer/constants";

const antonDisplay = Anton({
  weight: "400",
  subsets: ["latin"],
  variable: "--font-nr-display",
});

const accent = ACCENT_THEMES[ACTIVE_ACCENT];

/**
 * The accent is exposed as CSS variables rather than fixed Tailwind colours so
 * swapping ACTIVE_ACCENT re-themes every surface in the flow at once.
 */
const accentVars = {
  "--org-accent": accent.color,
  "--org-accent-hover": accent.hover,
  "--org-accent-ring": accent.ring,
  "--org-accent-fill": accent.fill,
} as CSSProperties;

export const metadata = {
  title: "Organizer Application — Night Ride",
  description: "Apply to publish events on Night Ride as a venue organizer.",
};

export default function OrganizerLayout({ children }: { children: ReactNode }) {
  return (
    <div
      className={`${antonDisplay.variable} flex h-dvh flex-col overflow-hidden bg-nr-bg font-sans text-nr-text-primary`}
      style={accentVars}
    >
      {children}
    </div>
  );
}
