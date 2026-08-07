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
  devSimulate,
  EMPTY_APPLICATION,
  ensureApplication,
  loadApplication,
  saveExtraSteps,
  savePhone,
  subscribeToApplication,
  type StoredApplication,
} from "./application-service";
import { OTP_MIN_LENGTH, REJECTION_REASON } from "./constants";
import { describeAuthError } from "./errors";
import { validateEmail, validatePassword } from "./validation";
import type { ApplicationStage, ExtraStep, ExtraStepType } from "./types";

/**
 * Firebase phone auth is deliberately NOT wired up.
 *
 * The phone and OTP screens are part of the designed flow, so they stay — but
 * no SMS is sent and any code of OTP_MIN_LENGTH digits is accepted. The number
 * the applicant types is still saved to their user document. To restore real
 * verification, reinstate `RecaptchaVerifier` + `linkWithPhoneNumber` in
 * submitPhone/submitOtp and drop `phoneVerified` in favour of the linked
 * phone credential on the Firebase user.
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
  captcha: boolean;
  phone: string;
  otp: string;
  error: string;
  openStepId: string | null;
  application: StoredApplication;
  /** Postcard codes being typed, keyed by step id — not persisted until submitted. */
  codeDrafts: Record<string, string>;
}

const INITIAL_STATE: ApplicationState = {
  ready: false,
  uid: null,
  busy: false,
  stage: "signup",
  email: "",
  password: "",
  captcha: false,
  phone: "",
  otp: "",
  error: "",
  openStepId: "nic",
  application: EMPTY_APPLICATION,
  codeDrafts: {},
};

type Action =
  | { type: "setCredential"; field: "email" | "password" | "phone" | "otp"; value: string }
  | { type: "toggleCaptcha" }
  | { type: "setBusy"; busy: boolean }
  | { type: "setError"; error: string }
  | { type: "setStage"; stage: ApplicationStage }
  | { type: "signedIn"; uid: string; stage: ApplicationStage; phone: string; email: string }
  | { type: "signedOut" }
  | { type: "applicationChanged"; application: StoredApplication }
  | { type: "toggleStep"; id: string }
  | { type: "setCodeDraft"; id: string; value: string };

function reducer(state: ApplicationState, action: Action): ApplicationState {
  switch (action.type) {
    case "setCredential":
      return { ...state, [action.field]: action.value, error: "" };
    case "toggleCaptcha":
      return { ...state, captcha: !state.captcha, error: "" };
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
    case "applicationChanged":
      return { ...state, application: action.application };
    case "toggleStep":
      return { ...state, openStepId: state.openStepId === action.id ? null : action.id };
    case "setCodeDraft":
      return { ...state, codeDrafts: { ...state.codeDrafts, [action.id]: action.value } };
    default:
      return state;
  }
}

export interface ApplicationActions {
  setCredential: (field: "email" | "password" | "phone" | "otp", value: string) => void;
  toggleCaptcha: () => void;
  submitSignup: () => Promise<void>;
  submitPhone: () => Promise<void>;
  submitOtp: () => Promise<void>;
  toggleStep: (id: string) => void;
  setExtraCode: (id: string, value: string) => void;
  submitExtraCode: (id: string) => Promise<void>;
  pickSlot: (id: string, slot: string) => Promise<void>;
  addExtraStep: (extraType: ExtraStepType) => Promise<void>;
  completeBaseSteps: () => Promise<void>;
  reject: () => Promise<void>;
  resubmit: () => Promise<void>;
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
      // Read the document once so a reload resumes at the right stage instead
      // of sending a half-finished applicant back to the phone screen.
      void loadApplication(user.uid)
        .then(({ application, phone }) => {
          dispatch({ type: "applicationChanged", application });
          dispatch({
            type: "signedIn",
            uid: user.uid,
            stage: application.phoneVerified ? "review" : "phone",
            phone,
            email: user.email ?? "",
          });
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

  // Live application document — admin decisions land here without a refresh.
  useEffect(() => {
    if (!state.uid) return;
    return subscribeToApplication(
      state.uid,
      (application) => dispatch({ type: "applicationChanged", application }),
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

    /**
     * Safe to read the array straight off state: Firestore applies writes to
     * the local cache and fires onSnapshot before the server acknowledges, so
     * `state.application.extraSteps` is current by the time a second action can
     * run — and every trigger is disabled while `busy` anyway.
     */
    const currentExtraSteps: ExtraStep[] = state.application.extraSteps;

    return {
      setCredential: (field, value) => dispatch({ type: "setCredential", field, value }),
      toggleCaptcha: () => dispatch({ type: "toggleCaptcha" }),
      toggleStep: (id) => dispatch({ type: "toggleStep", id }),
      setExtraCode: (id, value) => dispatch({ type: "setCodeDraft", id, value }),

      submitSignup: () =>
        run(async () => {
          const emailError = validateEmail(state.email);
          if (emailError) throw new Error(emailError);

          const passwordError = validatePassword(state.password);
          if (passwordError) throw new Error(passwordError);

          if (!state.captcha) throw new Error("Please confirm the captcha.");

          const email = state.email.trim();
          const credential = await createUserWithEmailAndPassword(
            getFirebaseAuth(),
            email,
            state.password
          );
          await ensureApplication(credential.user.uid, email);
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
          // code of the right length passes. The number is still recorded, and
          // `phoneVerified` is what lets a reload resume at the review stage.
          await savePhone(uid, state.phone.trim());
          dispatch({ type: "setStage", stage: "review" });
        }),

      submitExtraCode: (id) =>
        run(async () => {
          const uid = requireUid();
          if (!state.codeDrafts[id]?.trim()) throw new Error("Enter the code from your postcard.");
          await saveExtraSteps(
            uid,
            currentExtraSteps.map((step) => (step.id === id ? { ...step, status: "done" } : step))
          );
          dispatch({ type: "setBusy", busy: false });
        }),

      pickSlot: (id, slot) =>
        run(async () => {
          const uid = requireUid();
          await saveExtraSteps(
            uid,
            currentExtraSteps.map((step) =>
              step.id === id ? { ...step, status: "scheduled", scheduledSlot: slot } : step
            )
          );
          dispatch({ type: "setBusy", busy: false });
        }),

      addExtraStep: (extraType) =>
        run(async () => {
          const uid = requireUid();
          if (currentExtraSteps.some((step) => step.type === extraType)) {
            dispatch({ type: "toggleStep", id: extraType });
            dispatch({ type: "setBusy", busy: false });
            return;
          }
          await saveExtraSteps(uid, [
            ...currentExtraSteps,
            { id: extraType, type: extraType, status: "needs_info", scheduledSlot: null },
          ]);
          dispatch({ type: "setBusy", busy: false });
        }),

      completeBaseSteps: () =>
        run(async () => {
          await devSimulate.completeBaseSteps(requireUid());
          dispatch({ type: "setBusy", busy: false });
        }),

      reject: () =>
        run(async () => {
          await devSimulate.reject(requireUid(), REJECTION_REASON);
          dispatch({ type: "setBusy", busy: false });
        }),

      resubmit: () =>
        run(async () => {
          await devSimulate.clearRejection(requireUid());
          dispatch({ type: "setBusy", busy: false });
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
