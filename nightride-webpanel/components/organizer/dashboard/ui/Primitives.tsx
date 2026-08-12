"use client";

import type { ReactNode } from "react";
import { cn } from "@/components/admin/ui/cn";

/** Card with an Anton uppercase header bar, used across the dashboard sections. */
export function PanelCard({
  title,
  action,
  children,
  className,
  bodyClassName,
}: {
  title?: ReactNode;
  action?: ReactNode;
  children: ReactNode;
  className?: string;
  bodyClassName?: string;
}) {
  return (
    <div className={cn("overflow-hidden rounded-lg border border-nr-border bg-nr-surface", className)}>
      {title && (
        <div className="flex items-center justify-between gap-3 border-b border-nr-border px-5 py-4">
          <h2 className="font-display text-sm uppercase tracking-wider text-nr-text-primary">
            {title}
          </h2>
          {action}
        </div>
      )}
      <div className={bodyClassName}>{children}</div>
    </div>
  );
}

/** Small muted caption that labels a control group. */
export function FieldLabel({ children, className }: { children: ReactNode; className?: string }) {
  return <p className={cn("text-xs text-nr-text-secondary", className)}>{children}</p>;
}

const inputBase =
  "rounded-lg border border-nr-border bg-nr-surface-raised px-3 py-2.5 text-sm text-nr-text-primary placeholder:text-nr-text-hint focus:border-nr-primary focus:outline-none focus:ring-1 focus:ring-nr-primary";

/** Bare input matching the dashboard's inline-field style (no wrapper label). */
export function SlimInput({
  className,
  mono = false,
  ...props
}: React.InputHTMLAttributes<HTMLInputElement> & { mono?: boolean }) {
  return <input className={cn(inputBase, mono && "font-mono", className)} {...props} />;
}

export function SlimTextarea({
  className,
  ...props
}: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return <textarea className={cn(inputBase, "resize-y", className)} {...props} />;
}

/**
 * Pill toggle used for genres, dress codes, venue switchers, and filters.
 * Active state is the brand pink; inactive is a hairline outline.
 */
export function Chip({
  label,
  active,
  onClick,
  className,
  shape = "pill",
}: {
  label: ReactNode;
  active: boolean;
  onClick: () => void;
  className?: string;
  shape?: "pill" | "rounded";
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={active}
      className={cn(
        "px-3.5 py-2 text-xs font-semibold transition-colors",
        shape === "pill" ? "rounded-full" : "rounded-lg",
        active
          ? "border border-nr-primary bg-nr-primary/10 text-nr-primary"
          : "border border-nr-border text-nr-text-secondary hover:border-nr-text-secondary/60 hover:text-nr-text-primary",
        className
      )}
    >
      {label}
    </button>
  );
}

/** iOS-style switch — used for the recurring-residency toggle. */
export function Toggle({
  checked,
  onChange,
  label,
}: {
  checked: boolean;
  onChange: () => void;
  label: string;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      onClick={onChange}
      className={cn(
        "relative h-6 w-10 shrink-0 rounded-full transition-colors",
        checked ? "bg-nr-primary" : "bg-nr-border"
      )}
    >
      <span
        className={cn(
          "absolute top-1 h-4 w-4 rounded-full bg-nr-text-primary transition-all",
          checked ? "left-5" : "left-1"
        )}
      />
    </button>
  );
}

/** Horizontal row of venue filter chips, optionally prefixed with "All Venues". */
export function VenueSwitcher({
  venueOrder,
  venues,
  selected,
  onSelect,
  includeAll = false,
  trailing,
}: {
  venueOrder: string[];
  venues: Record<string, { name: string; verified: boolean }>;
  selected: string;
  onSelect: (id: string) => void;
  includeAll?: boolean;
  trailing?: ReactNode;
}) {
  const items = includeAll
    ? [{ id: "all", label: "All Venues" }, ...venueOrder.map((id) => ({ id, label: venues[id].name }))]
    : venueOrder.map((id) => ({
        id,
        label: venues[id].name + (venues[id].verified ? "" : " (pending)"),
      }));

  return (
    <div className="mb-5 flex flex-wrap gap-2.5">
      {items.map((v) => (
        <Chip
          key={v.id}
          label={v.label}
          active={v.id === selected}
          onClick={() => onSelect(v.id)}
          shape="rounded"
          className="px-4 py-2 text-[13px]"
        />
      ))}
      {trailing}
    </div>
  );
}

/** Muted monospace section divider, e.g. "DRAFTS — NOT YET SUBMITTED". */
export function SectionEyebrow({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <p className={cn("font-mono text-[11px] uppercase tracking-[0.1em] text-nr-text-hint", className)}>
      {children}
    </p>
  );
}
