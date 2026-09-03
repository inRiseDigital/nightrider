"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { getDoc, setDoc, updateDoc } from "firebase/firestore";
import { verifyBeforeUpdateEmail, type User } from "firebase/auth";
import { userDocRef } from "../data/refs";
import { describeFirestoreError } from "../data/errors";
import { describeAuthError } from "@/lib/organizer/errors";
import { DEFAULT_PREFERENCES, parsePreferences, preferencesDocRef, type OrganizerPreferences } from "../data/settings";
import { OTP_MIN_LENGTH } from "../constants";
import type { OrganizerProfile } from "../types";

export type ChangeField = "email" | "phone";
export type ChangeStage = "edit" | "otp";

function isValidEmail(v: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
}
function isValidPhone(v: string): boolean {
  return /^\+[1-9]\d{6,15}$/.test(v.replace(/[\s()-]/g, ""));
}

/**
 * `users/{uid}`'s `email`/`phone`, plus `users/{uid}/settings/preferences`.
 *
 * No profile read here: `useOrganizerAuth` (T5) already read `users/{uid}`
 * and publishes `organizer` — a second read of the same document is the
 * thing this layering exists to avoid, so `organizer`/`user`/`refreshOrganizer`
 * are threaded in from there.
 *
 * Email changes go through `verifyBeforeUpdateEmail` — the Auth record is the
 * source of truth for the address, never a direct Firestore field write.
 * Phone stays an honest stub, PHONE_AUTH_STUBBED (see `lib/organizer/store.tsx`):
 * no SMS is sent and any code of `OTP_MIN_LENGTH` digits is accepted, but the
 * number itself is written for real.
 */
export function useAccountSettings(
  uid: string,
  user: User | null,
  organizer: OrganizerProfile,
  refreshOrganizer: () => Promise<void>,
  showSnack: (text: string, tone?: "info" | "error") => void
) {
  const [changeField, setChangeField] = useState<ChangeField | null>(null);
  const [changeStage, setChangeStage] = useState<ChangeStage>("edit");
  const [changeValue, setChangeValue] = useState("");
  const [changeOtp, setChangeOtp] = useState("");
  const [changeError, setChangeError] = useState("");
  const [changeBusy, setChangeBusy] = useState(false);

  const startChangeField = useCallback(
    (field: ChangeField) => {
      setChangeField(field);
      setChangeStage("edit");
      setChangeValue(field === "email" ? organizer.email : organizer.phone);
      setChangeOtp("");
      setChangeError("");
    },
    [organizer.email, organizer.phone]
  );

  const cancelChangeField = useCallback(() => {
    setChangeField(null);
    setChangeStage("edit");
    setChangeValue("");
    setChangeOtp("");
    setChangeError("");
  }, []);

  const submitNewValue = useCallback(async () => {
    const value = changeValue.trim();
    if (!value) {
      setChangeError("Enter a value.");
      return;
    }

    if (changeField === "phone") {
      if (!isValidPhone(value)) {
        setChangeError("Enter the number in international format, for example +971 50 123 4567.");
        return;
      }
      // PHONE_AUTH_STUBBED: no SMS is sent — move straight to the code step.
      // See lib/organizer/store.tsx for the convention this follows.
      setChangeStage("otp");
      setChangeOtp("");
      setChangeError("");
      return;
    }

    if (changeField === "email") {
      if (!isValidEmail(value)) {
        setChangeError("Enter a valid email address.");
        return;
      }
      if (!user) {
        setChangeError("You're signed out. Sign in again to change your email.");
        return;
      }
      setChangeBusy(true);
      try {
        await verifyBeforeUpdateEmail(user, value);
        cancelChangeField();
        showSnack("Check your inbox to confirm the new email address.");
      } catch (err) {
        setChangeError(describeAuthError(err));
      } finally {
        setChangeBusy(false);
      }
    }
  }, [changeValue, changeField, user, cancelChangeField, showSnack]);

  const submitOtp = useCallback(async () => {
    if (changeField !== "phone") {
      // Email never reaches the otp stage — verifyBeforeUpdateEmail's
      // confirmation is a link in the organizer's inbox, not a code typed
      // back here.
      cancelChangeField();
      return;
    }
    if (changeOtp.trim().length < OTP_MIN_LENGTH) {
      setChangeError("Enter the code we sent you.");
      return;
    }
    // PHONE_AUTH_STUBBED: no confirmation result to check against, so any
    // code of the right length passes. The number is still recorded for real.
    setChangeBusy(true);
    try {
      await updateDoc(userDocRef(uid), { phone: changeValue.trim() });
      await refreshOrganizer();
      cancelChangeField();
      showSnack("Phone number updated.");
    } catch (err) {
      setChangeError(describeFirestoreError(err));
    } finally {
      setChangeBusy(false);
    }
  }, [changeField, changeOtp, changeValue, uid, refreshOrganizer, cancelChangeField, showSnack]);

  // ---- Preferences: users/{uid}/settings/preferences ----
  const [preferences, setPreferences] = useState<OrganizerPreferences>(DEFAULT_PREFERENCES);
  const [prefsLoading, setPrefsLoading] = useState(true);
  const [prefsError, setPrefsError] = useState("");

  useEffect(() => {
    let cancelled = false;
    setPrefsLoading(true);
    getDoc(preferencesDocRef(uid))
      .then((snap) => {
        if (cancelled) return;
        setPreferences(parsePreferences(snap.exists() ? (snap.data() as Record<string, unknown>) : undefined));
        setPrefsError("");
      })
      .catch((err) => {
        if (!cancelled) setPrefsError(describeFirestoreError(err));
      })
      .finally(() => {
        if (!cancelled) setPrefsLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [uid]);

  const togglePreference = useCallback(
    async (id: keyof OrganizerPreferences) => {
      const previous = preferences;
      const next = { ...previous, [id]: !previous[id] };
      setPreferences(next);
      try {
        await setDoc(preferencesDocRef(uid), next, { merge: true });
      } catch (err) {
        setPreferences(previous);
        showSnack(describeFirestoreError(err), "error");
      }
    },
    [uid, preferences, showSnack]
  );

  const data = useMemo(
    () => ({
      organizer,
      accountEmail: organizer.email,
      accountPhone: organizer.phone,
      changeField,
      changeStage,
      changeValue,
      changeOtp,
      changeError,
      preferences,
      prefsLoading,
      prefsError,
    }),
    [organizer, changeField, changeStage, changeValue, changeOtp, changeError, preferences, prefsLoading, prefsError]
  );

  return useMemo(
    () => ({
      data,
      loading: false,
      error: "",
      busy: changeBusy,
      actionError: changeError,
      startChangeField,
      cancelChangeField,
      setChangeValue,
      setChangeOtp,
      submitNewValue,
      submitOtp,
      togglePreference,
    }),
    [data, changeBusy, changeError, startChangeField, cancelChangeField, submitNewValue, submitOtp, togglePreference]
  );
}

export type AccountSettingsState = ReturnType<typeof useAccountSettings>;
