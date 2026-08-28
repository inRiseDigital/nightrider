import { BASE_STEPS, OVERALL_STATUS_STYLES, STEP_STATUS_STYLES } from "./constants";
import type { ApplicationState } from "./store";
import type { OverallView, StepStatus, StepView } from "./types";

/**
 * The four steps an admin wants done before writing a walkthrough script.
 * "Done" here is the applicant's own advisory claim rather than an admin
 * verdict: the flag exists to tell the applicant they are now waiting on us,
 * and for that purpose a submitted step counts the same as an accepted one.
 * An accepted step whose claim was never written still counts — a `needs_info`
 * cycle can clear a claim the admin has already seen.
 */
function videoPrerequisitesMet(state: ApplicationState): boolean {
  const app = state.application.steps;
  const review = state.review.steps;
  const done = (id: "nic" | "selfie" | "venueAddress" | "gps", claim: boolean) =>
    claim || review[id]?.status === "accepted";

  return (
    done("nic", app.nic.uploaded) &&
    done("selfie", app.selfie.uploaded) &&
    done("venueAddress", app.venueAddress !== null) &&
    done("gps", app.gps.attempts.length > 0)
  );
}

/**
 * Flattens the five schema steps into a single ordered list of render-ready
 * steps. Status and the admin's note are sourced from the review doc — the
 * one exception is the locally-derived 'submitted' presentation state below,
 * which layers the applicant's own advisory claim on top without writing
 * anything or affecting access control.
 */
export function deriveSteps(state: ApplicationState): StepView[] {
  return BASE_STEPS.map((def) => {
    const reviewStep = state.review.steps[def.id];
    const rawStatus = reviewStep?.status ?? "pending";

    // Keyed on the step id, not its kind: nic and selfie are cleared in the
    // mobile app, which sets the same advisory `uploaded` flag a browser
    // upload would. gps has no flag — its claim is the attempts array, which
    // this panel does not read.
    const applicantClaim =
      def.id === "venueAddress"
        ? state.application.steps.venueAddress !== null
        : def.id === "gps"
          ? false
          : state.application.steps[def.id].uploaded;

    // review.steps.<id>.status stays 'active' until an admin looks at it —
    // there is no server trigger that flips it the moment a file lands in
    // Storage. Showing "submitted" once the applicant has done their part
    // avoids implying there is still something for them to do. A
    // 'needs_info' cycle always re-opens the control: a stale claim from the
    // previous attempt must never block a required re-submission.
    const status: StepStatus = rawStatus === "active" && applicantClaim ? "submitted" : rawStatus;

    const style = STEP_STATUS_STYLES[status];
    const canAct = rawStatus === "active" || rawStatus === "needs_info";

    // The video step is locked until an admin publishes a script for this
    // venue. Once the other four are done, that lock is entirely on us, so the
    // step opens and says so instead of sitting there as an unexplained
    // "Locked" the applicant cannot act on.
    const script = def.id === "video" ? (reviewStep?.script ?? null) : null;
    const awaitingScript = def.id === "video" && rawStatus === "pending" && videoPrerequisitesMet(state);

    return {
      id: def.id,
      label: def.label,
      detail: def.detail,
      kind: def.kind,
      status,
      statusLabel: awaitingScript ? "Waiting for an admin" : style.label,
      borderClass: style.borderClass,
      badgeClass: style.badgeClass,
      statusTextClass: style.textClass,
      badgeContent: status === "accepted" ? "✓" : "•",
      isOpen: state.openStepId === def.id,
      interactive: status !== "pending" || awaitingScript,
      awaitingReview: status === "submitted",
      canAct,
      note: reviewStep?.note ?? "",
      attempt: reviewStep?.attempt ?? 0,
      script,
      awaitingScript,
      thumbLabel: def.thumbLabel,
    };
  });
}

export function deriveOverall(steps: StepView[], state: ApplicationState): OverallView {
  if (state.review.status === "rejected") {
    return { key: "rejected", ...OVERALL_STATUS_STYLES.rejected, detail: state.review.rejectionReason };
  }
  if (state.review.status === "approved") {
    return { key: "approved", ...OVERALL_STATUS_STYLES.approved };
  }

  const actionNeeded = steps.some((step) => step.status === "needs_info");
  if (actionNeeded) return { key: "action_required", ...OVERALL_STATUS_STYLES.action_required };

  const stillToDo = steps.some((step) => step.status === "active");
  if (stillToDo) return { key: "in_progress", ...OVERALL_STATUS_STYLES.in_progress };

  return { key: "under_review", ...OVERALL_STATUS_STYLES.under_review };
}
