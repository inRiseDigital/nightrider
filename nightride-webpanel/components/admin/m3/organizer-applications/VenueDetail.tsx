"use client";

import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import { MapTile } from "../primitives/MapTile";
import { FieldRowList } from "../primitives/FieldRowList";
import { initialsFor } from "@/lib/admin/present";
import { useVenueDetail } from "@/lib/admin/useVenueDetail";

export function VenueDetail({ venueId, onBack }: { venueId: string; onBack: () => void }) {
  const { loading, venue, owner, candidates, transferOpen, setTransferOpen, openTransfer, transferTo, toggleSuspend, busy, actionError } = useVenueDetail(venueId);

  if (loading || !venue) return <div style={{ color: "#9A8C91", fontSize: 14 }}>Loading venue…</div>;

  const suspended = venue.status !== "active";

  return (
    <>
      {transferOpen ? (
        <div onClick={() => setTransferOpen(false)} style={{ position: "fixed", inset: 0, zIndex: 60, background: "rgba(0,0,0,0.55)", display: "flex", alignItems: "center", justifyContent: "center", padding: 24 }}>
          <div onClick={(e) => e.stopPropagation()} style={{ width: "100%", maxWidth: 380, background: "#2A252A", borderRadius: 28, padding: "24px 0 12px" }}>
            <div style={{ padding: "0 24px 10px" }}>
              <div style={{ fontSize: 20 }}>Transfer {venue.name}</div>
              <div style={{ fontSize: 13, color: "#CFC0C5", marginTop: 6 }}>Pick the approved organizer who should manage this venue.</div>
            </div>
            {candidates.length === 0 ? (
              <div style={{ padding: "12px 24px", fontSize: 13, color: "#9A8C91" }}>No other approved organizers yet.</div>
            ) : (
              candidates.map((c) => (
                <Hoverable
                  key={c.uid}
                  onClick={() => void transferTo(c.uid)}
                  style={{ display: "flex", alignItems: "center", gap: 14, padding: "12px 24px", fontSize: 15, cursor: "pointer" }}
                  hoverStyle={{ background: "#FFFFFF14" }}
                >
                  <div style={{ width: 36, height: 36, borderRadius: "50%", background: "#1F4F49", color: "#A5F2E5", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13, fontWeight: 500, flexShrink: 0 }}>
                    {initialsFor(c.displayName, c.email)}
                  </div>
                  {c.displayName || c.email}
                </Hoverable>
              ))
            )}
            <div style={{ display: "flex", justifyContent: "flex-end", padding: "8px 16px 4px" }}>
              <Hoverable
                as="button"
                onClick={() => setTransferOpen(false)}
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
          onClick={onBack}
          style={{ display: "inline-flex", alignItems: "center", gap: 8, height: 40, padding: "0 16px 0 12px", borderRadius: 20, cursor: "pointer", color: "#CFC0C5", fontSize: 14, fontWeight: 500 }}
          hoverStyle={{ background: "#2A252A", color: "#EDE0E4" }}
        >
          <Icon name="arrow_back" size={20} />
          {owner?.displayName || owner?.email || "Organizer"}
        </Hoverable>
        <div style={{ minWidth: 0, marginLeft: 4 }}>
          <div style={{ fontSize: 20, lineHeight: 1.2 }}>{venue.name}</div>
          <div style={{ fontSize: 13, color: "#CFC0C5", marginTop: 2 }}>
            {venue.city} · managed by {owner?.displayName || owner?.email || "no one"}
          </div>
        </div>
        <div
          style={{
            display: "inline-flex",
            alignItems: "center",
            height: 32,
            padding: "0 12px",
            borderRadius: 8,
            fontSize: 13,
            fontWeight: 500,
            background: suspended ? "#42320A" : "#0F3D28",
            color: suspended ? "#F5C452" : "#7BE0A8",
            marginLeft: 4,
          }}
        >
          {suspended ? "Closed" : "Live"}
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 8, marginLeft: "auto", flexShrink: 0 }}>
          <Hoverable
            as="button"
            onClick={() => void toggleSuspend()}
            disabled={busy}
            style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#EDE0E4", border: "1px solid #524549", cursor: "pointer" }}
            hoverStyle={{ background: "#FFFFFF14" }}
          >
            {suspended ? "Reopen venue" : "Close venue"}
          </Hoverable>
          <button
            onClick={() => void openTransfer()}
            style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#1F4F49", color: "#A5F2E5", border: "none", cursor: "pointer" }}
          >
            Transfer venue
          </button>
        </div>
      </div>

      {actionError ? <div style={{ color: "#FFB4AB", fontSize: 13, marginBottom: 12 }}>{actionError}</div> : null}

      {suspended ? (
        <div style={{ display: "flex", alignItems: "center", gap: 12, background: "#42320A", color: "#F5C452", borderRadius: 12, padding: "14px 16px", marginBottom: 16, fontSize: 13 }}>
          <Icon name="pause_circle" size={20} />
          This venue is closed — no new events can be published here.
        </div>
      ) : null}

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(340px, 1fr))", gap: 16, alignItems: "start" }}>
        <div style={{ background: "#1B181B", borderRadius: 16, overflow: "hidden" }}>
          <MapTile geo={venue.geo} city={venue.city} height={220} />
        </div>

        <div style={{ background: "#1B181B", borderRadius: 16, padding: 20 }}>
          <div style={{ fontSize: 16, fontWeight: 500, marginBottom: 12 }}>Venue record</div>
          <FieldRowList
            rows={[
              { label: "City", value: venue.city },
              { label: "Country", value: venue.countryCode },
              { label: "Address", value: venue.address },
              { label: "Opening hours", value: venue.openingHours || "—" },
              { label: "Contact phone", value: venue.phone || "—", mono: true },
              { label: "Website", value: venue.website || "—" },
              { label: "Source", value: venue.source },
              { label: "Verified", value: venue.verified ? "Yes" : "No" },
            ]}
          />
        </div>
      </div>
    </>
  );
}
