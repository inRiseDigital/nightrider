"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { signInWithEmailAndPassword } from "firebase/auth";
import { AccentButton } from "@/components/organizer/ui/AccentButton";
import { AuthCard, BrandMark, ErrorNote } from "@/components/organizer/ui/AuthCard";
import { TextField } from "@/components/organizer/ui/TextField";
import { getFirebaseAuth, isFirebaseConfigured } from "@/lib/firebase";
import { describeAuthError } from "@/lib/organizer/errors";
import { validateEmail } from "@/lib/organizer/validation";

export function LoginForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit() {
    const emailError = validateEmail(email);
    if (emailError) {
      setError(emailError);
      return;
    }
    // Only emptiness is checked here — an existing account's password predates
    // the current strength rules, so validatePassword would reject valid logins.
    if (!password) {
      setError("Enter your password.");
      return;
    }
    if (!isFirebaseConfigured()) {
      setError("Firebase is not configured. Copy .env.example to .env.local and fill in the NEXT_PUBLIC_FIREBASE_* values.");
      return;
    }

    setBusy(true);
    setError("");
    try {
      await signInWithEmailAndPassword(getFirebaseAuth(), email.trim(), password);
      // The application store reads the signed-in user and resumes the flow at
      // whichever stage they left off — phone linking or review.
      router.replace("/organizer/apply");
    } catch (err) {
      setError(describeAuthError(err));
      setBusy(false);
    }
  }

  return (
    <AuthCard>
      <BrandMark tagline="ORGANIZER PANEL" />

      {/* noValidate keeps the browser's native bubble from pre-empting our own error box. */}
      <form
        noValidate
        className="flex flex-col gap-3.5"
        onSubmit={(e) => {
          e.preventDefault();
          void submit();
        }}
      >
        <TextField
          id="organizer-login-email"
          label="Email"
          type="email"
          autoComplete="email"
          placeholder="admin@nightride.app"
          value={email}
          onChange={(e) => {
            setEmail(e.target.value);
            setError("");
          }}
        />

        <TextField
          id="organizer-login-password"
          label="Password"
          type="password"
          autoComplete="current-password"
          placeholder="••••••••"
          value={password}
          onChange={(e) => {
            setPassword(e.target.value);
            setError("");
          }}
        />

        {error && <ErrorNote>{error}</ErrorNote>}

        <AccentButton type="submit" fullWidth loading={busy} className="mt-1.5">
          {busy ? "Signing in…" : "Sign in"}
        </AccentButton>
      </form>

      <p className="mt-4 text-center text-xs text-nr-text-hint">
        Applying as a venue organizer?{" "}
        <Link
          href="/organizer/apply"
          className="text-nr-primary-light transition-colors hover:text-[var(--org-accent)]"
        >
          Apply here
        </Link>
      </p>
    </AuthCard>
  );
}
