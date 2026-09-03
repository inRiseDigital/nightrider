"use client";

import { X } from "lucide-react";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { pct } from "@/lib/organizer/dashboard/format";
import { FieldLabel, SlimInput, SlimTextarea } from "../ui/Primitives";

/** Push copy budget — the count is advisory, matching the design. */
const PUSH_MAX_CHARS = 140;

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
    boost,
    setBoostNight,
    toggleBoost,
    promotionLoading,
    promotionError,
    promotionBusy,
    promotionActionError,
  } = useOrganizerDashboard();

  // Informational only — `promoState/current` is display state the organizer
  // cannot write, and the real weekly cap is enforced server-side by the FCM
  // fanout function before a queued push actually sends. Disabling "Send"
  // here would present a client-side read as a guarantee it isn't.
  const atQuota = push.rateMax > 0 && push.rateUsed >= push.rateMax;

  return (
    <div className="flex flex-col gap-4">
      {promotionError && (
        <p className="text-xs text-[var(--m3-err)]">Couldn&apos;t load promotion data: {promotionError}</p>
      )}
      {promotionActionError && <p className="text-xs text-[var(--m3-err)]">{promotionActionError}</p>}

      <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
        <div className="mb-2.5 flex flex-wrap items-center justify-between gap-2">
          <FieldLabel>Push to users who favourited your clubs</FieldLabel>
          <span className="font-mono text-[11px] text-[var(--m3-onv)]">
            {promotionLoading
              ? "Loading…"
              : `${Math.max(0, push.rateMax - push.rateUsed)} of ${push.rateMax} pushes left this week`}
          </span>
        </div>
        <div className="mb-3 h-1.5 overflow-hidden rounded-full bg-[var(--m3-surf2)]">
          <div className="h-full bg-[var(--m3-pri)]" style={{ width: pct(push.rateUsed, push.rateMax || 1) }} />
        </div>
        <SlimTextarea
          value={push.message}
          onChange={(e) => setPushMessage(e.target.value)}
          placeholder="Free entry before midnight — see you tonight."
          className="min-h-[60px] w-full"
        />
        <div className="mt-2 flex items-center justify-between gap-3">
          <span
            className="font-mono text-xs"
            style={{ color: push.message.length > PUSH_MAX_CHARS ? "var(--m3-err)" : "var(--m3-onv)" }}
          >
            {push.message.length}/{PUSH_MAX_CHARS}
          </span>
          <button
            onClick={sendPush}
            disabled={promotionBusy}
            className="rounded-lg border border-[var(--m3-pri)] bg-[var(--m3-pri)] px-4 py-2.5 text-xs font-semibold text-[var(--m3-on)] transition-colors hover:bg-[var(--m3-pric)] disabled:cursor-not-allowed disabled:opacity-50"
          >
            Send Push
          </button>
        </div>
        {atQuota && (
          <p className="mt-2 text-[11px] text-[var(--m3-warn)]">
            You&apos;re at this week&apos;s advisory limit — a send may still be held back when it goes out.
          </p>
        )}
      </div>

      <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
        <div className="mb-3 flex items-center justify-between">
          <FieldLabel>Guest list &amp; promo codes</FieldLabel>
          <button
            onClick={addPromo}
            disabled={promotionBusy}
            className="text-xs font-semibold text-[var(--m3-pri)] hover:text-[var(--m3-pric)] disabled:opacity-50"
          >
            + Add code
          </button>
        </div>
        {promotionLoading ? (
          <p className="py-2 text-xs text-[var(--m3-outline)]">Loading…</p>
        ) : promos.length === 0 ? (
          <p className="py-2 text-xs text-[var(--m3-outline)]">No promo codes yet.</p>
        ) : (
          promos.map((p, i) => (
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
          ))
        )}
      </div>

      <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
        <FieldLabel className="mb-3">Perks for high-rank / frequent check-in users</FieldLabel>
        {/* Read-only: `rankPerks/current` is `write: if false` in firestore.rules
            for every role — there is no client write path for this document. */}
        {promotionLoading ? (
          <p className="py-2 text-xs text-[var(--m3-outline)]">Loading…</p>
        ) : perks.length === 0 ? (
          <p className="py-2 text-xs text-[var(--m3-outline)]">No perks configured yet.</p>
        ) : (
          perks.map((p) => (
            <div key={p.tier} className="flex items-center gap-2.5 py-2">
              <span className="w-[70px] shrink-0 text-xs font-semibold text-[var(--m3-warn)]">{p.tier}</span>
              <SlimInput readOnly disabled value={p.perk} className="min-w-0 flex-1 py-2 text-xs opacity-70" />
            </div>
          ))
        )}
      </div>

      <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
        <FieldLabel className="mb-2.5">Featured / boost placement</FieldLabel>
        <div className="flex flex-wrap items-center gap-3">
          <SlimInput
            type="date"
            mono
            value={boost.night}
            onChange={(e) => setBoostNight(e.target.value)}
            disabled={boost.active}
            className="py-2"
          />
          <span className="font-mono text-[13px] text-[var(--m3-onv)]">${boost.price}</span>
          <button
            onClick={toggleBoost}
            disabled={promotionBusy}
            className={`rounded-lg border border-[var(--m3-warn)] px-4 py-2.5 text-xs font-semibold transition-colors disabled:cursor-not-allowed disabled:opacity-50 ${
              boost.active ? "bg-[var(--m3-warn)]/10 text-[var(--m3-warn)]" : "bg-[var(--m3-warn)] text-[var(--m3-onpri)]"
            }`}
          >
            {boost.active ? "Boost Active" : "Buy Boost"}
          </button>
        </div>
        {boost.active && (
          <p className="mt-2 text-[11px] text-[var(--m3-outline)]">
            Bought boosts can&apos;t be changed or cancelled from here.
          </p>
        )}
      </div>
    </div>
  );
}
