"use client";

import { useEffect, useState } from "react";
import { AccentButton } from "@/components/organizer/ui/AccentButton";
import { AuthCard, AuthCardTitle, ErrorNote } from "@/components/organizer/ui/AuthCard";
import { TextField } from "@/components/organizer/ui/TextField";
import { OTP_LENGTH, OTP_MAX_SENDS } from "@/lib/organizer/constants";
import { useApplicationActions, useApplicationState } from "@/lib/organizer/store";
import { MockPhoneAuthNote } from "./MockPhoneAuthNote";
import { RecaptchaContainer } from "./RecaptchaContainer";
import { SessionFooter } from "./SessionFooter";

export function OtpStage() {
  const { phone, otp, error, busy, otpSendCount, otpCooldownUntil } = useApplicationState();
  const { setCredential, submitOtp, submitPhone } = useApplicationActions();

  // The cooldown is stored as a deadline, so the countdown label needs a tick
  // to re-render against. The interval stops itself once the deadline passes
  // rather than running for as long as this stage is mounted.
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    if (otpCooldownUntil <= Date.now()) return;
    const timer = window.setInterval(() => {
      setNow(Date.now());
      if (Date.now() >= otpCooldownUntil) window.clearInterval(timer);
    }, 500);
    return () => window.clearInterval(timer);
  }, [otpCooldownUntil]);

  const secondsLeft = Math.max(0, Math.ceil((otpCooldownUntil - now) / 1000));
  const sendsLeft = OTP_MAX_SENDS - otpSendCount;
  const canResend = !busy && secondsLeft === 0 && sendsLeft > 0;

  return (
    <AuthCard>
      <AuthCardTitle title="Enter the code" description={`Sent to ${phone}`} />

      <form
        className="flex flex-col gap-3.5"
        onSubmit={(e) => {
          e.preventDefault();
          void submitOtp();
        }}
      >
        <TextField
          id="organizer-otp"
          type="text"
          inputMode="numeric"
          autoComplete="one-time-code"
          aria-label="Verification code"
          mono
          maxLength={OTP_LENGTH}
          placeholder="• • • • • •"
          value={otp}
          onChange={(e) => setCredential("otp", e.target.value)}
          className="py-3 text-center text-[22px] tracking-[0.5em]"
        />

        {error && <ErrorNote>{error}</ErrorNote>}

        <AccentButton type="submit" fullWidth loading={busy}>
          {busy ? "Verifying…" : "Verify"}
        </AccentButton>
      </form>

      {/* A resend builds a brand-new verifier, so the container has to be
          mounted on this stage too, not only on the phone stage. */}
      <RecaptchaContainer />

      <MockPhoneAuthNote />

      <p className="mt-3 text-center text-xs text-nr-text-hint">
        {sendsLeft > 0 ? (
          <>
            Didn&apos;t get it?{" "}
            <button
              type="button"
              disabled={!canResend}
              onClick={() => void submitPhone()}
              className="text-nr-primary-light transition-colors hover:text-[var(--org-accent)] disabled:cursor-not-allowed disabled:text-nr-text-hint disabled:hover:text-nr-text-hint"
            >
              {secondsLeft > 0
                ? `Resend code in ${secondsLeft}s`
                : sendsLeft === 1
                  ? "Resend code (last one)"
                  : "Resend code"}
            </button>
          </>
        ) : (
          <>
            You&apos;ve used all {OTP_MAX_SENDS} codes. Reload the page to start again.
          </>
        )}
      </p>

      <SessionFooter />
    </AuthCard>
  );
}
