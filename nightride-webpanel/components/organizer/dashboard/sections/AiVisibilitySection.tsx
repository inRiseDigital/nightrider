"use client";

import { useRouter } from "next/navigation";
import { useNow, useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { MOCK_AI_INTENTS, MOCK_AI_RECOMMEND_COUNT } from "@/lib/organizer/dashboard/mock-data";
import { FieldLabel, VenueSwitcher } from "../ui/Primitives";

interface Diagnostic {
  label: string;
  /** null = can't be checked from here. */
  pass: boolean | null;
  hint: string;
  ctaLabel?: string;
  onCta?: () => void;
}

export function AiVisibilitySection() {
  const router = useRouter();
  const { venueOrder, venues, editingVenue, setEditingVenue, profile, events, setVenueTab, openNewEvent } =
    useOrganizerDashboard();
  const now = useNow();

  const goToVenueTab = (tab: "attributes" | "gallery") => {
    setVenueTab(tab);
    router.push("/organizer/venues");
  };

  const genresSet = profile.genres.length > 0;
  const amenitiesSet = profile.amenities.length >= 2;

  // "Soon" means the event is upcoming and lands inside the next two weeks.
  const upcomingSoon = now
    ? events.some((e) => {
        if (e.venue !== editingVenue) return false;
        if (!["live", "scheduled", "in_review"].includes(e.status)) return false;
        const days = (new Date(e.date).getTime() - now.getTime()) / 86_400_000;
        return days < 14 && days >= -1;
      })
    : false;

  const diagnostics: Diagnostic[] = [
    {
      label: "Music genres set",
      pass: genresSet,
      hint: genresSet
        ? 'Genres help the AI match "techno tonight" style intents.'
        : "No genres tagged — you will be invisible to genre-based searches.",
      ctaLabel: genresSet ? undefined : "Set genres",
      onCta: () => goToVenueTab("attributes"),
    },
    {
      label: "Amenities & attributes complete",
      pass: amenitiesSet,
      hint: amenitiesSet
        ? "Filters like rooftop / smoking area are filled in."
        : "Add at least 2 amenities so filter-based searches surface you.",
      ctaLabel: amenitiesSet ? undefined : "Add amenities",
      onCta: () => goToVenueTab("attributes"),
    },
    {
      label: "Upcoming event within 14 days",
      pass: upcomingSoon,
      hint: upcomingSoon
        ? "You have something coming up — the AI can recommend you for tonight."
        : "No upcoming event soon — stale listings drop out of recommendations.",
      ctaLabel: upcomingSoon ? undefined : "Add event",
      onCta: () => {
        openNewEvent();
        router.push("/organizer/events");
      },
    },
    {
      label: "Gallery photos",
      pass: null,
      hint: "We can't verify from here — make sure you have a hero image plus 4 gallery photos.",
      ctaLabel: "Check gallery",
      onCta: () => goToVenueTab("gallery"),
    },
  ];

  const badgeFor = (pass: boolean | null) => {
    if (pass === true) return { mark: "✓", className: "bg-emerald-500/10 text-emerald-400" };
    if (pass === false) return { mark: "!", className: "bg-red-500/10 text-red-400" };
    return { mark: "?", className: "bg-white/5 text-[var(--m3-onv)]" };
  };

  return (
    <>
      <VenueSwitcher
        venueOrder={venueOrder}
        venues={venues}
        selected={editingVenue}
        onSelect={setEditingVenue}
      />

      <div className="mb-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
          <FieldLabel>Recommended by the AI companion this week</FieldLabel>
          <p className="mt-2 font-display text-[32px] leading-none text-[var(--m3-on)]">
            {MOCK_AI_RECOMMEND_COUNT}
          </p>
        </div>
        <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
          <FieldLabel className="mb-2.5">By intent</FieldLabel>
          {MOCK_AI_INTENTS.map((i) => (
            <div key={i.label} className="flex justify-between py-0.5 text-xs">
              <span className="text-[var(--m3-on)]">&ldquo;{i.label}&rdquo;</span>
              <span className="font-mono text-[var(--m3-onv)]">{i.count}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
        <FieldLabel className="mb-3.5">Why am I not being recommended more?</FieldLabel>
        {diagnostics.map((d) => {
          const badge = badgeFor(d.pass);
          return (
            <div
              key={d.label}
              className="flex flex-wrap items-center gap-3 border-b border-[var(--m3-outlinev)] py-3 last:border-b-0"
            >
              <span
                className={`flex h-[22px] w-[22px] shrink-0 items-center justify-center rounded-full text-xs font-bold ${badge.className}`}
              >
                {badge.mark}
              </span>
              <div className="min-w-[200px] flex-1">
                <p className="text-[13px] font-semibold text-[var(--m3-on)]">{d.label}</p>
                <p className="mt-px text-[11px] text-[var(--m3-outline)]">{d.hint}</p>
              </div>
              {d.ctaLabel && (
                <button
                  onClick={d.onCta}
                  className="whitespace-nowrap text-xs font-semibold text-[var(--m3-ter)] hover:text-[var(--m3-warn)]"
                >
                  {d.ctaLabel}
                </button>
              )}
            </div>
          );
        })}
      </div>
    </>
  );
}
