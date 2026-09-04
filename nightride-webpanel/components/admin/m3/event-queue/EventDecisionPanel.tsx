import { Hoverable } from "../Hoverable";
import { Icon } from "../Icon";
import { Chip } from "../primitives";
import { SURFACE, TEXT } from "@/lib/admin/tokens";
import type { EventQueueDetail } from "@/lib/admin/view-models";
import type { EventQueue } from "@/lib/admin/useEventQueue";

/**
 * Decision panel below the event detail — mirrors `{{ eqDetail.pending }}` /
 * `{{ eqDetail.decided }}` at lines 951-994 of the mockup, with one
 * deliberate deviation: this product has no pre-publish gate, so the copy
 * that assumed one ("Approve & publish", "the organizer cannot sell tickets
 * until this is approved") is rewritten to describe clearing a flag on an
 * already-live event / taking a live event down. See the PR description for
 * the exact before/after strings.
 */
export function EventDecisionPanel({ queue, detail }: { queue: EventQueue; detail: EventQueueDetail }) {
  const { rejectOpen, rejectReasonDraft, setRejectReasonDraft, rejectReasonPresets, openReject, cancelReject, confirmReject, approve, reopen, actionBusy, actionError } = queue;

  if (detail.isDecided) {
    return (
      <div style={{ background: SURFACE.overlay, borderRadius: 16, padding: "16px 20px", display: "flex", alignItems: "center", gap: 16, flexWrap: "wrap" }}>
        <div style={{ flex: 1, minWidth: 200 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, fontSize: 14, color: TEXT.primary }}>
            <Icon name="task_alt" size={20} color={detail.status === "rejected" ? "#FFB4AB" : "#7BE0A8"} />
            {detail.decidedLine}
          </div>
          {detail.rejectReason ? (
            <div style={{ fontSize: 13, color: TEXT.secondary, marginTop: 8, lineHeight: 1.5 }}>Reason sent: {detail.rejectReason}</div>
          ) : null}
        </div>
        <Hoverable
          as="button"
          onClick={() => void reopen(detail.id)}
          disabled={actionBusy}
          style={{
            height: 40,
            padding: "0 18px",
            borderRadius: 20,
            fontSize: 14,
            fontWeight: 500,
            background: "transparent",
            color: TEXT.primary,
            border: "1px solid #524549",
            cursor: actionBusy ? "default" : "pointer",
            flexShrink: 0,
          }}
          hoverStyle={{ background: "#FFFFFF14" }}
        >
          Reopen for review
        </Hoverable>
      </div>
    );
  }

  return (
    <div style={{ background: SURFACE.overlay, borderRadius: 16, padding: "16px 20px", display: "flex", flexDirection: "column", gap: 14 }}>
      {rejectOpen ? (
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <div style={{ fontSize: 14, fontWeight: 500, color: "#FFB4AB" }}>Why is this being rejected?</div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
            {rejectReasonPresets.map((preset) => (
              <Chip key={preset} label={preset} onClick={() => setRejectReasonDraft(preset)} />
            ))}
          </div>
          <textarea
            rows={3}
            value={rejectReasonDraft}
            onChange={(e) => setRejectReasonDraft(e.target.value)}
            placeholder="The organizer sees this reason in their app…"
            style={{ width: "100%", background: SURFACE.hover, border: "none", borderRadius: 12, padding: "12px 14px", fontSize: 14, lineHeight: 1.5, color: TEXT.primary, resize: "vertical" }}
          />
        </div>
      ) : null}
      {actionError ? <div style={{ color: "#FFB4AB", fontSize: 13 }}>{actionError}</div> : null}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 16, flexWrap: "wrap" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, fontSize: 13, color: TEXT.secondary, minWidth: 0 }}>
          <Icon name="pending_actions" size={20} color="#F5C452" />
          Live and flagged for review — approving clears the flag, rejecting takes it down.
        </div>
        <div style={{ display: "flex", gap: 8, flexShrink: 0, flexWrap: "wrap" }}>
          {rejectOpen ? (
            <>
              <Hoverable
                as="button"
                onClick={cancelReject}
                disabled={actionBusy}
                style={{ height: 40, padding: "0 18px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: TEXT.secondary, border: "none", cursor: actionBusy ? "default" : "pointer" }}
                hoverStyle={{ background: "#FFFFFF14" }}
              >
                Cancel
              </Hoverable>
              <Hoverable
                as="button"
                onClick={() => void confirmReject(detail.id)}
                disabled={actionBusy || !rejectReasonDraft.trim()}
                style={{
                  height: 40,
                  padding: "0 22px",
                  borderRadius: 20,
                  fontSize: 14,
                  fontWeight: 500,
                  background: "#93000A",
                  color: "#FFDAD6",
                  border: "none",
                  cursor: actionBusy || !rejectReasonDraft.trim() ? "default" : "pointer",
                  opacity: actionBusy || !rejectReasonDraft.trim() ? 0.6 : 1,
                  transition: "background-color 120ms linear",
                }}
                hoverStyle={{ background: "#A80010" }}
              >
                Reject &amp; take down
              </Hoverable>
            </>
          ) : (
            <>
              <Hoverable
                as="button"
                onClick={openReject}
                disabled={actionBusy}
                style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#5C1218", color: "#FFB4AB", border: "none", cursor: actionBusy ? "default" : "pointer", transition: "background-color 120ms linear" }}
                hoverStyle={{ background: "#711720" }}
              >
                Reject with reason
              </Hoverable>
              <Hoverable
                as="button"
                onClick={() => void approve(detail.id)}
                disabled={actionBusy}
                style={{ height: 40, padding: "0 24px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#FFB1C4", color: "#650430", border: "none", cursor: actionBusy ? "default" : "pointer", transition: "background-color 120ms linear" }}
                hoverStyle={{ background: "#FFC7D5" }}
              >
                Approve &amp; clear flag
              </Hoverable>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
