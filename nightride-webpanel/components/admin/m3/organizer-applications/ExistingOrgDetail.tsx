import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import type { AdminConsoleValues } from "@/lib/admin/useAdminConsole";

export function ExistingOrgDetail({
  detail,
  confirmMatchHandler,
  flagMismatchHandler,
  togglePhotoHandler,
  onInstructionsChange,
  sendInstructionsHandler,
  instructionPresets,
}: Pick<
  AdminConsoleValues,
  "detail" | "confirmMatchHandler" | "flagMismatchHandler" | "togglePhotoHandler" | "onInstructionsChange" | "sendInstructionsHandler" | "instructionPresets"
>) {
  return (
    <>
      <div style={{ marginBottom: 24 }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 10, marginBottom: 12 }}>
          <div style={{ fontSize: 16, fontWeight: 500 }}>Venues</div>
          <div style={{ fontSize: 13, color: "#9A8C91" }}>{detail.venuesNote}</div>
        </div>
        {detail.hasVenues ? (
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, 300px)", gap: 16 }}>
            {detail.venues.map((vn: any) => (
              <Hoverable
                key={vn.id}
                onClick={vn.open}
                style={{ background: "#1B181B", borderRadius: 16, overflow: "hidden", cursor: "pointer", transition: "background-color 120ms linear" }}
                hoverStyle={{ background: "#2A252A" }}
              >
                <div style={{ position: "relative", width: "100%", height: 104, background: "#2A252A", backgroundImage: `url('${vn.mapUrl}')`, backgroundSize: "cover", backgroundPosition: "center" }}>
                  <div style={{ position: "absolute", left: "50%", top: "50%", transform: "translate(-50%, -100%)", color: "#FFB1C4" }}>
                    <Icon name="location_on" size={28} filled style={{ filter: "drop-shadow(0 2px 4px rgba(0,0,0,0.6))" }} />
                  </div>
                  <div style={{ position: "absolute", top: 8, left: 8, display: "inline-flex", alignItems: "center", height: 24, padding: "0 10px", borderRadius: 8, fontSize: 11, fontWeight: 500, background: vn.stateBg, color: vn.stateFg }}>
                    {vn.stateLabel}
                  </div>
                </div>
                <div style={{ padding: "14px 16px", display: "flex", flexDirection: "column", gap: 10 }}>
                  <div>
                    <div style={{ fontSize: 15, fontWeight: 500 }}>{vn.name}</div>
                    <div style={{ fontSize: 12, color: "#CFC0C5", marginTop: 2, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{vn.address}</div>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: vn.gpsColor }}>
                    <Icon name={vn.gpsIcon} size={16} />
                    {vn.gpsLabel}
                  </div>
                  <div style={{ display: "flex", justifyContent: "space-between", gap: 10, fontSize: 12, color: "#9A8C91", fontFamily: "'Roboto Mono', monospace" }}>
                    <span>{vn.capacityLabel}</span>
                    <span>{vn.eventsLabel}</span>
                  </div>
                </div>
              </Hoverable>
            ))}
          </div>
        ) : null}
        {detail.noVenues ? (
          <div style={{ background: "#1B181B", borderRadius: 16, padding: 24, textAlign: "center", fontSize: 14, color: "#9A8C91" }}>
            No venues assigned to this organizer yet.
          </div>
        ) : null}
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(340px, 1fr))", gap: 16, alignItems: "start" }}>
        <div style={{ background: "#1B181B", borderRadius: 16, padding: 20, display: "flex", flexDirection: "column", gap: 18 }}>
          <div>
            <div style={{ fontSize: 16, fontWeight: 500 }}>Identity on file</div>
            <div style={{ fontSize: 13, color: "#9A8C91", marginTop: 2 }}>NIC photo vs. live capture</div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 12, padding: 14, borderRadius: 12, background: detail.nicCalloutBg }}>
            <Icon name={detail.nicCalloutIcon} size={24} color={detail.nicCalloutFg} />
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 500, color: detail.nicCalloutFg }}>{detail.nicCalloutTitle}</div>
              <div style={{ fontSize: 12, color: "#CFC0C5", marginTop: 2, lineHeight: 1.45 }}>{detail.nicCalloutBody}</div>
            </div>
          </div>

          {detail.showPhotoDirect ? (
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
              <div style={{ aspectRatio: "16/10", borderRadius: 12, background: "#2A252A", display: "flex", alignItems: "center", justifyContent: "center", color: "#9A8C91" }}>
                <Icon name="badge" size={26} />
              </div>
              <div style={{ aspectRatio: "16/10", borderRadius: 12, background: "#2A252A", outline: "2px solid #FFB4AB", outlineOffset: -2, display: "flex", alignItems: "center", justifyContent: "center", color: "#FFB4AB" }}>
                <Icon name="face" size={26} />
              </div>
            </div>
          ) : null}
          {detail.showPhotoHidden ? (
            detail.photoRevealed ? (
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
                <div style={{ aspectRatio: "16/10", borderRadius: 12, background: "#2A252A", display: "flex", alignItems: "center", justifyContent: "center", color: "#9A8C91" }}>
                  <Icon name="badge" size={26} />
                </div>
                <div style={{ aspectRatio: "16/10", borderRadius: 12, background: "#2A252A", display: "flex", alignItems: "center", justifyContent: "center", color: "#9A8C91" }}>
                  <Icon name="face" size={26} />
                </div>
              </div>
            ) : (
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12, padding: 14, borderRadius: 12, background: "#2A252A" }}>
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontSize: 14 }}>Photos hidden</div>
                  <div style={{ fontSize: 12, color: "#9A8C91", marginTop: 2 }}>Already verified — open only to double-check</div>
                </div>
                <button
                  onClick={togglePhotoHandler}
                  style={{ height: 36, padding: "0 16px", borderRadius: 18, fontSize: 13, fontWeight: 500, background: "transparent", color: "#EDE0E4", border: "1px solid #524549", cursor: "pointer", flexShrink: 0 }}
                >
                  View
                </button>
              </div>
            )
          ) : null}

          <div style={{ display: "flex", flexDirection: "column" }}>
            <div style={{ display: "flex", justifyContent: "space-between", gap: 16, padding: "8px 0", borderBottom: "1px solid #241F23", fontSize: 14 }}>
              <span style={{ color: "#9A8C91" }}>Name on NIC</span>
              <span>{detail.nicNameOnId}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", gap: 16, padding: "8px 0", borderBottom: "1px solid #241F23", fontSize: 14 }}>
              <span style={{ color: "#9A8C91" }}>Name on account</span>
              <span>{detail.name}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", gap: 16, padding: "8px 0", borderBottom: "1px solid #241F23", fontSize: 14 }}>
              <span style={{ color: "#9A8C91" }}>NIC number</span>
              <span style={{ fontFamily: "'Roboto Mono', monospace" }}>{detail.nicNumber}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", gap: 16, padding: "8px 0", fontSize: 14 }}>
              <span style={{ color: "#9A8C91" }}>Submitted</span>
              <span>{detail.nicSubmittedDate}</span>
            </div>
          </div>

          <div style={{ display: "flex", gap: 8 }}>
            <button
              onClick={confirmMatchHandler}
              disabled={detail.confirmDisabled}
              style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#EDE0E4", border: "1px solid #524549", cursor: "pointer", opacity: detail.confirmDisabled ? 0.4 : 1 }}
            >
              Confirm match
            </button>
            <Hoverable
              as="button"
              onClick={flagMismatchHandler}
              disabled={detail.flagDisabled}
              style={{ height: 40, padding: "0 18px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#CFC0C5", border: "none", cursor: "pointer", opacity: detail.flagDisabled ? 0.4 : 1 }}
              hoverStyle={{ background: "#FFFFFF14" }}
            >
              Flag mismatch
            </Hoverable>
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 16, minWidth: 0 }}>
          <div style={{ background: "#1B181B", borderRadius: 16, padding: 20 }}>
            <div style={{ fontSize: 16, fontWeight: 500, marginBottom: 14 }}>Video walkthrough</div>
            {detail.videoBefore ? (
              <>
                <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginBottom: 14 }}>
                  {instructionPresets.map((preset) => (
                    <Hoverable
                      key={preset.label}
                      as="button"
                      onClick={preset.apply}
                      style={{ height: 32, padding: "0 14px", borderRadius: 8, fontSize: 13, background: "transparent", color: "#CFC0C5", border: "1px solid #524549", cursor: "pointer" }}
                      hoverStyle={{ background: "#FFFFFF14", color: "#EDE0E4" }}
                    >
                      {preset.label}
                    </Hoverable>
                  ))}
                </div>
                <textarea
                  rows={3}
                  value={detail.instructions}
                  onChange={onInstructionsChange}
                  style={{ width: "100%", background: "#2A252A", border: "none", borderRadius: 12, padding: "14px 16px", fontSize: 14, lineHeight: 1.5, color: "#EDE0E4", resize: "vertical" }}
                />
                <button
                  onClick={sendInstructionsHandler}
                  style={{ marginTop: 14, height: 40, padding: "0 24px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#FFB1C4", color: "#650430", border: "none", cursor: "pointer" }}
                >
                  Send instructions
                </button>
              </>
            ) : null}
            {detail.videoAfter ? (
              <>
                <div style={{ fontSize: 12, color: "#9A8C91", marginBottom: 12 }}>Instructions sent {detail.videoSentAgo}</div>
                <div style={{ width: "100%", aspectRatio: "16/9", borderRadius: 12, background: "#0E0C0E", display: "flex", alignItems: "center", justifyContent: "center", color: "#524549" }}>
                  <Icon name="play_circle" size={44} />
                </div>
                <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginTop: 14 }}>
                  <button style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#EDE0E4", border: "1px solid #524549", cursor: "pointer" }}>
                    Replace video
                  </button>
                  <Hoverable
                    as="button"
                    style={{ height: 40, padding: "0 18px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#CFC0C5", border: "none", cursor: "pointer" }}
                    hoverStyle={{ background: "#FFFFFF14" }}
                  >
                    Resend instructions
                  </Hoverable>
                </div>
              </>
            ) : null}
          </div>
        </div>
      </div>
    </>
  );
}
