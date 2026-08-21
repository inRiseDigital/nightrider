"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useReducer,
  type ReactNode,
} from "react";
import { createUserWithEmailAndPassword, onAuthStateChanged, signOut } from "firebase/auth";
import { getFirebaseAuth, isFirebaseConfigured } from "@/lib/firebase";
import {
  beginReview,
  EMPTY_APPLICATION,
  EMPTY_REVIEW,
  ensureApplicationDoc,
  ensureReviewDoc,
  loadApplication,
  saveVenueAddress,
  savePhone,
  subscribeToApplication,
  uploadVideoFile,
} from "./application-service";
import { OTP_MIN_LENGTH } from "./constants";
import { describeAuthError } from "./errors";
import { validateEmail, validatePassword, validateVenueAddress } from "./validation";
import type { ApplicantApplication, ApplicationStage, ReviewDoc, VenueAddressDraft } from "./types";

/**
 * Firebase phone auth is deliberately NOT wired up.
 *
 * The phone and OTP screens are part of the designed flow, so they stay — but
 * no SMS is sent and any code of OTP_MIN_LENGTH digits is accepted. The
 * number the applicant types is still saved to their user document. To
 * restore real verification, reinstate `RecaptchaVerifier` +
 * `linkWithPhoneNumber` in submitPhone/submitOtp.
 *
 * Call sites are marked with a PHONE_AUTH_STUBBED comment.
 */

export interface ApplicationState {
  /** False until the Firebase auth listener has reported in. */
  ready: boolean;
  uid: string | null;
  busy: boolean;
  stage: ApplicationStage;
  email: string;
  password: string;
  phone: string;
  otp: string;
  error: string;
  openStepId: string | null;
  application: ApplicantApplication;
  review: ReviewDoc;
  /** Transient upload progress (0..1), keyed by step id — never persisted. */
  uploadProgress: Record<string, number>;
}

const INITIAL_STATE: ApplicationState = {
  ready: false,
  uid: null,
  busy: false,
  stage: "signup",
  email: "",
  password: "",
  phone: "",
  otp: "",
  error: "",
  openStepId: "venueAddress",
  application: EMPTY_APPLICATION,
  review: EMPTY_REVIEW,
  uploadProgress: {},
};

type Action =
  | { type: "setCredential"; field: "email" | "password" | "phone" | "otp"; value: string }
  | { type: "setBusy"; busy: boolean }
  | { type: "setError"; error: string }
  | { type: "setStage"; stage: ApplicationStage }
  | { type: "signedIn"; uid: string; stage: ApplicationStage; phone: string; email: string }
  | { type: "signedOut" }
  | { type: "snapshotChanged"; application: ApplicantApplication; review: ReviewDoc; phone?: string }
  | { type: "toggleStep"; id: string }
  | { type: "setUploadProgress"; id: string; progress: number }
  | { type: "clearUploadProgress"; id: string };

function reducer(state: ApplicationState, action: Action): ApplicationState {
  switch (action.type) {
    case "setCredential":
      return { ...state, [action.field]: action.value, error: "" };
    case "setBusy":
      return { ...state, busy: action.busy };
    case "setError":
      return { ...state, busy: false, error: action.error };
    case "setStage":
      return { ...state, stage: action.stage, busy: false, error: "" };
    case "signedIn":
      return {
        ...state,
        ready: true,
        uid: action.uid,
        stage: action.stage,
        phone: action.phone || state.phone,
        email: action.email || state.email,
        busy: false,
      };
    case "signedOut":
      return { ...INITIAL_STATE, ready: true };
    case "snapshotChanged":
      return {
        ...state,
        application: action.application,
        review: action.review,
        phone: action.phone ?? state.phone,
      };
    case "toggleStep":
      return { ...state, openStepId: state.openStepId === action.id ? null : action.id };
    case "setUploadProgress":
      return { ...state, uploadProgress: { ...state.uploadProgress, [action.id]: action.progress } };
    case "clearUploadProgress": {
      const next = { ...state.uploadProgress };
      delete next[action.id];
      return { ...state, uploadProgress: next };
    }
    default:
      return state;
  }
}

export interface ApplicationActions {
  setCredential: (field: "email" | "password" | "phone" | "otp", value: string) => void;
  submitSignup: () => Promise<void>;
  submitPhone: () => Promise<void>;
  submitOtp: () => Promise<void>;
  toggleStep: (id: string) => void;
  submitVenueAddress: (draft: VenueAddressDraft) => Promise<void>;
  /** The walkthrough is the only step still uploaded here — nic and selfie are captured in the app. */
  uploadVideo: (file: File) => Promise<void>;
  signOutApplicant: () => Promise<void>;
}

const StateContext = createContext<ApplicationState | null>(null);
const ActionsContext = createContext<ApplicationActions | null>(null);

export function OrganizerApplicationProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(reducer, INITIAL_STATE);

  // Resume an in-flight application on reload instead of restarting at signup.
  useEffect(() => {
    if (!isFirebaseConfigured()) {
      dispatch({
        type: "setError",
        error: "Firebase is not configured. Copy .env.example to .env.local and restart the dev server.",
      });
      return;
    }

    return onAuthStateChanged(getFirebaseAuth(), (user) => {
      if (!user) {
        dispatch({ type: "signedOut" });
        return;
      }
      // Read both documents once so a reload resumes at the right stage
      // instead of sending a half-finished applicant back to the phone
      // screen. `submitted` (not the old client-set `phoneVerified`, which no
      // longer exists — phoneVerified moved to the admin-owned review doc)
      // is the resume signal: it is only ever set once, in beginReview.
      void loadApplication(user.uid)
        .then(({ application, review, phone }) => {
          dispatch({ type: "snapshotChanged", application, review, phone });
          dispatch({
            type: "signedIn",
            uid: user.uid,
            stage: application.submitted ? "review" : "phone",
            phone,
            email: user.email ?? "",
          });
          // Defensive: guarantees the review doc exists even if a prior
          // beginReview call was interrupted before it completed. Idempotent.
          if (application.submitted) void ensureReviewDoc(user.uid);
        })
        .catch((error) => {
          dispatch({
            type: "signedIn",
            uid: user.uid,
            stage: "phone",
            phone: "",
            email: user.email ?? "",
          });
          dispatch({ type: "setError", error: describeAuthError(error) });
        });
    });
  }, []);

  // Live documents — admin decisions land here without a refresh.
  useEffect(() => {
    if (!state.uid) return;
    return subscribeToApplication(
      state.uid,
      ({ application, review, phone }) => dispatch({ type: "snapshotChanged", application, review, phone }),
      (error) => dispatch({ type: "setError", error: describeAuthError(error) })
    );
  }, [state.uid]);

  const run = useCallback(async (work: () => Promise<void>) => {
    dispatch({ type: "setBusy", busy: true });
    try {
      await work();
    } catch (error) {
      dispatch({ type: "setError", error: describeAuthError(error) });
    }
  }, []);

  const actions = useMemo<ApplicationActions>(() => {
    const requireUid = () => {
      const uid = state.uid;
      if (!uid) throw new Error("You are not signed in. Restart the application.");
      return uid;
    };

    return {
      setCredential: (field, value) => dispatch({ type: "setCredential", field, value }),
      toggleStep: (id) => dispatch({ type: "toggleStep", id }),

      submitSignup: () =>
        run(async () => {
          const emailError = validateEmail(state.email);
          if (emailError) throw new Error(emailError);

          const passwordError = validatePassword(state.password);
          if (passwordError) throw new Error(passwordError);

          const email = state.email.trim();
          const credential = await createUserWithEmailAndPassword(
            getFirebaseAuth(),
            email,
            state.password
          );
          await ensureApplicationDoc(credential.user.uid, email);
          dispatch({ type: "setStage", stage: "phone" });
        }),

      submitPhone: () =>
        run(async () => {
          requireUid();
          const phone = state.phone.trim();
          if (!phone) throw new Error("Enter a phone number.");
          if (!/^\+[1-9]\d{6,15}$/.test(phone.replace(/[\s()-]/g, ""))) {
            throw new Error("Enter the number in international format, for example +971 50 123 4567.");
          }

          // PHONE_AUTH_STUBBED: no SMS is sent. Format is still validated so the
          // number stored on the profile stays dialable.
          dispatch({ type: "setStage", stage: "otp" });
        }),

      submitOtp: () =>
        run(async () => {
          const uid = requireUid();
          if (state.otp.length < OTP_MIN_LENGTH) {
            throw new Error("Enter the code sent to your phone.");
          }
          // PHONE_AUTH_STUBBED: no confirmation result to check against, so any
          // code of the right length passes. The number is still recorded.
          await savePhone(uid, state.phone.trim());
          // First entry into the flow: creates the review doc (once) and
          // marks the application submitted.
          await beginReview(uid);
          dispatch({ type: "setStage", stage: "review" });
        }),

      submitVenueAddress: (draft) =>
        run(async () => {
          const uid = requireUid();
          const validationError = validateVenueAddress(draft);
          if (validationError) throw new Error(validationError);
          await saveVenueAddress(uid, draft);
        }),

      uploadVideo: (file) =>
        run(async () => {
          const uid = requireUid();
          const attempt = state.review.steps.video.attempt;
          try {
            await uploadVideoFile(uid, attempt, file, (progress) =>
              dispatch({ type: "setUploadProgress", id: "video", progress })
            );
          } finally {
            dispatch({ type: "clearUploadProgress", id: "video" });
          }
        }),

      signOutApplicant: () =>
        run(async () => {
          await signOut(getFirebaseAuth());
        }),
    };
  }, [state, run]);

  return (
    <StateContext.Provider value={state}>
      <ActionsContext.Provider value={actions}>{children}</ActionsContext.Provider>
    </StateContext.Provider>
  );
}

export function useApplicationState() {
  const state = useContext(StateContext);
  if (!state) throw new Error("useApplicationState must be used inside OrganizerApplicationProvider");
  return state;
}

export function useApplicationActions() {
  const actions = useContext(ActionsContext);
  if (!actions) throw new Error("useApplicationActions must be used inside OrganizerApplicationProvider");
  return actions;
}
