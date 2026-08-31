"use client";

import { History } from "lucide-react";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { PanelCard } from "../ui/Primitives";

/** Home tab — a feed of recent account activity, same data TeamSection's
 *  "Activity Log" panel already uses. */
export function ActivitySection() {
  const { activity } = useOrganizerDashboard();

  return (
    <PanelCard title="Activity">
      {activity.length === 0 ? (
        <p className="px-[18px] py-5 text-xs text-[var(--m3-outline)]">No recent activity.</p>
      ) : (
        activity.map((a, i) => (
          <div
            key={i}
            className="flex items-start gap-3.5 border-b border-[var(--m3-outlinev)] px-[18px] py-3.5 last:border-b-0"
          >
            <span
              className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-full"
              style={{ background: "var(--m3-surf3)", color: "var(--m3-onv)" }}
            >
              <History size={15} />
            </span>
            <div className="min-w-0 flex-1">
              <p className="text-[13px] text-[var(--m3-on)]">
                <span className="font-semibold">{a.who}</span> {a.what}
              </p>
              <p className="mt-1 font-mono text-[11px] text-[var(--m3-outline)]">{a.when}</p>
            </div>
          </div>
        ))
      )}
    </PanelCard>
  );
}
