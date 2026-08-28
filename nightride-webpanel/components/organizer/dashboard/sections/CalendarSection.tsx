"use client";

import { useRouter } from "next/navigation";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { useNow, useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { buildCalendar } from "@/lib/organizer/dashboard/format";
import { DAYS } from "@/lib/organizer/dashboard/constants";
import { VenueSwitcher } from "../ui/Primitives";

export function CalendarSection() {
  const router = useRouter();
  const {
    events,
    venues,
    venueOrder,
    calendarOffset,
    calendarVenueFilter,
    setCalendarVenueFilter,
    shiftCalendar,
    openNewEvent,
  } = useOrganizerDashboard();
  const now = useNow();

  // Closed-day shading needs one venue's hours, so it only applies when a
  // specific venue is selected.
  const filterProfile = calendarVenueFilter === "all" ? null : venues[calendarVenueFilter];

  // The month grid depends on today's date, which the server doesn't know.
  const calendar = now ? buildCalendar(now, calendarOffset, events, calendarVenueFilter, filterProfile) : null;

  const onCellClick = (dateISO: string) => {
    if (!dateISO) return;
    openNewEvent(dateISO);
    router.push("/organizer/events");
  };

  return (
    <>
      <VenueSwitcher
        venueOrder={venueOrder}
        venues={venues}
        selected={calendarVenueFilter}
        onSelect={setCalendarVenueFilter}
        includeAll
      />

      <div className="mb-3.5 flex items-center gap-3.5">
        <button
          onClick={() => shiftCalendar(-1)}
          className="flex h-[30px] w-[30px] items-center justify-center rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf2)] text-[var(--m3-on)] hover:border-[var(--m3-pri)]/50"
          aria-label="Previous month"
        >
          <ChevronLeft size={15} />
        </button>
        <p className="font-mono text-xs text-[var(--m3-onv)]">{calendar?.label ?? "—"}</p>
        <button
          onClick={() => shiftCalendar(1)}
          className="flex h-[30px] w-[30px] items-center justify-center rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf2)] text-[var(--m3-on)] hover:border-[var(--m3-pri)]/50"
          aria-label="Next month"
        >
          <ChevronRight size={15} />
        </button>
      </div>

      <div className="grid grid-cols-7 gap-1.5">
        {DAYS.map((d) => (
          <p key={d} className="pb-1 text-center font-mono text-[11px] text-[var(--m3-outline)]">
            {d}
          </p>
        ))}

        {calendar?.cells.map((cell) =>
          cell.dayNum === "" ? (
            <div key={cell.key} className="min-h-[82px]" />
          ) : (
            <button
              key={cell.key}
              onClick={() => onCellClick(cell.dateISO)}
              className={`min-h-[82px] rounded-lg border border-[var(--m3-outlinev)] p-2 text-left transition-colors hover:border-[var(--m3-pri)] hover:bg-white/5 ${
                cell.isClosed ? "bg-white/[0.02]" : "bg-[var(--m3-surf1)]"
              }`}
            >
              <span
                className={`font-mono text-[11px] ${
                  cell.isClosed ? "text-[var(--m3-outline)]/70" : "text-[var(--m3-onv)]"
                }`}
              >
                {cell.dayNum}
              </span>
              {cell.events.map((e) => (
                <span
                  key={e.id}
                  className="mt-1 block truncate rounded bg-[var(--m3-pri)]/10 px-1.5 py-0.5 text-[10px] text-[var(--m3-pri)]"
                >
                  {e.name}
                </span>
              ))}
              {cell.isClosed && (
                <span className="mt-1 block truncate text-[10px] text-[var(--m3-outline)]">
                  {cell.closedLabel}
                </span>
              )}
            </button>
          )
        )}
      </div>

      {!calendar && (
        <p className="mt-4 font-mono text-[11px] text-[var(--m3-outline)]">Loading calendar…</p>
      )}
    </>
  );
}
