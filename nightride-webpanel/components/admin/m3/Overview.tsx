import { Icon } from "./Icon";
import { Hoverable } from "./Hoverable";
import type { AdminConsoleValues } from "@/lib/admin/useAdminConsole";

export function Overview({ kpis, activity }: { kpis: AdminConsoleValues["kpis"]; activity: AdminConsoleValues["activity"] }) {
  return (
    <>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(190px, 1fr))", gap: 16, marginBottom: 16 }}>
        {kpis.map((kpi) => (
          <div key={kpi.label} style={{ background: kpi.cardBg, borderRadius: 16, padding: 20, display: "flex", flexDirection: "column", gap: 6 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, color: kpi.iconColor }}>
              <Icon name={kpi.icon} size={20} />
              <div style={{ fontSize: 13, fontWeight: 500, letterSpacing: "0.01em" }}>{kpi.label}</div>
            </div>
            <div style={{ fontSize: 40, fontWeight: 300, lineHeight: 1.1, letterSpacing: "-0.01em" }}>{kpi.value}</div>
            <div style={{ fontSize: 12, color: kpi.deltaColor }}>{kpi.delta}</div>
          </div>
        ))}
      </div>

      <div style={{ background: "#1B181B", borderRadius: 16, overflow: "hidden" }}>
        <div style={{ padding: "20px 24px 12px" }}>
          <div style={{ fontSize: 16, fontWeight: 500 }}>Recent activity</div>
          <div style={{ fontSize: 13, color: "#9A8C91", marginTop: 2 }}>Across all four cities</div>
        </div>
        {activity.map((row, i) => (
          <Hoverable
            key={i}
            style={{ display: "flex", alignItems: "center", gap: 16, padding: "12px 24px" }}
            hoverStyle={{ background: "#FFFFFF0A" }}
          >
            <div
              style={{
                width: 40,
                height: 40,
                borderRadius: "50%",
                flexShrink: 0,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                background: row.fill,
                color: row.color,
              }}
            >
              <Icon name={row.icon} size={20} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 14, lineHeight: 1.4 }}>{row.text}</div>
              <div style={{ fontSize: 12, color: "#9A8C91", marginTop: 2 }}>{row.status}</div>
            </div>
            <div style={{ fontFamily: "'Roboto Mono', monospace", fontSize: 12, color: "#9A8C91", flexShrink: 0 }}>{row.time}</div>
          </Hoverable>
        ))}
      </div>
    </>
  );
}
