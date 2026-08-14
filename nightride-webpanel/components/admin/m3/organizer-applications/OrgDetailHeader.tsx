import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import type { AdminConsoleValues } from "@/lib/admin/useAdminConsole";

export function OrgDetailHeader({
  detail,
  backToList,
  deactivateHandler,
  reactivateHandler,
  banHandler,
  unbanHandler,
  toggleMoreMenuHandler,
  resetPasswordHandler,
  viewAuditLogHandler,
}: Pick<
  AdminConsoleValues,
  | "detail"
  | "backToList"
  | "deactivateHandler"
  | "reactivateHandler"
  | "banHandler"
  | "unbanHandler"
  | "toggleMoreMenuHandler"
  | "resetPasswordHandler"
  | "viewAuditLogHandler"
>) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 12, flexWrap: "wrap", padding: "4px 0 16px" }}>
      <Hoverable
        onClick={backToList}
        style={{
          display: "inline-flex",
          alignItems: "center",
          gap: 8,
          height: 40,
          padding: "0 16px 0 12px",
          borderRadius: 20,
          cursor: "pointer",
          color: "#CFC0C5",
          fontSize: 14,
          fontWeight: 500,
        }}
        hoverStyle={{ background: "#2A252A", color: "#EDE0E4" }}
      >
        <Icon name="arrow_back" size={20} />
        Organizers
      </Hoverable>
      <div
        style={{
          width: 44,
          height: 44,
          borderRadius: "50%",
          background: "#8E1049",
          color: "#FFD9E2",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 15,
          fontWeight: 500,
          flexShrink: 0,
          marginLeft: 4,
        }}
      >
        {detail.initials}
      </div>
      <div style={{ minWidth: 0 }}>
        <div style={{ fontSize: 20, fontWeight: 400, lineHeight: 1.2 }}>{detail.name}</div>
        <div style={{ fontSize: 13, color: "#CFC0C5", marginTop: 2, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
          {detail.email} · {detail.phone}
        </div>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 8, marginLeft: "auto", flexShrink: 0, position: "relative" }}>
        {detail.isNewApp ? (
          <>
            <div
              style={{
                display: "inline-flex",
                alignItems: "center",
                height: 32,
                padding: "0 12px",
                borderRadius: 8,
                fontSize: 13,
                fontWeight: 500,
                background: detail.statusBg,
                color: detail.statusFg,
              }}
            >
              {detail.status}
            </div>
            <div style={{ fontFamily: "'Roboto Mono', monospace", fontSize: 12, color: "#9A8C91" }}>{detail.appliedLine}</div>
          </>
        ) : null}
        {detail.isExistingOrg ? (
          <>
            {detail.canDeactivate ? (
              <Hoverable
                as="button"
                onClick={deactivateHandler}
                style={{
                  height: 40,
                  padding: "0 20px",
                  borderRadius: 20,
                  fontSize: 14,
                  fontWeight: 500,
                  background: "transparent",
                  color: "#EDE0E4",
                  border: "1px solid #524549",
                  cursor: "pointer",
                }}
                hoverStyle={{ background: "#FFFFFF14" }}
              >
                Deactivate
              </Hoverable>
            ) : null}
            {detail.canReactivate ? (
              <button
                onClick={reactivateHandler}
                style={{
                  height: 40,
                  padding: "0 20px",
                  borderRadius: 20,
                  fontSize: 14,
                  fontWeight: 500,
                  background: "#0F3D28",
                  color: "#7BE0A8",
                  border: "none",
                  cursor: "pointer",
                }}
              >
                Reactivate
              </button>
            ) : null}
            {detail.canBan ? (
              <Hoverable
                as="button"
                onClick={banHandler}
                style={{
                  height: 40,
                  padding: "0 20px",
                  borderRadius: 20,
                  fontSize: 14,
                  fontWeight: 500,
                  background: "#93000A",
                  color: "#FFDAD6",
                  border: "none",
                  cursor: "pointer",
                  transition: "background-color 120ms linear",
                }}
                hoverStyle={{ background: "#A80010" }}
              >
                Ban
              </Hoverable>
            ) : null}
            {detail.canUnban ? (
              <Hoverable
                as="button"
                onClick={unbanHandler}
                style={{
                  height: 40,
                  padding: "0 20px",
                  borderRadius: 20,
                  fontSize: 14,
                  fontWeight: 500,
                  background: "transparent",
                  color: "#EDE0E4",
                  border: "1px solid #524549",
                  cursor: "pointer",
                }}
                hoverStyle={{ background: "#FFFFFF14" }}
              >
                Unban
              </Hoverable>
            ) : null}
            <Hoverable
              as="button"
              onClick={toggleMoreMenuHandler}
              style={{
                width: 40,
                height: 40,
                borderRadius: "50%",
                background: "transparent",
                color: "#CFC0C5",
                border: "none",
                cursor: "pointer",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
              hoverStyle={{ background: "#2A252A" }}
            >
              <Icon name="more_vert" size={22} />
            </Hoverable>
            {detail.moreMenuOpen ? (
              <div
                style={{
                  position: "absolute",
                  top: 46,
                  right: 0,
                  background: "#2A252A",
                  borderRadius: 12,
                  boxShadow: "0 4px 8px 3px rgba(0,0,0,0.35), 0 1px 3px rgba(0,0,0,0.5)",
                  zIndex: 30,
                  minWidth: 200,
                  overflow: "hidden",
                  padding: "8px 0",
                }}
              >
                <Hoverable
                  onClick={resetPasswordHandler}
                  style={{ display: "flex", alignItems: "center", gap: 12, padding: "10px 16px", fontSize: 14, cursor: "pointer" }}
                  hoverStyle={{ background: "#FFFFFF14" }}
                >
                  <Icon name="lock_reset" size={20} color="#CFC0C5" />
                  Reset password
                </Hoverable>
                <Hoverable
                  onClick={viewAuditLogHandler}
                  style={{ display: "flex", alignItems: "center", gap: 12, padding: "10px 16px", fontSize: 14, cursor: "pointer" }}
                  hoverStyle={{ background: "#FFFFFF14" }}
                >
                  <Icon name="history" size={20} color="#CFC0C5" />
                  View audit log
                </Hoverable>
              </div>
            ) : null}
          </>
        ) : null}
      </div>
    </div>
  );
}
