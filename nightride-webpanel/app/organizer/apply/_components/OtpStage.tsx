"use client";

import { AccentButton } from "@/components/organizer/ui/AccentButton";
import { AuthCard, AuthCardTitle, ErrorNote } from "@/components/organizer/ui/AuthCard";
import { TextField } from "@/components/organizer/ui/TextField";
import { IS_DEV, OTP_LENGTH } from "@/lib/organizer/constants";
import { useApplicationActions, useApplicationState } from "@/lib/organizer/store";
import { SessionFooter } from "./SessionFooter";

export function OtpStage() {
  const { phone, otp, error, busy } = useApplicationState();
  const { setCredential, submitOtp, submitPhone } = useApplicationActions();

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

      {IS_DEV && (
        <p className="mt-3 text-center font-mono text-[10px] text-nr-text-hint">
          Dev only — no SMS is sent; any {OTP_LENGTH} digits will pass.
        </p>
      )}

      <p className="mt-3 text-center text-xs text-nr-text-hint">
        Didn&apos;t get it?{" "}
        <button
          type="button"
          onClick={submitPhone}
          className="text-nr-primary-light transition-colors hover:text-[var(--org-accent)]"
        >
          Resend code
        </button>
      </p>

      <SessionFooter />
    </AuthCard>
  );
}
