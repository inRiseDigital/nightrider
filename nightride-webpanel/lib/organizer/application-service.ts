import {
  doc,
  getDoc,
  onSnapshot,
  serverTimestamp,
  setDoc,
  type DocumentReference,
  type Unsubscribe,
} from "firebase/firestore";
import { getDb } from "@/lib/firebase";
import type { BaseStepId, ExtraStep, StepStatus } from "./types";

/**
 * The organizer application lives on the shared `users/{uid}` document — the
 * same one the Flutter app creates (Nightride/lib/services/user_profile_service.dart)
 * and that firestore.rules `isOrganizer()` reads. It is nested under a single
 * `organizerApplication` key so nothing here collides with the profile fields
 * the mobile app owns.
 */
export interface StoredApplication {
  steps: Record<BaseStepId, StepStatus>;
  extraSteps: ExtraStep[];
  rejected: boolean;
  rejectionReason: string;
  /**
   * Whether the applicant has cleared the phone step. Firebase phone auth is
   * currently stubbed out (see submitOtp in store.tsx), so this is set by the
   * flow itself rather than by a linked phone credential — which is also why
   * resuming on reload reads this instead of `user.phoneNumber`.
   */
  phoneVerified: boolean;
}

const DEFAULT_STEPS: Record<BaseStepId, StepStatus> = {
  nic: "active",
  selfie: "active",
  gps: "active",
  video_request: "active",
};

export const EMPTY_APPLICATION: StoredApplication = {
  steps: DEFAULT_STEPS,
  extraSteps: [],
  rejected: false,
  rejectionReason: "",
  phoneVerified: false,
};

function userDocRef(uid: string): DocumentReference {
  return doc(getDb(), "users", uid);
}

function deriveUsername(email: string, uid: string) {
  const local = email.split("@")[0]?.replace(/[^a-zA-Z0-9_]/g, "") ?? "";
  return local || `user${uid.slice(0, 6)}`;
}

/** Tolerates documents written before this flow existed, or by the mobile app. */
export function parseApplication(data: Record<string, unknown> | undefined): StoredApplication {
  const raw = (data?.organizerApplication ?? {}) as Record<string, unknown>;
  return {
    steps: { ...DEFAULT_STEPS, ...((raw.steps as Record<BaseStepId, StepStatus>) ?? {}) },
    extraSteps: Array.isArray(raw.extraSteps) ? (raw.extraSteps as ExtraStep[]) : [],
    rejected: raw.rejected === true,
    rejectionReason: typeof raw.rejectionReason === "string" ? raw.rejectionReason : "",
    phoneVerified: raw.phoneVerified === true,
  };
}

/** One-shot read used at bootstrap to decide which stage to resume at. */
export async function loadApplication(
  uid: string
): Promise<{ application: StoredApplication; phone: string }> {
  const snapshot = await getDoc(userDocRef(uid));
  const data = snapshot.data();
  return {
    application: parseApplication(data),
    phone: typeof data?.phone === "string" ? data.phone : "",
  };
}

/**
 * Creates the profile document for a brand-new account, or attaches an
 * application to an existing one. Never overwrites profile fields the mobile
 * app owns, and never writes `isOrganizer` / `role: organizer` — approval is
 * an admin decision, not something the applicant can grant themselves.
 */
export async function ensureApplication(uid: string, email: string): Promise<void> {
  const ref = userDocRef(uid);
  const snapshot = await getDoc(ref);

  const application = {
    steps: DEFAULT_STEPS,
    extraSteps: [],
    rejected: false,
    rejectionReason: "",
    phoneVerified: false,
    startedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };

  if (!snapshot.exists()) {
    await setDoc(ref, {
      uid,
      email,
      displayName: "",
      username: deriveUsername(email, uid),
      phone: "",
      role: "user",
      isOrganizer: false,
      rank: 0,
      createdAt: serverTimestamp(),
      organizerApplication: application,
    });
    return;
  }

  if (!snapshot.data()?.organizerApplication) {
    await setDoc(ref, { organizerApplication: application }, { merge: true });
  }
}

/** Live subscription — admin-side changes reach the applicant without a refresh. */
export function subscribeToApplication(
  uid: string,
  onData: (application: StoredApplication) => void,
  onError: (error: Error) => void
): Unsubscribe {
  return onSnapshot(
    userDocRef(uid),
    (snapshot) => onData(parseApplication(snapshot.data())),
    onError
  );
}

export async function savePhone(uid: string, phone: string): Promise<void> {
  await setDoc(
    userDocRef(uid),
    { phone, organizerApplication: { phoneVerified: true, updatedAt: serverTimestamp() } },
    { merge: true }
  );
}

async function patchApplication(uid: string, patch: Record<string, unknown>): Promise<void> {
  await setDoc(
    userDocRef(uid),
    { organizerApplication: { ...patch, updatedAt: serverTimestamp() } },
    { merge: true }
  );
}

/** Applicant-driven: the whole array is rewritten because Firestore can't patch by index. */
export async function saveExtraSteps(uid: string, extraSteps: ExtraStep[]): Promise<void> {
  await patchApplication(uid, { extraSteps });
}

/**
 * Dev-only writers standing in for the admin panel and the mobile app, which
 * are the real authors of these fields. Guarded so they cannot ship: in
 * production these transitions must come from an admin action or a Cloud
 * Function, never from the applicant's own browser.
 */
export const devSimulate = {
  enabled: process.env.NODE_ENV !== "production",

  async completeBaseSteps(uid: string) {
    await patchApplication(uid, {
      steps: { nic: "done", selfie: "done", gps: "done", video_request: "done" },
    });
  },

  async reject(uid: string, reason: string) {
    await patchApplication(uid, { rejected: true, rejectionReason: reason });
  },

  async clearRejection(uid: string) {
    await patchApplication(uid, { rejected: false, rejectionReason: "" });
  },
};
