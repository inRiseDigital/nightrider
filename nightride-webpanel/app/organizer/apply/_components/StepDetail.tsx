"use client";

import { AccentButton } from "@/components/organizer/ui/AccentButton";
import { RequiresAppPill, StepThumb } from "@/components/organizer/ui/StepMedia";
import { TextField } from "@/components/organizer/ui/TextField";
import { useApplicationActions, useApplicationState } from "@/lib/organizer/store";
import type { StepView } from "@/lib/organizer/types";

/**
 * The body of an opened step — shared by the checklist (inline) and timeline
 * (panel below the rail) layouts.
 */
export function StepDetail({ step }: { step: StepView }) {
  const { busy } = useApplicationState();
  const { setExtraCode, submitExtraCode, pickSlot } = useApplicationActions();

  return (
    <div className="flex flex-col items-start gap-3">
      <p className="text-[13px] text-nr-text-secondary">{step.detail}</p>

      {step.showAppPill && <RequiresAppPill />}

      {step.showThumb && step.thumbLabel && <StepThumb label={step.thumbLabel} />}

      {step.showCode && (
        <form
          className="flex w-full gap-2"
          onSubmit={(e) => {
            e.preventDefault();
            void submitExtraCode(step.id);
          }}
        >
          <div className="flex-1">
            <TextField
              id={`${step.id}-code`}
              type="text"
              mono
              aria-label="Verification code from postcard"
              placeholder="6-digit code from postcard"
              value={step.codeValue}
              onChange={(e) => setExtraCode(step.id, e.target.value)}
              className="py-2 text-[13px]"
            />
          </div>
          <AccentButton type="submit" size="sm" loading={busy}>
            Verify code
          </AccentButton>
        </form>
      )}

      {step.showSlots && (
        <div className="flex flex-wrap gap-2">
          {step.slots.map((slot) => (
            <button
              key={slot}
              type="button"
              disabled={busy}
              onClick={() => void pickSlot(step.id, slot)}
              className="rounded-lg border border-nr-border bg-nr-surface-raised px-3.5 py-2 text-xs text-nr-text-primary transition-colors hover:border-nr-primary-light disabled:opacity-50"
            >
              {slot}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
