"use client";

import { useCallback, useMemo, useState } from "react";
import { MOCK_ORGANIZER } from "../mock-data";
import { OTP_MIN_LENGTH } from "../constants";
import type { OrganizerProfile } from "../types";

export type ChangeField = "email" | "phone";
export type ChangeStage = "edit" | "otp";

/** Organizer identity — `users/{uid}`'s `email`/`phone`, changed through an OTP flow. */
export function useAccountSettings() {
  const [organizer] = useState<OrganizerProfile>(MOCK_ORGANIZER);
  const [accountEmail, setAccountEmail] = useState(MOCK_ORGANIZER.email);
  const [accountPhone, setAccountPhone] = useState(MOCK_ORGANIZER.phone);
  const [changeField, setChangeField] = useState<ChangeField | null>(null);
  const [changeStage, setChangeStage] = useState<ChangeStage>("edit");
  const [changeValue, setChangeValue] = useState("");
  const [changeOtp, setChangeOtp] = useState("");
  const [changeError, setChangeError] = useState("");

  const startChangeField = useCallback(
    (field: ChangeField) => {
      setChangeField(field);
      setChangeStage("edit");
      setChangeValue(field === "email" ? accountEmail : accountPhone);
      setChangeOtp("");
      setChangeError("");
    },
    [accountEmail, accountPhone]
  );

  const cancelChangeField = useCallback(() => {
    setChangeField(null);
    setChangeStage("edit");
    setChangeValue("");
    setChangeOtp("");
    setChangeError("");
  }, []);

  const submitNewValue = useCallback(() => {
    if (!changeValue.trim()) {
      setChangeError("Enter a value.");
      return;
    }
    setChangeStage("otp");
    setChangeOtp("");
    setChangeError("");
  }, [changeValue]);

  const submitOtp = useCallback(() => {
    if (changeOtp.trim().length < OTP_MIN_LENGTH) {
      setChangeError("Enter the code we sent you.");
      return;
    }
    if (changeField === "email") setAccountEmail(changeValue.trim());
    if (changeField === "phone") setAccountPhone(changeValue.trim());
    cancelChangeField();
  }, [changeOtp, changeField, changeValue, cancelChangeField]);

  const data = useMemo(
    () => ({ organizer, accountEmail, accountPhone, changeField, changeStage, changeValue, changeOtp, changeError }),
    [organizer, accountEmail, accountPhone, changeField, changeStage, changeValue, changeOtp, changeError]
  );

  return useMemo(
    () => ({ data, loading: false, error: null, busy: false, actionError: "", startChangeField, cancelChangeField, setChangeValue, setChangeOtp, submitNewValue, submitOtp }),
    [data, startChangeField, cancelChangeField, submitNewValue, submitOtp]
  );
}

export type AccountSettingsState = ReturnType<typeof useAccountSettings>;
