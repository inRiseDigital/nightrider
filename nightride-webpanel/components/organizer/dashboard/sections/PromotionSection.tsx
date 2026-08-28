"use client";

import { X } from "lucide-react";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { pct } from "@/lib/organizer/dashboard/format";
import { FieldLabel, SlimInput, SlimTextarea } from "../ui/Primitives";

export function PromotionSection() {
  const {
    push,
    setPushMessage,
    sendPush,
    promos,
    addPromo,
    updatePromo,
    removePromo,
    perks,
    updatePerk,
    boost,
    setBoostNight,
    toggleBoost,
  } = useOrganizerDashboard();

  const pushLimited = push.rateUsed >= push.rateMax;

  return (
    <div className="flex flex-col gap-4">
      <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
        <div className="mb-2.5 flex flex-wrap items-center justify-between gap-2">
          <FieldLabel>Push to users who favourited your clubs</FieldLabel>
          <span className="font-mono text-[11px] text-[var(--m3-onv)]">
            {push.rateUsed} of {push.rateMax} pushes this month
          </span>
        </div>
        <div className="mb-3 h-1.5 overflow-hidden rounded-full bg-[var(--m3-surf2)]">
          <div
            className="h-full bg-[var(--m3-pri)]"
            style={{ width: pct(push.rateUsed, push.rateMax) }}
          />
        </div>
        <SlimTextarea
          value={push.message}
          onChange={(e) => setPushMessage(e.target.value)}
          placeholder="Free entry before midnight — see you tonight."
          className="min-h-[60px] w-full"
        />
        <button
          onClick={sendPush}
          disabled={pushLimited}
          className={`mt-2.5 rounded-lg border px-4 py-2.5 text-xs font-semibold transition-colors ${
            pushLimited
              ? "cursor-not-allowed border-[var(--m3-outlinev)] text-[var(--m3-outline)]"
              : "border-[var(--m3-pri)] bg-[var(--m3-pri)] text-[var(--m3-on)] hover:bg-[var(--m3-pric)]"
          }`}
        >
          {pushLimited ? "Limit Reached" : "Send Push"}
        </button>
      </div>

      <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
        <div className="mb-3 flex items-center justify-between">
          <FieldLabel>Guest list &amp; promo codes</FieldLabel>
          <button
            onClick={addPromo}
            className="text-xs font-semibold text-[var(--m3-pri)] hover:text-[var(--m3-pric)]"
          >
            + Add code
          </button>
        </div>
        {promos.map((p, i) => (
          <div
            key={i}
            className="flex flex-wrap items-center gap-2.5 border-b border-[var(--m3-outlinev)] py-2.5 last:border-b-0"
          >
            <SlimInput
              mono
              value={p.code}
              onChange={(e) => updatePromo(i, "code", e.target.value)}
              className="w-[150px] py-2 text-xs"
            />
            <SlimInput
              value={p.desc}
              onChange={(e) => updatePromo(i, "desc", e.target.value)}
              placeholder="Description"
              className="min-w-0 flex-1 py-2 text-xs"
            />
            <span className="whitespace-nowrap font-mono text-[11px] text-[var(--m3-onv)]">
              {p.used}/{p.maxUses} used
            </span>
            <button
              onClick={() => removePromo(i)}
              className="px-1 text-[var(--m3-outline)] hover:text-red-400"
              aria-label={`Remove code ${p.code}`}
            >
              <X size={14} />
            </button>
          </div>
        ))}
      </div>

      <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
        <FieldLabel className="mb-3">Perks for high-rank / frequent check-in users</FieldLabel>
        {perks.map((p, i) => (
          <div key={p.tier} className="flex items-center gap-2.5 py-2">
            <span className="w-[70px] shrink-0 text-xs font-semibold text-[var(--m3-warn)]">{p.tier}</span>
            <SlimInput
              value={p.perk}
              onChange={(e) => updatePerk(i, e.target.value)}
              className="min-w-0 flex-1 py-2 text-xs"
            />
          </div>
        ))}
      </div>

      <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
        <FieldLabel className="mb-2.5">Featured / boost placement</FieldLabel>
        <div className="flex flex-wrap items-center gap-3">
          <SlimInput
            type="date"
            mono
            value={boost.night}
            onChange={(e) => setBoostNight(e.target.value)}
            className="py-2"
          />
          <span className="font-mono text-[13px] text-[var(--m3-onv)]">${boost.price}</span>
          <button
            onClick={toggleBoost}
            className={`rounded-lg border border-[var(--m3-warn)] px-4 py-2.5 text-xs font-semibold transition-colors ${
              boost.active ? "bg-[var(--m3-warn)]/10 text-[var(--m3-warn)]" : "bg-[var(--m3-warn)] text-[var(--m3-onpri)]"
            }`}
          >
            {boost.active ? "Boost Active — Cancel" : "Buy Boost"}
          </button>
        </div>
      </div>
    </div>
  );
}
