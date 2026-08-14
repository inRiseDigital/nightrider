"use client";

import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import { STEP_ORDER } from "@/lib/admin/present";
import { deriveDisplayStepStatus } from "@/lib/admin/schema";
import { stepApplicantClaim, type ApplicantDetail } from "@/lib/admin/useApplicantDetail";

export function DecisionBar({ detail }: { detail: ApplicantDetail }) {
  const { user, review, rejectBoxOpen, setRejectBoxOpen, rejectDraft, setRejectDraft, submitReject, approve, busy, actionError } = detail;
  if (!user || !review) return null;

  const statuses = STEP_ORDER.map((id) => deriveDisplayStepStatus(review.steps[id].status, stepApplicantClaim(user, id)));
  const acceptedCount = statuses.filter((s) => s === "accepted").length;
  const needsInfoCount = statuses.filter((s) => s === "needs_info").length;
  const open = statuses.length - acceptedCount;

  const hint =
    needsInfoCount > 0
      ? `${needsInfoCount} step(s) waiting on the applicant.`
      : open === 0
        ? "All steps verified — safe to approve."
        : `${open} step(s) still open.`;
  const hintColor = needsInfoCount > 0 ? "#F5C452" : open === 0 ? "#7BE0A8" : "#CFC0C5";
  const hintIcon = needsInfoCount > 0 ? "pending" : open === 0 ? "verified_user" : "pending";

  return (
    <div style={{ flexShrink: 0, background: "#1F1B1F", boxShadow: "0 -1px 0 #332B30", padding: "10px 24px", display: "flex", flexDirection: "column", gap: 12 }}>
      {rejectBoxOpen ? (
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <div style={{ fontSize: 14, fontWeight: 500, color: "#FFB4AB" }}>Reason for rejection</div>
          <textarea
            value={rejectDraft}
            onChange={(e) => setRejectDraft(e.target.value)}
            rows={2}
            placeholder="Why is this application being rejected?"
            style={{ width: "100%", resize: "vertical", background: "#2A252A", border: "none", borderRadius: 12, padding: "12px 16px", fontSize: 14, lineHeight: 1.5, color: "#EDE0E4" }}
          />
          <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
            <button
              onClick={() => void submitReject()}
              disabled={busy || !rejectDraft.trim()}
              style={{ height: 40, padding: "0 22px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#5C1218", color: "#FFB4AB", border: "none", cursor: "pointer", opacity: busy || !rejectDraft.trim() ? 0.5 : 1 }}
            >
              Confirm reject
            </button>
            <Hoverable
              as="button"
              onClick={() => setRejectBoxOpen(false)}
              style={{ height: 40, padding: "0 18px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#CFC0C5", border: "none", cursor: "pointer" }}
              hoverStyle={{ background: "#FFFFFF14" }}
            >
              Cancel
            </Hoverable>
          </div>
        </div>
      ) : null}
      {actionError ? <div style={{ color: "#FFB4AB", fontSize: 13 }}>{actionError}</div> : null}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 16, flexWrap: "wrap" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, minWidth: 0 }}>
          <Icon name={hintIcon} size={20} color={hintColor} />
          <div style={{ fontSize: 13, color: hintColor, minWidth: 0 }}>{hint}</div>
        </div>
        <div style={{ display: "flex", gap: 8, flexShrink: 0, flexWrap: "wrap" }}>
          <Hoverable
            as="button"
            onClick={() => setRejectBoxOpen(!rejectBoxOpen)}
            disabled={busy}
            style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#5C1218", color: "#FFB4AB", border: "none", cursor: "pointer", transition: "background-color 120ms linear" }}
            hoverStyle={{ background: "#711720" }}
          >
            Reject
          </Hoverable>
          <Hoverable
            as="button"
            onClick={() => void approve()}
            disabled={busy}
            style={{ height: 40, padding: "0 24px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#FFB1C4", color: "#650430", border: "none", cursor: "pointer", transition: "background-color 120ms linear" }}
            hoverStyle={{ background: "#FFC7D5" }}
          >
            Approve organizer
          </Hoverable>
        </div>
      </div>
    </div>
  );
}
