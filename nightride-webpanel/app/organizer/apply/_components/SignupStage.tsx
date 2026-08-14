"use client";

import Link from "next/link";
import { Check } from "lucide-react";
import { AccentButton } from "@/components/organizer/ui/AccentButton";
import { AuthCard, AuthCardTitle, ErrorNote } from "@/components/organizer/ui/AuthCard";
import { TextField } from "@/components/organizer/ui/TextField";
import { cn } from "@/components/organizer/ui/cn";
import { COPY_TONE, TONE_COPY } from "@/lib/organizer/constants";
import { useApplicationActions, useApplicationState } from "@/lib/organizer/store";
import { PasswordRequirements } from "./PasswordRequirements";

export function SignupStage() {
  const { email, password, captcha, error, busy } = useApplicationState();
  const { setCredential, toggleCaptcha, submitSignup } = useApplicationActions();

  return (
    <AuthCard>
      <AuthCardTitle title="Create your organizer account" description={TONE_COPY[COPY_TONE].intro} />

      {/* noValidate keeps the browser's native bubble from pre-empting our own error box. */}
      <form
        noValidate
        className="flex flex-col gap-3"
        onSubmit={(e) => {
          e.preventDefault();
          void submitSignup();
        }}
      >
        <TextField
          id="organizer-email"
          label="Email"
          type="email"
          autoComplete="email"
          placeholder="you@venue.com"
          value={email}
          onChange={(e) => setCredential("email", e.target.value)}
        />

        <div>
          <TextField
            id="organizer-password"
            label="Password"
            type="password"
            autoComplete="new-password"
            placeholder="••••••••"
            value={password}
            onChange={(e) => setCredential("password", e.target.value)}
          />
          {password && <PasswordRequirements password={password} />}
        </div>

        <button
          type="button"
          role="checkbox"
          aria-checked={captcha}
          onClick={toggleCaptcha}
          className="mt-0.5 flex items-center gap-2.5 rounded-lg border border-nr-border bg-nr-surface-raised p-3 text-left transition-colors hover:border-nr-text-hint"
        >
          <span
            className={cn(
              "flex h-5 w-5 shrink-0 items-center justify-center rounded border border-nr-text-hint",
              captcha && "border-[var(--org-accent)] bg-[var(--org-accent)]"
            )}
          >
            {captcha && <Check size={13} strokeWidth={3} className="text-nr-bg" />}
          </span>
          <span className="text-[13px] text-nr-text-secondary">I&apos;m not a robot</span>
        </button>

        {error && <ErrorNote>{error}</ErrorNote>}

        <AccentButton type="submit" fullWidth loading={busy} className="mt-1.5">
          {busy ? "Creating account…" : "Continue"}
        </AccentButton>
      </form>

      <div className="my-3.5 flex items-center gap-2.5">
        <span className="h-px flex-1 bg-nr-border" />
        <span className="text-[11px] text-nr-text-hint">or continue with</span>
        <span className="h-px flex-1 bg-nr-border" />
      </div>

      <div className="flex gap-2.5">
        <SocialButton mark="G" label="Google" markClassName="font-mono" />
        <SocialButton mark="" label="Apple" />
      </div>

      <p className="mt-4 text-center text-xs text-nr-text-hint">
        Already an organizer?{" "}
        <Link href="/organizer/login" className="text-nr-primary-light transition-colors hover:text-[var(--org-accent)]">
          Log in
        </Link>
      </p>
    </AuthCard>
  );
}

function SocialButton({
  mark,
  label,
  markClassName,
}: {
  mark: string;
  label: string;
  markClassName?: string;
}) {
  return (
    <button
      type="button"
      className="flex flex-1 items-center justify-center gap-2 rounded-lg border border-nr-border bg-nr-surface-raised p-2.5 text-[13px] text-nr-text-primary transition-colors hover:border-nr-primary-light"
    >
      <span
        className={cn(
          "flex h-[18px] w-[18px] items-center justify-center rounded-full bg-nr-text-primary text-[11px] font-bold text-nr-bg",
          markClassName
        )}
        aria-hidden
      >
        {mark}
      </span>
      {label}
    </button>
  );
}
