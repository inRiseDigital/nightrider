"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useReducer,
  useRef,
  type ReactNode,
} from "react";
import {
  createUserWithEmailAndPassword,
  linkWithPhoneNumber,
  onAuthStateChanged,
  RecaptchaVerifier,
  signOut,
  type ConfirmationResult,
} from "firebase/auth";
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
  uploadNicFiles,
  uploadSelfieFile,
  uploadVideoFile,
} from "./application-service";
import {
  OTP_LENGTH,
  OTP_MAX_SENDS,
  OTP_RESEND_COOLDOWN_SECONDS,
  RECAPTCHA_CONTAINER_ID,
} from "./constants";
import { describeAuthError } from "./errors";
import { validateEmail, validatePassword, validateVenueAddress } from "./validation";
import type { ApplicantApplication, ApplicationStage, ReviewDoc, VenueAddressDraft } from "./types";

/**
 * Phone verification is real Firebase phone auth. It uses
 * `linkWithPhoneNumber`, not `signInWithPhoneNumber`: by the time this stage
 * runs the applicant is already signed in with the email/password from the
 * signup stage, so the phone is a second credential linked onto that account
 * rather than a way of signing in.
 *
 * Two objects live in refs rather than reducer state — neither is
 * serialisable and neither should ever cause a render:
 *
 *  - `verifierRef` — the invisible `RecaptchaVerifier`. It is single-use:
 *    `verify()` re-returns its already-spent token, so a second send with the
 *    same object fails `auth/captcha-check-failed`, and `clear()` destroys it
 *    permanently (a later `verify()` throws `auth/internal-error`). Every
 *    send therefore discards the old object and builds a fresh one against
 *    the container div the current stage renders — including on resend.
 *  - `confirmationRef` — the `ConfirmationResult` for the code in flight. A
 *    wrong-code retry reuses it, so a typo costs no second SMS.
 *
 * Verification state is never written from here.
 * `users/{uid}/private/organizerReview.phoneVerified` is create-once for the
 * applicant and admin-only on update — firestore.rules pins it to `false` at
 * create — so the source of truth this flow reads is
 * `auth.currentUser.phoneNumber`, i.e. whether a phone credential is linked.
 */

/** E.164, which is the only shape Firebase phone auth accepts. */
const E164_PATTERN = /^\+[1-9]\d{6,15}$/;

/** Strips the separators people type out of a number they read off a card. */
function normalizePhone(input: string): string {
  return input.replace(/[\s()\-.]/g, "");
}

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
  /** SMS sends spent since this page loaded, capped at OTP_MAX_SENDS. */
  otpSendCount: number;
  /**
   * Epoch ms the resend control unlocks at, 0 when nothing is pending. Stored
   * as a deadline rather than a ticking counter so a throttled or backgrounded
   * tab can't leave the cooldown stuck open.
   */
  otpCooldownUntil: number;
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
  otpSendCount: 0,
  otpCooldownUntil: 0,
};

type Action =
  | { type: "setCredential"; field: "email" | "password" | "phone" | "otp"; value: string }
  | { type: "setBusy"; busy: boolean }
  | { type: "setError"; error: string }
  | { type: "setStage"; stage: ApplicationStage }
  | { type: "otpSent"; cooldownUntil: number }
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
    case "otpSent":
      // Clears any code already typed: after a resend the earlier SMS is dead,
      // and confirming with it would only produce a confusing wrong-code error.
      return {
        ...state,
        stage: "otp",
        otp: "",
        otpSendCount: state.otpSendCount + 1,
        otpCooldownUntil: action.cooldownUntil,
        busy: false,
        error: "",
      };
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
  uploadNic: (front: File, back: File) => Promise<void>;
  uploadSelfie: (file: File) => Promise<void>;
  uploadVideo: (file: File) => Promise<void>;
  signOutApplicant: () => Promise<void>;
}

const StateContext = createContext<ApplicationState | null>(null);
const ActionsContext = createContext<ApplicationActions | null>(null);

export function OrganizerApplicationProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(reducer, INITIAL_STATE);
  const verifierRef = useRef<RecaptchaVerifier | null>(null);
  const confirmationRef = useRef<ConfirmationResult | null>(null);

  const discardVerifier = useCallback(() => {
    // clear() tears the widget out of its container, which by this point may
    // already have unmounted with the stage that rendered it. A failure to
    // dispose of the spent object must not block the next send.
    try {
      verifierRef.current?.clear();
    } catch {
      // Already detached — nothing left to dispose of.
    }
    verifierRef.current = null;
  }, []);

  // A verifier left behind holds a rendered reCAPTCHA widget and its timers.
  useEffect(() => discardVerifier, [discardVerifier]);

  /**
   * Sends one SMS. Always builds a brand-new verifier: the previous one is
   * spent whether the send it backed succeeded or failed, so reusing it is
   * how you get `auth/captcha-check-failed`.
   */
  const sendOtp = useCallback(
    async (phone: string) => {
      const auth = getFirebaseAuth();
      const user = auth.currentUser;
      if (!user) throw new Error("You are not signed in. Restart the application.");

      const container = document.getElementById(RECAPTCHA_CONTAINER_ID);
      if (!container) {
        throw new Error("The verification widget didn't load. Reload the page and try again.");
      }

      discardVerifier();
      const verifier = new RecaptchaVerifier(auth, container, { size: "invisible" });
      verifierRef.current = verifier;

      // On failure the previous ConfirmationResult is deliberately left in
      // place: if an earlier SMS did arrive, its code is still worth trying.
      confirmationRef.current = await linkWithPhoneNumber(user, phone, verifier);
    },
    [discardVerifier]
  );

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
        discardVerifier();
        confirmationRef.current = null;
        dispatch({ type: "signedOut" });
        return;
      }
      // Read both documents once so a reload resumes at the right stage
      // instead of sending a half-finished applicant back to the phone
      // screen. Two independent resume signals:
      //
      //  - `user.phoneNumber` — a linked phone credential, which is the only
      //    verification state this flow trusts. Its presence means the phone
      //    and otp stages are done, so they are skipped: re-verifying an
      //    already-linked number would only fail as
      //    `auth/provider-already-linked` after billing an SMS.
      //  - `application.submitted` — set once, in beginReview. (Not the old
      //    client-set `phoneVerified`, which no longer exists; phoneVerified
      //    moved to the admin-owned review doc.)
      const linkedPhone = user.phoneNumber ?? "";
      void loadApplication(user.uid)
        .then(({ application, review, phone }) => {
          const resumePhone = linkedPhone || phone;
          dispatch({ type: "snapshotChanged", application, review, phone: resumePhone });
          dispatch({
            type: "signedIn",
            uid: user.uid,
            stage: application.submitted || linkedPhone ? "review" : "phone",
            phone: resumePhone,
            email: user.email ?? "",
          });
          if (application.submitted) {
            // Defensive: guarantees the review doc exists even if a prior
            // beginReview call was interrupted before it completed. Idempotent.
            void ensureReviewDoc(user.uid);
          } else if (linkedPhone) {
            // The phone linked but the tab died between confirm() and
            // beginReview. Finish that tail here rather than charging the
            // applicant a second SMS for work already paid for. Both calls
            // are idempotent.
            void savePhone(user.uid, linkedPhone)
              .then(() => beginReview(user.uid))
              .catch((error) => dispatch({ type: "setError", error: describeAuthError(error) }));
          }
        })
        .catch((error) => {
          dispatch({
            type: "signedIn",
            uid: user.uid,
            stage: linkedPhone ? "review" : "phone",
            phone: linkedPhone,
            email: user.email ?? "",
          });
          dispatch({ type: "setError", error: describeAuthError(error) });
        });
    });
  }, [discardVerifier]);

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

      // The one send path — the OTP stage's "Resend code" calls this too, so
      // the cooldown and the cap cover both.
      submitPhone: () =>
        run(async () => {
          requireUid();
          const phone = normalizePhone(state.phone.trim());
          if (!phone) throw new Error("Enter a phone number.");
          if (!E164_PATTERN.test(phone)) {
            throw new Error("Enter the number in international format, for example +971 50 123 4567.");
          }

          // Both limits are enforced here rather than only on the button:
          // every send is a billed SMS, and a disabled button is a hint, not
          // a guarantee.
          if (state.otpSendCount >= OTP_MAX_SENDS) {
            throw new Error(
              `You've requested ${OTP_MAX_SENDS} codes. Reload the page to start again, or contact the Night Ride team.`
            );
          }
          const waitMs = state.otpCooldownUntil - Date.now();
          if (waitMs > 0) {
            throw new Error(`Wait ${Math.ceil(waitMs / 1000)}s before requesting another code.`);
          }

          await sendOtp(phone);
          dispatch({
            type: "otpSent",
            cooldownUntil: Date.now() + OTP_RESEND_COOLDOWN_SECONDS * 1000,
          });
        }),

      submitOtp: () =>
        run(async () => {
          const uid = requireUid();
          const code = state.otp.replace(/\D/g, "");
          if (code.length !== OTP_LENGTH) {
            throw new Error(`Enter the ${OTP_LENGTH}-digit code sent to your phone.`);
          }

          const confirmation = confirmationRef.current;
          if (!confirmation) {
            throw new Error("That verification attempt is no longer valid. Request a new code.");
          }

          // A wrong code throws here and leaves `confirmation` intact, so the
          // retry reuses the same verification session and sends no new SMS.
          const credential = await confirmation.confirm(code);

          // The verifier was spent the moment the SMS went out and nothing
          // past this point needs it; the next send builds its own.
          discardVerifier();

          // Firebase's own E.164 rendering of the credential it just linked,
          // in preference to whatever was typed into the field.
          await savePhone(uid, credential.user.phoneNumber ?? normalizePhone(state.phone.trim()));
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

      uploadNic: (front, back) =>
        run(async () => {
          const uid = requireUid();
          const attempt = state.review.steps.nic.attempt;
          try {
            await uploadNicFiles(uid, attempt, front, back, (progress) =>
              dispatch({ type: "setUploadProgress", id: "nic", progress })
            );
          } finally {
            dispatch({ type: "clearUploadProgress", id: "nic" });
          }
        }),

      uploadSelfie: (file) =>
        run(async () => {
          const uid = requireUid();
          const attempt = state.review.steps.selfie.attempt;
          try {
            await uploadSelfieFile(uid, attempt, file, (progress) =>
              dispatch({ type: "setUploadProgress", id: "selfie", progress })
            );
          } finally {
            dispatch({ type: "clearUploadProgress", id: "selfie" });
          }
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
  }, [state, run, sendOtp, discardVerifier]);

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
