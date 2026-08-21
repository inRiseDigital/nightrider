"use client";

import { AccentButton } from "@/components/organizer/ui/AccentButton";
import { AuthCard, AuthCardTitle, ErrorNote } from "@/components/organizer/ui/AuthCard";
import { TextField } from "@/components/organizer/ui/TextField";
import { useApplicationActions, useApplicationState } from "@/lib/organizer/store";
import { RecaptchaContainer } from "./RecaptchaContainer";
import { SessionFooter } from "./SessionFooter";

export function PhoneStage() {
  const { phone, error, busy } = useApplicationState();
  const { setCredential, submitPhone } = useApplicationActions();

  return (
    <AuthCard>
      <AuthCardTitle title="Verify your phone" description="We'll text a code to confirm it's you." />

      <form
        className="flex flex-col gap-3.5"
        onSubmit={(e) => {
          e.preventDefault();
          void submitPhone();
        }}
      >
        <TextField
          id="organizer-phone"
          label="Phone number"
          type="tel"
          autoComplete="tel"
          mono
          placeholder="+971 50 123 4567"
          value={phone}
          onChange={(e) => setCredential("phone", e.target.value)}
        />

        {error && <ErrorNote>{error}</ErrorNote>}

        <AccentButton type="submit" fullWidth loading={busy}>
          {busy ? "Sending…" : "Send code"}
        </AccentButton>

        {/* Must be in the DOM before submitPhone constructs the verifier. */}
        <RecaptchaContainer />
      </form>

      <SessionFooter />
    </AuthCard>
  );
}
