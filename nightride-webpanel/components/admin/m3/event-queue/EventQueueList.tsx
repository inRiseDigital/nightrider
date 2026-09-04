import { Hoverable } from "../Hoverable";
import { Icon } from "../Icon";
import { EmptyState } from "../primitives";
import { ACCENT, MONO, SURFACE, TEXT, badgeColors } from "@/lib/admin/tokens";
import type { EventQueue } from "@/lib/admin/useEventQueue";

/**
 * Left column of the master-detail layout — one row per event in the
 * current filter, pink accent bar + `#2A252A` background when selected. See
 * `{{ eqRows }}` / `{{ eqEmpty }}` at lines 844-867 of the mockup.
 */
export function EventQueueList({ queue }: { queue: EventQueue }) {
  const { rows, selectedId, select } = queue;

  return (
    <div style={{ flex: "1 1 320px", maxWidth: 340, minWidth: 0, background: SURFACE.raised, borderRadius: 16, overflow: "hidden" }}>
      {rows.map((row) => {
        const active = row.id === selectedId;
        const statusColors = badgeColors(row.statusTone);
        const statusLabel = row.status === "pending" ? "Awaiting review" : row.status === "approved" ? "Approved" : "Rejected";
        const flagColor = row.hasDangerFlag ? "#FFB4AB" : "#F5C452";
        return (
          <Hoverable
            key={row.id}
            as="div"
            onClick={() => select(row.id)}
            style={{
              display: "flex",
              gap: 12,
              padding: "14px 16px 14px 13px",
              cursor: "pointer",
              borderLeft: `3px solid ${active ? ACCENT.pink : "transparent"}`,
              background: active ? SURFACE.hover : "transparent",
              borderBottom: "1px solid #241F23",
              transition: "background-color 120ms linear",
            }}
            hoverStyle={{ background: SURFACE.hover }}
          >
            <div style={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column", gap: 5 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <div style={{ fontSize: 14, fontWeight: 500, flex: 1, minWidth: 0, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                  {row.name}
                </div>
                <div
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    height: 22,
                    padding: "0 8px",
                    borderRadius: 6,
                    fontSize: 11,
                    fontWeight: 500,
                    flexShrink: 0,
                    background: statusColors.bg,
                    color: statusColors.fg,
                  }}
                >
                  {statusLabel}
                </div>
              </div>
              <div style={{ fontSize: 12, color: TEXT.secondary, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                {row.venue} · {row.city}
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 10, fontSize: 11, color: TEXT.muted, fontFamily: MONO }}>
                <span>{row.dateLabel}</span>
                <span>{row.submittedTimeAgo}</span>
              </div>
              {row.flagCount > 0 ? (
                <div style={{ display: "flex", alignItems: "center", gap: 5, fontSize: 11, color: flagColor }}>
                  <Icon name="flag" size={14} />
                  {row.flagCount === 1 ? "1 flag" : `${row.flagCount} flags`}
                </div>
              ) : null}
            </div>
          </Hoverable>
        );
      })}
      {rows.length === 0 ? <EmptyState message="Nothing matches those filters." /> : null}
    </div>
  );
}
