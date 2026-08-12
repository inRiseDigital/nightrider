"use client";

import {
  gallerySlotIds,
  heroSlotId,
  useNow,
  useOrganizerDashboard,
} from "@/lib/organizer/dashboard/store";
import {
  capacityText,
  coverText,
  hoursTextFor,
  isOpenOn,
  mondayFirstIndex,
  toISODate,
} from "@/lib/organizer/dashboard/format";
import { ImageSlot } from "../ui/ImageSlot";
import { SectionEyebrow } from "../ui/Primitives";
import { StatusChip } from "../ui/StatusChip";

/**
 * The two cards the organizer's venue appears as inside the mobile app — the
 * map/list card and the full detail sheet. Both read the same image slot ids as
 * the editor, so edits show up here immediately.
 */
export function VenueAppPreview() {
  const { profile, editingVenue } = useOrganizerDashboard();
  const now = useNow();

  const hero = heroSlotId(editingVenue);
  const gallery = gallerySlotIds(editingVenue);

  // Before mount there is no clock, so fall back to Monday's row rather than
  // rendering a different day on the server than in the browser.
  const dayIdx = now ? mondayFirstIndex(now) : 0;
  const todayISO = now ? toISODate(now) : "";
  const openToday = now ? isOpenOn(profile, todayISO, dayIdx) : true;
  const nextException = profile.exceptions[0];

  const directionsHref = `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(
    `${profile.name} ${profile.city}`
  )}`;

  return (
    <div className="flex flex-col gap-3.5 lg:sticky lg:top-0">
      <SectionEyebrow>Live preview — how it appears in the app</SectionEyebrow>

      {/* Map / list card */}
      <div className="overflow-hidden rounded-2xl border border-nr-border bg-nr-surface">
        <div className="relative h-[150px]">
          <ImageSlot slotId={hero} placeholder="Hero image" rounded="rounded-none" />
          <div className="pointer-events-none absolute inset-0 bg-gradient-to-b from-transparent from-40% to-nr-bg/90" />
          <div className="pointer-events-none absolute right-2.5 top-2.5">
            <StatusChip
              label={openToday ? "OPEN TODAY" : "CLOSED TODAY"}
              className={
                openToday
                  ? "bg-emerald-500/10 text-emerald-400 ring-emerald-500/30"
                  : "bg-red-500/10 text-red-400 ring-red-500/30"
              }
              size="sm"
            />
          </div>
          <div className="pointer-events-none absolute bottom-2.5 left-3 right-3">
            <p className="font-display text-base uppercase tracking-wide text-nr-text-primary">
              {profile.name}
            </p>
            <p className="mt-0.5 text-[11px] text-nr-text-secondary">{profile.city}</p>
          </div>
        </div>
        <div className="flex flex-col gap-2 p-3">
          <div className="flex flex-wrap gap-1.5">
            {profile.genres.slice(0, 2).map((g) => (
              <span
                key={g}
                className="rounded-full border border-nr-primary-light/30 bg-nr-primary-light/10 px-2 py-0.5 text-[10px] font-semibold text-nr-primary-light"
              >
                {g}
              </span>
            ))}
          </div>
          <div className="flex justify-between font-mono text-[11px] text-nr-text-secondary">
            <span>{coverText(profile)}</span>
            <span>{capacityText(profile)}</span>
          </div>
        </div>
      </div>

      {/* Detail sheet */}
      <div className="overflow-hidden rounded-2xl border border-nr-border bg-nr-surface">
        <div className="relative h-[150px]">
          <ImageSlot slotId={hero} placeholder="Hero image" rounded="rounded-none" />
        </div>
        <div className="grid grid-cols-4 gap-1 p-1">
          {gallery.map((slotId) => (
            <ImageSlot
              key={slotId}
              slotId={slotId}
              placeholder="+"
              rounded="rounded-none"
              className="h-[42px]"
              compact
            />
          ))}
        </div>
        <div className="flex flex-col gap-3 p-4">
          <div>
            <p className="font-display text-lg uppercase text-nr-text-primary">{profile.name}</p>
            <p className="mt-0.5 text-xs text-nr-text-secondary">
              {profile.city} · {profile.dressCode} · {profile.agePolicy}
            </p>
          </div>
          <div className="flex flex-wrap gap-1.5">
            {[...profile.genres, ...profile.amenities].map((label) => (
              <span
                key={label}
                className="rounded-full border border-nr-primary-light/30 bg-nr-primary-light/10 px-2.5 py-0.5 text-[10px] font-semibold text-nr-primary-light"
              >
                {label}
              </span>
            ))}
          </div>
          <div className="flex justify-between border-t border-nr-border/60 pt-2.5 font-mono text-xs text-nr-text-secondary">
            <span>Cover {coverText(profile)}</span>
            <span>{capacityText(profile)}</span>
          </div>
          <p className="text-xs text-nr-text-primary">
            <span className="text-nr-text-secondary">Today: </span>
            {hoursTextFor(profile, dayIdx)}
          </p>
          {nextException && (
            <p className="rounded-lg border border-amber-500/30 bg-amber-500/10 px-2.5 py-2 text-[11px] text-amber-400">
              Upcoming: {nextException.label} — {nextException.date}
            </p>
          )}
          <div className="mt-1 flex gap-2">
            <span
              className={`flex-1 rounded-lg border px-2 py-2.5 text-center text-xs font-semibold ${
                profile.tableLink
                  ? "border-nr-primary bg-nr-primary text-nr-text-primary"
                  : "border-nr-border text-nr-text-hint"
              }`}
            >
              {profile.tableLink ? "Reserve a Table" : "Add table link"}
            </span>
            <a
              href={directionsHref}
              target="_blank"
              rel="noreferrer"
              className="flex-1 rounded-lg bg-nr-primary-light px-2 py-2.5 text-center text-xs font-semibold text-nr-bg hover:opacity-90"
            >
              Get Directions
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
