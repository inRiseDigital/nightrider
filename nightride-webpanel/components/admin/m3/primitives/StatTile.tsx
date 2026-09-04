import { MONO, TEXT } from "@/lib/admin/tokens";
import { Icon } from "../Icon";

/**
 * Compact mono-numeral stat used in the inline stat strips at the top of a
 * list screen (users, event queue, venues) — see e.g. `{{ userStats }}` in
 * the mockup: 26px weight-300 mono value + 12px muted label.
 */
export function StatTile({ value, label, color = TEXT.primary }: { value: string | number; label: string; color?: string }) {
  return (
    <div style={{ minWidth: 96 }}>
      <div style={{ fontSize: 26, fontWeight: 300, lineHeight: 1.2, color, fontFamily: MONO }}>{value}</div>
      <div style={{ fontSize: 12, color: TEXT.muted, marginTop: 2 }}>{label}</div>
    </div>
  );
}

/**
 * Dashboard KPI card variant — icon + label row, 40px weight-300 value, and
 * an optional delta line. See `{{ kpis }}` on the overview screen.
 */
export function KpiCard({
  icon,
  label,
  value,
  delta,
  cardBg = "#1B181B",
  iconColor = TEXT.secondary,
  deltaColor = TEXT.muted,
}: {
  icon: string;
  label: string;
  value: string | number;
  delta?: string;
  cardBg?: string;
  iconColor?: string;
  deltaColor?: string;
}) {
  return (
    <div style={{ background: cardBg, borderRadius: 16, padding: 20, display: "flex", flexDirection: "column", gap: 6 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 8, color: iconColor }}>
        <Icon name={icon} size={20} />
        <div style={{ fontSize: 13, fontWeight: 500, letterSpacing: "0.01em" }}>{label}</div>
      </div>
      <div style={{ fontSize: 40, fontWeight: 300, lineHeight: 1.1, letterSpacing: "-0.01em" }}>{value}</div>
      {delta ? <div style={{ fontSize: 12, color: deltaColor }}>{delta}</div> : null}
    </div>
  );
}
