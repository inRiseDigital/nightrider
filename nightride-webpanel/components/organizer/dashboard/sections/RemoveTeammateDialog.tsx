"use client";

import { AlertCircle, UserMinus } from "lucide-react";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { TextButton, TextField } from "../ui/Primitives";

/**
 * Confirmation for revoking a teammate's access — destructive and immediate,
 * so it asks for the account password and an explicit acknowledgement rather
 * than firing off a single click.
 */
export function RemoveTeammateDialog() {
  const {
    removeTarget,
    removePassword,
    removeAck,
    removeError,
    setRemovePassword,
    toggleRemoveAck,
    cancelRemoveTeamMember,
    confirmRemoveTeamMember,
    profile,
  } = useOrganizerDashboard();

  if (!removeTarget) return null;

  const armed = removeAck && removePassword.length >= 6;

  return (
    <div className="fixed inset-0 z-[75] flex items-center justify-center p-8">
      <div className="absolute inset-0 bg-black/60" onClick={cancelRemoveTeamMember} />
      <div
        role="dialog"
        aria-modal="true"
        aria-label={`Remove ${removeTarget.name}`}
        className="relative w-full max-w-[400px] rounded-[28px] p-6 shadow-[0_8px_24px_rgba(0,0,0,0.5)]"
        style={{ background: "var(--m3-surf2)" }}
      >
        <div
          className="mb-4 flex h-10 w-10 items-center justify-center rounded-full"
          style={{ background: "var(--m3-errc)", color: "var(--m3-onerrc)" }}
        >
          <UserMinus size={20} />
        </div>

        <h2 className="text-2xl leading-8" style={{ color: "var(--m3-on)" }}>
          Remove {removeTarget.name}?
        </h2>
        <p className="mt-2.5 text-sm leading-5 tracking-[0.25px]" style={{ color: "var(--m3-onv)" }}>
          They lose access to {profile.name} immediately — guest lists they built stay with the
          venue. Confirm with your password.
        </p>

        <TextField
          type="password"
          label="Your password"
          surface="var(--m3-surf2)"
          value={removePassword}
          onChange={(e) => setRemovePassword(e.target.value)}
          placeholder="••••••••"
          autoFocus
          wrapperClassName="mt-6"
          className={removeError ? "!border-[var(--m3-err)]" : undefined}
        />

        {removeError && (
          <p
            className="mt-2.5 flex items-start gap-2 text-xs leading-[18px] tracking-[0.4px]"
            style={{ color: "var(--m3-err)" }}
          >
            <AlertCircle size={15} className="mt-px shrink-0" />
            {removeError}
          </p>
        )}

        <button
          type="button"
          onClick={toggleRemoveAck}
          aria-pressed={removeAck}
          className="mt-5 flex w-full items-start gap-3 text-left"
        >
          <span
            className="mt-0.5 flex h-[18px] w-[18px] shrink-0 items-center justify-center rounded-sm border-2 text-xs font-bold"
            style={{
              borderColor: removeAck ? "var(--m3-pri)" : "var(--m3-outline)",
              background: removeAck ? "var(--m3-pri)" : "transparent",
              color: "var(--m3-onpri)",
            }}
          >
            {removeAck ? "✓" : ""}
          </span>
          <span className="text-sm leading-5 tracking-[0.25px]" style={{ color: "var(--m3-on)" }}>
            I understand this revokes their access and cannot be undone.
          </span>
        </button>

        <div className="mt-6 flex items-center justify-end gap-2">
          <TextButton onClick={cancelRemoveTeamMember}>Cancel</TextButton>
          <button
            type="button"
            onClick={confirmRemoveTeamMember}
            className="inline-flex h-10 items-center rounded-full px-6 text-sm font-medium transition-[filter] hover:brightness-95"
            style={
              armed
                ? { background: "#DC2626", color: "#FFFFFF" }
                : { background: "var(--m3-surf4)", color: "var(--m3-outline)" }
            }
          >
            Remove access
          </button>
        </div>
      </div>
    </div>
  );
}
