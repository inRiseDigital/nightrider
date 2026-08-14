"use client";

import { Fragment } from "react";
import { cn } from "@/components/organizer/ui/cn";
import { useApplicationActions } from "@/lib/organizer/store";
import type { StepView } from "@/lib/organizer/types";
import { StepDetail } from "./StepDetail";

export function StepTimeline({ steps }: { steps: StepView[] }) {
  const { toggleStep } = useApplicationActions();
  const openStep = steps.find((step) => step.isOpen) ?? null;

  return (
    <div>
      {/* The rail scrolls sideways rather than wrapping once admins add extra steps. */}
      <div className="flex items-start overflow-x-auto pb-2">
        {steps.map((step, index) => (
          <Fragment key={step.id}>
            <button
              type="button"
              disabled={!step.interactive}
              aria-expanded={step.isOpen}
              aria-controls="timeline-step-panel"
              onClick={() => toggleStep(step.id)}
              className="flex w-24 shrink-0 flex-col items-center gap-2 disabled:cursor-default"
            >
              <span
                className={cn(
                  "flex h-[34px] w-[34px] shrink-0 items-center justify-center rounded-full border-2 font-mono text-[13px] font-bold",
                  step.borderClass,
                  step.badgeClass
                )}
                aria-hidden
              >
                {step.badgeContent}
              </span>
              <span className="text-center text-xs font-semibold text-nr-text-primary">{step.label}</span>
              <span className={cn("text-center font-mono text-[10px]", step.statusTextClass)}>
                {step.statusLabel}
              </span>
            </button>

            {index < steps.length - 1 && (
              <span className="mx-1.5 mt-4 h-0.5 min-w-4 flex-1 bg-nr-border" aria-hidden />
            )}
          </Fragment>
        ))}
      </div>

      {openStep && (
        <div
          id="timeline-step-panel"
          className={cn("mt-5 rounded-lg border bg-nr-surface p-[18px]", openStep.borderClass)}
        >
          <p className="mb-2 text-sm font-semibold text-nr-text-primary">{openStep.label}</p>
          <StepDetail step={openStep} />
        </div>
      )}
    </div>
  );
}
