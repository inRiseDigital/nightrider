import { Hoverable } from "../Hoverable";
import { Icon } from "../Icon";
import type { AdminConsoleValues } from "@/lib/admin/useAdminConsole";

export function AddStepModal({
  addableSteps,
  onClose,
}: {
  addableSteps: AdminConsoleValues["detail"]["addableSteps"];
  onClose: () => void;
}) {
  return (
    <div
      onClick={onClose}
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 60,
        background: "rgba(0,0,0,0.55)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: 24,
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          width: "100%",
          maxWidth: 360,
          background: "#2A252A",
          borderRadius: 28,
          padding: "24px 0 12px",
          boxShadow: "0 8px 12px 6px rgba(0,0,0,0.3), 0 4px 4px rgba(0,0,0,0.5)",
        }}
      >
        <div style={{ padding: "0 24px 8px" }}>
          <div style={{ fontSize: 20, fontWeight: 400 }}>Add a verification step</div>
          <div style={{ fontSize: 13, color: "#CFC0C5", marginTop: 6 }}>The step is added to this application only.</div>
        </div>
        {addableSteps.map((ad: any) => (
          <Hoverable
            key={ad.type}
            onClick={ad.add}
            style={{ display: "flex", alignItems: "center", gap: 16, padding: "14px 24px", fontSize: 15, cursor: "pointer", color: ad.color }}
            hoverStyle={{ background: "#FFFFFF14" }}
          >
            <Icon name={ad.icon} size={22} />
            {ad.label}
          </Hoverable>
        ))}
        <div style={{ display: "flex", justifyContent: "flex-end", padding: "8px 16px 4px" }}>
          <Hoverable
            as="button"
            onClick={onClose}
            style={{ height: 40, padding: "0 18px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#FFB1C4", border: "none", cursor: "pointer" }}
            hoverStyle={{ background: "#FFFFFF14" }}
          >
            Cancel
          </Hoverable>
        </div>
      </div>
    </div>
  );
}
