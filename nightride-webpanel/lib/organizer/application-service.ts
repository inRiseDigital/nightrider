import {
  doc,
  getDoc,
  GeoPoint,
  onSnapshot,
  serverTimestamp,
  setDoc,
  type DocumentReference,
  type Unsubscribe,
} from "firebase/firestore";
import { ref as storageRef, uploadBytesResumable } from "firebase/storage";
import { getBucket, getDb } from "@/lib/firebase";
import { describeUploadError } from "./errors";
import { validateKycVideo } from "./validation";
import type {
  ApplicantApplication,
  ApplicantProfile,
  ApplicantSteps,
  ReviewDoc,
  ReviewStep,
  StepId,
  UploadStepId,
  VenueAddressDraft,
} from "./types";

/**
 * Split-document model (see docs/FIRESTORE_SCHEMA.md "users/{uid}" and
 * "users/{uid}/private/organizerReview"):
 *
 *  - `users/{uid}.organizerApplication` — everything in this file that writes
 *    to it is applicant-authored and advisory. It is never read for access
 *    control anywhere in the product.
 *  - `users/{uid}/private/organizerReview` — the verdict document. This file
 *    creates it exactly once, in the exact pinned initial shape the rules
 *    require, and never writes to it again. Every other field in it
 *    (attempt, status, note, ...) is admin-owned; the applicant only ever
 *    reads it, merged into the view model the UI consumes.
 */

export const DEFAULT_APPLICANT_STEPS: ApplicantSteps = {
  venueAddress: null,
  nic: { uploaded: false },
  selfie: { uploaded: false },
  video: { uploaded: false },
  gps: { attempts: [] },
};

export const EMPTY_PROFILE: ApplicantProfile = {
  orgName: "",
  venueName: "",
  instagram: "",
  website: "",
  bio: "",
  eventTypes: [],
  eventsPerMonth: 0,
};

export const EMPTY_APPLICATION: ApplicantApplication = {
  submitted: false,
  profile: EMPTY_PROFILE,
  steps: DEFAULT_APPLICANT_STEPS,
};

const DEFAULT_REVIEW_STEP: ReviewStep = { status: "pending", attempt: 0, note: "", venueId: null };

/**
 * The exact shape `initialShape()` in firestore.rules pins for a brand-new
 * review document — gps starts 'pending' because it depends on an admin
 * having accepted a venue address to measure against.
 */
export const EMPTY_REVIEW: ReviewDoc = {
  status: "none",
  rejectionReason: "",
  steps: {
    venueAddress: { ...DEFAULT_REVIEW_STEP, status: "active" },
    nic: { ...DEFAULT_REVIEW_STEP, status: "active" },
    selfie: { ...DEFAULT_REVIEW_STEP, status: "active" },
    video: { ...DEFAULT_REVIEW_STEP, status: "active" },
    gps: { ...DEFAULT_REVIEW_STEP, status: "pending" },
  },
};

function userDocRef(uid: string): DocumentReference {
  return doc(getDb(), "users", uid);
}

function reviewDocRef(uid: string): DocumentReference {
  return doc(getDb(), "users", uid, "private", "organizerReview");
}

function deriveUsername(email: string, uid: string) {
  const local = email.split("@")[0]?.replace(/[^a-zA-Z0-9_]/g, "") ?? "";
  return local || `user${uid.slice(0, 6)}`;
}

function isPermissionDenied(error: unknown): boolean {
  return typeof error === "object" && error !== null && "code" in error && (error as { code: unknown }).code === "permission-denied";
}

function parseGeo(raw: unknown): { latitude: number; longitude: number } | null {
  if (raw instanceof GeoPoint) return { latitude: raw.latitude, longitude: raw.longitude };
  return null;
}

function parseVenueAddress(raw: unknown): VenueAddressDraft | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>;
  return {
    address: typeof r.address === "string" ? r.address : "",
    city: typeof r.city === "string" ? r.city : "",
    countryCode: typeof r.countryCode === "string" ? r.countryCode : "",
    geo: parseGeo(r.geo),
    placeId: typeof r.placeId === "string" ? r.placeId : "",
  };
}

/** Tolerates a missing/partial document — a brand-new account or one written before this flow existed. */
export function parseApplication(data: Record<string, unknown> | undefined): ApplicantApplication {
  const raw = (data?.organizerApplication ?? {}) as Record<string, unknown>;
  const rawSteps = (raw.steps ?? {}) as Record<string, unknown>;
  const rawProfile = (raw.profile ?? {}) as Record<string, unknown>;

  return {
    submitted: raw.submitted === true,
    profile: {
      orgName: typeof rawProfile.orgName === "string" ? rawProfile.orgName : "",
      venueName: typeof rawProfile.venueName === "string" ? rawProfile.venueName : "",
      instagram: typeof rawProfile.instagram === "string" ? rawProfile.instagram : "",
      website: typeof rawProfile.website === "string" ? rawProfile.website : "",
      bio: typeof rawProfile.bio === "string" ? rawProfile.bio : "",
      eventTypes: Array.isArray(rawProfile.eventTypes) ? (rawProfile.eventTypes as string[]) : [],
      eventsPerMonth: typeof rawProfile.eventsPerMonth === "number" ? rawProfile.eventsPerMonth : 0,
    },
    steps: {
      venueAddress: parseVenueAddress(rawSteps.venueAddress),
      nic: { uploaded: (rawSteps.nic as { uploaded?: boolean } | undefined)?.uploaded === true },
      selfie: { uploaded: (rawSteps.selfie as { uploaded?: boolean } | undefined)?.uploaded === true },
      video: { uploaded: (rawSteps.video as { uploaded?: boolean } | undefined)?.uploaded === true },
      gps: {
        attempts: Array.isArray((rawSteps.gps as { attempts?: unknown } | undefined)?.attempts)
          ? ((rawSteps.gps as { attempts: unknown[] }).attempts as ApplicantSteps["gps"]["attempts"])
          : [],
      },
    },
  };
}

function parseReviewStep(raw: unknown, fallbackStatus: ReviewStep["status"]): ReviewStep {
  if (!raw || typeof raw !== "object") return { ...DEFAULT_REVIEW_STEP, status: fallbackStatus };
  const r = raw as Record<string, unknown>;
  return {
    status: (typeof r.status === "string" ? r.status : fallbackStatus) as ReviewStep["status"],
    attempt: typeof r.attempt === "number" ? r.attempt : 0,
    note: typeof r.note === "string" ? r.note : "",
    venueId: typeof r.venueId === "string" ? r.venueId : null,
  };
}

/** Tolerates the review doc not existing yet (before `ensureReviewDoc` has run). */
export function parseReview(data: Record<string, unknown> | undefined): ReviewDoc {
  if (!data) return EMPTY_REVIEW;
  const rawSteps = (data.steps ?? {}) as Record<string, unknown>;
  return {
    status: (typeof data.status === "string" ? data.status : "none") as ReviewDoc["status"],
    rejectionReason: typeof data.rejectionReason === "string" ? data.rejectionReason : "",
    steps: {
      venueAddress: parseReviewStep(rawSteps.venueAddress, "active"),
      nic: parseReviewStep(rawSteps.nic, "active"),
      selfie: parseReviewStep(rawSteps.selfie, "active"),
      video: parseReviewStep(rawSteps.video, "active"),
      gps: parseReviewStep(rawSteps.gps, "pending"),
    },
  };
}

export interface ApplicationSnapshot {
  application: ApplicantApplication;
  review: ReviewDoc;
  phone: string;
}

/** One-shot read used at bootstrap to decide which stage to resume at. */
export async function loadApplication(uid: string): Promise<ApplicationSnapshot> {
  const [userSnap, reviewSnap] = await Promise.all([getDoc(userDocRef(uid)), getDoc(reviewDocRef(uid))]);
  const data = userSnap.data();
  return {
    application: parseApplication(data),
    review: parseReview(reviewSnap.data()),
    phone: typeof data?.phone === "string" ? data.phone : "",
  };
}

/**
 * Live subscription to BOTH documents, merged into the snapshot the UI
 * consumes — admin decisions on the review doc reach the applicant without a
 * refresh, same as application-doc changes.
 */
export function subscribeToApplication(
  uid: string,
  onData: (snapshot: ApplicationSnapshot) => void,
  onError: (error: Error) => void
): Unsubscribe {
  let latestApplication = EMPTY_APPLICATION;
  let latestReview = EMPTY_REVIEW;
  let latestPhone = "";
  let userLoaded = false;
  let reviewLoaded = false;

  const emit = () => {
    if (!userLoaded || !reviewLoaded) return;
    onData({ application: latestApplication, review: latestReview, phone: latestPhone });
  };

  const unsubUser = onSnapshot(
    userDocRef(uid),
    (snapshot) => {
      const data = snapshot.data();
      latestApplication = parseApplication(data);
      latestPhone = typeof data?.phone === "string" ? data.phone : "";
      userLoaded = true;
      emit();
    },
    onError
  );

  const unsubReview = onSnapshot(
    reviewDocRef(uid),
    (snapshot) => {
      latestReview = parseReview(snapshot.data());
      reviewLoaded = true;
      emit();
    },
    onError
  );

  return () => {
    unsubUser();
    unsubReview();
  };
}

/**
 * Creates the profile document for a brand-new account. Never writes
 * `isAdmin` or a non-'none' `organizerStatus` — approval is an admin decision,
 * not something the applicant can grant themselves.
 */
export async function ensureApplicationDoc(uid: string, email: string): Promise<void> {
  const ref = userDocRef(uid);
  const snapshot = await getDoc(ref);
  if (snapshot.exists()) return;

  await setDoc(ref, {
    email,
    displayName: "",
    username: deriveUsername(email, uid),
    pronouns: "",
    bio: "",
    city: "",
    countryCode: "",
    ageRange: "",
    avatarUrl: "",
    instagram: "",
    facebook: "",
    phone: "",
    interests: [],
    genres: [],
    vibes: [],
    features: [],
    rank: 0,
    streakDays: 0,
    partiesAttended: 0,
    friendsCount: 0,
    lastActiveDate: "",
    isAdmin: false,
    organizerStatus: "none",
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
}

export async function savePhone(uid: string, phone: string): Promise<void> {
  await setDoc(userDocRef(uid), { phone, updatedAt: serverTimestamp() }, { merge: true });
}

/**
 * Every write that touches `organizerApplication` must resend `submitted`
 * (bool) and a fresh `submittedAt` in the SAME request — the rule
 * (`applicationOk()` in firestore.rules) checks the resulting document, not
 * the diff, so `submittedAt` has to equal `request.time` on every single
 * touch, not just the first one. That makes it a "last touched" timestamp in
 * practice, which is exactly what the schema doc's clock-skew comparison
 * against a gps observation's `capturedAt` wants.
 */
async function patchApplication(uid: string, patch: Record<string, unknown>): Promise<void> {
  await setDoc(
    userDocRef(uid),
    { organizerApplication: { ...patch, submitted: true, submittedAt: serverTimestamp() } },
    { merge: true }
  );
}

/**
 * Creates `users/{uid}/private/organizerReview` in the exact pinned initial
 * shape, tolerating the document already existing: a second `create` targets
 * an existing doc, so the rules evaluate it as an `update`, which the
 * applicant is never allowed to do — that denial is expected here, not a bug,
 * so it is swallowed rather than surfaced as an error.
 */
export async function ensureReviewDoc(uid: string): Promise<void> {
  const ref = reviewDocRef(uid);
  const snapshot = await getDoc(ref);
  if (snapshot.exists()) return;

  try {
    await setDoc(ref, {
      status: "none",
      appliedAt: serverTimestamp(),
      decidedAt: null,
      decidedBy: "",
      rejectionReason: "",
      phoneVerified: false,
      steps: {
        venueAddress: { status: "active", attempt: 0, note: "", reviewedAt: null, reviewedBy: null, venueId: null, mediaDeletedAt: null },
        nic: { status: "active", attempt: 0, note: "", reviewedAt: null, reviewedBy: null, venueId: null, mediaDeletedAt: null },
        selfie: { status: "active", attempt: 0, note: "", reviewedAt: null, reviewedBy: null, venueId: null, mediaDeletedAt: null },
        video: { status: "active", attempt: 0, note: "", reviewedAt: null, reviewedBy: null, venueId: null, mediaDeletedAt: null },
        gps: { status: "pending", attempt: 0, note: "", reviewedAt: null, reviewedBy: null, venueId: null, mediaDeletedAt: null },
      },
      updatedAt: serverTimestamp(),
    });
  } catch (error) {
    if (isPermissionDenied(error)) return;
    throw error;
  }
}

/**
 * Called once, when the applicant reaches the review stage: creates the
 * review doc (idempotent) and marks the application submitted. Idempotent on
 * the application side too — a second call must not wipe `steps` back to
 * defaults and lose an already-uploaded step's `uploaded: true` claim.
 */
export async function beginReview(uid: string): Promise<void> {
  await ensureReviewDoc(uid);
  const snapshot = await getDoc(userDocRef(uid));
  const alreadyInitialized = Boolean(snapshot.data()?.organizerApplication);
  await patchApplication(uid, alreadyInitialized ? {} : { profile: EMPTY_PROFILE, steps: DEFAULT_APPLICANT_STEPS });
}

/** Applicant's typed venue address — advisory; the admin's own read of it creates `venues/{venueId}`. */
export async function saveVenueAddress(uid: string, draft: VenueAddressDraft): Promise<void> {
  await patchApplication(uid, {
    steps: {
      venueAddress: {
        address: draft.address,
        city: draft.city,
        countryCode: draft.countryCode,
        geo: draft.geo ? new GeoPoint(draft.geo.latitude, draft.geo.longitude) : null,
        placeId: draft.placeId,
      },
    },
  });
}

/**
 * The applicant's own claim that they uploaded something — advisory, never
 * gates access. Only the video step calls this from the browser; the mobile
 * app writes the same flag for nic and selfie.
 */
async function markStepUploaded(uid: string, stepId: UploadStepId): Promise<void> {
  await patchApplication(uid, { steps: { [stepId]: { uploaded: true } } });
}

function kycPath(uid: string, stepId: StepId, attempt: number, file: string): string {
  return `kyc/${uid}/${stepId}/${attempt}/${file}`;
}

export type UploadProgressHandler = (fraction: number) => void;

async function uploadResumable(
  path: string,
  file: Blob,
  contentType: string,
  onProgress?: UploadProgressHandler
): Promise<void> {
  const objectRef = storageRef(getBucket(), path);
  const task = uploadBytesResumable(objectRef, file, { contentType });
  await new Promise<void>((resolve, reject) => {
    task.on(
      "state_changed",
      (snapshot) => onProgress?.(snapshot.totalBytes ? snapshot.bytesTransferred / snapshot.totalBytes : 0),
      reject,
      resolve
    );
  });
}

/**
 * Extracts a poster frame from the video in-browser using a hidden <video> +
 * <canvas> — no server function, no dependency. There is no thumbnail Cloud
 * Function and there will not be one (see docs/FIRESTORE_SCHEMA.md "Cloud
 * Storage"); this is the client doing the whole job with a standard browser
 * API, which is well within reach here.
 */
export function extractPosterFrame(videoFile: File): Promise<Blob> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(videoFile);
    const videoEl = document.createElement("video");
    videoEl.muted = true;
    videoEl.playsInline = true;
    videoEl.preload = "metadata";
    videoEl.src = url;

    const cleanup = () => URL.revokeObjectURL(url);

    videoEl.onloadedmetadata = () => {
      // A hair past t=0 avoids the all-black first frame some encoders emit.
      videoEl.currentTime = Math.min(0.1, (videoEl.duration || 0) / 2);
    };
    videoEl.onseeked = () => {
      const canvas = document.createElement("canvas");
      canvas.width = videoEl.videoWidth;
      canvas.height = videoEl.videoHeight;
      const ctx = canvas.getContext("2d");
      if (!ctx) {
        cleanup();
        reject(new Error("Canvas is not supported in this browser."));
        return;
      }
      ctx.drawImage(videoEl, 0, 0, canvas.width, canvas.height);
      canvas.toBlob(
        (blob) => {
          cleanup();
          if (blob) resolve(blob);
          else reject(new Error("Could not extract a poster frame from that video."));
        },
        "image/jpeg",
        0.85
      );
    };
    videoEl.onerror = () => {
      cleanup();
      reject(new Error("Could not read that video file to extract a poster frame."));
    };
  });
}

/**
 * Uploads the poster before the (much larger) walkthrough: if the connection
 * drops partway through, the small file is the one most likely to have
 * already landed, which biases a retry toward "only the video needs to go
 * again" rather than the reverse. There is no atomicity across the two
 * objects — the rules give each object its own independent create-once check
 * — so a retry after a genuine partial failure can still land on the
 * "already submitted" message for the file that did make it through; an
 * admin bumping the attempt is the recovery path for that edge case.
 */
/**
 * `{attempt}` always comes from the review doc, read live — never invented or
 * incremented here. Only an admin advances it, and the Storage rule compares
 * the path segment against it, so writing to the wrong attempt is a
 * structural denial, not just bad UX.
 */
export async function uploadVideoFile(
  uid: string,
  attempt: number,
  video: File,
  onProgress?: UploadProgressHandler
): Promise<void> {
  const videoError = validateKycVideo(video);
  if (videoError) throw new Error(videoError);

  const poster = await extractPosterFrame(video);

  try {
    await uploadResumable(kycPath(uid, "video", attempt, "poster.jpg"), poster, "image/jpeg", (f) => onProgress?.(f * 0.15));
    await uploadResumable(kycPath(uid, "video", attempt, "walkthrough.mp4"), video, "video/mp4", (f) => onProgress?.(0.15 + f * 0.85));
  } catch (error) {
    throw new Error(describeUploadError(error));
  }
  await markStepUploaded(uid, "video");
}
