"use client";

import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import { SimulatedBadge } from "../SimulatedBadge";
import { STEP_DEFS, STEP_ORDER, stepStatusChrome } from "@/lib/admin/present";
import { mockDuplicateChecks, mockFaceMatch, mockNicOcr, mockSignupSignals, type MockDuplicateCheck, type MockFaceMatch, type MockNicOcr, type MockSignupSignals } from "@/lib/admin/mock-overlay";
import { osmTileUrl } from "@/lib/admin/geo";
import { deriveDisplayStepStatus, type StepId, type UserRecord } from "@/lib/admin/schema";
import { stepApplicantClaim, type ApplicantDetail, type StepEvidence } from "@/lib/admin/useApplicantDetail";

function stepMeta(stepId: StepId, user: UserRecord): string {
  const app = user.organizerApplication;
  if (stepId === "venueAddress") {
    const v = app?.steps.venueAddress;
    return v ? `${v.address}, ${v.city}` : "No address submitted yet";
  }
  if (stepId === "gps") {
    const n = app?.steps.gps.attempts.length ?? 0;
    return n === 0 ? "No GPS attempts recorded yet" : `${n} attempt${n === 1 ? "" : "s"} recorded by the mobile app`;
  }
  const uploaded = app ? app.steps[stepId as "nic" | "selfie" | "video"].uploaded : false;
  return uploaded ? "The applicant says they've uploaded this" : "Not uploaded yet";
}

function DetailRow({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div style={{ display: "flex", justifyContent: "space-between", gap: 16, padding: "8px 0", borderBottom: "1px solid #241F23", fontSize: 14 }}>
      <span style={{ color: "#9A8C91", flexShrink: 0 }}>{label}</span>
      <span style={{ textAlign: "right", fontFamily: mono ? "'Roboto Mono', monospace" : "inherit" }}>{value}</span>
    </div>
  );
}

function EvidencePhoto({ url, label }: { url: string | null; label: string }) {
  if (!url) {
    return (
      <div style={{ aspectRatio: "16/10", borderRadius: 12, background: "#2A252A", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 6, color: "#9A8C91" }}>
        <Icon name="hide_image" size={24} />
        <div style={{ fontFamily: "'Roboto Mono', monospace", fontSize: 10, letterSpacing: "0.06em" }}>{label}</div>
      </div>
    );
  }
  // eslint-disable-next-line @next/next/no-img-element
  return <img src={url} alt={label} style={{ width: "100%", aspectRatio: "16/10", objectFit: "cover", borderRadius: 12, background: "#2A252A" }} />;
}

function StepEvidenceView({ stepId, user, evidence }: { stepId: StepId; user: UserRecord; evidence: StepEvidence }) {
  if (stepId === "venueAddress") {
    const v = user.organizerApplication?.steps.venueAddress;
    if (!v) return <div style={{ fontSize: 13, color: "#9A8C91" }}>Nothing submitted yet.</div>;
    return (
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: 16 }}>
        {v.geo ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={osmTileUrl(v.geo.latitude, v.geo.longitude)} alt="Venue map" style={{ width: "100%", height: 140, objectFit: "cover", borderRadius: 12 }} />
        ) : null}
        <div style={{ display: "flex", flexDirection: "column" }}>
          <DetailRow label="Address" value={v.address || "—"} />
          <DetailRow label="City" value={v.city || "—"} />
          <DetailRow label="Country" value={v.countryCode || "—"} />
          <DetailRow label="Pin source" value={v.placeId ? "Geocoder" : "Hand-placed"} />
        </div>
      </div>
    );
  }
  if (stepId === "gps") {
    const g = evidence.gps;
    if (!g.hasObservation) return <div style={{ fontSize: 13, color: "#9A8C91" }}>No GPS attempts recorded yet.</div>;
    return (
      <div style={{ display: "flex", flexDirection: "column" }}>
        <DetailRow
          label="Distance from venue"
          value={g.distanceM === null ? "Accept the venue address first" : `${Math.round(g.distanceM)} m`}
        />
        <DetailRow label="Accuracy" value={g.accuracyM !== null ? `±${Math.round(g.accuracyM)} m` : "—"} />
        <DetailRow label="Mock location detected" value={g.mocked ? "Yes — flag this" : "No"} />
      </div>
    );
  }
  if (stepId === "nic") {
    return (
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, maxWidth: 440 }}>
        <EvidencePhoto url={evidence.nic.front} label="NIC FRONT" />
        <EvidencePhoto url={evidence.nic.back} label="NIC BACK" />
      </div>
    );
  }
  if (stepId === "selfie") {
    return (
      <div style={{ maxWidth: 220 }}>
        <EvidencePhoto url={evidence.selfie.capture} label="LIVE CAPTURE" />
      </div>
    );
  }
  // video
  if (!evidence.video.walkthrough) {
    return <div style={{ fontSize: 13, color: "#9A8C91" }}>No video received yet.</div>;
  }
  return (
    <video controls poster={evidence.video.poster ?? undefined} src={evidence.video.walkthrough} style={{ width: "100%", maxWidth: 480, maxHeight: 320, borderRadius: 12, background: "#000" }} />
  );
}

function FaceMatchCard({ face }: { face: MockFaceMatch }) {
  return (
    <div style={{ background: face.mismatch ? "#2A1A1C" : "#1B181B", borderRadius: 16, padding: "14px 16px", display: "flex", flexDirection: "column", gap: 10 }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div style={{ fontSize: 13, fontWeight: 500 }}>
          Face match <span style={{ color: "#9A8C91", fontWeight: 400 }}>≥{face.threshold}</span>
        </div>
        <SimulatedBadge />
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <div style={{ fontSize: 26, fontWeight: 300, color: face.mismatch ? "#FFB4AB" : "#7BE0A8" }}>{face.score}</div>
        <div style={{ fontSize: 12, color: face.mismatch ? "#FFB4AB" : "#7BE0A8" }}>{face.verdict}</div>
      </div>
    </div>
  );
}

function NicOcrCard({ ocr }: { ocr: MockNicOcr }) {
  return (
    <div style={{ background: "#1B181B", borderRadius: 16, padding: 16, display: "flex", flexDirection: "column", gap: 10 }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div style={{ fontSize: 15, fontWeight: 500 }}>NIC extraction</div>
        <SimulatedBadge />
      </div>
      <DetailRow label="Document type" value={ocr.docType} />
      <DetailRow label="Fields extracted" value={ocr.fieldsExtracted} />
      <DetailRow label="Image quality" value={ocr.imageQuality} />
      <DetailRow label="OCR confidence" value={ocr.ocrConfidence} />
    </div>
  );
}

function SignupSignalsCard({ signals }: { signals: MockSignupSignals }) {
  return (
    <div style={{ background: "#1B181B", borderRadius: 16, padding: 16, display: "flex", flexDirection: "column", gap: 10 }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div style={{ fontSize: 15, fontWeight: 500 }}>Signup signals</div>
        <SimulatedBadge />
      </div>
      <DetailRow label="IP address" value={signals.ip} mono />
      <DetailRow label="Device" value={signals.device} />
      <DetailRow label="Email domain" value={signals.emailDomainNote} />
    </div>
  );
}

function DuplicateChecksCard({ items }: { items: MockDuplicateCheck[] }) {
  return (
    <div style={{ background: "#1B181B", borderRadius: 16, padding: 16, display: "flex", flexDirection: "column", gap: 12 }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div style={{ fontSize: 15, fontWeight: 500 }}>Duplicate checks</div>
        <SimulatedBadge />
      </div>
      {items.map((dp, i) => {
        const colors = dp.tone === "danger" ? { bg: "#5C1218", fg: "#FFB4AB" } : dp.tone === "warning" ? { bg: "#42320A", fg: "#F5C452" } : { bg: "#0F3D28", fg: "#7BE0A8" };
        return (
          <div key={i} style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
            <div style={{ width: 28, height: 28, borderRadius: "50%", flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center", background: colors.bg, color: colors.fg }}>
              <Icon name={dp.icon} size={16} />
            </div>
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 500 }}>{dp.title}</div>
              <div style={{ fontSize: 12, color: "#9A8C91", marginTop: 2, lineHeight: 1.45 }}>{dp.body}</div>
            </div>
          </div>
        );
      })}
    </div>
  );
}

export function VerificationFlow({ detail }: { detail: ApplicantDetail }) {
  const { user, review, evidence, openStepId, setOpenStepId, askAgainOpenFor, askAgainDraft, setAskAgainDraft, openAskAgain, cancelAskAgain, submitAskAgain, verifyStep, busy, actionError } = detail;
  if (!user || !review || !evidence) return null;

  const steps = STEP_ORDER.map((id) => {
    const raw = review.steps[id];
    const status = deriveDisplayStepStatus(raw.status, stepApplicantClaim(user, id));
    return { id, raw, status, chrome: stepStatusChrome(status), def: STEP_DEFS[id] };
  });
  const activeStep = steps.find((s) => s.id === openStepId) ?? steps[0];
  const doneCount = steps.filter((s) => s.raw.status === "accepted").length;
  const attemptCapped = activeStep.id !== "venueAddress" && activeStep.raw.attempt >= 3;

  const face = mockFaceMatch(user.uid);
  const ocr = mockNicOcr(user.uid, face.mismatch);
  const signals = mockSignupSignals(user.uid, user.email);
  const duplicates = mockDuplicateChecks(user.uid, face.mismatch);

  return (
    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(340px, 1fr))", gap: 16, alignItems: "start" }}>
      <div style={{ display: "flex", flexDirection: "column", gap: 16, minWidth: 0 }}>
        <div style={{ background: "#1B181B", borderRadius: 16 }}>
          <div style={{ padding: "20px 24px 14px", display: "flex", alignItems: "flex-end", justifyContent: "space-between", gap: 16, flexWrap: "wrap" }}>
            <div>
              <div style={{ fontSize: 16, fontWeight: 500 }}>Verification flow</div>
              <div style={{ fontSize: 13, color: "#9A8C91", marginTop: 2 }}>Review each step, then decide</div>
            </div>
            <div style={{ flexShrink: 0, minWidth: 140 }}>
              <div style={{ fontSize: 12, color: "#CFC0C5", textAlign: "right", marginBottom: 6 }}>
                {doneCount} of {steps.length} verified
              </div>
              <div style={{ height: 4, borderRadius: 99, background: "#524549", overflow: "hidden" }}>
                <div style={{ height: "100%", borderRadius: 99, background: "#FFB1C4", width: `${Math.round((doneCount / steps.length) * 100)}%` }} />
              </div>
            </div>
          </div>

          <div style={{ display: "flex", alignItems: "stretch", gap: 0, padding: "0 12px", borderBottom: "1px solid #332B30", overflowX: "auto" }}>
            {steps.map((s) => (
              <Hoverable
                key={s.id}
                onClick={() => setOpenStepId(s.id)}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 8,
                  height: 52,
                  padding: "0 14px",
                  cursor: "pointer",
                  flexShrink: 0,
                  borderBottom: `3px solid ${s.id === activeStep.id ? "#FFB1C4" : "transparent"}`,
                  borderRadius: "8px 8px 0 0",
                  color: s.id === activeStep.id ? "#FFB1C4" : "#CFC0C5",
                  transition: "color 120ms linear",
                }}
                hoverStyle={{ background: "#FFFFFF0A", color: "#EDE0E4" }}
              >
                <Icon name={s.def.icon} size={20} color={s.chrome.fg} />
                <div style={{ fontSize: 14, fontWeight: 500, whiteSpace: "nowrap" }}>{s.def.tabLabel}</div>
              </Hoverable>
            ))}
          </div>

          <div className="m3-rise" style={{ minHeight: 340, padding: "20px 24px 24px", display: "flex", flexDirection: "column", gap: 18 }}>
            <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 18, fontWeight: 400 }}>{activeStep.def.title}</div>
                <div style={{ fontSize: 13, color: "#9A8C91", marginTop: 3 }}>{stepMeta(activeStep.id, user)}</div>
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
                  background: activeStep.chrome.bg,
                  color: activeStep.chrome.fg,
                }}
              >
                <Icon name={activeStep.chrome.icon} size={16} />
                {activeStep.chrome.label}
              </div>
            </div>

            <StepEvidenceView stepId={activeStep.id} user={user} evidence={evidence} />

            {activeStep.raw.note ? (
              <div style={{ display: "flex", gap: 10, padding: "12px 14px", borderRadius: 12, background: "#2A252A", fontSize: 13, color: "#CFC0C5" }}>
                <Icon name="sticky_note_2" size={18} color="#9A8C91" />
                <div style={{ minWidth: 0 }}>You asked: {activeStep.raw.note}</div>
              </div>
            ) : null}

            {askAgainOpenFor === activeStep.id ? (
              <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                <textarea
                  rows={2}
                  value={askAgainDraft}
                  onChange={(e) => setAskAgainDraft(e.target.value)}
                  placeholder="What should they fix or resubmit?"
                  style={{ width: "100%", background: "#2A252A", border: "none", borderRadius: 12, padding: "12px 16px", fontSize: 14, color: "#EDE0E4", resize: "vertical" }}
                />
                <div style={{ display: "flex", gap: 8 }}>
                  <button
                    onClick={() => void submitAskAgain()}
                    disabled={busy || !askAgainDraft.trim()}
                    style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#1F4F49", color: "#A5F2E5", border: "none", cursor: "pointer", opacity: busy || !askAgainDraft.trim() ? 0.5 : 1 }}
                  >
                    Send
                  </button>
                  <Hoverable
                    as="button"
                    onClick={cancelAskAgain}
                    style={{ height: 40, padding: "0 18px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#CFC0C5", border: "none", cursor: "pointer" }}
                    hoverStyle={{ background: "#FFFFFF14" }}
                  >
                    Cancel
                  </Hoverable>
                </div>
              </div>
            ) : (
              <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: "auto", paddingTop: 4 }}>
                <Hoverable
                  as="button"
                  onClick={() => void verifyStep(activeStep.id)}
                  disabled={busy || activeStep.raw.status === "accepted"}
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
                    opacity: busy || activeStep.raw.status === "accepted" ? 0.5 : 1,
                  }}
                  hoverStyle={{ background: "#175236" }}
                >
                  <Icon name="check" size={18} />
                  {activeStep.raw.status === "accepted" ? "Verified" : "Verify"}
                </Hoverable>
                <Hoverable
                  as="button"
                  onClick={() => openAskAgain(activeStep.id)}
                  disabled={busy || attemptCapped}
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
                    opacity: busy || attemptCapped ? 0.5 : 1,
                  }}
                  hoverStyle={{ background: "#FFFFFF0A" }}
                >
                  <Icon name="refresh" size={18} />
                  {attemptCapped ? "Max attempts reached" : "Ask again"}
                </Hoverable>
              </div>
            )}
            {actionError ? <div style={{ color: "#FFB4AB", fontSize: 13 }}>{actionError}</div> : null}
          </div>
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))", gap: 12, alignItems: "start", minWidth: 0 }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 12, minWidth: 0 }}>
          <FaceMatchCard face={face} />
          <NicOcrCard ocr={ocr} />
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 12, minWidth: 0 }}>
          <SignupSignalsCard signals={signals} />
          <DuplicateChecksCard items={duplicates} />
        </div>
      </div>
    </div>
  );
}
