import { Smartphone } from "lucide-react";

/**
 * Static marker on a step that can only be cleared in the Night Ride app —
 * nic, selfie, and gps. Deliberately not a button: this panel has nothing to
 * navigate to (the app has no deep-link scheme, see Info.plist /
 * AndroidManifest.xml), so a control here would be a dead end. It tells the
 * applicant where the step happens; the step's own copy says what to do.
 */
export function RequiresAppLabel() {
  return (
    <span
      className="inline-flex items-center gap-2 rounded-lg px-4 py-2.5 text-[13px] font-bold"
      style={{ background: "var(--terc, #62d6c81a)", color: "var(--onterc, #62d6c8)" }}
    >
      <Smartphone size={16} aria-hidden />
      Continue in mobile app
    </span>
  );
}

/** Placeholder tile standing in for media the mobile app has yet to upload. */
export function StepThumb({ label }: { label: string }) {
  return (
    <div
      className="flex h-[90px] w-[140px] items-center justify-center rounded-lg border border-nr-border"
      style={{
        backgroundImage:
          "repeating-linear-gradient(45deg, var(--nr-surface-raised, #17171a), var(--nr-surface-raised, #17171a) 8px, var(--nr-bg, #0f0f0f) 8px, var(--nr-bg, #0f0f0f) 16px)",
      }}
    >
      <span className="whitespace-pre-line px-2 text-center font-mono text-[10px] text-nr-text-hint">{label}</span>
    </div>
  );
}
