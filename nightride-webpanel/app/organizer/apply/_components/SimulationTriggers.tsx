"use client";

import { devSimulate } from "@/lib/organizer/application-service";
import { useApplicationActions, useApplicationState } from "@/lib/organizer/store";

/**
 * Stand-ins for events this page cannot originate: admin decisions and mobile
 * app uploads. They write to the same Firestore document the real actors will,
 * so the states are genuinely persisted — but they are hidden outside
 * development, because an applicant must never be able to drive these fields.
 */
export function SimulationTriggers() {
  const { busy } = useApplicationState();
  const { addExtraStep, completeBaseSteps, reject } = useApplicationActions();

  if (!devSimulate.enabled) return null;

  const triggers: { label: string; onClick: () => void }[] = [
    { label: "simulate: admin requests more info", onClick: () => void addExtraStep("more_info") },
    { label: "simulate: mail verification code (postcard)", onClick: () => void addExtraStep("postcard") },
    { label: "simulate: schedule live video call", onClick: () => void addExtraStep("video_call") },
    { label: "simulate: mobile app completes all steps", onClick: () => void completeBaseSteps() },
    { label: "simulate: application rejected", onClick: () => void reject() },
  ];

  return (
    <div className="mt-6 border-t border-nr-border/60 pt-4">
      <p className="mb-2.5 font-mono text-[10px] uppercase tracking-[0.08em] text-nr-text-hint">
        Dev only — stands in for the admin panel and mobile app
      </p>
      <div className="flex flex-wrap gap-3.5">
        {triggers.map((trigger) => (
          <button
            key={trigger.label}
            type="button"
            disabled={busy}
            onClick={trigger.onClick}
            className="border-b border-dashed border-nr-border font-mono text-[11px] text-nr-text-hint transition-colors hover:text-nr-text-secondary disabled:opacity-40"
          >
            {trigger.label}
          </button>
        ))}
      </div>
    </div>
  );
}
