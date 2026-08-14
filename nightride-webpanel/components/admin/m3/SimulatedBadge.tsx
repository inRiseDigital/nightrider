import { Icon } from "./Icon";

/** Marks a panel as fabricated data with no real backing — see lib/admin/mock-overlay.ts. */
export function SimulatedBadge() {
  return (
    <span
      title="No real verification pipeline backs this — illustrative only."
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 4,
        height: 20,
        padding: "0 8px",
        borderRadius: 6,
        fontSize: 10,
        fontWeight: 500,
        letterSpacing: "0.04em",
        textTransform: "uppercase",
        background: "#332B30",
        color: "#CFC0C5",
      }}
    >
      <Icon name="science" size={12} />
      Simulated
    </span>
  );
}
