"use client";

import { Pencil } from "lucide-react";
import { useNow, useOrganizerDashboard, type EventFilter } from "@/lib/organizer/dashboard/store";
import { deriveEventChip, venueName } from "@/lib/organizer/dashboard/format";
import { Chip, IconButton, SlimTextarea } from "../ui/Primitives";
import { StatusChip } from "../ui/StatusChip";

const FILTERS: { id: EventFilter; label: string }[] = [
  { id: "all", label: "All" },
  { id: "in_review", label: "In review" },
  { id: "scheduled", label: "Scheduled" },
  { id: "live", label: "Live" },
  { id: "draft", label: "Drafts" },
];

/** Shared column track, so the header and every row line up. */
const COLS = "grid-cols-[2.2fr_1.2fr_1.1fr_1fr_1fr_48px]";

export function EventsSection() {
  const {
    events,
    eventFilter,
    setEventFilter,
    venues,
    openEditEvent,
    startCancel,
    cancelingEventId,
    cancelReasonInput,
    setCancelReasonInput,
    confirmCancel,
    cancelCancelFlow,
  } = useOrganizerDashboard();
  const now = useNow();

  const rows = events.filter((e) => eventFilter === "all" || e.status === eventFilter);

  return (
    <>
      <div className="mb-5 flex flex-wrap items-center gap-2">
        {FILTERS.map((f) => (
          <Chip
            key={f.id}
            label={f.label}
            active={eventFilter === f.id}
            onClick={() => setEventFilter(f.id)}
          />
        ))}
      </div>

      <div className="overflow-hidden rounded-xl" style={{ background: "var(--m3-surf1)" }}>
        <div
          className={`grid ${COLS} h-14 items-center border-b px-6 text-xs font-medium tracking-[0.5px]`}
          style={{ borderColor: "var(--m3-outlinev)", color: "var(--m3-onv)" }}
        >
          <div>EVENT</div>
          <div>VENUE</div>
          <div>DATE</div>
          <div>STATUS</div>
          <div className="text-right">SOLD / REV</div>
          <div />
        </div>

        {rows.length === 0 && (
          <p className="px-6 py-5 text-xs" style={{ color: "var(--m3-outline)" }}>
            No events match this filter.
          </p>
        )}

        {rows.map((ev) => {
          const chip = deriveEventChip(ev, now);
          const cancelable = ev.status === "live" || ev.status === "scheduled";
          const currency = venues[ev.venue]?.currency ?? "";

          return (
            <div key={ev.id} className="border-b last:border-b-0" style={{ borderColor: "var(--m3-outlinev)" }}>
              <div
                className={`grid ${COLS} min-h-16 items-center px-6 py-2 transition-colors hover:bg-[var(--m3-surf2)]`}
              >
                <div className="min-w-0 pr-3">
                  <p className="truncate text-sm font-medium" style={{ color: "var(--m3-on)" }}>
                    {ev.name || "(untitled)"}
                  </p>
                  <p className="mt-0.5 flex items-center gap-2 truncate text-xs" style={{ color: "var(--m3-onv)" }}>
                    <span className="truncate">{ev.lineup.length ? ev.lineup.join(" · ") : "TBA"}</span>
                    {cancelable && cancelingEventId !== ev.id && (
                      <button
                        onClick={() => startCancel(ev.id)}
                        className="shrink-0 font-medium text-[var(--m3-err)] hover:underline"
                      >
                        Cancel
                      </button>
                    )}
                  </p>
                </div>
                <div className="truncate text-[13px]" style={{ color: "var(--m3-onv)" }}>
                  {venueName(venues, ev.venue)}
                </div>
                <div className="font-mono text-[13px]" style={{ color: "var(--m3-onv)" }}>
                  {ev.date || "—"}
                </div>
                <div>
                  <StatusChip label={chip.label} className={chip.className} size="sm" />
                </div>
                <div className="text-right">
                  {ev.sold > 0 || ev.revenue > 0 ? (
                    <>
                      <p className="font-mono text-[13px]" style={{ color: "var(--m3-on)" }}>
                        {ev.sold}/{capacityOf(ev.tiers)}
                      </p>
                      <p className="mt-0.5 text-xs" style={{ color: "var(--m3-onv)" }}>
                        {currency} {ev.revenue.toLocaleString()}
                      </p>
                    </>
                  ) : (
                    // Not on sale yet — one dash rather than a stacked pair.
                    <p className="font-mono text-[13px]" style={{ color: "var(--m3-onv)" }}>
                      —
                    </p>
                  )}
                </div>
                <IconButton
                  onClick={() => openEditEvent(ev.id)}
                  aria-label={`Edit ${ev.name}`}
                  className="justify-self-end"
                >
                  <Pencil size={18} />
                </IconButton>
              </div>

              {cancelingEventId === ev.id && (
                <div
                  className="flex flex-wrap items-start gap-2.5 px-6 py-3.5"
                  style={{ background: "var(--m3-surf2)" }}
                >
                  <SlimTextarea
                    value={cancelReasonInput}
                    onChange={(e) => setCancelReasonInput(e.target.value)}
                    placeholder="Reason shown to attendees (e.g. artist cancelled)"
                    className="min-h-[44px] flex-1 bg-[var(--m3-surf1)] py-2 text-xs"
                  />
                  <button
                    onClick={confirmCancel}
                    className="whitespace-nowrap rounded-full bg-[#dc2626] px-4 py-2.5 text-xs font-semibold text-white hover:bg-[#b91c1c]"
                  >
                    Confirm cancel
                  </button>
                  <button
                    onClick={cancelCancelFlow}
                    className="whitespace-nowrap px-3.5 py-2.5 text-xs text-[var(--m3-onv)] hover:text-[var(--m3-on)]"
                  >
                    Never mind
                  </button>
                </div>
              )}

              {ev.status === "cancelled" && ev.cancelReason && (
                <p className="px-6 pb-3.5 text-xs" style={{ color: "var(--m3-err)" }}>
                  Cancelled: {ev.cancelReason}
                </p>
              )}
            </div>
          );
        })}
      </div>
    </>
  );
}

/** Total tickets across all tiers — the denominator in the SOLD column. */
function capacityOf(tiers: { qty: number }[]): number {
  return tiers.reduce((n, t) => n + t.qty, 0);
}
