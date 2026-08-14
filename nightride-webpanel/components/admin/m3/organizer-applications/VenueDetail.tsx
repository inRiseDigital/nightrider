import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import type { AdminConsoleValues } from "@/lib/admin/useAdminConsole";

export function VenueDetail({
  venue,
  backToOrg,
  toggleTransferHandler,
}: Pick<AdminConsoleValues, "venue" | "backToOrg" | "toggleTransferHandler">) {
  return (
    <>
      {venue.transferOpen ? (
        <div
          onClick={toggleTransferHandler}
          style={{ position: "fixed", inset: 0, zIndex: 60, background: "rgba(0,0,0,0.55)", display: "flex", alignItems: "center", justifyContent: "center", padding: 24 }}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{ width: "100%", maxWidth: 380, background: "#2A252A", borderRadius: 28, padding: "24px 0 12px", boxShadow: "0 8px 12px 6px rgba(0,0,0,0.3), 0 4px 4px rgba(0,0,0,0.5)" }}
          >
            <div style={{ padding: "0 24px 10px" }}>
              <div style={{ fontSize: 20 }}>Transfer {venue.name}</div>
              <div style={{ fontSize: 13, color: "#CFC0C5", marginTop: 6 }}>
                Pick the organizer who should manage this venue. Published events stay with the venue.
              </div>
            </div>
            {venue.transferTargets.map((t: any) => (
              <Hoverable
                key={t.name}
                onClick={t.pick}
                style={{ display: "flex", alignItems: "center", gap: 14, padding: "12px 24px", fontSize: 15, cursor: "pointer" }}
                hoverStyle={{ background: "#FFFFFF14" }}
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
                  {t.initials}
                </div>
                {t.name}
              </Hoverable>
            ))}
            <div style={{ display: "flex", justifyContent: "flex-end", padding: "8px 16px 4px" }}>
              <Hoverable
                as="button"
                onClick={toggleTransferHandler}
                style={{ height: 40, padding: "0 18px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#FFB1C4", border: "none", cursor: "pointer" }}
                hoverStyle={{ background: "#FFFFFF14" }}
              >
                Cancel
              </Hoverable>
            </div>
          </div>
        </div>
      ) : null}

      <div style={{ display: "flex", alignItems: "center", gap: 12, flexWrap: "wrap", padding: "4px 0 16px" }}>
        <Hoverable
          onClick={backToOrg}
          style={{ display: "inline-flex", alignItems: "center", gap: 8, height: 40, padding: "0 16px 0 12px", borderRadius: 20, cursor: "pointer", color: "#CFC0C5", fontSize: 14, fontWeight: 500 }}
          hoverStyle={{ background: "#2A252A", color: "#EDE0E4" }}
        >
          <Icon name="arrow_back" size={20} />
          {venue.organizerName}
        </Hoverable>
        <div style={{ minWidth: 0, marginLeft: 4 }}>
          <div style={{ fontSize: 20, lineHeight: 1.2 }}>{venue.name}</div>
          <div style={{ fontSize: 13, color: "#CFC0C5", marginTop: 2 }}>
            {venue.city} · managed by {venue.organizerName}
          </div>
        </div>
        <div style={{ display: "inline-flex", alignItems: "center", height: 32, padding: "0 12px", borderRadius: 8, fontSize: 13, fontWeight: 500, background: venue.stateBg, color: venue.stateFg, marginLeft: 4 }}>
          {venue.stateLabel}
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 8, marginLeft: "auto", flexShrink: 0 }}>
          <Hoverable
            as="button"
            onClick={venue.toggleSuspend}
            style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#EDE0E4", border: "1px solid #524549", cursor: "pointer" }}
            hoverStyle={{ background: "#FFFFFF14" }}
          >
            {venue.suspendLabel}
          </Hoverable>
          <button
            onClick={toggleTransferHandler}
            style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#1F4F49", color: "#A5F2E5", border: "none", cursor: "pointer" }}
          >
            Transfer venue
          </button>
        </div>
      </div>

      {venue.suspended ? (
        <div style={{ display: "flex", alignItems: "center", gap: 12, background: "#42320A", color: "#F5C452", borderRadius: 12, padding: "14px 16px", marginBottom: 16, fontSize: 13 }}>
          <Icon name="pause_circle" size={20} />
          This venue is suspended — no new events can be published here. The organizer&apos;s other venues are unaffected.
        </div>
      ) : null}

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(340px, 1fr))", gap: 16, alignItems: "start" }}>
        <div style={{ background: "#1B181B", borderRadius: 16, overflow: "hidden" }}>
          <div style={{ position: "relative", width: "100%", height: 220, background: "#2A252A", backgroundImage: `url('${venue.mapUrl}')`, backgroundSize: "cover", backgroundPosition: "center" }}>
            <div style={{ position: "absolute", left: "50%", top: "50%", transform: "translate(-50%, -100%)", color: "#FFB1C4" }}>
              <Icon name="location_on" size={36} filled style={{ filter: "drop-shadow(0 2px 4px rgba(0,0,0,0.6))" }} />
            </div>
            <div style={{ position: "absolute", right: 8, bottom: 6, fontSize: 9, color: "#EDE0E4", background: "rgba(0,0,0,0.55)", padding: "2px 6px", borderRadius: 6 }}>
              © OpenStreetMap
            </div>
          </div>
          <div style={{ padding: "16px 20px", display: "flex", alignItems: "center", gap: 8, fontSize: 13, color: venue.gpsColor }}>
            <Icon name={venue.gpsIcon} size={18} />
            {venue.gpsLabel}
          </div>
        </div>

        <div style={{ background: "#1B181B", borderRadius: 16, padding: 20 }}>
          <div style={{ fontSize: 16, fontWeight: 500, marginBottom: 12 }}>Venue record</div>
          <div style={{ display: "flex", flexDirection: "column" }}>
            {venue.rows.map((r: any, i: number) => (
              <div key={i} style={{ display: "flex", justifyContent: "space-between", gap: 16, padding: "9px 0", borderBottom: "1px solid #241F23", fontSize: 14 }}>
                <span style={{ color: "#9A8C91", flexShrink: 0 }}>{r.label}</span>
                <span style={{ textAlign: "right", fontFamily: r.font, minWidth: 0, wordBreak: "break-word" }}>{r.value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  );
}
