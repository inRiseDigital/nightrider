"use client";

import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { pct } from "@/lib/organizer/dashboard/format";
import {
  MOCK_AGE_BANDS,
  MOCK_FUNNEL,
  MOCK_GENRE_FOLLOWS,
  MOCK_LOCAL_SPLIT,
} from "@/lib/organizer/dashboard/mock-data";
import { Chip, FieldLabel, VenueSwitcher } from "../ui/Primitives";

export function PerformanceSection() {
  const {
    venueOrder,
    venues,
    events,
    perfVenueFilter,
    setPerfVenueFilter,
    perfEventId,
    setPerfEventId,
  } = useOrganizerDashboard();

  // Only events an audience can actually see have a funnel.
  const perfEvents = events.filter(
    (e) =>
      (e.status === "live" || e.status === "scheduled" || e.status === "in_review") &&
      (perfVenueFilter === "all" || e.venue === perfVenueFilter)
  );

  const funnel = [
    { label: "Views", value: MOCK_FUNNEL.views, width: "100%" },
    { label: "Saves", value: MOCK_FUNNEL.saves, width: pct(MOCK_FUNNEL.saves, MOCK_FUNNEL.views) },
    {
      label: "Directions",
      value: MOCK_FUNNEL.directions,
      width: pct(MOCK_FUNNEL.directions, MOCK_FUNNEL.views),
    },
  ];

  return (
    <>
      <VenueSwitcher
        venueOrder={venueOrder}
        venues={venues}
        selected={perfVenueFilter}
        onSelect={setPerfVenueFilter}
        includeAll
      />

      <div className="mb-[18px] flex flex-wrap gap-2">
        {perfEvents.length === 0 ? (
          <p className="text-xs text-nr-text-hint">No live or scheduled events for this venue.</p>
        ) : (
          perfEvents.map((e) => (
            <Chip
              key={e.id}
              label={e.name}
              active={perfEventId === e.id}
              onClick={() => setPerfEventId(e.id)}
              shape="rounded"
            />
          ))
        )}
      </div>

      <div className="mb-4 rounded-lg border border-nr-border bg-nr-surface p-5">
        <FieldLabel className="mb-3.5">Views → Saves → Directions</FieldLabel>
        {funnel.map((stage) => (
          <div key={stage.label} className="mb-2.5 flex items-center gap-3">
            <span className="w-[110px] shrink-0 text-xs text-nr-text-secondary">{stage.label}</span>
            <span className="h-5 flex-1 overflow-hidden rounded-md bg-nr-surface-raised">
              <span className="block h-full rounded-md bg-nr-primary" style={{ width: stage.width }} />
            </span>
            <span className="w-[70px] shrink-0 text-right font-mono text-xs text-nr-text-primary">
              {stage.value.toLocaleString()}
            </span>
          </div>
        ))}
      </div>

      <div className="mb-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="rounded-lg border border-nr-border bg-nr-surface p-[18px]">
          <FieldLabel>Week over week</FieldLabel>
          <p className="mt-1.5 font-display text-[26px] leading-none text-nr-text-primary">
            640 directions
          </p>
          <p className="mt-1 font-mono text-[11px] text-emerald-400">+18% vs last week</p>
        </div>
        <div className="rounded-lg border border-nr-border bg-nr-surface p-[18px]">
          <FieldLabel>Same night, last month</FieldLabel>
          <p className="mt-1.5 font-display text-[26px] leading-none text-nr-text-primary">
            520 directions
          </p>
          <p className="mt-1 font-mono text-[11px] text-red-400">-6% vs same night last month</p>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <BreakdownCard title="Age band" rows={MOCK_AGE_BANDS} />
        <BreakdownCard title="Local vs tourist" rows={MOCK_LOCAL_SPLIT} />
        <BreakdownCard title="Top followed genres" rows={MOCK_GENRE_FOLLOWS} />
      </div>

      <p className="mt-3 text-[11px] text-nr-text-hint">
        Aggregated and anonymised — shown only above the platform&apos;s minimum group-size
        threshold. No individual profiles.
      </p>
    </>
  );
}

function BreakdownCard({ title, rows }: { title: string; rows: { label: string; pct: string }[] }) {
  return (
    <div className="rounded-lg border border-nr-border bg-nr-surface p-4">
      <p className="mb-2.5 text-[11px] text-nr-text-secondary">{title}</p>
      {rows.map((r) => (
        <div key={r.label} className="flex justify-between py-1 text-xs text-nr-text-primary">
          <span>{r.label}</span>
          <span className="font-mono text-nr-text-secondary">{r.pct}</span>
        </div>
      ))}
    </div>
  );
}
