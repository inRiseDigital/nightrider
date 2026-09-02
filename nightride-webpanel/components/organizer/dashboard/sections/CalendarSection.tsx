"use client";

import { ChevronLeft, ChevronRight } from "lucide-react";
import { useNow, useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { buildCalendar, venueAccent } from "@/lib/organizer/dashboard/format";
import { DAYS } from "@/lib/organizer/dashboard/constants";
import { IconButton, VenueSwitcher } from "../ui/Primitives";

/** Events shown inline in a day cell before the rest collapse into "+N more". */
const CELL_EVENT_CAP = 2;

export function CalendarSection() {
  const {
    events,
    venues,
    venueOrder,
    calendarOffset,
    calendarVenueFilter,
    setCalendarVenueFilter,
    shiftCalendar,
    openNewEvent,
    openDayDialog,
  } = useOrganizerDashboard();
  const now = useNow();

  // Closed-day shading needs one venue's hours, so it only applies when a
  // specific venue is selected.
  const filterProfile = calendarVenueFilter === "all" ? null : venues[calendarVenueFilter];

  // The month grid depends on today's date, which the server doesn't know.
  const calendar = now ? buildCalendar(now, calendarOffset, events, calendarVenueFilter, filterProfile) : null;

  return (
    <>
      <VenueSwitcher
        venueOrder={venueOrder}
        venues={venues}
        selected={calendarVenueFilter}
        onSelect={setCalendarVenueFilter}
        includeAll
      />

      <div className="rounded-xl p-5" style={{ background: "var(--m3-surf1)" }}>
        <div className="mb-4 flex items-center gap-2">
          <p className="text-base font-medium" style={{ color: "var(--m3-on)" }}>
            {calendar?.label ?? "—"}
          </p>
          <div className="flex flex-1 items-center gap-4 pl-5">
            {venueOrder.map((id) => (
              <span key={id} className="flex items-center gap-1.5">
                <span
                  className="h-3.5 w-[3px] rounded-full"
                  style={{ background: venueAccent(venueOrder, id) }}
                />
                <span className="text-xs" style={{ color: "var(--m3-onv)" }}>
                  {venues[id].name}
                </span>
              </span>
            ))}
          </div>
          <IconButton onClick={() => shiftCalendar(-1)} aria-label="Previous month">
            <ChevronLeft size={20} />
          </IconButton>
          <IconButton onClick={() => shiftCalendar(1)} aria-label="Next month">
            <ChevronRight size={20} />
          </IconButton>
        </div>

        <div className="grid grid-cols-7 gap-2">
          {DAYS.map((d) => (
            <p
              key={d}
              className="pb-1 text-center text-[11px] font-medium tracking-[1px]"
              style={{ color: "var(--m3-onv)" }}
            >
              {d.toUpperCase()}
            </p>
          ))}
        </div>

        <div className="mt-1 grid grid-cols-7 gap-2">
          {calendar?.cells.map((cell) => {
            if (cell.dayNum === "") return <div key={cell.key} className="min-h-[104px]" />;

            const shown = cell.events.slice(0, CELL_EVENT_CAP);
            const extra = cell.events.length - shown.length;
            const hasEvents = cell.events.length > 0;

            return (
              <div
                key={cell.key}
                role="button"
                tabIndex={0}
                onClick={() =>
                  hasEvents ? openDayDialog(cell.dateISO, cell.label) : openNewEvent(cell.dateISO)
                }
                onKeyDown={(e) => {
                  if (e.key !== "Enter") return;
                  if (hasEvents) openDayDialog(cell.dateISO, cell.label);
                  else openNewEvent(cell.dateISO);
                }}
                className="min-h-[104px] cursor-pointer rounded-xl border p-2 transition-colors hover:bg-[var(--m3-surf3)]"
                style={{
                  background: hasEvents ? "var(--m3-surf2)" : "transparent",
                  borderColor: hasEvents ? "transparent" : "var(--m3-outlinev)",
                }}
              >
                <span
                  className="font-mono text-[13px]"
                  style={{ color: cell.isClosed ? "var(--m3-outline)" : "var(--m3-onv)" }}
                >
                  {cell.dayNum}
                </span>

                {shown.map((e) => (
                  <span
                    key={e.id}
                    className="mt-1.5 flex items-start gap-1.5 rounded-md px-1.5 py-1 text-[11px] font-medium leading-[14px]"
                    style={{ background: "var(--m3-surf3)", color: "var(--m3-on)" }}
                  >
                    <span
                      className="min-h-[14px] w-[3px] shrink-0 self-stretch rounded-full"
                      style={{ background: venueAccent(venueOrder, e.venue) }}
                    />
                    <span className="min-w-0">
                      <span className="block truncate">{e.name}</span>
                      <span
                        className="mt-px block truncate text-[10px] font-normal opacity-80"
                        style={{ color: "var(--m3-onv)" }}
                      >
                        {venues[e.venue]?.name ?? e.venue}
                      </span>
                    </span>
                  </span>
                ))}

                {extra > 0 && (
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      openDayDialog(cell.dateISO, cell.label);
                    }}
                    className="mt-1.5 rounded-md px-1.5 py-0.5 text-[11px] font-medium hover:bg-[var(--m3-surf4)]"
                    style={{ color: "var(--m3-pri)" }}
                  >
                    +{extra} more
                  </button>
                )}

                {cell.isClosed && !hasEvents && (
                  <span className="mt-1 block truncate text-[10px]" style={{ color: "var(--m3-outline)" }}>
                    {cell.closedLabel}
                  </span>
                )}
              </div>
            );
          })}
        </div>

        {!calendar && (
          <p className="mt-4 font-mono text-[11px]" style={{ color: "var(--m3-outline)" }}>
            Loading calendar…
          </p>
        )}
      </div>
    </>
  );
}
