"use client";

import { Hoverable } from "./Hoverable";
import { Icon } from "./Icon";
import { KpiCard } from "./primitives/StatTile";
import { useOverviewData } from "@/lib/admin/useOverviewData";

export function Overview() {
  const { loading, error, counts, activity } = useOverviewData();

  const kpis = counts
    ? [
        { label: "Pending applications", value: counts.pendingApplications, icon: "how_to_reg", cardBg: "#2A1A22", iconColor: "#FFB1C4" },
        { label: "Events in review", value: counts.eventsInReview, icon: "flag", cardBg: "#1B181B", iconColor: "#A5F2E5" },
        { label: "Active venues", value: counts.activeVenues, icon: "storefront", cardBg: "#1B181B", iconColor: "#A5F2E5" },
        { label: "Active organizers", value: counts.activeOrganizers, icon: "group", cardBg: "#1B181B", iconColor: "#A5F2E5" },
      ]
    : [];

  if (error) {
    return (
      <div style={{ background: "#2A1A1C", color: "#FFB4AB", borderRadius: 16, padding: 20 }}>
        Couldn&apos;t load the dashboard: {error}
      </div>
    );
  }

  return (
    <>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(190px, 1fr))", gap: 16, marginBottom: 16 }}>
        {loading
          ? Array.from({ length: 4 }).map((_, i) => (
              <div key={i} style={{ background: "#1B181B", borderRadius: 16, padding: 20, height: 96 }} />
            ))
          : kpis.map((kpi) => (
              <KpiCard
                key={kpi.label}
                icon={kpi.icon}
                label={kpi.label}
                value={kpi.value}
                cardBg={kpi.cardBg}
                iconColor={kpi.iconColor}
              />
            ))}
      </div>

      <div style={{ background: "#1B181B", borderRadius: 16, overflow: "hidden" }}>
        <div style={{ padding: "20px 24px 12px" }}>
          <div style={{ fontSize: 16, fontWeight: 500 }}>Recent activity</div>
          <div style={{ fontSize: 13, color: "#9A8C91", marginTop: 2 }}>From the audit log, most recent first</div>
        </div>
        {!loading && activity.length === 0 ? (
          <div style={{ padding: "24px", textAlign: "center", fontSize: 13, color: "#9A8C91" }}>Nothing logged yet.</div>
        ) : null}
        {activity.map((row) => (
          <Hoverable
            key={row.id}
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
