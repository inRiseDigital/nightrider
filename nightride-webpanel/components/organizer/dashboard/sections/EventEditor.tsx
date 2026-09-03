"use client";

import { CalendarDays, Plus, Trash2, X } from "lucide-react";
import { eventSlotIds, useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { ImageSlot } from "../ui/ImageSlot";
import {
  FilledButton,
  IconButton,
  OutlinedButton,
  SectionLabel,
  Select,
  SlimInput,
  TextButton,
  TextField,
  Toggle,
} from "../ui/Primitives";
import { StatusChip } from "../ui/StatusChip";

const MODERATION_STYLES = {
  pending: {
    label: "AWAITING ADMIN REVIEW",
    className: "bg-amber-500/10 text-amber-400 ring-amber-500/30",
  },
  clean: {
    label: "PASSED AUTO-SCAN",
    className: "bg-emerald-500/10 text-emerald-400 ring-emerald-500/30",
  },
} as const;

/** The dialog sits on --m3-surf2, so notched field labels must mask that tone. */
const SURFACE = "var(--m3-surf2)";

/**
 * Event editor — a modal over the events list, matching the design. Submissions
 * enter the platform review queue rather than publishing straight away.
 */
export function EventEditor() {
  const {
    eventEditorOpen,
    eventDraft,
    editingEventId,
    venueOrder,
    venues,
    closeEditor,
    updateDraft,
    lineupInput,
    setLineupInput,
    addLineup,
    removeLineup,
    addTier,
    updateTier,
    removeTier,
    saveDraftEvent,
    submitEvent,
    eventBusy,
    eventActionError,
  } = useOrganizerDashboard();

  if (!eventEditorOpen || !eventDraft) return null;

  const isEditingExisting = !!editingEventId;
  const slots = eventSlotIds(editingEventId ?? "new");
  const moderation =
    eventDraft.moderationFlag === "pending"
      ? MODERATION_STYLES.pending
      : eventDraft.moderationFlag === "clean"
        ? MODERATION_STYLES.clean
        : null;

  // Only verified venues can host a submission.
  const selectableVenues = venueOrder
    .filter((id) => venues[id].verified)
    .map((id) => ({ value: id, label: venues[id].name }));

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center p-8">
      <div className="absolute inset-0 bg-black/60" onClick={closeEditor} />
      <div
        role="dialog"
        aria-modal="true"
        aria-label={isEditingExisting ? "Edit event" : "New event"}
        className="relative max-h-full w-full max-w-[680px] overflow-y-auto rounded-[28px] p-6 shadow-[0_8px_24px_rgba(0,0,0,0.6)]"
        style={{ background: SURFACE }}
      >
        <div className="mb-5 flex items-center gap-3">
          <div
            className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full"
            style={{ background: "var(--m3-pric)", color: "var(--m3-onpric)" }}
          >
            <CalendarDays size={20} />
          </div>
          <div className="min-w-0 flex-1">
            <h2 className="text-[22px] leading-7" style={{ color: "var(--m3-on)" }}>
              {isEditingExisting ? "Edit event" : "New event"}
            </h2>
            <p className="mt-0.5 text-[13px]" style={{ color: "var(--m3-onv)" }}>
              Submissions go to platform review before publishing.
            </p>
          </div>
          <IconButton onClick={closeEditor} aria-label="Close">
            <X size={20} />
          </IconButton>
        </div>

        <div className="flex flex-col gap-[22px]">
          <TextField
            label="Event name"
            surface={SURFACE}
            value={eventDraft.name}
            onChange={(e) => updateDraft("name", e.target.value)}
            placeholder="Full Moon Rooftop"
          />

          <div className="flex flex-wrap gap-4">
            <Select
              label="Venue"
              surface={SURFACE}
              options={selectableVenues}
              value={eventDraft.venue}
              onChange={(e) => updateDraft("venue", e.target.value)}
              wrapperClassName="min-w-[180px] flex-1"
            />
            <TextField
              label="Date"
              surface={SURFACE}
              type="date"
              mono
              value={eventDraft.date}
              onChange={(e) => updateDraft("date", e.target.value)}
              wrapperClassName="min-w-[150px] flex-1"
            />
          </div>

          <div className="flex gap-4">
            <TextField
              label="Doors"
              surface={SURFACE}
              type="time"
              mono
              value={eventDraft.startTime}
              onChange={(e) => updateDraft("startTime", e.target.value)}
              wrapperClassName="flex-1"
            />
            <TextField
              label="Close"
              surface={SURFACE}
              type="time"
              mono
              value={eventDraft.endTime}
              onChange={(e) => updateDraft("endTime", e.target.value)}
              wrapperClassName="flex-1"
            />
          </div>

          <div>
            <SectionLabel className="mb-2.5">Lineup</SectionLabel>
            <div className="flex flex-wrap items-center gap-2">
              {eventDraft.lineup.map((name, i) => (
                <span
                  key={`${name}-${i}`}
                  className="flex h-8 items-center gap-1.5 rounded-lg pl-3.5 pr-2 text-sm font-medium"
                  style={{ background: "var(--m3-surf3)", color: "var(--m3-on)" }}
                >
                  {name}
                  <button
                    onClick={() => removeLineup(i)}
                    aria-label={`Remove ${name}`}
                    className="text-[var(--m3-onv)] hover:text-[var(--m3-on)]"
                  >
                    <X size={14} />
                  </button>
                </span>
              ))}
              <input
                value={lineupInput}
                onChange={(e) => setLineupInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    e.preventDefault();
                    addLineup();
                  }
                }}
                placeholder="Add artist + Enter"
                className="min-w-[160px] flex-1 rounded-lg border border-dashed bg-transparent px-3 py-2 text-sm outline-none placeholder:text-[var(--m3-outline)]"
                style={{ borderColor: "var(--m3-outline)", color: "var(--m3-on)" }}
              />
            </div>
          </div>

          <div>
            <SectionLabel className="mb-2.5">Ticket tiers</SectionLabel>
            {eventDraft.tiers.map((tier, i) => (
              <div key={i} className="mb-2.5 flex items-center gap-3">
                <SlimInput
                  value={tier.name}
                  onChange={(e) => updateTier(i, "name", e.target.value)}
                  placeholder="Tier name"
                  className="min-w-0 flex-[2]"
                />
                <SlimInput
                  type="number"
                  mono
                  value={tier.price}
                  onChange={(e) => updateTier(i, "price", e.target.value)}
                  placeholder="Price"
                  className="min-w-0 flex-1"
                />
                <SlimInput
                  type="number"
                  mono
                  value={tier.qty}
                  onChange={(e) => updateTier(i, "qty", e.target.value)}
                  placeholder="Qty"
                  className="min-w-0 flex-1"
                />
                <IconButton onClick={() => removeTier(i)} danger aria-label={`Remove tier ${tier.name}`}>
                  <Trash2 size={18} />
                </IconButton>
              </div>
            ))}
            <OutlinedButton onClick={addTier} icon={<Plus size={16} />} className="h-9 text-[13px]">
              Add tier
            </OutlinedButton>
          </div>

          <div>
            <SectionLabel className="mb-2.5">Images</SectionLabel>
            {/* The `eventMedia` storage rule authorizes an upload against the
                event document existing — save the draft once before either
                slot can accept a file. */}
            <div className="grid grid-cols-2 gap-2.5">
              <ImageSlot
                slotId={slots.cover}
                placeholder="Cover image"
                className="h-[140px]"
                disabled={!isEditingExisting}
                disabledHint="Save draft first"
              />
              <ImageSlot
                slotId={slots.poster}
                placeholder="Poster image"
                className="h-[140px]"
                disabled={!isEditingExisting}
                disabledHint="Save draft first"
              />
            </div>
          </div>

          <div
            className="flex flex-wrap items-center gap-3 rounded-xl p-3.5"
            style={{ background: "var(--m3-surf1)" }}
          >
            <Toggle
              checked={eventDraft.recurring}
              onChange={() => updateDraft("recurring", !eventDraft.recurring)}
              label="Recurring residency"
            />
            <div className="min-w-0 flex-1">
              <p className="text-[13px] font-medium" style={{ color: "var(--m3-on)" }}>
                Recurring residency
              </p>
              <p className="mt-px text-[11px]" style={{ color: "var(--m3-outline)" }}>
                e.g. &ldquo;Techno Fridays&rdquo; — repeats without re-entering it every week
              </p>
            </div>
            {eventDraft.recurring && (
              <SlimInput
                value={eventDraft.recurrenceLabel}
                onChange={(e) => updateDraft("recurrenceLabel", e.target.value)}
                placeholder="Every Friday"
                className="w-[160px] py-2 text-xs"
              />
            )}
          </div>

          <TextField
            label="Schedule publish (optional)"
            surface={SURFACE}
            type="datetime-local"
            mono
            value={eventDraft.scheduledPublish}
            onChange={(e) => updateDraft("scheduledPublish", e.target.value)}
          />

          {isEditingExisting && (
            <button
              onClick={() => updateDraft("notifyOnChange", !eventDraft.notifyOnChange)}
              className="flex items-center gap-2.5 rounded-xl px-3.5 py-3 text-left"
              style={{ background: "var(--m3-surf1)" }}
            >
              <span
                className="flex h-[18px] w-[18px] shrink-0 items-center justify-center rounded-sm border-2 text-[12px] font-bold"
                style={{
                  borderColor: eventDraft.notifyOnChange ? "var(--m3-pri)" : "var(--m3-outline)",
                  background: eventDraft.notifyOnChange ? "var(--m3-pri)" : "transparent",
                  color: "var(--m3-onpri)",
                }}
              >
                {eventDraft.notifyOnChange ? "✓" : ""}
              </span>
              <span className="text-xs" style={{ color: "var(--m3-onv)" }}>
                Notify everyone who saved this event if I change the date, price, or lineup
              </span>
            </button>
          )}

          {moderation && (
            <div
              className="flex flex-wrap items-center gap-2.5 rounded-xl px-3.5 py-3"
              style={{ background: "var(--m3-surf1)" }}
            >
              <StatusChip label={moderation.label} className={moderation.className} size="sm" />
              <span className="text-[11px]" style={{ color: "var(--m3-onv)" }}>
                {eventDraft.moderationEta}
              </span>
            </div>
          )}
        </div>

        {eventActionError && (
          <p className="mt-4 text-[13px]" style={{ color: "var(--m3-err)" }}>
            {eventActionError}
          </p>
        )}

        <div className="mt-7 flex flex-wrap items-center justify-end gap-2">
          <TextButton onClick={closeEditor} disabled={eventBusy}>
            Cancel
          </TextButton>
          <FilledButton onClick={saveDraftEvent} tonal loading={eventBusy} disabled={eventBusy}>
            Save draft
          </FilledButton>
          <FilledButton onClick={submitEvent} loading={eventBusy} disabled={eventBusy}>
            {eventDraft.scheduledPublish ? "Schedule publish" : "Submit for review"}
          </FilledButton>
        </div>
      </div>
    </div>
  );
}
