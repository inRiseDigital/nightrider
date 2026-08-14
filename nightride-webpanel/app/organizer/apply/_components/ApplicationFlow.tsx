"use client";

import { useMemo } from "react";
import { Loader2 } from "lucide-react";
import { cn } from "@/components/organizer/ui/cn";
import { deriveOverall, deriveSteps } from "@/lib/organizer/derive";
import { useApplicationState } from "@/lib/organizer/store";
import { ApplicationStatusBar } from "./ApplicationStatusBar";
import { OtpStage } from "./OtpStage";
import { PhoneStage } from "./PhoneStage";
import { ReviewStage } from "./ReviewStage";
import { SignupStage } from "./SignupStage";

export function ApplicationFlow() {
  const state = useApplicationState();
  const isReview = state.stage === "review";

  const steps = useMemo(() => deriveSteps(state), [state]);
  const overall = useMemo(() => deriveOverall(steps, state), [steps, state]);

  return (
    <>
      <div
        className={cn(
          "flex min-h-0 w-full flex-1 justify-center overflow-y-auto px-5 py-10",
          isReview ? "items-start" : "items-center"
        )}
      >
        {!state.ready ? (
          <Loader2 size={22} className="animate-spin text-nr-text-hint" aria-label="Loading" />
        ) : (
          <>
            {state.stage === "signup" && <SignupStage />}
            {state.stage === "phone" && <PhoneStage />}
            {state.stage === "otp" && <OtpStage />}
            {isReview && <ReviewStage steps={steps} />}
          </>
        )}
      </div>

      {state.ready && isReview && <ApplicationStatusBar overall={overall} />}
    </>
  );
}
