"use client";

import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { DOOR_STATUSES } from "@/lib/organizer/dashboard/constants";
import { FieldLabel, SlimInput, VenueSwitcher } from "../ui/Primitives";
import { StatusChip } from "../ui/StatusChip";

export function TonightSection() {
  const {
    venueOrder,
    venues,
    editingVenue,
    setEditingVenue,
    tonight,
    setDoorStatus,
    setQueueMinutes,
    setFlashText,
    setFlashUntil,
    toggleFlash,
    toggleEmergency,
  } = useOrganizerDashboard();

  const activeStatus = DOOR_STATUSES.find((s) => s.id === tonight.status) ?? DOOR_STATUSES[0];
  const queueText = `${tonight.queueMinutes} min wait`;

  return (
    <>
      <VenueSwitcher
        venueOrder={venueOrder}
        venues={venues}
        selected={editingVenue}
        onSelect={setEditingVenue}
      />

      <div className="grid grid-cols-1 items-start gap-5 xl:grid-cols-[1.3fr_1fr]">
        <div className="flex flex-col gap-4">
          <div className="rounded-lg border border-nr-border bg-nr-surface p-[18px]">
            <FieldLabel className="mb-2.5">
              Live status — stops the app sending people you can&apos;t let in
            </FieldLabel>
            <div className="flex flex-wrap gap-2">
              {DOOR_STATUSES.map((s) => (
                <button
                  key={s.id}
                  onClick={() => setDoorStatus(s.id)}
                  aria-pressed={tonight.status === s.id}
                  className={`rounded-lg px-3.5 py-2.5 text-xs font-semibold ring-1 ring-inset transition-colors ${
                    tonight.status === s.id
                      ? s.className
                      : "text-nr-text-secondary ring-nr-border hover:text-nr-text-primary"
                  }`}
                >
                  {s.label}
                </button>
              ))}
            </div>
          </div>

          <div className="rounded-lg border border-nr-border bg-nr-surface p-[18px]">
            <FieldLabel className="mb-2.5">Current queue / wait time</FieldLabel>
            <div className="flex flex-wrap items-center gap-2.5">
              <SlimInput
                type="number"
                mono
                min={0}
                value={tonight.queueMinutes}
                onChange={(e) => setQueueMinutes(Number(e.target.value) || 0)}
                className="w-[100px] py-2"
              />
              <span className="text-xs text-nr-text-secondary">
                min wait — posted live as &ldquo;{queueText}&rdquo;
              </span>
            </div>
          </div>

          <div className="rounded-lg border border-nr-border bg-nr-surface p-[18px]">
            <FieldLabel className="mb-3">Tonight-only flash offer</FieldLabel>
            <div className="mb-2.5 flex flex-wrap gap-2.5">
              <SlimInput
                value={tonight.flashText}
                onChange={(e) => setFlashText(e.target.value)}
                placeholder="Free entry before midnight"
                className="min-w-[200px] flex-1 py-2"
              />
              <SlimInput
                type="time"
                mono
                value={tonight.flashUntil}
                onChange={(e) => setFlashUntil(e.target.value)}
                className="py-2"
              />
            </div>
            <button
              onClick={toggleFlash}
              className={`rounded-lg border px-4 py-2.5 text-xs font-semibold transition-colors ${
                tonight.flashActive
                  ? "border-nr-accent bg-nr-accent text-nr-bg"
                  : "border-nr-border text-nr-text-primary hover:border-nr-accent/50"
              }`}
            >
              {tonight.flashActive ? "Flash Offer Live — Stop" : "Go Live With Offer"}
            </button>
          </div>

          <div className="rounded-lg border border-red-600 bg-nr-surface p-[18px]">
            <FieldLabel className="mb-2.5">
              Emergency closure — instantly pulls you from the map and notifies anyone heading over
            </FieldLabel>
            <button
              onClick={toggleEmergency}
              className={`rounded-lg px-[18px] py-2.5 text-[13px] font-semibold text-nr-text-primary transition-colors ${
                tonight.emergencyActive
                  ? "bg-nr-text-secondary text-nr-bg hover:opacity-90"
                  : "bg-red-600 hover:bg-red-700"
              }`}
            >
              {tonight.emergencyActive ? "Resolve & Reopen" : "Publish Emergency Closure"}
            </button>
          </div>
        </div>

        <div className="w-full max-w-[260px] overflow-hidden rounded-2xl border border-nr-border bg-nr-surface">
          <p className="border-b border-nr-border/60 px-4 py-3.5 font-mono text-[10px] tracking-[0.15em] text-nr-text-hint">
            TONIGHT SCREEN
          </p>
          <div className="flex flex-col gap-3 p-4">
            <p className="font-display text-base uppercase text-nr-text-primary">
              {venues[editingVenue].name}
            </p>
            <div>
              <StatusChip
                label={activeStatus.label}
                className={`${activeStatus.className} rounded-full`}
                size="sm"
              />
            </div>
            <p className="text-xs text-nr-text-secondary">Queue: {queueText}</p>
            {tonight.flashActive && (
              <p className="rounded-lg border border-nr-accent/30 bg-nr-accent/10 px-2.5 py-2 text-[11px] text-nr-accent">
                LIVE: {tonight.flashText} until {tonight.flashUntil}
              </p>
            )}
            {tonight.emergencyActive && (
              <p className="rounded-lg border border-red-500/30 bg-red-500/10 px-2.5 py-2 text-[11px] text-red-400">
                Emergency closure live — off the map
              </p>
            )}
            <p className="border-t border-nr-border/60 pt-2.5 text-xs text-nr-text-secondary">
              Saves tonight: 84 · one-tap broadcast ready
            </p>
          </div>
        </div>
      </div>
    </>
  );
}
