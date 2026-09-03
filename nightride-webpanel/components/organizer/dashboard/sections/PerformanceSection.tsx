"use client";

import { useNow, useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { isEventLive } from "@/lib/organizer/dashboard/format";
import { Card, Chip, FieldLabel, VenueSwitcher } from "../ui/Primitives";

export function PerformanceSection() {
  const {
    venueOrder,
    venues,
    events,
    perfVenueFilter,
    setPerfVenueFilter,
    perfEventId,
    setPerfEventId,
    perfMetrics,
    perfLoading,
    perfError,
  } = useOrganizerDashboard();
  const now = useNow();

  // Only events an audience can actually see have a funnel.
  const perfEvents = events.filter(
    (e) => (isEventLive(e, now) || e.status === "scheduled" || e.status === "in_review") && e.venue === perfVenueFilter
  );

  const attendance = perfMetrics?.attendance ?? [];
  const ceiling = perfMetrics?.attendanceCeiling ?? 0;
  const funnel = perfMetrics?.funnel ?? [];
  const topNights = perfMetrics?.topNights ?? [];
  const ageBands = perfMetrics?.ageBands ?? [];
  const localSplit = perfMetrics?.localSplit ?? [];
  const genreFollows = perfMetrics?.genreFollows ?? [];

  return (
    <>
      <VenueSwitcher venueOrder={venueOrder} venues={venues} selected={perfVenueFilter} onSelect={setPerfVenueFilter} />

      <div className="mb-[18px] flex flex-wrap gap-2">
        {perfEvents.length === 0 ? (
          <p className="text-xs text-[var(--m3-outline)]">No live or scheduled events for this venue.</p>
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

      {perfError && (
        <p className="mb-3 text-xs text-[var(--m3-err)]">Couldn&apos;t load performance data: {perfError}</p>
      )}

      {perfLoading ? (
        <Card className="mb-4 animate-pulse">
          <div className="h-[220px]" />
        </Card>
      ) : !perfMetrics ? (
        <Card className="mb-4">
          <p className="text-sm text-[var(--m3-onv)]">
            No performance data yet for this venue — figures appear once nightly analytics have run.
          </p>
        </Card>
      ) : (
        <>
          <Card className="mb-4">
            <div className="flex flex-wrap items-center justify-between gap-4">
              <h3 className="text-base font-medium tracking-[0.15px] text-[var(--m3-on)]">
                Attendance, last 7 nights
              </h3>
              {attendance.length > 0 && (
                <p className="text-[13px] text-[var(--m3-onv)]">
                  Avg. {perfMetrics.attendanceAvg} guests · peak {perfMetrics.attendancePeak}
                </p>
              )}
            </div>
            {attendance.length === 0 ? (
              <p className="mt-4 text-xs text-[var(--m3-outline)]">No attendance data for this week yet.</p>
            ) : (
              <div className="mt-6 flex h-[220px] items-end gap-4">
                {attendance.map((bar) => (
                  <div key={bar.label} className="flex h-full flex-1 flex-col items-center justify-end gap-2">
                    <span className="font-mono text-xs text-[var(--m3-onv)]">{bar.value || "–"}</span>
                    {/* The bar sizes against this track, not the whole column, so the
                        value and label rows can't squash the tallest nights. */}
                    <div className="flex w-full flex-1 items-end">
                      <div
                        className="w-full rounded-t-lg rounded-b"
                        style={{
                          height: `${ceiling > 0 ? Math.round((bar.value / ceiling) * 100) : 0}%`,
                          background:
                            bar.value > 500 ? "var(--m3-pri)" : bar.value > 0 ? "var(--m3-pric)" : "var(--m3-surf3)",
                        }}
                      />
                    </div>
                    <span className="text-[11px] tracking-[0.5px] text-[var(--m3-onv)]">{bar.label}</span>
                  </div>
                ))}
              </div>
            )}
          </Card>

          <div className="mb-4 grid grid-cols-1 gap-4 lg:grid-cols-2">
            <Card>
              <h3 className="mb-5 text-base font-medium tracking-[0.15px] text-[var(--m3-on)]">Discovery funnel</h3>
              {funnel.length === 0 ? (
                <p className="text-xs text-[var(--m3-outline)]">No funnel data for the last 30 days yet.</p>
              ) : (
                funnel.map((stage) => (
                  <div key={stage.label} className="mb-4 last:mb-0">
                    <div className="mb-1.5 flex justify-between text-[13px]">
                      <span className="text-[var(--m3-on)]">{stage.label}</span>
                      <span className="font-mono text-[var(--m3-onv)]">{stage.value}</span>
                    </div>
                    <div className="h-2 overflow-hidden rounded-full bg-[var(--m3-track)]">
                      <div
                        className="h-full rounded-full"
                        style={{ width: stage.width, background: stage.tone === "primary" ? "var(--m3-pri)" : "var(--m3-ter)" }}
                      />
                    </div>
                  </div>
                ))
              )}
            </Card>

            <Card className="!p-0 py-2">
              <h3 className="px-5 pb-2 pt-3 text-base font-medium tracking-[0.15px] text-[var(--m3-on)]">
                Top performing nights
              </h3>
              {topNights.length === 0 ? (
                <p className="px-5 py-4 text-xs text-[var(--m3-outline)]">No nights recorded for this week yet.</p>
              ) : (
                topNights.map((night) => (
                  <div key={night.rank} className="flex h-[60px] items-center gap-4 px-5 hover:bg-[var(--m3-surf2)]">
                    <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-[var(--m3-surf3)] font-mono text-[13px] text-[var(--m3-onv)]">
                      {night.rank}
                    </span>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium text-[var(--m3-on)]">{night.name}</p>
                      <p className="text-xs text-[var(--m3-onv)]">{night.date}</p>
                    </div>
                    <span className="font-mono text-sm text-[var(--m3-on)]">{night.value}</span>
                  </div>
                ))
              )}
            </Card>
          </div>

          {/* Not part of `venues/{id}/metrics/{periodId}` in this task's scope
              (no `directions` field on either seeded period) — kept as
              illustrative placeholders rather than a fabricated derivation. */}
          <div className="mb-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
              <FieldLabel>Week over week</FieldLabel>
              <p className="mt-1.5 font-display text-[26px] leading-none text-[var(--m3-on)]">640 directions</p>
              <p className="mt-1 font-mono text-[11px] text-emerald-400">+18% vs last week</p>
            </div>
            <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
              <FieldLabel>Same night, last month</FieldLabel>
              <p className="mt-1.5 font-display text-[26px] leading-none text-[var(--m3-on)]">520 directions</p>
              <p className="mt-1 font-mono text-[11px] text-red-400">-6% vs same night last month</p>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <BreakdownCard title="Age band" rows={ageBands} />
            <BreakdownCard title="Local vs tourist" rows={localSplit} />
            <BreakdownCard title="Top followed genres" rows={genreFollows} />
          </div>

          <p className="mt-3 text-[11px] text-[var(--m3-outline)]">
            Aggregated and anonymised — shown only above the platform&apos;s minimum group-size threshold. No
            individual profiles.
          </p>
        </>
      )}
    </>
  );
}

function BreakdownCard({ title, rows }: { title: string; rows: { label: string; pct: string }[] }) {
  return (
    <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-4">
      <p className="mb-2.5 text-[11px] text-[var(--m3-onv)]">{title}</p>
      {rows.length === 0 ? (
        <p className="py-1 text-xs text-[var(--m3-outline)]">No data yet.</p>
      ) : (
        rows.map((r) => (
          <div key={r.label} className="flex justify-between py-1 text-xs text-[var(--m3-on)]">
            <span>{r.label}</span>
            <span className="font-mono text-[var(--m3-onv)]">{r.pct}</span>
          </div>
        ))
      )}
    </div>
  );
}
