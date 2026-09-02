"use client";

import { Plus, X } from "lucide-react";
import { useNow, useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { deriveEventChip, venueAccent, venueName } from "@/lib/organizer/dashboard/format";
import { FilledButton, IconButton } from "../ui/Primitives";
import { StatusChip } from "../ui/StatusChip";

/**
 * What's on for one calendar day. Opened by clicking a day that already has
 * events, or its "+N more" link — an empty day skips straight to the editor.
 */
export function EventDayDialog() {
  const {
    dayDialog,
    closeDayDialog,
    events,
    venues,
    venueOrder,
    openEditEvent,
    openNewEvent,
  } = useOrganizerDashboard();
  const now = useNow();

  if (!dayDialog) return null;

  const rows = events.filter((e) => e.date === dayDialog.iso && e.status !== "cancelled");

  return (
    <div className="fixed inset-0 z-[70] flex items-center justify-center p-8">
      <div className="absolute inset-0 bg-black/60" onClick={closeDayDialog} />
      <div
        role="dialog"
        aria-modal="true"
        aria-label={dayDialog.label}
        className="relative max-h-full w-full max-w-[480px] overflow-y-auto rounded-[28px] p-6 shadow-[0_8px_24px_rgba(0,0,0,0.6)]"
        style={{ background: "var(--m3-surf2)" }}
      >
        <div className="mb-4 flex items-center gap-3">
          <h2 className="flex-1 text-[22px] leading-7" style={{ color: "var(--m3-on)" }}>
            {dayDialog.label}
          </h2>
          <IconButton onClick={closeDayDialog} aria-label="Close">
            <X size={20} />
          </IconButton>
        </div>

        <div className="flex flex-col">
          {rows.length === 0 && (
            <p className="py-2 text-[13px]" style={{ color: "var(--m3-outline)" }}>
              Nothing booked for this night yet.
            </p>
          )}
          {rows.map((ev) => {
            const chip = deriveEventChip(ev, now);
            return (
              <button
                key={ev.id}
                onClick={() => {
                  closeDayDialog();
                  openEditEvent(ev.id);
                }}
                className="flex items-center gap-3.5 rounded-xl px-2 py-3 text-left transition-colors hover:bg-[var(--m3-surf3)]"
              >
                <span
                  className="w-[3px] self-stretch rounded-full"
                  style={{ background: venueAccent(venueOrder, ev.venue) }}
                />
                <span className="min-w-0 flex-1">
                  <span
                    className="block truncate text-sm font-medium"
                    style={{ color: "var(--m3-on)" }}
                  >
                    {ev.name || "(untitled)"}
                  </span>
                  <span className="mt-0.5 block truncate text-[13px]" style={{ color: "var(--m3-onv)" }}>
                    {venueName(venues, ev.venue)} · {ev.lineup.length ? ev.lineup.join(" · ") : "TBA"}
                  </span>
                </span>
                <StatusChip label={chip.label} className={chip.className} size="sm" />
              </button>
            );
          })}
        </div>

        <div className="mt-5 flex items-center justify-end">
          <FilledButton
            icon={<Plus size={18} />}
            onClick={() => {
              const iso = dayDialog.iso;
              closeDayDialog();
              openNewEvent(iso);
            }}
          >
            Add event
          </FilledButton>
        </div>
      </div>
    </div>
  );
}
