"use client";

import Link from "next/link";
import {
  OctagonAlert,
  Check,
  Gavel,
  Image as ImageIcon,
  Martini,
  Megaphone,
  Minus,
  Plus,
  Sparkles,
  Star,
  Ticket,
  Wallet,
  Eye,
  type LucideIcon,
} from "lucide-react";
import {
  heroSlotId,
  useNow,
  useOrganizerDashboard,
} from "@/lib/organizer/dashboard/store";
import { DOOR_STATUSES } from "@/lib/organizer/dashboard/constants";
import { deriveEventChip, toISODate, venueName } from "@/lib/organizer/dashboard/format";
import { resolveTimeZone } from "@/lib/organizer/dashboard/data/time";
import { Toggle } from "../ui/Primitives";
import { StatusChip } from "../ui/StatusChip";

const MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

/**
 * The mockup's door control is three wide segments; we carry all five door
 * states, so the pill uses abbreviated labels (full text stays in the tooltip).
 */
const DOOR_SHORT_LABELS: Record<string, string> = {
  open: "Open",
  filling: "Filling",
  capacity: "Full",
  guestlist: "List",
  closed: "Closed",
};

const KPI_ICONS: Record<string, LucideIcon> = {
  rsvp: Ticket,
  revenue: Wallet,
  views: Eye,
  ai: Sparkles,
};

/**
 * Trend deltas have no backing document in this task's four shapes (metrics,
 * aiVisibility, promotion, activity) — nothing here stores a week-over-week
 * comparison to derive them from, so they stay illustrative placeholders
 * rather than a number invented to look real. `value` is filled in for real
 * below, from `tonightEvent`, the performance funnel, and the AI score.
 */
const KPI_META: {
  icon: "rsvp" | "revenue" | "views" | "ai";
  label: string;
  delta: string;
  tone: "primary" | "tertiary";
  deltaTone: "up" | "down";
}[] = [
  { icon: "rsvp", label: "RSVPs tonight", delta: "+18%", tone: "primary", deltaTone: "up" },
  { icon: "revenue", label: "Ticket revenue (AED)", delta: "+7%", tone: "tertiary", deltaTone: "up" },
  { icon: "views", label: "Profile views, 7d", delta: "−4%", tone: "primary", deltaTone: "down" },
  { icon: "ai", label: "AI recommendation score", delta: "+6", tone: "tertiary", deltaTone: "up" },
];

/**
 * Home → Live operations: the mockup's single combined control screen — one
 * live-ops card for tonight's door, then the KPI row, then the two review
 * panels. Everything reads the shared dashboard store, so edits here show up
 * on the venue's tonight screen too.
 */
export function LiveOperationsSection() {
  const {
    profile,
    editingVenue,
    venues,
    venueMeta,
    venueOrder,
    events,
    reviews,
    images,
    tonight,
    liveBusy,
    setDoorStatus,
    setQueueMinutes,
    toggleFlash,
    toggleEmergency,
    setEventsTab,
    setAudienceTab,
    setAccountTab,
    setVenueTab,
    openAddVenue,
    perfMetrics,
    aiVisibility,
  } = useOrganizerDashboard();
  const now = useNow();

  const doorsOpen = tonight.status === "open" || tonight.status === "filling";
  const occupancyPct = profile.capacity
    ? Math.min(100, Math.round((tonight.inVenue / profile.capacity) * 100))
    : 0;

  // Tonight's event at this venue, else the soonest one still to come.
  const venueEvents = events
    .filter((e) => e.venue === editingVenue && e.status !== "cancelled")
    .slice()
    .sort((a, b) => a.date.localeCompare(b.date));
  const todayISO = now ? toISODate(now) : "";
  const tonightEvent = venueEvents.find((e) => e.date === todayISO) ?? venueEvents[0];

  // "Profile views" reuses the discovery funnel's "Profile opened" count —
  // the same absolute number the Performance tab derives its bar chart from,
  // not a second, independently-maintained figure.
  const profileViews = perfMetrics?.funnel.find((f) => f.label === "Profile opened")?.value ?? "—";
  const kpiValues: Record<string, string> = {
    rsvp: tonightEvent ? String(tonightEvent.sold) : "—",
    revenue: tonightEvent ? `${(tonightEvent.revenue / 1000).toFixed(1)}k` : "—",
    views: profileViews,
    ai: aiVisibility ? String(aiVisibility.score) : "—",
  };

  const attention = buildAttention();

  // The mockup's "next 7 nights"; the seeded events sit outside a real 7-day
  // window, so fall back to the soonest upcoming nights rather than an empty panel.
  const upcoming = events
    .filter((e) => e.status !== "cancelled")
    .slice()
    .sort((a, b) => a.date.localeCompare(b.date));
  const withinWeek = todayISO
    ? upcoming.filter((e) => e.date >= todayISO && e.date <= addDays(todayISO, 7))
    : [];
  const nextNights = (withinWeek.length ? withinWeek : upcoming).slice(0, 4);

  function buildAttention() {
    const rows: {
      key: string;
      Icon: LucideIcon;
      iconBg: string;
      iconFg: string;
      title: string;
      body: string;
      action: string;
      href: string;
      onClick: () => void;
    }[] = [];

    for (const ev of events.filter((e) => e.status === "in_review")) {
      rows.push({
        key: `review-${ev.id}`,
        Icon: Gavel,
        iconBg: "var(--m3-warnc)",
        iconFg: "var(--m3-onwarnc)",
        title: `${ev.name} is in review`,
        body:
          ev.moderationFlag === "pending"
            ? `Flagged as a possible duplicate${ev.moderationEta ? ` · ${ev.moderationEta}` : ""}`
            : "Awaiting platform review before it publishes",
        action: "Review",
        href: "/organizer/events",
        onClick: () => setEventsTab("list"),
      });
    }

    for (const [id, venue] of Object.entries(venues)) {
      if (images[heroSlotId(id)]) continue;
      rows.push({
        key: `hero-${id}`,
        Icon: ImageIcon,
        iconBg: "var(--m3-pric)",
        iconFg: "var(--m3-onpric)",
        title: `${venue.name} is missing a hero image`,
        body: "Listings without a hero rank lower in the assistant",
        action: "Upload",
        href: "/organizer/venues",
        onClick: () => setVenueTab("profile"),
      });
    }

    const flagged = reviews.filter((r) => r.flagged);
    if (flagged.length) {
      rows.push({
        key: "flagged-reviews",
        Icon: Star,
        iconBg: "var(--m3-errc)",
        iconFg: "var(--m3-onerrc)",
        title: `${flagged.length} review${flagged.length > 1 ? "s" : ""} flagged for moderation`,
        body: flagged.map((r) => r.author).join(", "),
        action: "Open",
        href: "/organizer/performance",
        onClick: () => setAudienceTab("reviews"),
      });
    }

    return rows;
  }

  if (venueOrder.length === 0) {
    return (
      <div className="rounded-2xl bg-[var(--m3-surf2)] p-8 text-center">
        <p className="text-sm text-[var(--m3-on)]">Add a venue to get started.</p>
        <p className="mt-1.5 text-[13px] text-[var(--m3-onv)]">
          Tonight&apos;s door status, KPIs, and activity all live here once you have a venue.
        </p>
        <Link
          href="/organizer/venues"
          onClick={openAddVenue}
          className="mx-auto mt-4 flex h-10 w-fit items-center gap-2 rounded-full px-6 text-sm font-medium transition-opacity hover:opacity-90"
          style={{ background: "var(--m3-pri)", color: "var(--m3-onpri)" }}
        >
          <Plus size={18} />
          Add venue
        </Link>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Live operations control */}
      <div className="rounded-2xl bg-[var(--m3-surf2)] p-6">
        <div className="flex flex-wrap items-start gap-4">
          <div className="min-w-[260px] flex-1">
            <div className="flex flex-wrap items-center gap-2.5">
              <Martini size={19} color="var(--m3-pri)" />
              <p className="text-base font-medium text-[var(--m3-on)]">
                Tonight — {profile.name}
              </p>
              <span
                className="flex items-center gap-1.5 rounded-lg px-2.5 py-1 text-[11px] font-medium tracking-wide"
                style={
                  doorsOpen
                    ? { background: "var(--m3-succ)", color: "var(--m3-onsucc)" }
                    : { background: "var(--m3-errc)", color: "var(--m3-onerrc)" }
                }
              >
                <span
                  className="h-1.5 w-1.5 rounded-full"
                  style={{ background: doorsOpen ? "var(--m3-suc)" : "var(--m3-err)" }}
                />
                {doorsOpen ? "DOORS OPEN" : "DOORS CLOSED"}
              </span>
            </div>
            <p className="mt-1.5 text-sm text-[var(--m3-onv)]">
              {tonightEvent
                ? `${tonightEvent.name} · ${tonightEvent.startTime}–${tonightEvent.endTime} · `
                : ""}
              Live operations control
            </p>
          </div>

          <div className="flex items-center gap-2">
            <Link
              href="/organizer/account"
              onClick={() => setAccountTab("promotion")}
              className="flex h-10 items-center gap-2 rounded-full px-5 text-sm font-medium transition-opacity hover:opacity-90"
              style={{ background: "var(--m3-pri)", color: "var(--m3-onpri)" }}
            >
              <Megaphone size={17} />
              Send update
            </Link>
            <button
              onClick={toggleEmergency}
              disabled={liveBusy.emergency}
              className="flex h-10 items-center gap-2 rounded-full border px-5 text-sm font-medium transition-colors disabled:cursor-not-allowed disabled:opacity-50"
              style={{
                borderColor: "var(--m3-err)",
                color: tonight.emergencyActive ? "var(--m3-onerrc)" : "var(--m3-err)",
                background: tonight.emergencyActive ? "var(--m3-errc)" : "transparent",
              }}
            >
              <OctagonAlert size={17} />
              {tonight.emergencyActive ? "Reopen venue" : "Emergency close"}
            </button>
          </div>
        </div>

        <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {/* Door status */}
          <div className="rounded-xl bg-[var(--m3-surf1)] p-4">
            <p className="text-xs text-[var(--m3-onv)]">Door status</p>
            <div
              className="mt-3 flex overflow-hidden rounded-full border"
              style={{ borderColor: "var(--m3-outline)" }}
            >
              {DOOR_STATUSES.map((s, i) => {
                const active = tonight.status === s.id;
                return (
                  <button
                    key={s.id}
                    onClick={() => setDoorStatus(s.id)}
                    disabled={liveBusy.door}
                    aria-pressed={active}
                    title={s.label}
                    className="flex h-10 min-w-0 flex-1 items-center justify-center gap-1 px-1.5 text-[11px] font-medium transition-colors disabled:cursor-not-allowed disabled:opacity-50"
                    style={{
                      borderLeft: `1px solid ${i === 0 ? "transparent" : "var(--m3-outline)"}`,
                      background: active ? "var(--m3-pric)" : "transparent",
                      color: active ? "var(--m3-onpric)" : "var(--m3-onv)",
                    }}
                  >
                    {active && <Check size={13} className="shrink-0" />}
                    <span className="truncate">{DOOR_SHORT_LABELS[s.id] ?? s.label}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* In venue */}
          <div className="rounded-xl bg-[var(--m3-surf1)] p-4">
            <p className="text-xs text-[var(--m3-onv)]">In venue</p>
            <div className="mt-1.5 flex items-baseline gap-1.5">
              <span className="font-mono text-[28px] font-medium text-[var(--m3-on)]">
                {tonight.inVenue}
              </span>
              <span className="text-[13px] text-[var(--m3-onv)]">/ {profile.capacity}</span>
            </div>
            <div
              className="mt-3 h-1 overflow-hidden rounded-full"
              style={{ background: "var(--m3-track)" }}
            >
              <div
                className="h-full rounded-full"
                style={{ width: `${occupancyPct}%`, background: "var(--m3-pri)" }}
              />
            </div>
          </div>

          {/* Queue wait */}
          <div className="rounded-xl bg-[var(--m3-surf1)] p-4">
            <p className="text-xs text-[var(--m3-onv)]">Queue wait</p>
            <div className="mt-2 flex items-center gap-2">
              <button
                onClick={() => setQueueMinutes(Math.max(0, tonight.queueMinutes - 5))}
                aria-label="Decrease queue wait"
                className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border text-[var(--m3-onv)] transition-colors hover:bg-[var(--m3-surf3)]"
                style={{ borderColor: "var(--m3-outline)" }}
              >
                <Minus size={16} />
              </button>
              <p className="flex-1 text-center font-mono text-2xl font-medium text-[var(--m3-on)]">
                {tonight.queueMinutes}
                <span className="font-sans text-xs text-[var(--m3-onv)]"> min</span>
              </p>
              <button
                onClick={() => setQueueMinutes(tonight.queueMinutes + 5)}
                aria-label="Increase queue wait"
                className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border text-[var(--m3-onv)] transition-colors hover:bg-[var(--m3-surf3)]"
                style={{ borderColor: "var(--m3-outline)" }}
              >
                <Plus size={16} />
              </button>
            </div>
          </div>

          {/* Flash offer */}
          <div className="rounded-xl bg-[var(--m3-surf1)] p-4">
            <div className="flex items-center justify-between gap-3">
              <div className="min-w-0">
                <p className="text-xs text-[var(--m3-onv)]">Flash offer</p>
                <p className="mt-1.5 text-[13px] text-[var(--m3-on)]">
                  {tonight.flashText || "No offer set"}
                </p>
              </div>
              <Toggle
                checked={tonight.flashActive}
                onChange={toggleFlash}
                label="Flash offer"
                disabled={liveBusy.flash}
              />
            </div>
          </div>
        </div>
      </div>

      {/* KPI row */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {KPI_META.map((kpi) => {
          const Icon = KPI_ICONS[kpi.icon] ?? Sparkles;
          return (
            <div key={kpi.label} className="rounded-xl bg-[var(--m3-surf1)] p-5">
              <div className="flex items-center justify-between">
                <span
                  className="flex h-10 w-10 items-center justify-center rounded-full"
                  style={{
                    background: "var(--m3-surf3)",
                    color: kpi.tone === "primary" ? "var(--m3-pri)" : "var(--m3-ter)",
                  }}
                >
                  <Icon size={21} />
                </span>
                <span
                  className="text-xs font-medium tracking-wide"
                  style={{ color: kpi.deltaTone === "up" ? "var(--m3-suc)" : "var(--m3-warn)" }}
                >
                  {kpi.delta}
                </span>
              </div>
              <p className="mt-4 font-mono text-[30px] font-medium leading-none text-[var(--m3-on)]">
                {kpiValues[kpi.icon]}
              </p>
              <p className="mt-1.5 text-[13px] text-[var(--m3-onv)]">{kpi.label}</p>
            </div>
          );
        })}
      </div>

      {/* Attention + next nights */}
      <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
        <div className="rounded-xl bg-[var(--m3-surf1)] py-2">
          <h2 className="px-5 pb-2 pt-4 text-base font-medium text-[var(--m3-on)]">
            Needs your attention
          </h2>
          {attention.length === 0 ? (
            <p className="px-5 py-4 text-[13px] text-[var(--m3-outline)]">
              Nothing needs you right now.
            </p>
          ) : (
            attention.map((a) => (
              <div
                key={a.key}
                className="flex min-h-[72px] items-center gap-4 px-5 py-3 transition-colors hover:bg-[var(--m3-surf2)]"
              >
                <span
                  className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full"
                  style={{ background: a.iconBg, color: a.iconFg }}
                >
                  <a.Icon size={19} />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-medium text-[var(--m3-on)]">{a.title}</p>
                  <p className="mt-0.5 truncate text-[13px] text-[var(--m3-onv)]">{a.body}</p>
                </div>
                <Link
                  href={a.href}
                  onClick={a.onClick}
                  className="flex h-9 shrink-0 items-center rounded-full bg-[var(--m3-surf3)] px-4 text-[13px] font-medium text-[var(--m3-on)] transition-colors hover:bg-[var(--m3-surf4)]"
                >
                  {a.action}
                </Link>
              </div>
            ))
          )}
        </div>

        <div className="rounded-xl bg-[var(--m3-surf1)] py-2">
          <h2 className="px-5 pb-2 pt-4 text-base font-medium text-[var(--m3-on)]">
            Next 7 nights
          </h2>
          {nextNights.length === 0 ? (
            <p className="px-5 py-4 text-[13px] text-[var(--m3-outline)]">
              No nights booked yet.
            </p>
          ) : (
            nextNights.map((ev) => {
              const chip = deriveEventChip(ev, now, resolveTimeZone(venueMeta[ev.venue]?.timeZone));
              const [, month, day] = ev.date.split("-");
              return (
                <Link
                  key={ev.id}
                  href="/organizer/events"
                  onClick={() => setEventsTab("list")}
                  className="flex min-h-[72px] items-center gap-4 px-5 py-3 transition-colors hover:bg-[var(--m3-surf2)]"
                >
                  <div className="w-12 shrink-0 text-center">
                    <p className="text-[11px] uppercase tracking-widest text-[var(--m3-onv)]">
                      {month ? MONTHS[Number(month) - 1] : "—"}
                    </p>
                    <p className="font-mono text-[22px] font-medium leading-tight text-[var(--m3-on)]">
                      {day ?? "–"}
                    </p>
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium text-[var(--m3-on)]">{ev.name}</p>
                    <p className="mt-0.5 truncate text-[13px] text-[var(--m3-onv)]">
                      {venueName(venues, ev.venue)}
                      {ev.lineup.length ? ` · ${ev.lineup.join(" · ")}` : ""}
                    </p>
                  </div>
                  <StatusChip label={chip.label} className={chip.className} />
                </Link>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
}

/** ISO date `days` after `iso`, used for the 7-night window. */
function addDays(iso: string, days: number): string {
  const d = new Date(`${iso}T00:00:00`);
  d.setDate(d.getDate() + days);
  return d.toISOString().slice(0, 10);
}
