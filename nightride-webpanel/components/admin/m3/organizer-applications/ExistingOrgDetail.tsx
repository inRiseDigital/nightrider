"use client";

import { useState } from "react";
import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import { SimulatedBadge } from "../SimulatedBadge";
import { osmTileUrl } from "@/lib/admin/geo";
import { formatTimestamp } from "@/lib/admin/present";
import { MOCK_INSTRUCTION_PRESETS } from "@/lib/admin/mock-overlay";
import type { ApplicantDetail } from "@/lib/admin/useApplicantDetail";

export function ExistingOrgDetail({ detail, onOpenVenue }: { detail: ApplicantDetail; onOpenVenue: (venueId: string) => void }) {
  const { user, review, venues, evidence, photoRevealed, setPhotoRevealed } = detail;
  const [instructions, setInstructions] = useState(MOCK_INSTRUCTION_PRESETS[0].text);
  const [sentAgo, setSentAgo] = useState<string | null>(null);

  if (!user || !review || !evidence) return null;

  return (
    <>
      <div style={{ marginBottom: 24 }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 10, marginBottom: 12 }}>
          <div style={{ fontSize: 16, fontWeight: 500 }}>Venues</div>
          <div style={{ fontSize: 13, color: "#9A8C91" }}>
            {venues.length === 0 ? "None assigned" : `${venues.length} assigned`}
          </div>
        </div>
        {venues.length > 0 ? (
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, 300px)", gap: 16 }}>
            {venues.map((v) => (
              <Hoverable
                key={v.id}
                onClick={() => onOpenVenue(v.id)}
                style={{ background: "#1B181B", borderRadius: 16, overflow: "hidden", cursor: "pointer", transition: "background-color 120ms linear" }}
                hoverStyle={{ background: "#2A252A" }}
              >
                <div style={{ position: "relative", width: "100%", height: 104, background: "#2A252A" }}>
                  {v.geo ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={osmTileUrl(v.geo.latitude, v.geo.longitude)} alt={v.name} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                  ) : null}
                  <div
                    style={{
                      position: "absolute",
                      top: 8,
                      left: 8,
                      display: "inline-flex",
                      alignItems: "center",
                      height: 24,
                      padding: "0 10px",
                      borderRadius: 8,
                      fontSize: 11,
                      fontWeight: 500,
                      background: v.status === "active" ? "#0F3D28" : "#42320A",
                      color: v.status === "active" ? "#7BE0A8" : "#F5C452",
                    }}
                  >
                    {v.status === "active" ? "Live" : "Closed"}
                  </div>
                </div>
                <div style={{ padding: "14px 16px", display: "flex", flexDirection: "column", gap: 8 }}>
                  <div>
                    <div style={{ fontSize: 15, fontWeight: 500 }}>{v.name}</div>
                    <div style={{ fontSize: 12, color: "#CFC0C5", marginTop: 2, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{v.address}</div>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: v.verified ? "#7BE0A8" : "#9A8C91" }}>
                    <Icon name={v.verified ? "verified" : "help"} size={16} />
                    {v.verified ? "Verified" : "Not verified"}
                  </div>
                </div>
              </Hoverable>
            ))}
          </div>
        ) : (
          <div style={{ background: "#1B181B", borderRadius: 16, padding: 24, textAlign: "center", fontSize: 14, color: "#9A8C91" }}>
            No venues assigned to this organizer yet.
          </div>
        )}
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(340px, 1fr))", gap: 16, alignItems: "start" }}>
        <div style={{ background: "#1B181B", borderRadius: 16, padding: 20, display: "flex", flexDirection: "column", gap: 18 }}>
          <div>
            <div style={{ fontSize: 16, fontWeight: 500 }}>Identity on file</div>
            <div style={{ fontSize: 13, color: "#9A8C91", marginTop: 2 }}>NIC photo and live capture from the review</div>
          </div>

          {photoRevealed ? (
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10 }}>
              {[
                { url: evidence.nic.front, label: "NIC FRONT" },
                { url: evidence.nic.back, label: "NIC BACK" },
                { url: evidence.selfie.capture, label: "SELFIE" },
              ].map((p) =>
                p.url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img key={p.label} src={p.url} alt={p.label} style={{ width: "100%", aspectRatio: "3/4", objectFit: "cover", borderRadius: 12 }} />
                ) : (
                  <div key={p.label} style={{ aspectRatio: "3/4", borderRadius: 12, background: "#2A252A", display: "flex", alignItems: "center", justifyContent: "center", color: "#9A8C91" }}>
                    <Icon name="hide_image" size={22} />
                  </div>
                ),
              )}
            </div>
          ) : (
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12, padding: 14, borderRadius: 12, background: "#2A252A" }}>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 14 }}>Photos hidden</div>
                <div style={{ fontSize: 12, color: "#9A8C91", marginTop: 2 }}>Already decided — open only to double-check</div>
              </div>
              <button
                onClick={() => setPhotoRevealed(true)}
                style={{ height: 36, padding: "0 16px", borderRadius: 18, fontSize: 13, fontWeight: 500, background: "transparent", color: "#EDE0E4", border: "1px solid #524549", cursor: "pointer", flexShrink: 0 }}
              >
                View
              </button>
            </div>
          )}

          <div style={{ display: "flex", flexDirection: "column" }}>
            <div style={{ display: "flex", justifyContent: "space-between", gap: 16, padding: "8px 0", borderBottom: "1px solid #241F23", fontSize: 14 }}>
              <span style={{ color: "#9A8C91" }}>Name on account</span>
              <span>{user.displayName || "—"}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", gap: 16, padding: "8px 0", fontSize: 14 }}>
              <span style={{ color: "#9A8C91" }}>Applied</span>
              <span>{formatTimestamp(user.applicationSubmittedAt)}</span>
            </div>
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 16, minWidth: 0 }}>
          <div style={{ background: "#1B181B", borderRadius: 16, padding: 20 }}>
            <div style={{ fontSize: 16, fontWeight: 500, marginBottom: 14 }}>Video walkthrough</div>
            {evidence.video.walkthrough ? (
              <video controls poster={evidence.video.poster ?? undefined} src={evidence.video.walkthrough} style={{ width: "100%", maxHeight: 260, borderRadius: 12, background: "#000", marginBottom: 14 }} />
            ) : (
              <div style={{ width: "100%", aspectRatio: "16/9", borderRadius: 12, background: "#0E0C0E", display: "flex", alignItems: "center", justifyContent: "center", color: "#524549", marginBottom: 14 }}>
                <Icon name="videocam_off" size={36} />
              </div>
            )}

            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 10 }}>
              <div style={{ fontSize: 13, color: "#9A8C91" }}>Send follow-up instructions</div>
              <SimulatedBadge />
            </div>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginBottom: 12 }}>
              {MOCK_INSTRUCTION_PRESETS.map((preset) => (
                <Hoverable
                  key={preset.label}
                  as="button"
                  onClick={() => setInstructions(preset.text)}
                  style={{ height: 32, padding: "0 14px", borderRadius: 8, fontSize: 13, background: "transparent", color: "#CFC0C5", border: "1px solid #524549", cursor: "pointer" }}
                  hoverStyle={{ background: "#FFFFFF14", color: "#EDE0E4" }}
                >
                  {preset.label}
                </Hoverable>
              ))}
            </div>
            <textarea
              rows={3}
              value={instructions}
              onChange={(e) => setInstructions(e.target.value)}
              style={{ width: "100%", background: "#2A252A", border: "none", borderRadius: 12, padding: "14px 16px", fontSize: 14, lineHeight: 1.5, color: "#EDE0E4", resize: "vertical" }}
            />
            <button
              onClick={() => setSentAgo("just now")}
              style={{ marginTop: 14, height: 40, padding: "0 24px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#FFB1C4", color: "#650430", border: "none", cursor: "pointer" }}
            >
              Send instructions
            </button>
            {sentAgo ? <div style={{ fontSize: 12, color: "#9A8C91", marginTop: 8 }}>Sent {sentAgo} (simulated — not delivered anywhere).</div> : null}
          </div>
        </div>
      </div>
    </>
  );
}
