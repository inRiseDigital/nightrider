"use client";

import { useRouter } from "next/navigation";
import { CheckCircle2 } from "lucide-react";
import { useNow, useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { MOCK_AI_INTENTS, MOCK_AI_RECOMMEND_COUNT } from "@/lib/organizer/dashboard/mock-data";
import {
  MOCK_AI_PROMPTS,
  MOCK_AI_SCORE,
  MOCK_AI_TIPS,
  type AiPrompt,
} from "@/lib/organizer/dashboard/mock-analytics";
import { Card, FieldLabel, SectionLabel, VenueSwitcher } from "../ui/Primitives";

/** Chip tone per ranking band — top spots read as success, absence as neutral. */
const RANK_CHIP: Record<AiPrompt["band"], { background: string; color: string }> = {
  top: { background: "var(--m3-succ)", color: "var(--m3-onsucc)" },
  strong: { background: "var(--m3-terc)", color: "var(--m3-onterc)" },
  weak: { background: "var(--m3-warnc)", color: "var(--m3-onwarnc)" },
  absent: { background: "var(--m3-surf3)", color: "var(--m3-onv)" },
};

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

  const goToVenueProfile = () => {
    setVenueTab("profile");
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
      onCta: () => goToVenueProfile(),
    },
    {
      label: "Amenities & attributes complete",
      pass: amenitiesSet,
      hint: amenitiesSet
        ? "Filters like rooftop / smoking area are filled in."
        : "Add at least 2 amenities so filter-based searches surface you.",
      ctaLabel: amenitiesSet ? undefined : "Add amenities",
      onCta: () => goToVenueProfile(),
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
      onCta: () => goToVenueProfile(),
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

      <div className="mb-4 grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div
          className="flex flex-col items-center rounded-2xl p-6 text-center"
          style={{ background: "var(--m3-surf2)" }}
        >
          <h3 className="self-start text-base font-medium tracking-[0.15px] text-[var(--m3-on)]">
            AI recommendation score
          </h3>
          <div
            className="my-6 mb-2 flex h-[180px] w-[180px] items-center justify-center rounded-full"
            style={{
              background: `conic-gradient(var(--m3-pri) 0turn ${
                MOCK_AI_SCORE / 100
              }turn, var(--m3-surf3) ${MOCK_AI_SCORE / 100}turn 1turn)`,
            }}
            role="img"
            aria-label={`AI recommendation score ${MOCK_AI_SCORE} of 100`}
          >
            <div
              className="flex h-36 w-36 flex-col items-center justify-center rounded-full"
              style={{ background: "var(--m3-surf2)" }}
            >
              <span className="font-mono text-[40px] font-medium leading-none text-[var(--m3-on)]">
                {MOCK_AI_SCORE}
              </span>
              <span className="mt-1 text-xs tracking-[0.5px] text-[var(--m3-onv)]">of 100</span>
            </div>
          </div>
          <p className="max-w-[280px] text-[13px] leading-5 text-[var(--m3-onv)]">
            How often Night Ride&apos;s assistant surfaces your venue for matching requests.
          </p>
        </div>

        <Card className="!p-0 py-2">
          <h3 className="px-5 pb-2 pt-3 text-base font-medium tracking-[0.15px] text-[var(--m3-on)]">
            Where you appear
          </h3>
          {MOCK_AI_PROMPTS.map((p) => (
            <div
              key={p.prompt}
              className="flex min-h-16 items-center gap-4 border-b border-[var(--m3-outlinev)] px-5 py-3"
            >
              <div className="min-w-0 flex-1">
                <p className="text-sm text-[var(--m3-on)]">&ldquo;{p.prompt}&rdquo;</p>
                <p className="mt-0.5 text-xs text-[var(--m3-onv)]">{p.volume}</p>
              </div>
              <span
                className="shrink-0 rounded-lg px-2.5 py-1 text-[11px] font-medium tracking-[0.5px]"
                style={RANK_CHIP[p.band]}
              >
                {p.rank}
              </span>
            </div>
          ))}
          <div className="px-5 py-4">
            <SectionLabel className="mb-2.5">Raise your score</SectionLabel>
            {MOCK_AI_TIPS.map((tip) => (
              <div key={tip} className="mb-3 flex items-start gap-3 last:mb-0">
                <CheckCircle2 size={18} className="mt-px shrink-0" color="var(--m3-ter)" />
                <p className="text-[13px] leading-[19px] text-[var(--m3-onv)]">{tip}</p>
              </div>
            ))}
          </div>
        </Card>
      </div>

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
