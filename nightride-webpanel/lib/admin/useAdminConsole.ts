"use client";

import { useState } from "react";
import {
  ACTIVITY,
  KPIS,
  INSTRUCTION_PRESETS,
  NAV_GROUPS_DEF,
  SECTION_TITLES,
  badgeColors,
  cityTile,
  getDetailExtra,
  getOrgs,
  getVenues,
  stepChrome,
  type BadgeType,
  type OrgBase,
  type StepStatusValue,
} from "./m3-data";

type OrgScreen = "list" | "detail" | "venue";

interface AdminConsoleState {
  selected: string;
  orgScreen: OrgScreen;
  activeOrgId: string;
  orgSearch: string;
  orgFilter: string;
  nicPhotoRevealed: Record<string, boolean>;
  statusOverrides: Record<string, OrgBase["status"]>;
  nicOverrides: Record<string, OrgBase["nicStatus"]>;
  videoOverrides: Record<string, "before" | "after">;
  instructionsDraft: Record<string, string>;
  infoRequestDraft: Record<string, string>;
  infoRequestSent: Record<string, boolean>;
  infoRequestOpen: Record<string, boolean>;
  moreMenuOpen: Record<string, boolean>;
  stepStatus: Record<string, StepStatusValue>;
  stepOpen: Record<string, string>;
  stepNotes: Record<string, string>;
  stepNoteOpen: Record<string, boolean>;
  stepNoteDraft: Record<string, string>;
  extraSteps: Record<string, string[]>;
  addStepMenuOpen: boolean;
  activeVenueId: string | null;
  suspendedVenues: Record<string, boolean>;
  transferredVenues: Record<string, string>;
  transferOpen: boolean;
}

const key = (id: string, stepId: string) => id + ":" + stepId;

function initialState(): AdminConsoleState {
  return {
    selected: "overview",
    orgScreen: "list",
    activeOrgId: "layla-osman",
    orgSearch: "",
    orgFilter: "all",
    nicPhotoRevealed: {},
    statusOverrides: {},
    nicOverrides: {},
    videoOverrides: {},
    instructionsDraft: {},
    infoRequestDraft: {},
    infoRequestSent: {},
    infoRequestOpen: {},
    moreMenuOpen: {},
    stepStatus: {},
    stepOpen: {},
    stepNotes: {},
    stepNoteOpen: {},
    stepNoteDraft: {},
    extraSteps: {},
    addStepMenuOpen: false,
    activeVenueId: null,
    suspendedVenues: {},
    transferredVenues: {},
    transferOpen: false,
  };
}

export function useAdminConsole() {
  const [state, setState] = useState<AdminConsoleState>(initialState);

  const patch = (p: Partial<AdminConsoleState> | ((s: AdminConsoleState) => Partial<AdminConsoleState>)) =>
    setState((s) => ({ ...s, ...(typeof p === "function" ? p(s) : p) }));

  // ---- nav / screen actions ----
  const select = (id: string) => patch({ selected: id, orgScreen: "list" });
  const openOrg = (id: string) => patch({ selected: "org-apps", orgScreen: "detail", activeOrgId: id });
  const backToList = () => patch({ orgScreen: "list" });
  const openVenue = (vid: string) => patch({ orgScreen: "venue", activeVenueId: vid, transferOpen: false });
  const backToOrg = () => patch({ orgScreen: "detail", activeVenueId: null, transferOpen: false });
  const toggleTransfer = () => patch((s) => ({ transferOpen: !s.transferOpen }));
  const transferVenue = (vid: string, toName: string) =>
    patch((s) => ({
      transferredVenues: { ...s.transferredVenues, [vid]: toName },
      transferOpen: false,
      orgScreen: "detail",
      activeVenueId: null,
    }));
  const toggleSuspendVenue = (vid: string) =>
    patch((s) => ({ suspendedVenues: { ...s.suspendedVenues, [vid]: !s.suspendedVenues[vid] } }));

  // ---- verification step actions ----
  const selectStep = (id: string, stepId: string) =>
    patch((s) => ({ stepOpen: { ...s.stepOpen, [id]: stepId }, addStepMenuOpen: false }));
  const setStepStatus = (id: string, stepId: string, status: StepStatusValue, nextId?: string) =>
    patch((s) => ({
      stepStatus: { ...s.stepStatus, [key(id, stepId)]: status },
      stepOpen: { ...s.stepOpen, [id]: nextId || stepId },
    }));
  const toggleAddStepMenu = () => patch((s) => ({ addStepMenuOpen: !s.addStepMenuOpen }));
  const toggleStepNote = (id: string, stepId: string) => {
    const k = key(id, stepId);
    patch((s) => ({ stepNoteOpen: { ...s.stepNoteOpen, [k]: !s.stepNoteOpen[k] } }));
  };
  const setStepNoteDraft = (id: string, stepId: string, v: string) =>
    patch((s) => ({ stepNoteDraft: { ...s.stepNoteDraft, [key(id, stepId)]: v } }));
  const saveStepNote = (id: string, stepId: string) => {
    const k = key(id, stepId);
    patch((s) => ({
      stepNotes: { ...s.stepNotes, [k]: s.stepNoteDraft[k] || "" },
      stepNoteOpen: { ...s.stepNoteOpen, [k]: false },
    }));
  };
  const addExtraStep = (id: string, type: string) =>
    patch((s) => {
      const list = s.extraSteps[id] || [];
      if (list.includes(type)) return { stepOpen: { ...s.stepOpen, [id]: type }, addStepMenuOpen: false };
      return {
        extraSteps: { ...s.extraSteps, [id]: [...list, type] },
        stepOpen: { ...s.stepOpen, [id]: type },
        addStepMenuOpen: false,
      };
    });

  // ---- org detail actions ----
  const togglePhoto = (id: string) =>
    patch((s) => ({ nicPhotoRevealed: { ...s.nicPhotoRevealed, [id]: !s.nicPhotoRevealed[id] } }));
  const setStatus = (id: string, status: OrgBase["status"]) =>
    patch((s) => ({ statusOverrides: { ...s.statusOverrides, [id]: status } }));
  const setNic = (id: string, nicStatus: OrgBase["nicStatus"]) =>
    patch((s) => ({ nicOverrides: { ...s.nicOverrides, [id]: nicStatus } }));
  const setInfoRequest = (id: string, text: string) =>
    patch((s) => ({ infoRequestDraft: { ...s.infoRequestDraft, [id]: text } }));
  const openInfoRequest = (id: string) =>
    patch((s) => ({ infoRequestOpen: { ...s.infoRequestOpen, [id]: true }, infoRequestSent: { ...s.infoRequestSent, [id]: false } }));
  const cancelInfoRequest = (id: string) => patch((s) => ({ infoRequestOpen: { ...s.infoRequestOpen, [id]: false } }));
  const sendInfoRequest = (id: string) =>
    patch((s) => ({
      infoRequestSent: { ...s.infoRequestSent, [id]: true },
      statusOverrides: { ...s.statusOverrides, [id]: "Info requested" },
    }));
  const toggleMoreMenu = (id: string) => patch((s) => ({ moreMenuOpen: { ...s.moreMenuOpen, [id]: !s.moreMenuOpen[id] } }));
  const resetPassword = (id: string) => patch((s) => ({ moreMenuOpen: { ...s.moreMenuOpen, [id]: false } }));
  const viewAuditLog = (id: string) => patch((s) => ({ moreMenuOpen: { ...s.moreMenuOpen, [id]: false } }));
  const sendInstructions = (id: string) => patch((s) => ({ videoOverrides: { ...s.videoOverrides, [id]: "after" } }));
  const setInstructions = (id: string, text: string) =>
    patch((s) => ({ instructionsDraft: { ...s.instructionsDraft, [id]: text } }));

  // ---- badge/step helpers bound to state ----
  function buildOrgCard(base: OrgBase) {
    const status = state.statusOverrides[base.id] || base.status;
    const statusType: BadgeType =
      status === "Rejected" || status === "Banned"
        ? "danger"
        : status === "Approved"
          ? "success"
          : status === "Info requested"
            ? "info"
            : status === "Deactivated"
              ? "neutral"
              : "warning";
    const nicStatus = state.nicOverrides[base.id] || base.nicStatus;
    const nicTypeMap: Record<string, BadgeType> = { matched: "success", mismatch: "danger" };
    const sc = badgeColors(statusType);
    const nc = badgeColors(nicTypeMap[nicStatus]);
    const pending = base.group === "pending";
    return {
      ...base,
      status,
      nicStatus,
      nicLabel: nicStatus === "matched" ? "Face matched" : "Face mismatch",
      nicIcon: nicStatus === "matched" ? "verified_user" : "report",
      statusBg: sc.bg,
      statusFg: sc.fg,
      nicBg: nc.bg,
      nicFg: nc.fg,
      avatarBg: pending ? "#8E1049" : "#1F4F49",
      avatarFg: pending ? "#FFD9E2" : "#A5F2E5",
      open: () => openOrg(base.id),
    };
  }

  function buildSteps(id: string, base: OrgBase, extra: ReturnType<typeof getDetailExtra>[string]) {
    const mismatch = base.nicStatus === "mismatch";
    const defs: Array<{
      id: string;
      title: string;
      tabLabel: string;
      icon: string;
      meta: string;
      def: StepStatusValue;
      previews?: Array<{ label: string; icon: string; danger?: boolean }>;
      evidence: Array<{ label: string; value: string; color?: string }>;
    }> = [
      {
        id: "nic",
        title: "NIC document",
        tabLabel: "NIC",
        icon: "badge",
        meta: "Uploaded 12 Aug · 21:04 · both sides",
        def: "verified",
        previews: [
          { label: "NIC FRONT", icon: "badge" },
          { label: "NIC BACK", icon: "flip_to_back" },
        ],
        evidence: [
          { label: "Document type", value: extra.nicDocType || "Sri Lanka NIC — new (12-digit)" },
          { label: "Fields extracted", value: "8 of 8" },
          { label: "Image quality", value: "Good — no glare or crop" },
          { label: "Tamper check", value: "No edits detected", color: "#7BE0A8" },
        ],
      },
      {
        id: "live",
        title: "Live face capture",
        tabLabel: "Live capture",
        icon: "face",
        meta: "Captured 12 Aug · 21:06 · in-app camera",
        def: mismatch ? "review" : "verified",
        previews: [
          { label: "NIC PHOTO", icon: "badge" },
          { label: "LIVE CAPTURE", icon: "face", danger: mismatch },
        ],
        evidence: [
          { label: "Liveness", value: "Passed — blink + head turn", color: "#7BE0A8" },
          {
            label: "Similarity to NIC photo",
            value: mismatch ? "41% — below threshold" : "94% — above threshold",
            color: mismatch ? "#FFB4AB" : "#7BE0A8",
          },
          { label: "Capture attempts", value: mismatch ? "3" : "1" },
        ],
      },
      {
        id: "venue",
        title: "Venue address",
        tabLabel: "Venue",
        icon: "storefront",
        meta: extra.address || base.address || "Submitted with application",
        def: "verified",
        evidence: [
          { label: "Venue name", value: extra.venueName || "—" },
          { label: "Address", value: extra.address || base.address || "—" },
          { label: "Matches licence record", value: "Yes", color: "#7BE0A8" },
        ],
      },
      {
        id: "gps",
        title: "On-site GPS check",
        tabLabel: "GPS",
        icon: "my_location",
        meta: "Pin dropped 180 m from stated address",
        def: "review",
        evidence: [
          { label: "Distance from address", value: "180 m", color: "#F5C452" },
          { label: "Checked at", value: "12 Aug · 23:41 local" },
          { label: "Accuracy", value: "±35 m" },
        ],
      },
      {
        id: "video",
        title: "Video walkthrough",
        tabLabel: "Video",
        icon: "videocam",
        meta: extra.videoState === "after" ? "Received — 1 min 48 s" : "Instructions not sent yet",
        def: extra.videoState === "after" ? "review" : "awaiting",
        evidence: [
          { label: "Status", value: extra.videoState === "after" ? "Uploaded, not yet watched" : "Waiting on organizer" },
          { label: "Required shots", value: "Entrance, main floor, bar" },
        ],
      },
    ];

    const extraDefs: Record<string, (typeof defs)[number]> = {
      code: {
        id: "code",
        title: "Posted code to address",
        tabLabel: "Posted code",
        icon: "local_post_office",
        meta: "Letter with a one-time code to the address they provided",
        def: "awaiting",
        evidence: [
          { label: "Posted to", value: extra.nicAddress || extra.address || base.address || "—" },
          { label: "Letter status", value: "Not posted yet" },
          { label: "Code state", value: "Not entered yet" },
        ],
      },
      call: {
        id: "call",
        title: "Live video call",
        tabLabel: "Video call",
        icon: "video_call",
        meta: "Live video call with the applicant",
        def: "awaiting",
        evidence: [
          { label: "Scheduled", value: "Not scheduled" },
          { label: "Assigned to", value: "Unassigned" },
          { label: "Checks on call", value: "Face vs. NIC, venue in frame" },
        ],
      },
    };
    (state.extraSteps[id] || []).forEach((t) => extraDefs[t] && defs.push(extraDefs[t]));

    const statuses = defs.map((d) => state.stepStatus[key(id, d.id)] || d.def);
    const resolved = (st: StepStatusValue) => st === "verified" || st === "failed";
    const firstOpen = defs.findIndex((_d, i) => !resolved(statuses[i]));
    const openId = state.stepOpen[id] || defs[firstOpen >= 0 ? firstOpen : 0].id;

    return defs.map((d, i) => {
      const k = key(id, d.id);
      const status = statuses[i];
      const c = stepChrome(status);
      const noteOpen = !!state.stepNoteOpen[k];
      const previews = (d.previews || []).map((p) => ({
        label: p.label,
        icon: p.icon,
        border: p.danger ? "#FFB4AB" : "transparent",
        color: p.danger ? "#FFB4AB" : "#9A8C91",
      }));
      const order = defs.map((_x, j) => (i + 1 + j) % defs.length).filter((j) => j !== i);
      const nextIdx = order.find((j) => !resolved(statuses[j]));
      const nextId = nextIdx === undefined ? d.id : defs[nextIdx].id;
      const active = openId === d.id;
      return {
        ...d,
        ...c,
        status,
        previews,
        active,
        evidence: d.evidence.map((e) => ({ ...e, color: e.color || "#EDE0E4" })),
        hasPreview: previews.length > 0,
        tabUnderline: active ? "#FFB1C4" : "transparent",
        tabColor: active ? "#FFB1C4" : "#CFC0C5",
        note: state.stepNotes[k] || "",
        noteOpen,
        noteLabel: noteOpen ? "Cancel" : "Add note",
        noteDraft: state.stepNoteDraft[k] || "",
        select: () => selectStep(id, d.id),
        markVerified: () => setStepStatus(id, d.id, "verified", nextId),
        markFailed: () => setStepStatus(id, d.id, "failed", nextId),
        requestResubmit: () => setStepStatus(id, d.id, "resubmit", nextId),
        toggleNote: () => toggleStepNote(id, d.id),
        onNoteChange: (e: React.ChangeEvent<HTMLInputElement>) => setStepNoteDraft(id, d.id, e.target.value),
        saveNote: () => saveStepNote(id, d.id),
      };
    });
  }

  function buildReviewPane(id: string, base: OrgBase, extra: ReturnType<typeof getDetailExtra>[string]) {
    const steps = buildSteps(id, base, extra);
    const done = steps.filter((s) => s.status === "verified").length;
    const failed = steps.filter((s) => s.status === "failed").length;
    const mismatch = base.nicStatus === "mismatch";
    const face = mismatch
      ? {
          score: "41%",
          verdict: "Flagged — below threshold",
          body: "The automated check could not confirm the live capture is the person on the NIC.",
          type: "danger" as BadgeType,
        }
      : {
          score: "94%",
          verdict: "Auto-approved — above threshold",
          body: "Cleared automatically. Shown for the record; override only if something looks wrong.",
          type: "success" as BadgeType,
        };
    const fc = badgeColors(face.type);

    const mono = "'Roboto Mono', monospace";
    const nameMismatch = (extra.nicNameOnId || base.name) !== base.name;
    const nicFields = [
      { label: "NIC number", value: extra.nicNumber || "—", font: mono },
      { label: "Name in full", value: extra.nicNameOnId || base.name, color: nameMismatch ? "#FFB4AB" : "#EDE0E4" },
      { label: "Other names", value: extra.nicOtherNames || "—" },
      { label: "Date of birth", value: extra.nicDob || "—" },
      { label: "Sex", value: extra.nicSex || "—" },
      { label: "Permanent address", value: extra.nicAddress || "—" },
      { label: "Date of issue", value: extra.nicIssued || "—" },
      { label: "Card serial", value: extra.nicSerial || "—", font: mono },
      { label: "DOB derived from number", value: "Matches", color: "#7BE0A8" },
      { label: "Checksum", value: "Valid", color: "#7BE0A8" },
    ].map((f) => ({ ...f, color: f.color || "#EDE0E4", font: f.font || "inherit" }));

    const signals = [
      { label: "Signed up", value: extra.signupDate || "—" },
      { label: "Account age", value: extra.accountAge || base.submitted || "—" },
      { label: "IP address", value: extra.ip || "—", font: mono },
      { label: "IP city", value: (extra.clubLocation || "Dubai") + " · matches venue", color: "#7BE0A8" },
      { label: "Device", value: extra.device || "—" },
      { label: "Email domain", value: (base.email.split("@")[1] || "") + " · free provider" },
    ].map((s) => ({ ...s, color: s.color || "#EDE0E4", font: s.font || "inherit" }));

    const duplicates = mismatch
      ? [
          { icon: "warning", bg: "#5C1218", fg: "#FFB4AB", title: "Similar NIC on file", body: "NIC ending 0128 was used by a rejected application in Mar 2026." },
          { icon: "content_copy", bg: "#42320A", fg: "#F5C452", title: "Venue name near-match", body: `"${extra.venueName || "This venue"}" is one character from an existing listing.` },
        ]
      : [
          { icon: "check", bg: "#0F3D28", fg: "#7BE0A8", title: "No duplicate NIC", body: "This NIC number has not been submitted before." },
          { icon: "check", bg: "#0F3D28", fg: "#7BE0A8", title: "No prior applications", body: "First application from this email and phone." },
        ];

    const blocking = failed > 0 || mismatch;
    const open = steps.length - done;
    return {
      steps,
      activeStep: steps.find((s) => s.active) || steps[0],
      stepProgressLabel: done + " of " + steps.length + " verified",
      stepProgressPct: Math.round((done / steps.length) * 100) + "%",
      addStepMenuOpen: state.addStepMenuOpen,
      addableSteps: [
        { type: "code", label: "Post a code to their address", icon: "local_post_office" },
        { type: "call", label: "Verification live video call", icon: "video_call" },
      ].map((a) => {
        const added = (state.extraSteps[id] || []).includes(a.type);
        return {
          ...a,
          label: added ? a.label + " · added" : a.label,
          color: added ? "#9A8C91" : "#EDE0E4",
          add: () => addExtraStep(id, a.type),
        };
      }),
      appliedLine: "Applied " + (base.submitted || "recently") + " · " + (extra.clubLocation || "Dubai"),
      decisionHint: blocking
        ? mismatch
          ? "Face match is below threshold — approving overrides the automated check."
          : failed + " step(s) flagged failed."
        : open === 0
          ? "All steps verified — safe to approve."
          : open + " step(s) still open.",
      decisionHintColor: blocking ? "#FFB4AB" : open === 0 ? "#7BE0A8" : "#CFC0C5",
      decisionIcon: blocking ? "gpp_maybe" : open === 0 ? "verified_user" : "pending",
      faceScore: face.score,
      faceVerdict: face.verdict,
      faceBody: face.body,
      faceThreshold: "85%",
      faceFg: fc.fg,
      faceCardBg: mismatch ? "#2A1A1C" : "#1B181B",
      nicDocType: extra.nicDocType || "Sri Lanka NIC — new (12-digit)",
      ocrConfidence: mismatch ? "91%" : "98%",
      nicFields,
      signals,
      duplicates,
    };
  }

  // ---- assemble render values ----
  const sel = state.selected;
  const orgs = getOrgs();
  const pendingCount = orgs.filter((o) => o.group === "pending").length;

  const navGroups = NAV_GROUPS_DEF.map((g) => ({
    label: g.label,
    items: g.items.map((item) => {
      const count = item.id === "org-apps" ? pendingCount : (item as { count?: number }).count;
      return {
        id: item.id,
        label: item.label,
        icon: item.icon,
        count,
        showCount: !!count,
        active: sel === item.id,
        select: () => select(item.id),
      };
    }),
  }));

  const [currentTitle, currentSubtitle] = SECTION_TITLES[sel] || SECTION_TITLES.overview;
  const isOrgApps = sel === "org-apps";
  const orgScreen = state.orgScreen;

  let verifyStrip: Array<ReturnType<typeof buildOrgCard> & { review: () => void }> = [];
  let orgGroups: Array<{ label: string; note: string; orgs: ReturnType<typeof buildOrgCard>[] }> = [];
   
  let detail: any = { mapUrl: "" };
   
  let venue: any = { mapUrl: "", rows: [], transferTargets: [] };

  if (isOrgApps) {
    const cards = orgs.map((o) => buildOrgCard(o));
    verifyStrip = cards.filter((o) => o.group === "pending").map((o) => ({ ...o, review: () => openOrg(o.id) }));

    const search = state.orgSearch.trim().toLowerCase();
    const filter = state.orgFilter;
    const matches = (o: (typeof cards)[number]) =>
      (!search || o.name.toLowerCase().includes(search) || o.email.toLowerCase().includes(search)) &&
      (filter === "all" || o.status === filter);

    orgGroups = [
      { key: "recent", label: "Recently added", note: "Newest organizer sign-ups" },
      { key: "approved", label: "Approved", note: "Cleared to publish events" },
      { key: "pending", label: "Pending verification", note: "Awaiting identity review" },
    ]
      .map((s) => {
        const list = cards.filter((o) => o.group === s.key && matches(o));
        return { label: s.label, note: list.length + " · " + s.note, orgs: list };
      })
      .filter((g) => g.orgs.length > 0);

    if ((orgScreen === "detail" || orgScreen === "venue") && state.activeOrgId) {
      const id = state.activeOrgId;
      const base = orgs.find((o) => o.id === id);
      if (base) {
        const extra = getDetailExtra()[id] || ({} as ReturnType<typeof getDetailExtra>[string]);
        const videoState = state.videoOverrides[id] || extra.videoState;
        const revealed = !!state.nicPhotoRevealed[id];
        const nicCallout = (
          {
            mismatch: { bg: "#2A1A1C", fg: "#FFB4AB", icon: "report", title: "Face mismatch", body: "The live capture does not match the face on the NIC." },
            matched: { bg: "#12291F", fg: "#7BE0A8", icon: "verified_user", title: "Face matched", body: "The live capture matches the face on the NIC." },
          } as const
        )[base.nicStatus];

        const tile = cityTile(extra.clubLocation || "Dubai");
        const currentStatus = state.statusOverrides[id] || base.status;

        detail = {
          ...base,
          ...extra,
          status: currentStatus,
          mapUrl: tile,
          isNewApp: base.group === "pending",
          isExistingOrg: base.group !== "pending",
          showInfoRequestBox: !!state.infoRequestOpen[id],
          infoRequestText:
            state.infoRequestDraft[id] ?? "Please retake your live photo in better lighting, and upload a clearer photo of your NIC.",
          infoRequestSent: !!state.infoRequestSent[id],
          moreMenuOpen: !!state.moreMenuOpen[id],
          canDeactivate: currentStatus !== "Deactivated" && currentStatus !== "Banned",
          canReactivate: currentStatus === "Deactivated",
          canBan: currentStatus !== "Banned",
          canUnban: currentStatus === "Banned",
          statusBg: badgeColors(
            currentStatus === "Rejected" || currentStatus === "Banned"
              ? "danger"
              : currentStatus === "Approved"
                ? "success"
                : currentStatus === "Info requested"
                  ? "info"
                  : currentStatus === "Deactivated"
                    ? "neutral"
                    : "warning",
          ).bg,
          statusFg: badgeColors(
            currentStatus === "Rejected" || currentStatus === "Banned"
              ? "danger"
              : currentStatus === "Approved"
                ? "success"
                : currentStatus === "Info requested"
                  ? "info"
                  : currentStatus === "Deactivated"
                    ? "neutral"
                    : "warning",
          ).fg,
          instructions:
            state.instructionsDraft[id] ??
            "Please record a short video walkthrough of your venue (entrance, main floor, and bar/DJ booth) and send it back here so we can complete your verification.",
          nicCalloutBg: nicCallout.bg,
          nicCalloutFg: nicCallout.fg,
          nicCalloutIcon: nicCallout.icon,
          nicCalloutTitle: nicCallout.title,
          nicCalloutBody: nicCallout.body,
          showPhotoDirect: base.nicStatus === "mismatch",
          showPhotoHidden: base.nicStatus === "matched",
          photoRevealed: revealed,
          photoHidden: !revealed,
          confirmDisabled: base.nicStatus === "matched",
          flagDisabled: base.nicStatus === "mismatch",
          videoBefore: videoState === "before",
          videoAfter: videoState === "after",
          ...buildReviewPane(id, base, extra),
        };

        const raw = (getVenues()[id] || []).filter((v) => !state.transferredVenues[v.id]);
        const venues = raw.map((v) => {
          const suspended = !!state.suspendedVenues[v.id];
          return {
            ...v,
            suspended,
            mapUrl: cityTile(v.city),
            capacityLabel: v.capacity + " cap",
            eventsLabel: v.events + " events",
            gpsLabel: v.gps ? "GPS verified" : "GPS not verified",
            gpsIcon: v.gps ? "where_to_vote" : "location_off",
            gpsColor: v.gps ? "#7BE0A8" : "#F5C452",
            stateBg: suspended ? "#42320A" : "#0F3D28",
            stateFg: suspended ? "#F5C452" : "#7BE0A8",
            stateLabel: suspended ? "Suspended" : "Live",
            open: () => openVenue(v.id),
          };
        });
        detail.venues = venues;
        detail.venuesNote = venues.length === 1 ? "1 venue assigned" : venues.length + " venues assigned";
        detail.hasVenues = venues.length > 0;
        detail.noVenues = venues.length === 0;
      }
    }

    if (orgScreen === "venue" && state.activeVenueId) {
      const list = getVenues()[state.activeOrgId] || [];
      const v = list.find((x) => x.id === state.activeVenueId);
      if (v) {
        const suspended = !!state.suspendedVenues[v.id];
        const transferredTo = state.transferredVenues[v.id];
        venue = {
          ...v,
          suspended,
          mapUrl: cityTile(v.city),
          stateBg: suspended ? "#42320A" : "#0F3D28",
          stateFg: suspended ? "#F5C452" : "#7BE0A8",
          stateLabel: suspended ? "Suspended" : "Live",
          suspendLabel: suspended ? "Un-suspend venue" : "Suspend venue",
          gpsLabel: v.gps ? "GPS verified on site" : "GPS not verified",
          gpsColor: v.gps ? "#7BE0A8" : "#F5C452",
          gpsIcon: v.gps ? "where_to_vote" : "location_off",
          transferredTo: transferredTo || "",
          wasTransferred: !!transferredTo,
          transferOpen: state.transferOpen,
          organizerName: detail.name,
          rows: [
            { label: "City", value: v.city },
            { label: "Address", value: v.address },
            { label: "Capacity", value: String(v.capacity), mono: true },
            { label: "Licence number", value: v.licence, mono: true },
            { label: "Licence expiry", value: v.licenceExpiry },
            { label: "Opening hours", value: v.hours },
            { label: "Contact phone", value: v.phone, mono: true },
            { label: "Events published", value: String(v.events), mono: true },
            { label: "Assigned to organizer", value: v.assigned },
          ].map((r) => ({ ...r, font: r.mono ? "'Roboto Mono', monospace" : "inherit" })),
          transferTargets: getOrgs()
            .filter((o) => o.group !== "pending" && o.id !== state.activeOrgId)
            .map((o) => ({ name: o.name, initials: o.initials, pick: () => transferVenue(v.id, o.name) })),
          toggleSuspend: () => toggleSuspendVenue(v.id),
        };
      }
    }
  }

  return {
    navGroups,
    isOverview: sel === "overview",
    isOrgApps,
    isOrgList: isOrgApps && orgScreen === "list",
    isOrgDetail: isOrgApps && orgScreen === "detail",
    isVenueDetail: isOrgApps && orgScreen === "venue",
    isPlaceholder: sel !== "overview" && !isOrgApps,
    currentTitle,
    currentSubtitle,
    orgSearch: state.orgSearch,
    orgFilter: state.orgFilter,
    onSearchChange: (e: React.ChangeEvent<HTMLInputElement>) => patch({ orgSearch: e.target.value }),
    onFilterChange: (e: React.ChangeEvent<HTMLSelectElement>) => patch({ orgFilter: e.target.value }),
    verifyStrip,
    orgGroups,
    detail,
    venue,
    backToList,
    backToOrg,
    toggleTransferHandler: toggleTransfer,
    showDecisionBar: isOrgApps && orgScreen === "detail" && !!detail.isNewApp,
    approveHandler: () => detail?.id && setStatus(detail.id, "Approved"),
    rejectHandler: () => detail?.id && setStatus(detail.id, "Rejected"),
    togglePhotoHandler: () => detail?.id && togglePhoto(detail.id),
    confirmMatchHandler: () => detail?.id && setNic(detail.id, "matched"),
    flagMismatchHandler: () => detail?.id && setNic(detail.id, "mismatch"),
    requestInfoHandler: () => detail?.id && openInfoRequest(detail.id),
    cancelInfoRequestHandler: () => detail?.id && cancelInfoRequest(detail.id),
    sendInfoRequestHandler: () => detail?.id && sendInfoRequest(detail.id),
    onInfoRequestChange: (e: React.ChangeEvent<HTMLTextAreaElement>) => detail?.id && setInfoRequest(detail.id, e.target.value),
    deactivateHandler: () => detail?.id && setStatus(detail.id, "Deactivated"),
    reactivateHandler: () => detail?.id && setStatus(detail.id, "Approved"),
    banHandler: () => detail?.id && setStatus(detail.id, "Banned"),
    unbanHandler: () => detail?.id && setStatus(detail.id, "Approved"),
    toggleMoreMenuHandler: () => detail?.id && toggleMoreMenu(detail.id),
    resetPasswordHandler: () => detail?.id && resetPassword(detail.id),
    viewAuditLogHandler: () => detail?.id && viewAuditLog(detail.id),
    toggleAddStepHandler: toggleAddStepMenu,
    sendInstructionsHandler: () => detail?.id && sendInstructions(detail.id),
    onInstructionsChange: (e: React.ChangeEvent<HTMLTextAreaElement>) => detail?.id && setInstructions(detail.id, e.target.value),
    instructionPresets: INSTRUCTION_PRESETS.map((p) => ({ ...p, apply: () => detail?.id && setInstructions(detail.id, p.text) })),
    kpis: KPIS,
    activity: ACTIVITY,
  };
}

export type AdminConsoleValues = ReturnType<typeof useAdminConsole>;
