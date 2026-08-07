import {
  BASE_STEPS,
  EXTRA_STEPS,
  OVERALL_STATUS_STYLES,
  STEP_STATUS_STYLES,
  VIDEO_CALL_SLOTS,
} from "./constants";
import type { ApplicationState } from "./store";
import type { OverallView, StepView } from "./types";

/**
 * Flattens the four base checks plus any admin-requested extra steps into a
 * single ordered list of render-ready steps. Step data comes from the live
 * Firestore document; only the postcard code draft is local.
 */
export function deriveSteps(state: ApplicationState): StepView[] {
  const { steps: baseStatus, extraSteps } = state.application;

  const baseViews: StepView[] = BASE_STEPS.map((def) => {
    const status = baseStatus[def.id] ?? "active";
    const style = STEP_STATUS_STYLES[status];
    return {
      id: def.id,
      label: def.label,
      detail: def.detail,
      kind: "app",
      status,
      statusLabel: style.label,
      borderClass: style.borderClass,
      badgeClass: style.badgeClass,
      statusTextClass: style.textClass,
      badgeContent: status === "done" ? "✓" : "•",
      isOpen: state.openStepId === def.id,
      interactive: status !== "pending",
      showThumb: status === "active" || status === "done",
      thumbLabel: def.thumbLabel,
      showAppPill: status === "active",
      showCode: false,
      codeValue: "",
      showSlots: false,
      slots: [],
    };
  });

  const extraViews: StepView[] = extraSteps.map((step) => {
    const def = EXTRA_STEPS[step.type];
    const style = STEP_STATUS_STYLES[step.status];
    const isAppStep = def.kind === "app";
    const detail =
      step.status === "scheduled" && step.scheduledSlot
        ? `Meeting scheduled for ${step.scheduledSlot}. A calendar invite has been sent to your email.`
        : def.detail;

    return {
      id: step.id,
      label: def.label,
      detail,
      kind: def.kind,
      status: step.status,
      statusLabel: style.label,
      borderClass: style.borderClass,
      badgeClass: style.badgeClass,
      statusTextClass: style.textClass,
      badgeContent: step.status === "done" || step.status === "scheduled" ? "✓" : "•",
      isOpen: state.openStepId === step.id,
      interactive: true,
      showThumb: isAppStep && step.status !== "done",
      thumbLabel: def.thumbLabel,
      showAppPill: isAppStep && step.status !== "done",
      showCode: def.kind === "code" && step.status !== "done",
      codeValue: state.codeDrafts[step.id] ?? "",
      showSlots: def.kind === "schedule" && step.status !== "scheduled",
      slots: def.kind === "schedule" ? VIDEO_CALL_SLOTS : [],
    };
  });

  return [...baseViews, ...extraViews];
}

export function deriveOverall(steps: StepView[], state: ApplicationState): OverallView {
  if (state.application.rejected) return { key: "rejected", ...OVERALL_STATUS_STYLES.rejected };

  const actionNeeded = state.application.extraSteps.some((step) => step.status === "needs_info");
  if (actionNeeded) return { key: "action_required", ...OVERALL_STATUS_STYLES.action_required };

  const allDone = steps.every((step) => step.status === "done");
  if (allDone) return { key: "under_review", ...OVERALL_STATUS_STYLES.under_review };

  return { key: "in_progress", ...OVERALL_STATUS_STYLES.in_progress };
}
