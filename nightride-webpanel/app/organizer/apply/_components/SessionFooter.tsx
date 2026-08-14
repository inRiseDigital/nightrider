"use client";

import { useApplicationActions, useApplicationState } from "@/lib/organizer/store";

/**
 * The mid-flow stages are reached only when already signed in, and the Firebase
 * session survives reloads — without this there is no way back to the signup
 * screen short of clearing site data.
 */
export function SessionFooter() {
  const { email, busy } = useApplicationState();
  const { signOutApplicant } = useApplicationActions();

  return (
    <p className="mt-4 border-t border-nr-border/60 pt-3 text-center text-xs text-nr-text-hint">
      {email && (
        <>
          Signed in as <span className="text-nr-text-secondary">{email}</span>
          {" · "}
        </>
      )}
      <button
        type="button"
        disabled={busy}
        onClick={() => void signOutApplicant()}
        className="text-nr-primary-light transition-colors hover:text-[var(--org-accent)] disabled:opacity-50"
      >
        Start over
      </button>
    </p>
  );
}
