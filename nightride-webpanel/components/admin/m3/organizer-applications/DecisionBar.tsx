import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import type { AdminConsoleValues } from "@/lib/admin/useAdminConsole";

export function DecisionBar({
  detail,
  onInfoRequestChange,
  sendInfoRequestHandler,
  cancelInfoRequestHandler,
  requestInfoHandler,
  rejectHandler,
  approveHandler,
}: Pick<
  AdminConsoleValues,
  "detail" | "onInfoRequestChange" | "sendInfoRequestHandler" | "cancelInfoRequestHandler" | "requestInfoHandler" | "rejectHandler" | "approveHandler"
>) {
  return (
    <div style={{ flexShrink: 0, background: "#1F1B1F", boxShadow: "0 -1px 0 #332B30", padding: "10px 24px", display: "flex", flexDirection: "column", gap: 12 }}>
      {detail.showInfoRequestBox ? (
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <div style={{ fontSize: 14, fontWeight: 500, color: "#A5F2E5" }}>Request additional info</div>
          <textarea
            value={detail.infoRequestText}
            onChange={onInfoRequestChange}
            rows={2}
            style={{ width: "100%", resize: "vertical", background: "#2A252A", border: "none", borderRadius: 12, padding: "12px 16px", fontSize: 14, lineHeight: 1.5, color: "#EDE0E4" }}
          />
          <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
            <button
              onClick={sendInfoRequestHandler}
              style={{ height: 40, padding: "0 22px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#1F4F49", color: "#A5F2E5", border: "none", cursor: "pointer" }}
            >
              Send request
            </button>
            <Hoverable
              as="button"
              onClick={cancelInfoRequestHandler}
              style={{ height: 40, padding: "0 18px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#CFC0C5", border: "none", cursor: "pointer" }}
              hoverStyle={{ background: "#FFFFFF14" }}
            >
              Cancel
            </Hoverable>
            {detail.infoRequestSent ? (
              <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13, color: "#7BE0A8" }}>
                <Icon name="task_alt" size={18} />
                Sent — the organizer sees this in their app
              </div>
            ) : null}
          </div>
        </div>
      ) : null}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 16, flexWrap: "wrap" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, minWidth: 0 }}>
          <Icon name={detail.decisionIcon} size={20} color={detail.decisionHintColor} />
          <div style={{ fontSize: 13, color: detail.decisionHintColor, minWidth: 0 }}>{detail.decisionHint}</div>
        </div>
        <div style={{ display: "flex", gap: 8, flexShrink: 0, flexWrap: "wrap" }}>
          <Hoverable
            as="button"
            onClick={requestInfoHandler}
            style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#A5F2E5", border: "1px solid #3E5F5A", cursor: "pointer" }}
            hoverStyle={{ background: "#FFFFFF0A" }}
          >
            Request info
          </Hoverable>
          <Hoverable
            as="button"
            onClick={rejectHandler}
            style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#5C1218", color: "#FFB4AB", border: "none", cursor: "pointer", transition: "background-color 120ms linear" }}
            hoverStyle={{ background: "#711720" }}
          >
            Reject
          </Hoverable>
          <Hoverable
            as="button"
            onClick={approveHandler}
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
