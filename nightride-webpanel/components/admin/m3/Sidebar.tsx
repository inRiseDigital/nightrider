import { Icon } from "./Icon";
import { Hoverable } from "./Hoverable";
import { initialsFor } from "@/lib/admin/present";
import type { AdminNav } from "@/lib/admin/useAdminNav";

export function Sidebar({
  nav,
  adminName,
  adminEmail,
  onSignOut,
}: {
  nav: AdminNav["navGroups"];
  adminName: string | null;
  adminEmail: string | null;
  onSignOut: () => void;
}) {
  return (
    <div
      style={{
        width: 272,
        flexShrink: 0,
        background: "#1B181B",
        display: "flex",
        flexDirection: "column",
        padding: "12px 12px 16px",
        overflowY: "auto",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "12px 12px 20px" }}>
        <div
          style={{
            width: 40,
            height: 40,
            borderRadius: 12,
            background: "#8E1049",
            color: "#FFD9E2",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexShrink: 0,
          }}
        >
          <Icon name="nightlife" size={22} />
        </div>
        <div style={{ minWidth: 0 }}>
          <div style={{ fontSize: 16, fontWeight: 500, letterSpacing: "0.01em", lineHeight: 1.2 }}>Night Ride</div>
          <div style={{ fontSize: 12, color: "#CFC0C5", lineHeight: 1.3 }}>Admin console</div>
        </div>
      </div>

      {nav.map((group) => (
        <div key={group.label} style={{ marginBottom: 12 }}>
          <div
            style={{
              fontSize: 11,
              fontWeight: 500,
              letterSpacing: "0.09em",
              color: "#9A8C91",
              padding: "10px 16px 6px",
              textTransform: "uppercase",
            }}
          >
            {group.label}
          </div>
          {group.items.map((item) => (
            <Hoverable
              key={item.id}
              as="div"
              onClick={item.select}
              title={item.label}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 12,
                height: 52,
                padding: "0 16px",
                borderRadius: 26,
                cursor: "pointer",
                marginBottom: 2,
                background: item.active ? "#4E1930" : "transparent",
                color: item.active ? "#FFD9E2" : "#CFC0C5",
                transition: "background-color 120ms linear, color 120ms linear",
              }}
              hoverStyle={item.active ? undefined : { background: "#2A252A", color: "#EDE0E4" }}
            >
              <Icon name={item.icon} size={22} filled={item.active} />
              <div
                style={{
                  fontSize: 14,
                  fontWeight: 500,
                  letterSpacing: "0.01em",
                  whiteSpace: "nowrap",
                  overflow: "hidden",
                  textOverflow: "ellipsis",
                }}
              >
                {item.label}
              </div>
              {item.showCount ? (
                <div style={{ marginLeft: "auto", fontFamily: "'Roboto Mono', monospace", fontSize: 12, color: item.active ? "#FFD9E2" : "#CFC0C5" }}>
                  {item.count}
                </div>
              ) : null}
            </Hoverable>
          ))}
        </div>
      ))}

      <Hoverable
        onClick={onSignOut}
        title="Sign out"
        style={{
          marginTop: "auto",
          display: "flex",
          alignItems: "center",
          gap: 12,
          padding: 12,
          borderRadius: 16,
          background: "#1F1B1F",
          cursor: "pointer",
        }}
        hoverStyle={{ background: "#2A252A" }}
      >
        <div
          style={{
            width: 36,
            height: 36,
            borderRadius: "50%",
            background: "#1F4F49",
            color: "#A5F2E5",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: 13,
            fontWeight: 500,
            flexShrink: 0,
          }}
        >
          {initialsFor(adminName ?? "", adminEmail ?? "")}
        </div>
        <div style={{ minWidth: 0, flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{adminName || "Admin"}</div>
          <div
            style={{
              fontSize: 11,
              color: "#9A8C91",
              fontFamily: "'Roboto Mono', monospace",
              overflow: "hidden",
              textOverflow: "ellipsis",
              whiteSpace: "nowrap",
            }}
          >
            {adminEmail || ""}
          </div>
        </div>
        <Icon name="logout" size={18} color="#9A8C91" />
      </Hoverable>
    </div>
  );
}
