"use client";

import { ChevronDown, ChevronUp } from "lucide-react";
import { cn } from "@/components/organizer/ui/cn";
import { useApplicationActions } from "@/lib/organizer/store";
import type { StepView } from "@/lib/organizer/types";
import { StepDetail } from "./StepDetail";

export function StepChecklist({ steps }: { steps: StepView[] }) {
  const { toggleStep } = useApplicationActions();

  return (
    <ul className="flex flex-col gap-2.5">
      {steps.map((step) => (
        <li key={step.id} className={cn("overflow-hidden rounded-lg border bg-nr-surface", step.borderClass)}>
          <button
            type="button"
            disabled={!step.interactive}
            aria-expanded={step.isOpen}
            aria-controls={`${step.id}-panel`}
            onClick={() => toggleStep(step.id)}
            className="flex w-full items-center gap-3 px-4 py-4 text-left disabled:cursor-default sm:px-[18px]"
          >
            <span
              className={cn(
                "flex h-[26px] w-[26px] shrink-0 items-center justify-center rounded-full font-mono text-xs font-bold",
                step.badgeClass
              )}
              aria-hidden
            >
              {step.badgeContent}
            </span>
            <span className="min-w-0 flex-1">
              <span className="block text-sm font-semibold text-nr-text-primary">{step.label}</span>
              <span className={cn("mt-0.5 block font-mono text-[11px]", step.statusTextClass)}>
                {step.statusLabel}
              </span>
            </span>
            {step.interactive &&
              (step.isOpen ? (
                <ChevronUp size={14} className="shrink-0 text-nr-text-hint" aria-hidden />
              ) : (
                <ChevronDown size={14} className="shrink-0 text-nr-text-hint" aria-hidden />
              ))}
          </button>

          {step.isOpen && (
            <div id={`${step.id}-panel`} className="border-t border-nr-border px-4 pb-[18px] pt-3.5 sm:px-[18px]">
              <StepDetail step={step} />
            </div>
          )}
        </li>
      ))}
    </ul>
  );
}
