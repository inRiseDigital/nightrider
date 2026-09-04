"use client";

import { useState, type ReactNode } from "react";
import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import { SimulatedBadge } from "../SimulatedBadge";
import { STEP_DEFS, STEP_ORDER, stepStatusChrome } from "@/lib/admin/present";
import { mockDuplicateChecks, mockFaceMatch, mockNicOcr, mockSignupSignals, type MockDuplicateCheck, type MockFaceMatch, type MockNicOcr, type MockSignupSignals } from "@/lib/admin/mock-overlay";
import { osmTileUrl } from "@/lib/admin/geo";
import { deriveDisplayStepStatus, type StepId, type UserRecord } from "@/lib/admin/schema";
import { stepApplicantClaim, videoScriptReady, type ApplicantDetail, type StepEvidence } from "@/lib/admin/useApplicantDetail";
import { VIDEO_SCRIPT_MAX_LINES, VIDEO_SCRIPT_TEMPLATES } from "@/lib/organizer/constants";

// ---------------------------------------------------------------------------
// Extra (addable) verification steps — `users/{uid}/private/organizerReview`'s
// `steps` map is a fixed five-key shape firestore.rules enforces, so these two
// steps have nowhere real to live. They're session-only UI state on this
// component: added, viewed, and noted here, gone on refresh/unmount. Always
// rendered with <SimulatedBadge/> so nobody mistakes them for persisted state.
// ---------------------------------------------------------------------------

type ExtraStepId = "code" | "call";

const EXTRA_STEP_ORDER: ExtraStepId[] = ["code", "call"];

const EXTRA_STEP_DEFS: Record<ExtraStepId, { tabLabel: string; icon: string; title: string; menuLabel: string; meta: string }> = {
  code: { tabLabel: "Posted code", icon: "local_post_office", title: "Posted code to address", menuLabel: "Post a code to their address", meta: "Letter with a one-time code to the address they provided" },
  call: { tabLabel: "Video call", icon: "video_call", title: "Verification live video call", menuLabel: "Verification live video call", meta: "Live video call with the applicant" },
};

function extraStepEvidence(type: ExtraStepId, user: UserRecord): { label: string; value: string }[] {
  if (type === "code") {
    const address = user.organizerApplication?.steps.venueAddress?.address || "—";
    return [
      { label: "Posted to", value: address },
      { label: "Letter status", value: "Not posted yet" },
      { label: "Code state", value: "Not entered yet" },
    ];
  }
  return [
    { label: "Scheduled", value: "Not scheduled" },
    { label: "Assigned to", value: "Unassigned" },
    { label: "Checks on call", value: "Face vs. NIC, venue in frame" },
  ];
}

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

/**
 * The walkthrough script for this applicant. Publishing one is what unlocks
 * their video step, so this panel is the only way that step ever opens — see
 * docs/FIRESTORE_SCHEMA.md on `steps.video`.
 */
function VideoScriptPanel({ detail }: { detail: ApplicantDetail }) {
  const {
    user,
    review,
    busy,
    scriptEditorOpen,
    scriptFormat,
    setScriptFormat,
    scriptDraft,
    setScriptDraft,
    openScriptEditor,
    closeScriptEditor,
    applyScriptTemplate,
    submitScript,
  } = detail;
  if (!user || !review) return null;

  const script = review.steps.video.script;
  const locked = review.steps.video.status === "pending";
  const ready = videoScriptReady(user, review);
  const draftLines = scriptDraft.split("\n").map((l) => l.trim()).filter(Boolean);
  const overLimit = draftLines.length > VIDEO_SCRIPT_MAX_LINES;

  if (!scriptEditorOpen) {
    return (
      <div style={{ background: "#1B181B", borderRadius: 16, padding: 16, display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
          <div style={{ fontSize: 15, fontWeight: 500 }}>
            Walkthrough script
            {script && script.revision > 0 ? (
              <span style={{ marginLeft: 8, fontSize: 12, fontWeight: 400, color: "#F5C452" }}>
                revised {script.revision} time{script.revision === 1 ? "" : "s"}
              </span>
            ) : null}
          </div>
          <Hoverable
            as="button"
            onClick={openScriptEditor}
            disabled={busy}
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: 8,
              height: 36,
              padding: "0 16px 0 12px",
              borderRadius: 18,
              fontSize: 13,
              fontWeight: 500,
              background: script ? "transparent" : "#42320A",
              color: script ? "#A5F2E5" : "#F5C452",
              border: script ? "1px solid #3E5F5A" : "none",
              cursor: "pointer",
              opacity: busy ? 0.5 : 1,
            }}
            hoverStyle={{ background: "#FFFFFF14" }}
          >
            <Icon name={script ? "edit" : "post_add"} size={18} />
            {script ? "Revise script" : "Write script"}
          </Hoverable>
        </div>

        {script ? (
          <ol
            style={{
              margin: 0,
              paddingLeft: script.format === "list" ? 22 : 0,
              listStyleType: script.format === "list" ? "decimal" : "none",
              display: "flex",
              flexDirection: "column",
              gap: 6,
              fontSize: 13,
              color: "#CFC0C5",
              lineHeight: 1.5,
            }}
          >
            {script.lines.map((line, i) => (
              <li key={i}>{line}</li>
            ))}
          </ol>
        ) : (
          <div style={{ fontSize: 13, color: "#9A8C91", lineHeight: 1.5 }}>
            No script published yet, so the applicant&apos;s video step is locked. Write one and it
            unlocks — they record against these lines.
          </div>
        )}

        {locked && !ready ? (
          <div style={{ display: "flex", gap: 8, alignItems: "flex-start", fontSize: 12, color: "#9A8C91" }}>
            <Icon name="info" size={16} color="#9A8C91" />
            <div>
              One of the other four steps is still outstanding. You can send a script now anyway — this
              is a note, not a block.
            </div>
          </div>
        ) : null}
      </div>
    );
  }

  return (
    <div style={{ background: "#1B181B", borderRadius: 16, padding: 16, display: "flex", flexDirection: "column", gap: 12 }}>
      <div style={{ fontSize: 15, fontWeight: 500 }}>{script ? "Revise the script" : "Write the script"}</div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 8, alignItems: "center" }}>
        <span style={{ fontSize: 12, color: "#9A8C91" }}>Start from</span>
        {VIDEO_SCRIPT_TEMPLATES.map((t) => (
          <Hoverable
            key={t.id}
            as="button"
            onClick={() => applyScriptTemplate(t.id)}
            style={{ height: 32, padding: "0 14px", borderRadius: 16, fontSize: 13, background: "transparent", color: "#CFC0C5", border: "1px solid #524549", cursor: "pointer" }}
            hoverStyle={{ background: "#FFFFFF0A", color: "#EDE0E4" }}
          >
            {t.label}
          </Hoverable>
        ))}
      </div>

      <textarea
        rows={10}
        value={scriptDraft}
        onChange={(e) => setScriptDraft(e.target.value)}
        placeholder={"One shot per line.\nStart outside with the signage visible.\nWalk in and show the door check."}
        style={{ width: "100%", background: "#2A252A", border: "none", borderRadius: 12, padding: "12px 16px", fontSize: 14, lineHeight: 1.55, color: "#EDE0E4", resize: "vertical" }}
      />

      <div style={{ display: "flex", flexWrap: "wrap", alignItems: "center", gap: 12, fontSize: 12, color: "#9A8C91" }}>
        <span>One line per entry.</span>
        <span style={{ color: overLimit ? "#FFB4AB" : "#9A8C91" }}>
          {draftLines.length}/{VIDEO_SCRIPT_MAX_LINES}
        </span>
        <div style={{ display: "flex", gap: 6, marginLeft: "auto" }}>
          {(["list", "text"] as const).map((f) => (
            <Hoverable
              key={f}
              as="button"
              onClick={() => setScriptFormat(f)}
              style={{
                height: 30,
                padding: "0 12px",
                borderRadius: 15,
                fontSize: 12,
                fontWeight: 500,
                background: scriptFormat === f ? "#1F4F49" : "transparent",
                color: scriptFormat === f ? "#A5F2E5" : "#CFC0C5",
                border: scriptFormat === f ? "none" : "1px solid #524549",
                cursor: "pointer",
              }}
              hoverStyle={{ background: "#FFFFFF14" }}
            >
              {f === "list" ? "Numbered list" : "Paragraphs"}
            </Hoverable>
          ))}
        </div>
      </div>

      <div style={{ display: "flex", gap: 8 }}>
        <button
          onClick={() => void submitScript()}
          disabled={busy || draftLines.length === 0 || overLimit}
          style={{
            height: 40,
            padding: "0 20px",
            borderRadius: 20,
            fontSize: 14,
            fontWeight: 500,
            background: "#1F4F49",
            color: "#A5F2E5",
            border: "none",
            cursor: "pointer",
            opacity: busy || draftLines.length === 0 || overLimit ? 0.5 : 1,
          }}
        >
          {script ? "Publish revision" : "Publish and unlock"}
        </button>
        <Hoverable
          as="button"
          onClick={closeScriptEditor}
          style={{ height: 40, padding: "0 18px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#CFC0C5", border: "none", cursor: "pointer" }}
          hoverStyle={{ background: "#FFFFFF14" }}
        >
          Cancel
        </Hoverable>
      </div>
    </div>
  );
}

/**
 * Internal-only note on one verification step (real or extra). Neither the
 * five real steps nor the two extra ones have a Firestore field for this —
 * `ReviewStep.note` is already spoken for by the ask-again flow (shown above
 * as "You asked: …") — so this is session-only state on the component, same
 * as the extra steps themselves.
 */
function StepNoteSection({
  savedNote,
  open,
  draft,
  onToggle,
  onDraftChange,
  onSave,
}: {
  savedNote: string;
  open: boolean;
  draft: string;
  onToggle: () => void;
  onDraftChange: (value: string) => void;
  onSave: () => void;
}) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
      {savedNote ? (
        <div style={{ display: "flex", flexDirection: "column", gap: 6, padding: "12px 14px", borderRadius: 12, background: "#2A252A" }}>
          <div style={{ display: "flex", gap: 10, fontSize: 13, color: "#CFC0C5" }}>
            <Icon name="sticky_note_2" size={18} color="#9A8C91" />
            <div style={{ minWidth: 0 }}>{savedNote}</div>
          </div>
          {/*
            There is no field behind this yet — organizerReview's per-step
            `note` is already the ask-again message the applicant sees. Say so
            on the note itself: a reviewer who thinks they have recorded a
            concern, and has not, is worse off than one who never typed it.
          */}
          <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: "#F5C452" }}>
            <Icon name="warning" size={14} />
            Kept on this screen only — not saved to the applicant&apos;s record.
          </div>
        </div>
      ) : null}
      {open ? (
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          <input
            value={draft}
            onChange={(e) => onDraftChange(e.target.value)}
            placeholder="Internal note — the organizer never sees this"
            style={{ flex: 1, minWidth: 200, height: 48, background: "#2A252A", border: "none", borderRadius: 12, padding: "0 16px", fontSize: 14, color: "#EDE0E4" }}
          />
          <button
            onClick={onSave}
            style={{ height: 48, padding: "0 22px", borderRadius: 24, fontSize: 14, fontWeight: 500, background: "#1F4F49", color: "#A5F2E5", border: "none", cursor: "pointer" }}
          >
            Save note
          </button>
        </div>
      ) : (
        <Hoverable
          as="button"
          onClick={onToggle}
          style={{ alignSelf: "flex-start", display: "inline-flex", alignItems: "center", gap: 8, height: 36, padding: "0 14px", borderRadius: 18, fontSize: 13, fontWeight: 500, background: "transparent", color: "#CFC0C5", border: "none", cursor: "pointer" }}
          hoverStyle={{ background: "#FFFFFF14", color: "#EDE0E4" }}
        >
          <Icon name="edit_note" size={18} />
          Add note
        </Hoverable>
      )}
    </div>
  );
}

function ExtraStepPanel({ type, user, note }: { type: ExtraStepId; user: UserRecord; note: ReactNode }) {
  const def = EXTRA_STEP_DEFS[type];
  const evidence = extraStepEvidence(type, user);
  return (
    <>
      <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
        <div style={{ minWidth: 0 }}>
          <div style={{ fontSize: 18, fontWeight: 400 }}>{def.title}</div>
          <div style={{ fontSize: 13, color: "#9A8C91", marginTop: 3 }}>{def.meta}</div>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 8, flexShrink: 0 }}>
          <div style={{ display: "inline-flex", alignItems: "center", gap: 6, height: 32, padding: "0 12px", borderRadius: 8, fontSize: 13, fontWeight: 500, background: "#332B30", color: "#CFC0C5" }}>
            <Icon name="schedule" size={16} />
            Not started
          </div>
          <SimulatedBadge />
        </div>
      </div>
      <div style={{ display: "flex", flexDirection: "column" }}>
        {evidence.map((row) => (
          <DetailRow key={row.label} label={row.label} value={row.value} />
        ))}
      </div>
      {note}
    </>
  );
}

export function VerificationFlow({ detail }: { detail: ApplicantDetail }) {
  const { user, review, evidence, openStepId, setOpenStepId, askAgainOpenFor, askAgainDraft, setAskAgainDraft, openAskAgain, cancelAskAgain, submitAskAgain, verifyStep, busy, actionError } = detail;

  const [extraSteps, setExtraSteps] = useState<ExtraStepId[]>([]);
  const [extraOpenId, setExtraOpenId] = useState<ExtraStepId | null>(null);
  const [addStepMenuOpen, setAddStepMenuOpen] = useState(false);
  const [stepNotes, setStepNotes] = useState<Record<string, string>>({});
  const [stepNoteOpen, setStepNoteOpen] = useState<Record<string, boolean>>({});
  const [stepNoteDraft, setStepNoteDraft] = useState<Record<string, string>>({});
  const [notedUid, setNotedUid] = useState<string | null>(null);

  // Session-only state (extra steps, notes) is per-applicant — switching to a
  // different application must not leak one applicant's added steps/notes
  // into another's view, even though this component itself doesn't remount.
  // Adjusting state during render (rather than in an effect) per
  // https://react.dev/learn/you-might-not-need-an-effect#adjusting-some-state-when-a-prop-changes.
  if (user && user.uid !== notedUid) {
    setNotedUid(user.uid);
    setExtraSteps([]);
    setExtraOpenId(null);
    setAddStepMenuOpen(false);
    setStepNotes({});
    setStepNoteOpen({});
    setStepNoteDraft({});
  }

  if (!user || !review || !evidence) return null;

  function toggleStepNote(key: string) {
    setStepNoteOpen((s) => ({ ...s, [key]: !s[key] }));
    setStepNoteDraft((s) => ({ ...s, [key]: s[key] ?? stepNotes[key] ?? "" }));
  }
  function saveStepNote(key: string) {
    setStepNotes((s) => ({ ...s, [key]: (stepNoteDraft[key] ?? "").trim() }));
    setStepNoteOpen((s) => ({ ...s, [key]: false }));
  }
  function addExtraStep(type: ExtraStepId) {
    setExtraSteps((s) => (s.includes(type) ? s : [...s, type]));
    setExtraOpenId(type);
    setAddStepMenuOpen(false);
  }

  const steps = STEP_ORDER.map((id) => {
    const raw = review.steps[id];
    const status = deriveDisplayStepStatus(raw.status, stepApplicantClaim(user, id));
    return { id, raw, status, chrome: stepStatusChrome(status), def: STEP_DEFS[id] };
  });
  const activeStep = extraOpenId ? null : steps.find((s) => s.id === openStepId) ?? steps[0];
  const doneCount = steps.filter((s) => s.raw.status === "accepted").length;
  const attemptCapped = activeStep !== null && activeStep.id !== "venueAddress" && activeStep.raw.attempt >= 3;

  const face = mockFaceMatch(user.uid);
  const ocr = mockNicOcr(user.uid, face.mismatch);
  const signals = mockSignupSignals(user.uid, user.email);
  const duplicates = mockDuplicateChecks(user.uid, face.mismatch);

  const activeKey = extraOpenId ?? activeStep?.id ?? "";

  return (
    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(340px, 1fr))", gap: 16, alignItems: "start" }}>
      <div style={{ display: "flex", flexDirection: "column", gap: 16, minWidth: 0 }}>
        <div style={{ background: "#1B181B", borderRadius: 16, position: "relative" }}>
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

          <div style={{ display: "flex", alignItems: "stretch", gap: 0, padding: "0 12px", borderBottom: "1px solid #332B30" }}>
            <div style={{ display: "flex", alignItems: "stretch", flex: 1, minWidth: 0, overflowX: "auto" }}>
              {steps.map((s) => (
                <Hoverable
                  key={s.id}
                  onClick={() => {
                    setOpenStepId(s.id);
                    setExtraOpenId(null);
                  }}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 8,
                    height: 52,
                    padding: "0 14px",
                    cursor: "pointer",
                    flexShrink: 0,
                    borderBottom: `3px solid ${s.id === activeKey ? "#FFB1C4" : "transparent"}`,
                    borderRadius: "8px 8px 0 0",
                    color: s.id === activeKey ? "#FFB1C4" : "#CFC0C5",
                    transition: "color 120ms linear",
                  }}
                  hoverStyle={{ background: "#FFFFFF0A", color: "#EDE0E4" }}
                >
                  <Icon name={s.def.icon} size={20} color={s.chrome.fg} />
                  <div style={{ fontSize: 14, fontWeight: 500, whiteSpace: "nowrap" }}>{s.def.tabLabel}</div>
                </Hoverable>
              ))}
              {extraSteps.map((type) => {
                const def = EXTRA_STEP_DEFS[type];
                const active = type === activeKey;
                return (
                  <Hoverable
                    key={type}
                    onClick={() => setExtraOpenId(type)}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 8,
                      height: 52,
                      padding: "0 14px",
                      cursor: "pointer",
                      flexShrink: 0,
                      borderBottom: `3px solid ${active ? "#FFB1C4" : "transparent"}`,
                      borderRadius: "8px 8px 0 0",
                      color: active ? "#FFB1C4" : "#CFC0C5",
                      transition: "color 120ms linear",
                    }}
                    hoverStyle={{ background: "#FFFFFF0A", color: "#EDE0E4" }}
                  >
                    <Icon name={def.icon} size={20} color="#CFC0C5" />
                    <div style={{ fontSize: 14, fontWeight: 500, whiteSpace: "nowrap" }}>{def.tabLabel}</div>
                  </Hoverable>
                );
              })}
            </div>
            <div style={{ display: "flex", alignItems: "center", paddingLeft: 8, flexShrink: 0 }}>
              <Hoverable
                as="button"
                onClick={() => setAddStepMenuOpen(true)}
                title="Add a verification step"
                style={{ width: 36, height: 36, borderRadius: "50%", background: "#2A252A", color: "#CFC0C5", border: "none", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}
                hoverStyle={{ background: "#3A333A", color: "#EDE0E4" }}
              >
                <Icon name="add" size={20} />
              </Hoverable>
            </div>
          </div>

          <div className="m3-rise" style={{ minHeight: 340, padding: "20px 24px 24px", display: "flex", flexDirection: "column", gap: 18 }}>
            {extraOpenId ? (
              <ExtraStepPanel
                type={extraOpenId}
                user={user}
                note={
                  <StepNoteSection
                    savedNote={stepNotes[extraOpenId] ?? ""}
                    open={!!stepNoteOpen[extraOpenId]}
                    draft={stepNoteDraft[extraOpenId] ?? ""}
                    onToggle={() => toggleStepNote(extraOpenId)}
                    onDraftChange={(v) => setStepNoteDraft((s) => ({ ...s, [extraOpenId]: v }))}
                    onSave={() => saveStepNote(extraOpenId)}
                  />
                }
              />
            ) : activeStep ? (
              <>
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

                {activeStep.id === "video" ? <VideoScriptPanel detail={detail} /> : null}

                {activeStep.raw.note ? (
                  <div style={{ display: "flex", gap: 10, padding: "12px 14px", borderRadius: 12, background: "#2A252A", fontSize: 13, color: "#CFC0C5" }}>
                    <Icon name="sticky_note_2" size={18} color="#9A8C91" />
                    <div style={{ minWidth: 0 }}>You asked: {activeStep.raw.note}</div>
                  </div>
                ) : null}

                <StepNoteSection
                  savedNote={stepNotes[activeStep.id] ?? ""}
                  open={!!stepNoteOpen[activeStep.id]}
                  draft={stepNoteDraft[activeStep.id] ?? ""}
                  onToggle={() => toggleStepNote(activeStep.id)}
                  onDraftChange={(v) => setStepNoteDraft((s) => ({ ...s, [activeStep.id]: v }))}
                  onSave={() => saveStepNote(activeStep.id)}
                />

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
              </>
            ) : null}
            {actionError ? <div style={{ color: "#FFB4AB", fontSize: 13 }}>{actionError}</div> : null}
          </div>

          {addStepMenuOpen ? (
            <div
              onClick={() => setAddStepMenuOpen(false)}
              style={{ position: "fixed", inset: 0, zIndex: 60, background: "rgba(0,0,0,0.55)", display: "flex", alignItems: "center", justifyContent: "center", padding: 24 }}
            >
              <div onClick={(e) => e.stopPropagation()} style={{ width: "100%", maxWidth: 360, background: "#2A252A", borderRadius: 28, padding: "24px 0 12px" }}>
                <div style={{ padding: "0 24px 8px" }}>
                  <div style={{ fontSize: 20, fontWeight: 400 }}>Add a verification step</div>
                  <div style={{ fontSize: 13, color: "#CFC0C5", marginTop: 6 }}>The step is added to this application only.</div>
                </div>
                {EXTRA_STEP_ORDER.map((type) => {
                  const def = EXTRA_STEP_DEFS[type];
                  const added = extraSteps.includes(type);
                  return (
                    <Hoverable
                      key={type}
                      onClick={() => addExtraStep(type)}
                      style={{ display: "flex", alignItems: "center", gap: 16, padding: "14px 24px", fontSize: 15, cursor: "pointer", color: added ? "#9A8C91" : "#EDE0E4" }}
                      hoverStyle={{ background: "#FFFFFF14" }}
                    >
                      <Icon name={def.icon} size={22} />
                      {def.menuLabel}
                      {added ? " · added" : ""}
                    </Hoverable>
                  );
                })}
                <div style={{ display: "flex", justifyContent: "flex-end", padding: "8px 16px 4px" }}>
                  <Hoverable
                    as="button"
                    onClick={() => setAddStepMenuOpen(false)}
                    style={{ height: 40, padding: "0 18px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#FFB1C4", border: "none", cursor: "pointer" }}
                    hoverStyle={{ background: "#FFFFFF14" }}
                  >
                    Cancel
                  </Hoverable>
                </div>
              </div>
            </div>
          ) : null}
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
