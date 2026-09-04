import {
  collection,
  doc,
  getCountFromServer,
  getDoc,
  getDocs,
  GeoPoint,
  limit,
  orderBy,
  query,
  serverTimestamp,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
  type DocumentReference,
} from "firebase/firestore";
import { getDb, getFirebaseAuth } from "@/lib/firebase";
import { encodeGeohash } from "./geo";
import type {
  AdminReviewDoc,
  AdminReviewStep,
  LogAction,
  LogEntry,
  LogTargetType,
  OrganizerStatus,
  StepId,
  UserRecord,
  Venue,
  VenueStatus,
} from "./schema";
import { parseApplication, parseVideoScript } from "@/lib/organizer/application-service";
import { VIDEO_SCRIPT_MAX_LINES, VIDEO_SCRIPT_MAX_LINE_CHARS } from "@/lib/organizer/constants";
import type { VideoScript } from "@/lib/organizer/types";

function userDocRef(uid: string): DocumentReference {
  return doc(getDb(), "users", uid);
}
function reviewDocRef(uid: string): DocumentReference {
  return doc(getDb(), "users", uid, "private", "organizerReview");
}

function toTimestampOrNull(raw: unknown): Timestamp | null {
  return raw instanceof Timestamp ? raw : null;
}
function toGeoOrNull(raw: unknown): { latitude: number; longitude: number } | null {
  return raw instanceof GeoPoint ? { latitude: raw.latitude, longitude: raw.longitude } : null;
}

// ---------------------------------------------------------------------------
// Parsing — defensive, mirrors lib/organizer/application-service.ts's style.
// ---------------------------------------------------------------------------

export function parseUserRecord(uid: string, data: Record<string, unknown> | undefined): UserRecord {
  const d = data ?? {};
  return {
    uid,
    email: typeof d.email === "string" ? d.email : "",
    displayName: typeof d.displayName === "string" ? d.displayName : "",
    city: typeof d.city === "string" ? d.city : "",
    phone: typeof d.phone === "string" ? d.phone : "",
    instagram: typeof d.instagram === "string" ? d.instagram : "",
    isAdmin: d.isAdmin === true,
    organizerStatus: (typeof d.organizerStatus === "string" ? d.organizerStatus : "none") as OrganizerStatus,
    organizerApplication: d.organizerApplication ? parseApplication(d) : null,
    applicationSubmittedAt: toTimestampOrNull((d.organizerApplication as Record<string, unknown> | undefined)?.submittedAt),
    createdAt: toTimestampOrNull(d.createdAt),
    updatedAt: toTimestampOrNull(d.updatedAt),
  };
}

const DEFAULT_ADMIN_REVIEW_STEP: AdminReviewStep = {
  status: "pending",
  attempt: 0,
  note: "",
  reviewedAt: null,
  reviewedBy: null,
  venueId: null,
  mediaDeletedAt: null,
  script: null,
};

function parseAdminReviewStep(raw: unknown, fallbackStatus: AdminReviewStep["status"]): AdminReviewStep {
  if (!raw || typeof raw !== "object") return { ...DEFAULT_ADMIN_REVIEW_STEP, status: fallbackStatus };
  const r = raw as Record<string, unknown>;
  return {
    status: (typeof r.status === "string" ? r.status : fallbackStatus) as AdminReviewStep["status"],
    attempt: typeof r.attempt === "number" ? r.attempt : 0,
    note: typeof r.note === "string" ? r.note : "",
    reviewedAt: toTimestampOrNull(r.reviewedAt),
    reviewedBy: typeof r.reviewedBy === "string" ? r.reviewedBy : null,
    venueId: typeof r.venueId === "string" ? r.venueId : null,
    mediaDeletedAt: toTimestampOrNull(r.mediaDeletedAt),
    script: parseVideoScript(r.script),
  };
}

export function parseAdminReviewDoc(data: Record<string, unknown> | undefined): AdminReviewDoc | null {
  if (!data) return null;
  const rawSteps = (data.steps ?? {}) as Record<string, unknown>;
  return {
    status: (typeof data.status === "string" ? data.status : "none") as OrganizerStatus,
    appliedAt: toTimestampOrNull(data.appliedAt),
    decidedAt: toTimestampOrNull(data.decidedAt),
    decidedBy: typeof data.decidedBy === "string" ? data.decidedBy : "",
    rejectionReason: typeof data.rejectionReason === "string" ? data.rejectionReason : "",
    phoneVerified: data.phoneVerified === true,
    steps: {
      venueAddress: parseAdminReviewStep(rawSteps.venueAddress, "active"),
      nic: parseAdminReviewStep(rawSteps.nic, "active"),
      selfie: parseAdminReviewStep(rawSteps.selfie, "active"),
      video: parseAdminReviewStep(rawSteps.video, "pending"),
      gps: parseAdminReviewStep(rawSteps.gps, "pending"),
    },
    updatedAt: toTimestampOrNull(data.updatedAt),
  };
}

export function parseVenueDoc(id: string, data: Record<string, unknown>): Venue {
  return {
    id,
    name: typeof data.name === "string" ? data.name : "",
    geo: toGeoOrNull(data.geo),
    geohash: typeof data.geohash === "string" ? data.geohash : "",
    type: typeof data.type === "string" ? data.type : "",
    typeLabel: typeof data.typeLabel === "string" ? data.typeLabel : "",
    city: typeof data.city === "string" ? data.city : "",
    countryCode: typeof data.countryCode === "string" ? data.countryCode : "",
    address: typeof data.address === "string" ? data.address : "",
    openingHours: typeof data.openingHours === "string" ? data.openingHours : "",
    phone: typeof data.phone === "string" ? data.phone : "",
    website: typeof data.website === "string" ? data.website : "",
    photos: Array.isArray(data.photos) ? (data.photos as string[]) : [],
    source: (typeof data.source === "string" ? data.source : "admin") as Venue["source"],
    osmId: typeof data.osmId === "string" ? data.osmId : null,
    ownerUid: typeof data.ownerUid === "string" ? data.ownerUid : null,
    verified: data.verified === true,
    status: (typeof data.status === "string" ? data.status : "active") as VenueStatus,
    createdAt: toTimestampOrNull(data.createdAt),
    updatedAt: toTimestampOrNull(data.updatedAt),
  };
}

export function parseLogEntry(id: string, data: Record<string, unknown>): LogEntry {
  return {
    id,
    action: (typeof data.action === "string" ? data.action : "kyc.accept") as LogAction,
    actorUid: typeof data.actorUid === "string" ? data.actorUid : "",
    targetType: (typeof data.targetType === "string" ? data.targetType : "user") as LogTargetType,
    targetId: typeof data.targetId === "string" ? data.targetId : "",
    summary: typeof data.summary === "string" ? data.summary : "",
    at: toTimestampOrNull(data.at),
  };
}

// ---------------------------------------------------------------------------
// Reads
// ---------------------------------------------------------------------------

/** Every user who has ever applied — bucket client-side by organizerStatus. */
export async function listApplicantUsers(): Promise<UserRecord[]> {
  const q = query(collection(getDb(), "users"), where("organizerApplication.submitted", "==", true));
  const snap = await getDocs(q);
  return snap.docs.map((d) => parseUserRecord(d.id, d.data()));
}

export async function getUserRecord(uid: string): Promise<UserRecord | null> {
  const snap = await getDoc(userDocRef(uid));
  return snap.exists() ? parseUserRecord(uid, snap.data()) : null;
}

export async function getAdminReviewDoc(uid: string): Promise<AdminReviewDoc | null> {
  const snap = await getDoc(reviewDocRef(uid));
  return parseAdminReviewDoc(snap.data());
}

export async function listVenuesByOwner(uid: string): Promise<Venue[]> {
  const q = query(collection(getDb(), "venues"), where("ownerUid", "==", uid));
  const snap = await getDocs(q);
  return snap.docs.map((d) => parseVenueDoc(d.id, d.data()));
}

export async function getVenueDoc(id: string): Promise<Venue | null> {
  const snap = await getDoc(doc(getDb(), "venues", id));
  return snap.exists() ? parseVenueDoc(snap.id, snap.data()) : null;
}

/** Organizers an admin could transfer a venue to — approved, excluding the current owner. */
export async function listTransferCandidates(excludeUid: string): Promise<UserRecord[]> {
  const q = query(collection(getDb(), "users"), where("organizerStatus", "==", "approved"));
  const snap = await getDocs(q);
  return snap.docs.map((d) => parseUserRecord(d.id, d.data())).filter((u) => u.uid !== excludeUid);
}

export async function listRecentLogs(max = 8): Promise<LogEntry[]> {
  const q = query(collection(getDb(), "logs"), orderBy("at", "desc"), limit(max));
  const snap = await getDocs(q);
  return snap.docs.map((d) => parseLogEntry(d.id, d.data()));
}

export interface OverviewCounts {
  pendingApplications: number;
  eventsInReview: number;
  activeVenues: number;
  activeOrganizers: number;
}

export async function getOverviewCounts(): Promise<OverviewCounts> {
  const db = getDb();
  const [pending, eventsInReview, venues, organizers] = await Promise.all([
    getCountFromServer(query(collection(db, "users"), where("organizerStatus", "==", "none"), where("organizerApplication.submitted", "==", true))),
    getCountFromServer(query(collection(db, "events"), where("moderation.flag", "==", "pending"))),
    getCountFromServer(query(collection(db, "venues"), where("status", "==", "active"))),
    getCountFromServer(query(collection(db, "users"), where("organizerStatus", "==", "approved"))),
  ]);
  return {
    pendingApplications: pending.data().count,
    eventsInReview: eventsInReview.data().count,
    activeVenues: venues.data().count,
    activeOrganizers: organizers.data().count,
  };
}

// ---------------------------------------------------------------------------
// Mutations — every write here is a direct client write an isAdmin() session
// is allowed to make under firestore.rules. See docs/FIRESTORE_SCHEMA.md.
// ---------------------------------------------------------------------------

function currentAdminUid(): string {
  const uid = getFirebaseAuth().currentUser?.uid;
  if (!uid) throw new Error("Not signed in.");
  return uid;
}

/** organizerStatus 'none' -> 'pending' — "a human has it now." Fired once, on first open. */
export async function pickUpApplication(uid: string): Promise<void> {
  await updateDoc(userDocRef(uid), { organizerStatus: "pending", updatedAt: serverTimestamp() });
}

/** Accepts nic/selfie/video/gps — the steps with no side effect beyond the verdict. */
export async function acceptSimpleStep(uid: string, stepId: Exclude<StepId, "venueAddress">): Promise<void> {
  const adminUid = currentAdminUid();
  const now = serverTimestamp();
  const batch = writeBatch(getDb());
  batch.update(reviewDocRef(uid), {
    [`steps.${stepId}.status`]: "accepted",
    [`steps.${stepId}.reviewedAt`]: now,
    [`steps.${stepId}.reviewedBy`]: adminUid,
    updatedAt: now,
  });
  const logRef = doc(collection(getDb(), "logs"));
  batch.set(logRef, {
    action: "kyc.accept",
    actorUid: adminUid,
    targetType: "user",
    targetId: uid,
    summary: `Accepted the ${stepId} step`,
    at: now,
  });
  await batch.commit();
}

/**
 * Accepting venueAddress is what creates venues/{venueId} (idempotent — reuses
 * steps.venueAddress.venueId if already set), and unlocks gps if it was still
 * 'pending'. Returns the venue id.
 */
export async function acceptVenueAddressStep(user: UserRecord, review: AdminReviewDoc): Promise<string> {
  const draft = user.organizerApplication?.steps.venueAddress;
  if (!draft) throw new Error("No venue address submitted yet.");

  const adminUid = currentAdminUid();
  const db = getDb();
  const now = serverTimestamp();
  const batch = writeBatch(db);
  let venueId = review.steps.venueAddress.venueId;

  if (!venueId) {
    const venueRef = doc(collection(db, "venues"));
    venueId = venueRef.id;
    const geo = draft.geo ? new GeoPoint(draft.geo.latitude, draft.geo.longitude) : null;
    batch.set(venueRef, {
      name: user.organizerApplication?.profile.venueName || draft.address || "Untitled venue",
      geo,
      geohash: draft.geo ? encodeGeohash(draft.geo.latitude, draft.geo.longitude) : "",
      type: "",
      typeLabel: "",
      city: draft.city,
      countryCode: draft.countryCode,
      address: draft.address,
      openingHours: "",
      phone: user.phone,
      website: user.organizerApplication?.profile.website || "",
      photos: [],
      source: "admin",
      osmId: null,
      ownerUid: user.uid,
      // firestore.rules' canEditVenue() and storage.rules' isVenueEditor()
      // both key off `editors`, not `ownerUid` — mirrors the webpanel's own
      // createVenue() (useVenues.ts). Omitting these left every admin-approved
      // venue's owner unable to write their own listing or upload photos.
      editorUids: [user.uid],
      editors: { [user.uid]: "owner" },
      verified: true,
      status: "active",
      createdAt: now,
      updatedAt: now,
    });
  }

  batch.update(reviewDocRef(user.uid), {
    "steps.venueAddress.status": "accepted",
    "steps.venueAddress.reviewedAt": now,
    "steps.venueAddress.reviewedBy": adminUid,
    "steps.venueAddress.venueId": venueId,
    ...(review.steps.gps.status === "pending" ? { "steps.gps.status": "active" } : {}),
    updatedAt: now,
  });

  const logRef = doc(collection(db, "logs"));
  batch.set(logRef, {
    action: "venue.create",
    actorUid: adminUid,
    targetType: "venue",
    targetId: venueId,
    summary: `Created venue from ${user.displayName || user.email || user.uid}'s application`,
    at: now,
  });

  await batch.commit();
  return venueId;
}

/**
 * Publishes (or revises) the walkthrough script for one applicant, which is
 * what unlocks their video step — until a script exists there is nothing for
 * them to record against, so `steps.video.status` sits at 'pending'.
 *
 * A revision deliberately leaves `steps.video.attempt` alone: re-scripting is
 * the admin changing their own mind, and it must not spend one of the
 * applicant's three upload attempts. It also leaves a step that is already
 * open, submitted, or accepted exactly where it is — only the initial 'pending'
 * is flipped.
 */
export async function publishVideoScript(
  uid: string,
  review: AdminReviewDoc,
  draft: { format: VideoScript["format"]; lines: string[] },
): Promise<void> {
  const adminUid = currentAdminUid();
  const lines = draft.lines.map((line) => line.trim()).filter(Boolean);
  if (lines.length === 0) throw new Error("A script needs at least one line.");
  if (lines.length > VIDEO_SCRIPT_MAX_LINES) {
    throw new Error(`A script can have at most ${VIDEO_SCRIPT_MAX_LINES} lines.`);
  }
  if (lines.some((line) => line.length > VIDEO_SCRIPT_MAX_LINE_CHARS)) {
    throw new Error(`Each line has to be under ${VIDEO_SCRIPT_MAX_LINE_CHARS} characters.`);
  }

  const existing = review.steps.video.script;
  const revision = existing ? existing.revision + 1 : 0;
  const now = serverTimestamp();
  const batch = writeBatch(getDb());

  batch.update(reviewDocRef(uid), {
    "steps.video.script": {
      format: draft.format,
      lines,
      revision,
      updatedAt: now,
      updatedBy: adminUid,
    },
    ...(review.steps.video.status === "pending" ? { "steps.video.status": "active" } : {}),
    updatedAt: now,
  });

  const logRef = doc(collection(getDb(), "logs"));
  batch.set(logRef, {
    action: "kyc.script",
    actorUid: adminUid,
    targetType: "user",
    targetId: uid,
    summary: revision === 0 ? "Published the walkthrough script" : `Revised the walkthrough script (revision ${revision})`,
    at: now,
  });

  await batch.commit();
}

/**
 * Asks the applicant to redo a step: sets `needs_info` + the admin's note, and
 * (for the Storage-backed steps) advances `attempt` so a fresh upload path
 * opens up — storage.rules ties the writable path to this exact number.
 * venueAddress has no Storage path, so its attempt never moves.
 */
export async function requestStepInfo(uid: string, stepId: StepId, note: string, currentAttempt: number): Promise<void> {
  const adminUid = currentAdminUid();
  const now = serverTimestamp();
  const nextAttempt = stepId === "venueAddress" ? currentAttempt : Math.min(3, currentAttempt + 1);
  const batch = writeBatch(getDb());
  batch.update(reviewDocRef(uid), {
    [`steps.${stepId}.status`]: "needs_info",
    [`steps.${stepId}.note`]: note,
    [`steps.${stepId}.attempt`]: nextAttempt,
    [`steps.${stepId}.reviewedAt`]: now,
    [`steps.${stepId}.reviewedBy`]: adminUid,
    updatedAt: now,
  });
  const logRef = doc(collection(getDb(), "logs"));
  batch.set(logRef, {
    action: "kyc.needsInfo",
    actorUid: adminUid,
    targetType: "user",
    targetId: uid,
    summary: note.slice(0, 500),
    at: now,
  });
  await batch.commit();
}

export async function approveApplication(uid: string): Promise<void> {
  const adminUid = currentAdminUid();
  const now = serverTimestamp();
  const batch = writeBatch(getDb());
  batch.update(reviewDocRef(uid), { status: "approved", decidedAt: now, decidedBy: adminUid, updatedAt: now });
  batch.update(userDocRef(uid), { organizerStatus: "approved", updatedAt: now });
  const logRef = doc(collection(getDb(), "logs"));
  batch.set(logRef, { action: "organizer.approve", actorUid: adminUid, targetType: "user", targetId: uid, summary: "Approved organizer application", at: now });
  await batch.commit();
}

export async function rejectApplication(uid: string, reason: string): Promise<void> {
  const adminUid = currentAdminUid();
  const now = serverTimestamp();
  const batch = writeBatch(getDb());
  batch.update(reviewDocRef(uid), { status: "rejected", decidedAt: now, decidedBy: adminUid, rejectionReason: reason, updatedAt: now });
  batch.update(userDocRef(uid), { organizerStatus: "rejected", updatedAt: now });
  const logRef = doc(collection(getDb(), "logs"));
  batch.set(logRef, { action: "organizer.reject", actorUid: adminUid, targetType: "user", targetId: uid, summary: reason.slice(0, 500), at: now });
  await batch.commit();
}

export async function setVenueStatus(venueId: string, status: VenueStatus): Promise<void> {
  await updateDoc(doc(getDb(), "venues", venueId), { status, updatedAt: serverTimestamp() });
}

export async function transferVenueOwner(venueId: string, newOwnerUid: string): Promise<void> {
  const venueRef = doc(getDb(), "venues", venueId);
  const snap = await getDoc(venueRef);
  const data = snap.data() ?? {};
  const priorOwnerUid = typeof data.ownerUid === "string" ? data.ownerUid : null;
  const editors = { ...(data.editors as Record<string, string> | undefined) };
  // Same rules dependency as the venue-creation site above: `ownerUid` alone
  // doesn't grant `editors`/`storage.rules` access — the new owner needs an
  // `editors` entry, and the outgoing owner's stale "owner" entry would
  // otherwise leave them with unintended edit rights.
  if (priorOwnerUid && priorOwnerUid !== newOwnerUid) editors[priorOwnerUid] = "manager";
  editors[newOwnerUid] = "owner";
  const editorUids = Array.from(new Set([...(Array.isArray(data.editorUids) ? data.editorUids : []), newOwnerUid]));
  await updateDoc(venueRef, { ownerUid: newOwnerUid, editors, editorUids, updatedAt: serverTimestamp() });
}

/**
 * The only real "remove this organizer" mechanism — full account deletion via
 * the Admin SDK (Storage + Firestore + Auth), because there is no partial
 * suspend/ban field anywhere in the schema. Requires the Netlify Functions
 * runtime locally (`netlify dev`), not bare `next dev` — see LOCAL_DEV.md.
 */
export async function banOrganizerAccount(uid: string): Promise<void> {
  const token = await getFirebaseAuth().currentUser?.getIdToken();
  if (!token) throw new Error("Not signed in.");
  const res = await fetch("/api/admin/account", {
    method: "DELETE",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify({ uid }),
  });
  if (!res.ok) {
    const body = (await res.json().catch(() => ({}))) as { error?: string };
    throw new Error(body.error || `Delete failed (${res.status}). Is this running under 'netlify dev'?`);
  }
}
