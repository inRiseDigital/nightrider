"use client";

import { ChevronDown, ChevronUp } from "lucide-react";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { VERIFY_STEPS } from "@/lib/organizer/dashboard/constants";

/**
 * Gate shown instead of the venue editor until an admin approves a newly added
 * venue. The checks themselves are completed in the mobile app, so this screen
 * only reports progress — the one clickable action is the prototype's
 * "simulate approval" affordance.
 */
export function VenueVerifyPending() {
  const { profile, editingVenue, toggleVerifyStep } = useOrganizerDashboard();

  return (
    <div className="max-w-[640px]">
      <h2 className="mb-1.5 font-display text-base uppercase tracking-wide text-[var(--m3-on)]">
        Verify {profile.name} before it goes live
      </h2>
      <p className="mb-5 text-[13px] text-[var(--m3-onv)]">
        New venues go through the same verification as your organizer application — complete these
        from the mobile app.
      </p>

      <div className="flex flex-col gap-2.5">
        {VERIFY_STEPS.map((step) => {
          const done = profile.verificationSteps?.[step.id] === "done";
          const isOpen = profile.openVerifyStep === step.id;
          return (
            <div
              key={step.id}
              className={`overflow-hidden rounded-lg border bg-[var(--m3-surf1)] ${
                done ? "border-emerald-500/30" : "border-[var(--m3-ter)]/30"
              }`}
            >
              <button
                onClick={() => toggleVerifyStep(editingVenue, step.id)}
                aria-expanded={isOpen}
                className="flex w-full items-center gap-3 px-[18px] py-4 text-left"
              >
                <span
                  className={`flex h-[26px] w-[26px] shrink-0 items-center justify-center rounded-full font-mono text-xs font-bold ${
                    done
                      ? "bg-emerald-500/10 text-emerald-400"
                      : "bg-[var(--m3-ter)]/10 text-[var(--m3-ter)]"
                  }`}
                >
                  {done ? "✓" : "•"}
                </span>
                <span className="flex-1">
                  <span className="block text-sm font-semibold text-[var(--m3-on)]">
                    {step.label}
                  </span>
                  <span
                    className={`mt-0.5 block font-mono text-[11px] ${
                      done ? "text-emerald-400" : "text-[var(--m3-ter)]"
                    }`}
                  >
                    {done ? "Completed" : "In progress — waiting on mobile app"}
                  </span>
                </span>
                <span className="text-[var(--m3-outline)]">
                  {isOpen ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
                </span>
              </button>
              {isOpen && (
                <div className="border-t border-[var(--m3-outlinev)] px-[18px] pb-[18px]">
                  <p className="my-3.5 text-[13px] text-[var(--m3-onv)]">{step.detail}</p>
                  <div className="h-[90px] w-[140px] rounded-lg border border-[var(--m3-outlinev)] bg-[repeating-linear-gradient(45deg,#17171A,#17171A_8px,#0F0F0F_8px,#0F0F0F_16px)]" />
                </div>
              )}
            </div>
          );
        })}
      </div>

      <p className="mt-[18px] rounded-lg border border-[var(--m3-ter)]/30 bg-[var(--m3-ter)]/10 px-4 py-3.5 text-xs text-[var(--m3-ter)]">
        Once all steps are complete, an admin reviews and approves the venue — then its editor and
        app preview unlock.
      </p>
    </div>
  );
}
