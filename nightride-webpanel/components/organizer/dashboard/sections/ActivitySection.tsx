"use client";

import {
  AlertTriangle,
  BadgeCheck,
  History,
  Megaphone,
  Pencil,
  Ticket,
  Upload,
  type LucideIcon,
} from "lucide-react";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { PanelCard } from "../ui/Primitives";

/**
 * Entries are free text, so the icon is inferred from what the line says. The
 * fallback is deliberately generic rather than wrong.
 */
function iconFor(text: string): { Icon: LucideIcon; bg: string; fg: string } {
  const t = text.toLowerCase();
  if (t.includes("flag") || t.includes("duplicate") || t.includes("violation"))
    return { Icon: AlertTriangle, bg: "var(--m3-warnc)", fg: "var(--m3-onwarnc)" };
  if (t.includes("reinstate") || t.includes("approved") || t.includes("verified"))
    return { Icon: BadgeCheck, bg: "var(--m3-succ)", fg: "var(--m3-onsucc)" };
  if (t.includes("ticket") || t.includes("sold") || t.includes("price"))
    return { Icon: Ticket, bg: "var(--m3-pric)", fg: "var(--m3-onpric)" };
  if (t.includes("offer") || t.includes("push") || t.includes("broadcast"))
    return { Icon: Megaphone, bg: "var(--m3-terc)", fg: "var(--m3-onterc)" };
  if (t.includes("published") || t.includes("live status") || t.includes("submitted"))
    return { Icon: Upload, bg: "var(--m3-terc)", fg: "var(--m3-onterc)" };
  if (t.includes("changed") || t.includes("edited") || t.includes("updated"))
    return { Icon: Pencil, bg: "var(--m3-surf3)", fg: "var(--m3-onv)" };
  return { Icon: History, bg: "var(--m3-surf3)", fg: "var(--m3-onv)" };
}

/** Home tab — a timeline of recent account activity. */
export function ActivitySection() {
  const { activity, activityLoading, activityError } = useOrganizerDashboard();

  return (
    <PanelCard title="Activity" className="max-w-[820px]">
      {activityError && (
        <p className="px-5 pb-2 text-xs text-[var(--m3-err)]">Couldn&apos;t load activity: {activityError}</p>
      )}
      {activityLoading ? (
        <p className="px-5 py-5 text-xs text-[var(--m3-outline)]">Loading…</p>
      ) : activity.length === 0 ? (
        <p className="px-5 py-5 text-xs text-[var(--m3-outline)]">No recent activity.</p>
      ) : (
        activity.map((a, i) => {
          const { Icon, bg, fg } = iconFor(`${a.who} ${a.what}`);
          const last = i === activity.length - 1;
          return (
            // Vertical padding sits on the text, not the row, so the rule can
            // run unbroken from one icon down to the next.
            <div key={i} className="flex gap-4 px-5">
              <div className="flex shrink-0 flex-col items-center pt-3.5">
                <span
                  className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full"
                  style={{ background: bg, color: fg }}
                >
                  <Icon size={16} />
                </span>
                {/* The rule joins one entry to the next, so the last has none. */}
                {!last && (
                  <span className="w-0.5 flex-1" style={{ background: "var(--m3-outlinev)" }} />
                )}
              </div>
              <div className="min-w-0 flex-1 py-3.5">
                <p className="text-sm text-[var(--m3-on)]">
                  <span className="font-medium">{a.who}</span> {a.what}
                </p>
                <p className="mt-0.5 font-mono text-xs text-[var(--m3-onv)]">{a.when}</p>
              </div>
            </div>
          );
        })
      )}
    </PanelCard>
  );
}
