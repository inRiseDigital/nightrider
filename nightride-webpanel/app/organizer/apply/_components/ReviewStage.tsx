"use client";

import { ErrorNote } from "@/components/organizer/ui/AuthCard";
import { COPY_TONE, FLOW_LAYOUT, TONE_COPY } from "@/lib/organizer/constants";
import { useApplicationActions, useApplicationState } from "@/lib/organizer/store";
import type { StepView } from "@/lib/organizer/types";
import { StepChecklist } from "./StepChecklist";
import { StepTimeline } from "./StepTimeline";

export function ReviewStage({ steps }: { steps: StepView[] }) {
  const { error } = useApplicationState();
  const { signOutApplicant } = useApplicationActions();

  return (
    <div className="w-full max-w-[640px] pb-10">
      <header className="mb-[18px] flex items-start justify-between gap-4">
        <div>
          <h1 className="font-display text-xl uppercase tracking-wide text-nr-text-primary">
            Verification steps
          </h1>
          <p className="mt-1 text-[13px] text-nr-text-secondary">{TONE_COPY[COPY_TONE].reviewIntro}</p>
        </div>
        <button
          type="button"
          onClick={() => void signOutApplicant()}
          className="shrink-0 font-mono text-[11px] text-nr-text-hint transition-colors hover:text-nr-text-secondary"
        >
          Sign out
        </button>
      </header>

      {error && (
        <div className="mb-4">
          <ErrorNote>{error}</ErrorNote>
        </div>
      )}

      {FLOW_LAYOUT === "timeline" ? <StepTimeline steps={steps} /> : <StepChecklist steps={steps} />}
    </div>
  );
}
