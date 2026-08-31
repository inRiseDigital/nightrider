"use client";

import type { ReactNode } from "react";
import { cn } from "@/components/admin/ui/cn";

/** Destination-level tab strip (Home/Events/Audience/Account pages) — same
 *  underline pattern as the venue editor's internal tabs. */
export function TabStrip<T extends string>({
  tabs,
  active,
  onChange,
}: {
  tabs: readonly { id: T; label: string }[];
  active: T;
  onChange: (id: T) => void;
}) {
  return (
    <div className="mb-[18px] flex gap-5 border-b border-[var(--m3-outlinev)]">
      {tabs.map((t) => (
        <button
          key={t.id}
          onClick={() => onChange(t.id)}
          className={cn(
            "border-b-2 px-0.5 py-2.5 text-[13px] font-semibold transition-colors",
            active === t.id
              ? "border-[var(--m3-pri)] text-[var(--m3-on)]"
              : "border-transparent text-[var(--m3-onv)] hover:text-[var(--m3-on)]"
          )}
        >
          {t.label}
        </button>
      ))}
    </div>
  );
}

/** Card with a header bar, used across the dashboard sections — M3 surface. */
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
    <div
      className={cn("overflow-hidden rounded-xl", className)}
      style={{ background: "var(--m3-surf1)" }}
    >
      {title && (
        <div
          className="flex items-center justify-between gap-3 border-b px-5 py-4"
          style={{ borderColor: "var(--m3-outlinev)" }}
        >
          <h2 className="text-sm font-medium tracking-wide" style={{ color: "var(--m3-on)" }}>
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
  return (
    <p className={cn("text-xs", className)} style={{ color: "var(--m3-onv)" }}>
      {children}
    </p>
  );
}

/** Bare input matching the M3 outlined-field style (no wrapper label). */
export function SlimInput({
  className,
  mono = false,
  style,
  ...props
}: React.InputHTMLAttributes<HTMLInputElement> & { mono?: boolean }) {
  return (
    <input
      className={cn(
        "rounded-md border px-3 py-2.5 text-sm outline-none transition-colors",
        mono && "font-mono",
        className
      )}
      style={{
        borderColor: "var(--m3-outline)",
        background: "var(--m3-surf2)",
        color: "var(--m3-on)",
        ...style,
      }}
      {...props}
    />
  );
}

export function SlimTextarea({
  className,
  style,
  ...props
}: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea
      className={cn("resize-y rounded-md border px-3 py-2.5 text-sm outline-none", className)}
      style={{
        borderColor: "var(--m3-outline)",
        background: "var(--m3-surf2)",
        color: "var(--m3-on)",
        ...style,
      }}
      {...props}
    />
  );
}

/**
 * Pill toggle used for genres, dress codes, venue switchers, and filters.
 * Active state is the M3 primary tone; inactive is a hairline outline.
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
        "flex items-center gap-1.5 px-3.5 py-2 text-xs font-medium transition-colors border",
        shape === "pill" ? "rounded-full" : "rounded-lg",
        className
      )}
      style={
        active
          ? { borderColor: "var(--m3-pri)", background: "color-mix(in srgb, var(--m3-pri) 12%, transparent)", color: "var(--m3-pri)" }
          : { borderColor: "var(--m3-outline)", color: "var(--m3-onv)" }
      }
    >
      {active && <span className="msi text-base leading-none">check</span>}
      {label}
    </button>
  );
}

/** Switch — used for the recurring-residency toggle and other on/off state. */
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
      className="relative h-6 w-10 shrink-0 rounded-full border-2 transition-colors"
      style={{
        background: checked ? "var(--m3-pric)" : "var(--m3-surf3)",
        borderColor: checked ? "var(--m3-pric)" : "var(--m3-outline)",
      }}
    >
      <span
        className="absolute top-0.5 h-4 w-4 rounded-full transition-all"
        style={{
          background: checked ? "var(--m3-onpric)" : "var(--m3-onv)",
          left: checked ? "18px" : "2px",
        }}
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
    <p
      className={cn("font-mono text-[11px] uppercase tracking-[0.1em]", className)}
      style={{ color: "var(--m3-outline)" }}
    >
      {children}
    </p>
  );
}
