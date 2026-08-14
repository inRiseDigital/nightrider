"use client";

import { ArrowLeft, X } from "lucide-react";
import {
  eventSlotIds,
  useOrganizerDashboard,
} from "@/lib/organizer/dashboard/store";
import { ImageSlot } from "../ui/ImageSlot";
import { Chip, FieldLabel, SlimInput, Toggle } from "../ui/Primitives";
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

export function EventEditor() {
  const {
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
  } = useOrganizerDashboard();

  if (!eventDraft) return null;

  const isEditingExisting = !!editingEventId;
  const slots = eventSlotIds(editingEventId ?? "new");
  const moderation =
    eventDraft.moderationFlag === "pending"
      ? MODERATION_STYLES.pending
      : eventDraft.moderationFlag === "clean"
        ? MODERATION_STYLES.clean
        : null;

  // Only verified venues can host a submission.
  const selectableVenues = venueOrder.filter((id) => venues[id].verified);

  return (
    <div className="max-w-[760px]">
      <button
        onClick={closeEditor}
        className="mb-3.5 flex items-center gap-1.5 text-xs text-nr-primary-light hover:text-nr-accent"
      >
        <ArrowLeft size={13} /> Back to events
      </button>

      <div className="flex flex-col gap-[18px] rounded-lg border border-nr-border bg-nr-surface p-5">
        <div className="grid grid-cols-1 gap-3.5 sm:grid-cols-[2fr_1fr]">
          <div>
            <FieldLabel className="mb-1.5">Event name</FieldLabel>
            <SlimInput
              value={eventDraft.name}
              onChange={(e) => updateDraft("name", e.target.value)}
              placeholder="e.g. Full Moon Rooftop"
              className="w-full"
            />
          </div>
          <div>
            <FieldLabel className="mb-1.5">Venue</FieldLabel>
            <div className="flex gap-2">
              {selectableVenues.map((id) => (
                <Chip
                  key={id}
                  label={venues[id].name}
                  active={eventDraft.venue === id}
                  onClick={() => updateDraft("venue", id)}
                  shape="rounded"
                  className="flex-1 px-2.5 py-2.5 text-center"
                />
              ))}
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-3.5 sm:grid-cols-3">
          <div>
            <FieldLabel className="mb-1.5">Date</FieldLabel>
            <SlimInput
              type="date"
              mono
              value={eventDraft.date}
              onChange={(e) => updateDraft("date", e.target.value)}
              className="w-full"
            />
          </div>
          <div>
            <FieldLabel className="mb-1.5">Start time</FieldLabel>
            <SlimInput
              type="time"
              mono
              value={eventDraft.startTime}
              onChange={(e) => updateDraft("startTime", e.target.value)}
              className="w-full"
            />
          </div>
          <div>
            <FieldLabel className="mb-1.5">End time</FieldLabel>
            <SlimInput
              type="time"
              mono
              value={eventDraft.endTime}
              onChange={(e) => updateDraft("endTime", e.target.value)}
              className="w-full"
            />
          </div>
        </div>

        <div>
          <FieldLabel className="mb-2">Lineup / DJs</FieldLabel>
          <div className="mb-2.5 flex gap-2">
            <SlimInput
              value={lineupInput}
              onChange={(e) => setLineupInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault();
                  addLineup();
                }
              }}
              placeholder="Add a DJ or act"
              className="flex-1"
            />
            <button
              onClick={addLineup}
              className="whitespace-nowrap rounded-lg border border-nr-border bg-nr-surface-raised px-4 text-xs font-semibold text-nr-text-primary hover:border-nr-primary/50"
            >
              Add
            </button>
          </div>
          <div className="flex flex-wrap gap-2">
            {eventDraft.lineup.map((name, i) => (
              <span
                key={`${name}-${i}`}
                className="flex items-center gap-1.5 rounded-full border border-nr-primary/30 bg-nr-primary/10 px-2.5 py-1.5 text-xs text-nr-primary"
              >
                {name}
                <button
                  onClick={() => removeLineup(i)}
                  className="text-nr-text-secondary hover:text-nr-text-primary"
                  aria-label={`Remove ${name}`}
                >
                  <X size={11} />
                </button>
              </span>
            ))}
          </div>
        </div>

        <div>
          <div className="mb-2.5 flex items-center justify-between">
            <FieldLabel>Ticket tiers</FieldLabel>
            <button
              onClick={addTier}
              className="text-xs font-semibold text-nr-primary hover:text-nr-primary-dark"
            >
              + Add tier
            </button>
          </div>
          {eventDraft.tiers.length === 0 ? (
            <p className="py-1.5 text-xs text-nr-text-hint">No ticket tiers yet.</p>
          ) : (
            eventDraft.tiers.map((tier, i) => (
              <div key={i} className="flex items-center gap-2.5 border-b border-nr-border/60 py-2">
                <SlimInput
                  value={tier.name}
                  onChange={(e) => updateTier(i, "name", e.target.value)}
                  placeholder="Tier name"
                  className="min-w-0 flex-1 py-2 text-xs"
                />
                <SlimInput
                  type="number"
                  mono
                  value={tier.price}
                  onChange={(e) => updateTier(i, "price", e.target.value)}
                  placeholder="Price"
                  className="w-[90px] py-2 text-xs"
                />
                <SlimInput
                  type="number"
                  mono
                  value={tier.qty}
                  onChange={(e) => updateTier(i, "qty", e.target.value)}
                  placeholder="Qty"
                  className="w-[90px] py-2 text-xs"
                />
                <button
                  onClick={() => removeTier(i)}
                  className="px-1 text-nr-text-hint hover:text-red-400"
                  aria-label={`Remove tier ${tier.name}`}
                >
                  <X size={14} />
                </button>
              </div>
            ))
          )}
        </div>

        <div>
          <FieldLabel className="mb-2">Images</FieldLabel>
          <div className="grid grid-cols-2 gap-2.5">
            <ImageSlot slotId={slots.cover} placeholder="Cover image" className="h-[140px]" />
            <ImageSlot slotId={slots.poster} placeholder="Poster image" className="h-[140px]" />
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-3 rounded-lg border border-nr-border bg-nr-surface-raised p-3.5">
          <Toggle
            checked={eventDraft.recurring}
            onChange={() => updateDraft("recurring", !eventDraft.recurring)}
            label="Recurring residency"
          />
          <div className="flex-1">
            <p className="text-[13px] font-semibold text-nr-text-primary">Recurring residency</p>
            <p className="mt-px text-[11px] text-nr-text-hint">
              e.g. &ldquo;Techno Fridays&rdquo; — repeats without re-entering it every week
            </p>
          </div>
          {eventDraft.recurring && (
            <SlimInput
              value={eventDraft.recurrenceLabel}
              onChange={(e) => updateDraft("recurrenceLabel", e.target.value)}
              placeholder="Every Friday"
              className="w-[160px] bg-nr-surface py-2 text-xs"
            />
          )}
        </div>

        <div>
          <FieldLabel className="mb-1.5">
            Schedule publish (optional — goes out even if you&apos;re not online)
          </FieldLabel>
          <SlimInput
            type="datetime-local"
            mono
            value={eventDraft.scheduledPublish}
            onChange={(e) => updateDraft("scheduledPublish", e.target.value)}
          />
        </div>

        {isEditingExisting && (
          <button
            onClick={() => updateDraft("notifyOnChange", !eventDraft.notifyOnChange)}
            className="flex items-center gap-2.5 rounded-lg border border-nr-border bg-nr-surface-raised px-3.5 py-3 text-left"
          >
            <span
              className={`flex h-4 w-4 shrink-0 items-center justify-center rounded border border-nr-primary-light text-[10px] text-nr-bg ${
                eventDraft.notifyOnChange ? "bg-nr-primary-light" : "bg-transparent"
              }`}
            >
              {eventDraft.notifyOnChange ? "✓" : ""}
            </span>
            <span className="text-xs text-nr-text-secondary">
              Notify everyone who saved this event if I change the date, price, or lineup
            </span>
          </button>
        )}

        {moderation && (
          <div className="flex flex-wrap items-center gap-2.5 rounded-lg border border-nr-border bg-nr-surface-raised px-3.5 py-3">
            <StatusChip label={moderation.label} className={moderation.className} size="sm" />
            <span className="text-[11px] text-nr-text-secondary">{eventDraft.moderationEta}</span>
          </div>
        )}

        <div className="flex flex-wrap justify-end gap-2.5 border-t border-nr-border/60 pt-4">
          <button
            onClick={closeEditor}
            className="rounded-lg px-4 py-2.5 text-[13px] font-semibold text-nr-text-secondary hover:text-nr-text-primary"
          >
            Discard
          </button>
          <button
            onClick={saveDraftEvent}
            className="rounded-lg border border-nr-border px-4 py-2.5 text-[13px] font-semibold text-nr-text-primary hover:border-nr-primary/50"
          >
            Save as Draft
          </button>
          <button
            onClick={submitEvent}
            className="rounded-lg bg-nr-accent px-[18px] py-2.5 text-[13px] font-semibold text-nr-bg hover:bg-nr-accent/80"
          >
            {eventDraft.scheduledPublish ? "Schedule Publish" : "Submit for Review"}
          </button>
        </div>
      </div>
    </div>
  );
}
