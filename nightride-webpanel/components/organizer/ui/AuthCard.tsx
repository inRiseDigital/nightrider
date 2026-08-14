import { ReactNode } from "react";
import { cn } from "./cn";

/** The 400px-wide surface the signup, phone and OTP stages sit on. */
export function AuthCard({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className={cn("w-full max-w-[400px] rounded-lg border border-nr-border bg-nr-surface p-8", className)}>
      {children}
    </div>
  );
}

export function AuthCardTitle({ title, description }: { title: string; description?: string }) {
  return (
    <div className="mb-6">
      <h1 className="font-display text-lg uppercase tracking-wide text-nr-text-primary">{title}</h1>
      {description && <p className="mt-1.5 text-[13px] text-nr-text-secondary">{description}</p>}
    </div>
  );
}

export function BrandMark({ tagline, intro }: { tagline: string; intro?: string }) {
  return (
    <div className="mb-6 text-center">
      <div className="font-display text-2xl tracking-[0.04em]">
        <span className="text-[var(--org-accent)]">NIGHT</span>
        <span className="text-nr-text-primary">RIDE</span>
      </div>
      <p className="mt-1.5 font-mono text-[11px] tracking-[0.15em] text-nr-text-hint">{tagline}</p>
      {intro && <p className="mt-2 text-[13px] text-nr-text-secondary">{intro}</p>}
    </div>
  );
}

export function ErrorNote({ children }: { children: ReactNode }) {
  return (
    <p role="alert" className="rounded-lg border border-red-500/30 bg-red-500/10 px-3 py-2.5 text-xs text-red-400">
      {children}
    </p>
  );
}
