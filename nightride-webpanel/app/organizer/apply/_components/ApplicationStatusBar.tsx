"use client";

import { AccentButton } from "@/components/organizer/ui/AccentButton";
import { cn } from "@/components/organizer/ui/cn";
import { useApplicationActions, useApplicationState } from "@/lib/organizer/store";
import type { OverallView } from "@/lib/organizer/types";

/** Pinned summary of where the whole application stands. */
export function ApplicationStatusBar({ overall }: { overall: OverallView }) {
  const { application, busy } = useApplicationState();
  const { resubmit } = useApplicationActions();
  const { rejected, rejectionReason } = application;

  return (
    <div className="w-full shrink-0 px-5 pb-5">
      <div className="mx-auto w-full max-w-[640px]">
        <div
          className={cn(
            "flex flex-wrap items-center gap-3 rounded-lg border p-4 sm:flex-nowrap sm:px-[18px]",
            overall.borderClass,
            overall.fillClass
          )}
        >
          <span
            className={cn(
              "flex h-[26px] w-[26px] shrink-0 items-center justify-center rounded-full font-mono text-sm font-bold",
              overall.badgeClass
            )}
            aria-hidden
          >
            !
          </span>

          <div className="min-w-0 flex-1">
            <p className="text-sm font-semibold text-nr-text-primary">Application status</p>
            <p className={cn("mt-0.5 font-mono text-[11px]", overall.textClass)}>{overall.label}</p>
            {rejected && (
              <p className="mt-1.5 max-w-[420px] text-xs text-nr-text-secondary">Reason: {rejectionReason}</p>
            )}
          </div>

          {rejected ? (
            <AccentButton onClick={() => void resubmit()} loading={busy} className="shrink-0">
              Resubmit application
            </AccentButton>
          ) : (
            <p className="max-w-[220px] text-xs text-nr-text-secondary sm:text-right">{overall.detail}</p>
          )}
        </div>
      </div>
    </div>
  );
}
