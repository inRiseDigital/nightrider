import { Smartphone } from "lucide-react";

/** Teal chip marking a step that can only be cleared from the mobile app. */
export function RequiresAppPill() {
  return (
    <span
      className="inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 font-mono text-[10px] uppercase tracking-[0.06em]"
      style={{ background: "var(--terc, #62d6c81a)", color: "var(--onterc, #62d6c8)" }}
    >
      <Smartphone size={12} aria-hidden />
      Requires mobile app
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
