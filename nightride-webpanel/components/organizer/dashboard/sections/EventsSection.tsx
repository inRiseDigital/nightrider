"use client";

import { useNow, useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { deriveEventChip, venueName } from "@/lib/organizer/dashboard/format";
import { SectionEyebrow, SlimTextarea } from "../ui/Primitives";
import { StatusChip } from "../ui/StatusChip";
import { EventEditor } from "./EventEditor";

export function EventsSection() {
  const {
    eventEditorOpen,
    events,
    venues,
    openEditEvent,
    duplicateEvent,
    startCancel,
    cancelingEventId,
    cancelReasonInput,
    setCancelReasonInput,
    confirmCancel,
    cancelCancelFlow,
  } = useOrganizerDashboard();
  const now = useNow();

  if (eventEditorOpen) return <EventEditor />;

  const published = events.filter((e) => e.status !== "draft");
  const drafts = events.filter((e) => e.status === "draft");

  return (
    <>
      <div className="overflow-hidden rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)]">
        {published.length === 0 && (
          <p className="px-[18px] py-5 text-xs text-[var(--m3-outline)]">
            Nothing published yet — start with a draft.
          </p>
        )}
        {published.map((ev) => {
          const chip = deriveEventChip(ev, now);
          const cancelable = ev.status === "live" || ev.status === "scheduled";
          return (
            <div key={ev.id} className="border-b border-[var(--m3-outlinev)] last:border-b-0">
              <div className="flex flex-wrap items-center gap-3.5 px-[18px] py-3.5">
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <p className="text-[13px] font-semibold text-[var(--m3-on)]">{ev.name}</p>
                    {ev.recurring && ev.recurrenceLabel && (
                      <span className="rounded-full border border-[var(--m3-ter)]/30 bg-[var(--m3-ter)]/10 px-1.5 py-px font-mono text-[10px] text-[var(--m3-ter)]">
                        {ev.recurrenceLabel}
                      </span>
                    )}
                  </div>
                  <p className="mt-0.5 font-mono text-[11px] text-[var(--m3-outline)]">
                    {venueName(venues, ev.venue)} · {ev.date} · {ev.startTime}–{ev.endTime}
                  </p>
                </div>
                <StatusChip label={chip.label} className={chip.className} />
                <button
                  onClick={() => openEditEvent(ev.id)}
                  className="text-xs font-semibold text-[var(--m3-ter)] hover:text-[var(--m3-warn)]"
                >
                  Edit
                </button>
                <button
                  onClick={() => duplicateEvent(ev.id)}
                  className="text-xs font-semibold text-[var(--m3-onv)] hover:text-[var(--m3-on)]"
                >
                  Duplicate
                </button>
                {cancelable && (
                  <button
                    onClick={() => startCancel(ev.id)}
                    className="text-xs font-semibold text-red-400 hover:text-red-300"
                  >
                    Cancel
                  </button>
                )}
              </div>

              {cancelingEventId === ev.id && (
                <div className="flex flex-wrap items-start gap-2.5 bg-[var(--m3-surf2)] px-[18px] py-3.5">
                  <SlimTextarea
                    value={cancelReasonInput}
                    onChange={(e) => setCancelReasonInput(e.target.value)}
                    placeholder="Reason shown to attendees (e.g. artist cancelled)"
                    className="min-h-[44px] flex-1 bg-[var(--m3-surf1)] py-2 text-xs"
                  />
                  <button
                    onClick={confirmCancel}
                    className="whitespace-nowrap rounded-lg bg-red-600 px-3.5 py-2.5 text-xs font-semibold text-white hover:bg-red-700"
                  >
                    Confirm Cancel
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
                <p className="px-[18px] pb-3.5 pt-0 text-xs text-red-400">
                  Cancelled: {ev.cancelReason}
                </p>
              )}
            </div>
          );
        })}
      </div>

      <SectionEyebrow className="mb-2.5 mt-6">Drafts — not yet submitted</SectionEyebrow>
      <div className="overflow-hidden rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)]">
        {drafts.length === 0 ? (
          <p className="px-[18px] py-5 text-xs text-[var(--m3-outline)]">No drafts.</p>
        ) : (
          drafts.map((ev) => (
            <div
              key={ev.id}
              className="flex flex-wrap items-center gap-3.5 border-b border-[var(--m3-outlinev)] px-[18px] py-3.5 last:border-b-0"
            >
              <div className="min-w-0 flex-1">
                <p className="text-[13px] font-semibold text-[var(--m3-on)]">
                  {ev.name || "(untitled)"}
                </p>
                <p className="mt-0.5 font-mono text-[11px] text-[var(--m3-outline)]">
                  {venueName(venues, ev.venue)} · {ev.date || "no date set"}
                </p>
              </div>
              <button
                onClick={() => openEditEvent(ev.id)}
                className="text-xs font-semibold text-[var(--m3-ter)] hover:text-[var(--m3-warn)]"
              >
                Continue editing
              </button>
              <button
                onClick={() => duplicateEvent(ev.id)}
                className="text-xs font-semibold text-[var(--m3-onv)] hover:text-[var(--m3-on)]"
              >
                Duplicate
              </button>
            </div>
          ))
        )}
      </div>
    </>
  );
}
