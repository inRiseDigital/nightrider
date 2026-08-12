"use client";

import { Check } from "lucide-react";
import { useOrganizerDashboard, useNow } from "@/lib/organizer/dashboard/store";
import { deriveEventChip, venueName } from "@/lib/organizer/dashboard/format";
import { MOCK_KPIS } from "@/lib/organizer/dashboard/mock-data";
import { PanelCard } from "../ui/Primitives";
import { StatusChip } from "../ui/StatusChip";

export function OverviewSection() {
  const { events, venues, venueOrder } = useOrganizerDashboard();
  const now = useNow();

  // Everything except cancelled events, soonest first.
  const upcoming = events
    .filter((e) => e.status !== "cancelled")
    .slice()
    .sort((a, b) => a.date.localeCompare(b.date))
    .slice(0, 5);

  return (
    <>
      <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {MOCK_KPIS.map((kpi) => (
          <div key={kpi.label} className="rounded-lg border border-nr-border bg-nr-surface p-[18px]">
            <p className="text-xs text-nr-text-secondary">{kpi.label}</p>
            <p className="mt-2 font-display text-[32px] leading-none text-nr-text-primary">
              {kpi.value}
            </p>
            <p className={`mt-1.5 font-mono text-[11px] ${kpi.deltaClass}`}>{kpi.delta}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 items-start gap-4 lg:grid-cols-[1.4fr_1fr]">
        <PanelCard title="Upcoming Events">
          {upcoming.map((ev) => {
            const chip = deriveEventChip(ev, now);
            return (
              <div
                key={ev.id}
                className="flex items-center gap-3.5 border-b border-nr-border/60 px-[18px] py-3.5 last:border-b-0"
              >
                <div className="h-11 w-11 shrink-0 rounded-lg border border-nr-border bg-[repeating-linear-gradient(45deg,#17171A,#17171A_6px,#0F0F0F_6px,#0F0F0F_12px)]" />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-[13px] font-semibold text-nr-text-primary">{ev.name}</p>
                  <p className="mt-0.5 font-mono text-[11px] text-nr-text-hint">
                    {venueName(venues, ev.venue)} · {ev.date}
                  </p>
                </div>
                <StatusChip label={chip.label} className={chip.className} />
                <p className="w-16 shrink-0 text-right font-mono text-xs text-nr-text-secondary">
                  {ev.tiers.length ? `${ev.tiers.reduce((s, t) => s + t.qty, 0)} qty` : "—"}
                </p>
              </div>
            );
          })}
        </PanelCard>

        <div className="flex flex-col gap-4">
          <PanelCard title="Your Venues">
            {venueOrder.map((id) => (
              <div
                key={id}
                className="flex items-center gap-3 border-b border-nr-border/60 px-[18px] py-3 last:border-b-0"
              >
                <span
                  className={`h-2 w-2 shrink-0 rounded-full ${
                    venues[id].verified ? "bg-nr-accent" : "bg-nr-text-hint"
                  }`}
                />
                <div className="min-w-0 flex-1">
                  <p className="text-[13px] font-semibold text-nr-text-primary">{venues[id].name}</p>
                  <p className="mt-px font-mono text-[11px] text-nr-text-hint">{venues[id].city}</p>
                </div>
              </div>
            ))}
          </PanelCard>

          <div className="rounded-lg border border-nr-border bg-nr-surface p-[18px]">
            <h2 className="mb-3 font-display text-sm uppercase tracking-wider text-nr-text-primary">
              Application Status
            </h2>
            <div className="flex items-center gap-3">
              <span className="flex h-[26px] w-[26px] shrink-0 items-center justify-center rounded-full bg-emerald-500/10 text-emerald-400">
                <Check size={14} strokeWidth={3} />
              </span>
              <div>
                <p className="text-[13px] font-semibold text-nr-text-primary">Verified organizer</p>
                <p className="mt-0.5 font-mono text-[11px] text-emerald-400">Approved</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
