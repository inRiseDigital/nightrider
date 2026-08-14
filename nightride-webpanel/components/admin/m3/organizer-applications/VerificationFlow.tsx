import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import { AddStepModal } from "./AddStepModal";
import type { AdminConsoleValues } from "@/lib/admin/useAdminConsole";

export function VerificationFlow({
  detail,
  toggleAddStepHandler,
  confirmMatchHandler,
  flagMismatchHandler,
}: Pick<AdminConsoleValues, "detail" | "toggleAddStepHandler" | "confirmMatchHandler" | "flagMismatchHandler">) {
  const activeStep = detail.activeStep;

  return (
    <>
      {detail.addStepMenuOpen ? <AddStepModal addableSteps={detail.addableSteps} onClose={toggleAddStepHandler} /> : null}

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(340px, 1fr))", gap: 16, alignItems: "start" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 16, minWidth: 0 }}>
          <div style={{ background: "#1B181B", borderRadius: 16 }}>
            <div style={{ padding: "20px 24px 14px", display: "flex", alignItems: "flex-end", justifyContent: "space-between", gap: 16, flexWrap: "wrap" }}>
              <div>
                <div style={{ fontSize: 16, fontWeight: 500 }}>Verification flow</div>
                <div style={{ fontSize: 13, color: "#9A8C91", marginTop: 2 }}>Review each step, then decide</div>
              </div>
              <div style={{ flexShrink: 0, minWidth: 140 }}>
                <div style={{ fontSize: 12, color: "#CFC0C5", textAlign: "right", marginBottom: 6 }}>{detail.stepProgressLabel}</div>
                <div style={{ height: 4, borderRadius: 99, background: "#524549", overflow: "hidden" }}>
                  <div
                    style={{
                      height: "100%",
                      borderRadius: 99,
                      background: "#FFB1C4",
                      width: detail.stepProgressPct,
                      transition: "width 200ms cubic-bezier(0.2,0,0,1)",
                    }}
                  />
                </div>
              </div>
            </div>

            <div style={{ display: "flex", alignItems: "stretch", gap: 0, padding: "0 12px", borderBottom: "1px solid #332B30" }}>
              <div style={{ display: "flex", alignItems: "stretch", flex: 1, minWidth: 0, overflowX: "auto", overflowY: "hidden" }}>
                {detail.steps.map((st: any) => (
                  <Hoverable
                    key={st.id}
                    onClick={st.select}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 8,
                      height: 52,
                      padding: "0 14px",
                      cursor: "pointer",
                      flexShrink: 0,
                      borderBottom: `3px solid ${st.tabUnderline}`,
                      borderRadius: "8px 8px 0 0",
                      color: st.tabColor,
                      transition: "color 120ms linear",
                    }}
                    hoverStyle={{ background: "#FFFFFF0A", color: "#EDE0E4" }}
                  >
                    <Icon name={st.icon} size={20} color={st.fg} />
                    <div style={{ fontSize: 14, fontWeight: 500, whiteSpace: "nowrap" }}>{st.tabLabel}</div>
                  </Hoverable>
                ))}
              </div>
              <div style={{ position: "relative", display: "flex", alignItems: "center", paddingLeft: 8, flexShrink: 0 }}>
                <Hoverable
                  as="button"
                  onClick={toggleAddStepHandler}
                  title="Add a verification step"
                  style={{
                    width: 36,
                    height: 36,
                    borderRadius: "50%",
                    background: "#2A252A",
                    color: "#CFC0C5",
                    border: "none",
                    cursor: "pointer",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                  }}
                  hoverStyle={{ background: "#3A333A", color: "#EDE0E4" }}
                >
                  <Icon name="add" size={20} />
                </Hoverable>
              </div>
            </div>

            <div className="m3-rise" style={{ minHeight: 340, padding: "20px 24px 24px", display: "flex", flexDirection: "column", gap: 18 }}>
              <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontSize: 18, fontWeight: 400 }}>{activeStep.title}</div>
                  <div style={{ fontSize: 13, color: "#9A8C91", marginTop: 3 }}>{activeStep.meta}</div>
                </div>
                <div
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: 6,
                    height: 32,
                    padding: "0 12px",
                    borderRadius: 8,
                    fontSize: 13,
                    fontWeight: 500,
                    flexShrink: 0,
                    background: activeStep.bg,
                    color: activeStep.fg,
                  }}
                >
                  <Icon name={activeStep.statusIcon} size={16} />
                  {activeStep.statusLabel}
                </div>
              </div>

              {activeStep.hasPreview ? (
                <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(150px, 1fr))", gap: 12, maxWidth: 440 }}>
                  {activeStep.previews.map((pv: any, i: number) => (
                    <div
                      key={i}
                      style={{
                        aspectRatio: "16/10",
                        borderRadius: 12,
                        background: "#2A252A",
                        outline: `2px solid ${pv.border}`,
                        outlineOffset: -2,
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "center",
                        justifyContent: "center",
                        gap: 6,
                        color: pv.color,
                      }}
                    >
                      <Icon name={pv.icon} size={24} />
                      <div style={{ fontFamily: "'Roboto Mono', monospace", fontSize: 10, letterSpacing: "0.06em" }}>{pv.label}</div>
                    </div>
                  ))}
                </div>
              ) : null}

              <div style={{ display: "flex", flexDirection: "column" }}>
                {activeStep.evidence.map((ev: any, i: number) => (
                  <div key={i} style={{ display: "flex", justifyContent: "space-between", gap: 20, padding: "9px 0", borderBottom: "1px solid #241F23", fontSize: 14 }}>
                    <span style={{ color: "#9A8C91", flexShrink: 0 }}>{ev.label}</span>
                    <span style={{ color: ev.color, textAlign: "right", minWidth: 0 }}>{ev.value}</span>
                  </div>
                ))}
              </div>

              {activeStep.note && !activeStep.noteOpen ? (
                <div style={{ display: "flex", gap: 10, padding: "12px 14px", borderRadius: 12, background: "#2A252A", fontSize: 13, color: "#CFC0C5" }}>
                  <Icon name="sticky_note_2" size={18} color="#9A8C91" />
                  <div style={{ minWidth: 0 }}>{activeStep.note}</div>
                </div>
              ) : null}
              {activeStep.noteOpen ? (
                <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                  <input
                    value={activeStep.noteDraft}
                    onChange={activeStep.onNoteChange}
                    placeholder="Internal note — the organizer never sees this"
                    style={{ flex: 1, minWidth: 200, height: 48, background: "#2A252A", border: "none", borderRadius: 12, padding: "0 16px", fontSize: 14, color: "#EDE0E4" }}
                  />
                  <button
                    onClick={activeStep.saveNote}
                    style={{ height: 48, padding: "0 22px", borderRadius: 24, fontSize: 14, fontWeight: 500, background: "#1F4F49", color: "#A5F2E5", border: "none", cursor: "pointer" }}
                  >
                    Save note
                  </button>
                </div>
              ) : null}

              <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: "auto", paddingTop: 4 }}>
                <Hoverable
                  as="button"
                  onClick={activeStep.markVerified}
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: 8,
                    height: 40,
                    padding: "0 20px 0 16px",
                    borderRadius: 20,
                    fontSize: 14,
                    fontWeight: 500,
                    background: "#0F3D28",
                    color: "#7BE0A8",
                    border: "none",
                    cursor: "pointer",
                    transition: "background-color 120ms linear",
                  }}
                  hoverStyle={{ background: "#175236" }}
                >
                  <Icon name="check" size={18} />
                  Verify
                </Hoverable>
                <Hoverable
                  as="button"
                  onClick={activeStep.markFailed}
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: 8,
                    height: 40,
                    padding: "0 20px 0 16px",
                    borderRadius: 20,
                    fontSize: 14,
                    fontWeight: 500,
                    background: "#5C1218",
                    color: "#FFB4AB",
                    border: "none",
                    cursor: "pointer",
                    transition: "background-color 120ms linear",
                  }}
                  hoverStyle={{ background: "#711720" }}
                >
                  <Icon name="close" size={18} />
                  Flag failed
                </Hoverable>
                <Hoverable
                  as="button"
                  onClick={activeStep.requestResubmit}
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: 8,
                    height: 40,
                    padding: "0 20px 0 16px",
                    borderRadius: 20,
                    fontSize: 14,
                    fontWeight: 500,
                    background: "transparent",
                    color: "#A5F2E5",
                    border: "1px solid #3E5F5A",
                    cursor: "pointer",
                  }}
                  hoverStyle={{ background: "#FFFFFF0A" }}
                >
                  <Icon name="refresh" size={18} />
                  Ask again
                </Hoverable>
                <Hoverable
                  as="button"
                  onClick={activeStep.toggleNote}
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: 8,
                    height: 40,
                    padding: "0 16px",
                    borderRadius: 20,
                    fontSize: 14,
                    fontWeight: 500,
                    background: "transparent",
                    color: "#CFC0C5",
                    border: "none",
                    cursor: "pointer",
                  }}
                  hoverStyle={{ background: "#FFFFFF14", color: "#EDE0E4" }}
                >
                  <Icon name="edit_note" size={18} />
                  {activeStep.noteLabel}
                </Hoverable>
              </div>
            </div>
          </div>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))", gap: 12, alignItems: "start", minWidth: 0 }}>
          <div style={{ display: "flex", flexDirection: "column", gap: 12, minWidth: 0 }}>
            <div style={{ background: detail.faceCardBg, borderRadius: 16, padding: "14px 16px", display: "flex", flexDirection: "column", gap: 10 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <div style={{ display: "flex", gap: 4, flexShrink: 0 }}>
                  <div style={{ width: 36, height: 36, borderRadius: 10, background: "#2A252A", display: "flex", alignItems: "center", justifyContent: "center", color: "#9A8C91" }}>
                    <Icon name="badge" size={20} />
                  </div>
                  <div
                    style={{
                      width: 36,
                      height: 36,
                      borderRadius: 10,
                      background: "#2A252A",
                      outline: `2px solid ${detail.faceFg}`,
                      outlineOffset: -2,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      color: detail.faceFg,
                    }}
                  >
                    <Icon name="face" size={20} />
                  </div>
                </div>
                <div style={{ minWidth: 0, flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 500 }}>
                    Face match <span style={{ color: "#9A8C91", fontFamily: "'Roboto Mono', monospace", fontWeight: 400 }}>≥{detail.faceThreshold}</span>
                  </div>
                  <div style={{ fontSize: 12, color: detail.faceFg, marginTop: 2, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                    {detail.faceVerdict}
                  </div>
                </div>
                <div style={{ fontSize: 26, fontWeight: 300, lineHeight: 1, color: detail.faceFg, flexShrink: 0 }}>{detail.faceScore}</div>
              </div>
              <div style={{ height: 4, borderRadius: 99, background: "#524549", overflow: "hidden" }}>
                <div style={{ height: "100%", borderRadius: 99, background: detail.faceFg, width: detail.faceScore }} />
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <button
                  onClick={confirmMatchHandler}
                  disabled={detail.confirmDisabled}
                  style={{ height: 32, padding: "0 14px", borderRadius: 16, fontSize: 13, fontWeight: 500, background: "transparent", color: "#EDE0E4", border: "1px solid #524549", cursor: "pointer", opacity: detail.confirmDisabled ? 0.4 : 1 }}
                >
                  Confirm
                </button>
                <Hoverable
                  as="button"
                  onClick={flagMismatchHandler}
                  disabled={detail.flagDisabled}
                  style={{ height: 32, padding: "0 14px", borderRadius: 16, fontSize: 13, fontWeight: 500, background: "transparent", color: "#CFC0C5", border: "none", cursor: "pointer", opacity: detail.flagDisabled ? 0.4 : 1 }}
                  hoverStyle={{ background: "#FFFFFF14" }}
                >
                  Override
                </Hoverable>
              </div>
            </div>

            <div style={{ background: "#1B181B", borderRadius: 16, padding: 16, display: "flex", flexDirection: "column", gap: 10, minWidth: 0 }}>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 8 }}>
                <div style={{ fontSize: 15, fontWeight: 500 }}>NIC extraction</div>
                <div style={{ fontFamily: "'Roboto Mono', monospace", fontSize: 11, color: "#9A8C91" }}>OCR {detail.ocrConfidence}</div>
              </div>
              <div style={{ fontSize: 12, color: "#9A8C91" }}>{detail.nicDocType}</div>
              <div style={{ display: "flex", flexDirection: "column" }}>
                {detail.nicFields.map((f: any, i: number) => (
                  <div key={i} style={{ display: "flex", justifyContent: "space-between", gap: 14, padding: "7px 0", borderBottom: "1px solid #241F23", fontSize: 13 }}>
                    <span style={{ color: "#9A8C91", flexShrink: 0 }}>{f.label}</span>
                    <span style={{ textAlign: "right", color: f.color, fontFamily: f.font, minWidth: 0, wordBreak: "break-word" }}>{f.value}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 12, minWidth: 0 }}>
            <div style={{ background: "#1B181B", borderRadius: 16, overflow: "hidden", display: "flex", flexDirection: "column", minWidth: 0 }}>
              {detail.mapUrl ? (
                <div style={{ position: "relative", width: "100%", height: 110, background: "#2A252A", backgroundImage: `url('${detail.mapUrl}')`, backgroundSize: "cover", backgroundPosition: "center" }}>
                  <div style={{ position: "absolute", left: "50%", top: "50%", transform: "translate(-50%, -100%)", color: "#FFB1C4" }}>
                    <Icon name="location_on" size={30} filled style={{ filter: "drop-shadow(0 2px 4px rgba(0,0,0,0.6))" }} />
                  </div>
                  <div style={{ position: "absolute", right: 6, bottom: 4, fontSize: 9, color: "#EDE0E4", background: "rgba(0,0,0,0.55)", padding: "2px 6px", borderRadius: 6 }}>
                    © OpenStreetMap
                  </div>
                </div>
              ) : null}
              <div style={{ padding: "14px 16px" }}>
                <div style={{ fontSize: 15, fontWeight: 500 }}>{detail.venueName}</div>
                <div style={{ fontSize: 13, color: "#CFC0C5", marginTop: 3, lineHeight: 1.4 }}>{detail.address}</div>
              </div>
            </div>

            <div style={{ background: "#1B181B", borderRadius: 16, padding: 16, display: "flex", flexDirection: "column", gap: 10, minWidth: 0 }}>
              <div style={{ fontSize: 15, fontWeight: 500 }}>Signup signals</div>
              <div style={{ display: "flex", flexDirection: "column" }}>
                {detail.signals.map((sg: any, i: number) => (
                  <div key={i} style={{ display: "flex", justifyContent: "space-between", gap: 14, padding: "7px 0", borderBottom: "1px solid #241F23", fontSize: 13 }}>
                    <span style={{ color: "#9A8C91", flexShrink: 0 }}>{sg.label}</span>
                    <span style={{ textAlign: "right", fontFamily: sg.font, color: sg.color, minWidth: 0, wordBreak: "break-word" }}>{sg.value}</span>
                  </div>
                ))}
              </div>
            </div>

            <div style={{ background: "#1B181B", borderRadius: 16, padding: 16, display: "flex", flexDirection: "column", gap: 12, minWidth: 0 }}>
              <div style={{ fontSize: 15, fontWeight: 500 }}>Duplicate checks</div>
              {detail.duplicates.map((dp: any, i: number) => (
                <div key={i} style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
                  <div style={{ width: 28, height: 28, borderRadius: "50%", flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center", background: dp.bg, color: dp.fg }}>
                    <Icon name={dp.icon} size={16} />
                  </div>
                  <div style={{ minWidth: 0 }}>
                    <div style={{ fontSize: 13, fontWeight: 500 }}>{dp.title}</div>
                    <div style={{ fontSize: 12, color: "#9A8C91", marginTop: 2, lineHeight: 1.45 }}>{dp.body}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
