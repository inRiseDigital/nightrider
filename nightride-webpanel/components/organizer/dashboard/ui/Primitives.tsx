"use client";

import { useId, type ReactNode } from "react";
import { ChevronDown } from "lucide-react";
import { cn } from "@/components/admin/ui/cn";

/**
 * Material 3 metrics used across the organizer dashboard. Keeping them in one
 * place is what stops the page drifting back into "generic dark cards":
 *
 *   card      12px radius, 20px padding, 24px gap between cards
 *   field     4px radius, 56px tall (40px dense), 16px horizontal padding
 *   chip      8px radius, 32px tall
 *   button    fully rounded, 40px tall, 24px horizontal padding
 *   icon btn  40px round hit area
 *
 * Everything else lands on the 4dp grid.
 */
export const M3_CARD = "rounded-xl border p-5";

/** Card surface + hairline, as inline style so it reads the live tokens. */
export const m3CardStyle = {
  background: "var(--m3-surf1)",
  borderColor: "var(--m3-outlinev)",
} as const;

/** Convenience wrapper for the standard M3 surface card. */
export function Card({
  children,
  className,
  style,
}: {
  children: ReactNode;
  className?: string;
  style?: React.CSSProperties;
}) {
  return (
    <div className={cn(M3_CARD, className)} style={{ ...m3CardStyle, ...style }}>
      {children}
    </div>
  );
}

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

/** Group heading — M3 caption: 12px, 500, 0.5px tracking, uppercase. */
export function SectionLabel({
  children,
  className,
  trailing,
}: {
  children: ReactNode;
  className?: string;
  trailing?: ReactNode;
}) {
  return (
    <div className={cn("flex items-center justify-between gap-3", className)}>
      <p
        className="text-xs font-medium uppercase tracking-[0.5px]"
        style={{ color: "var(--m3-onv)" }}
      >
        {children}
      </p>
      {trailing}
    </div>
  );
}

/**
 * The notched label of an M3 outlined field. It sits astride the top border and
 * paints the card's own surface behind itself so the stroke reads as broken
 * rather than crossed out — which is why the surface has to be passed in.
 */
function NotchedLabel({
  htmlFor,
  surface,
  children,
}: {
  htmlFor: string;
  surface: string;
  children: ReactNode;
}) {
  return (
    <label
      htmlFor={htmlFor}
      className="pointer-events-none absolute -top-2 left-3 z-[1] px-1 text-xs tracking-[0.4px]"
      style={{ background: surface, color: "var(--m3-onv)" }}
    >
      {children}
    </label>
  );
}

const fieldBase =
  "peer w-full rounded border bg-transparent outline-none transition-colors " +
  "border-[var(--m3-outline)] text-[var(--m3-on)] " +
  "focus:border-[var(--m3-pri)] focus:shadow-[0_0_0_1px_var(--m3-pri)] " +
  "placeholder:text-[var(--m3-outline)]";

/**
 * M3 outlined text field. `dense` drops it from the 56px default to 40px for
 * table-style rows (opening hours, menu items) where 56px would be overbearing.
 */
export function TextField({
  label,
  surface = "var(--m3-surf1)",
  mono = false,
  dense = false,
  className,
  wrapperClassName,
  id,
  ...props
}: React.InputHTMLAttributes<HTMLInputElement> & {
  label?: string;
  surface?: string;
  mono?: boolean;
  dense?: boolean;
  wrapperClassName?: string;
}) {
  const autoId = useId();
  const fieldId = id ?? autoId;

  return (
    <div className={cn("relative", wrapperClassName)}>
      {label && (
        <NotchedLabel htmlFor={fieldId} surface={surface}>
          {label}
        </NotchedLabel>
      )}
      <input
        id={fieldId}
        className={cn(
          fieldBase,
          dense ? "h-10 px-3 text-sm" : "h-14 px-4 text-base",
          mono && "font-mono",
          className
        )}
        {...props}
      />
    </div>
  );
}

/** M3 outlined textarea — same anatomy as TextField, free height. */
export function TextArea({
  label,
  surface = "var(--m3-surf1)",
  className,
  wrapperClassName,
  id,
  ...props
}: React.TextareaHTMLAttributes<HTMLTextAreaElement> & {
  label?: string;
  surface?: string;
  wrapperClassName?: string;
}) {
  const autoId = useId();
  const fieldId = id ?? autoId;

  return (
    <div className={cn("relative", wrapperClassName)}>
      {label && (
        <NotchedLabel htmlFor={fieldId} surface={surface}>
          {label}
        </NotchedLabel>
      )}
      <textarea
        id={fieldId}
        className={cn(fieldBase, "resize-y p-4 text-[15px] leading-relaxed", className)}
        {...props}
      />
    </div>
  );
}

/**
 * M3 outlined select. The native control is stripped back to the same box as
 * TextField so a select and an input can sit side by side on one row.
 */
export function Select({
  label,
  surface = "var(--m3-surf1)",
  dense = false,
  options,
  className,
  wrapperClassName,
  id,
  ...props
}: Omit<React.SelectHTMLAttributes<HTMLSelectElement>, "children"> & {
  label?: string;
  surface?: string;
  dense?: boolean;
  options: readonly { value: string; label: string }[] | readonly string[];
  wrapperClassName?: string;
}) {
  const autoId = useId();
  const fieldId = id ?? autoId;
  const items = options.map((o) => (typeof o === "string" ? { value: o, label: o } : o));

  return (
    <div className={cn("relative", wrapperClassName)}>
      {label && (
        <NotchedLabel htmlFor={fieldId} surface={surface}>
          {label}
        </NotchedLabel>
      )}
      <select
        id={fieldId}
        className={cn(
          fieldBase,
          "cursor-pointer appearance-none",
          dense ? "h-10 pl-3 pr-9 text-sm" : "h-14 pl-4 pr-10 text-base",
          className
        )}
        {...props}
      >
        {items.map((o) => (
          <option key={o.value} value={o.value} style={{ background: "var(--m3-surf2)" }}>
            {o.label}
          </option>
        ))}
      </select>
      <ChevronDown
        size={dense ? 16 : 20}
        className={cn(
          "pointer-events-none absolute top-1/2 -translate-y-1/2 text-[var(--m3-onv)]",
          dense ? "right-2.5" : "right-3"
        )}
      />
    </div>
  );
}

/** M3 filled button — 40px tall, fully rounded, 24px horizontal padding. */
export function FilledButton({
  children,
  icon,
  tonal = false,
  className,
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & { icon?: ReactNode; tonal?: boolean }) {
  return (
    <button
      type="button"
      className={cn(
        "inline-flex h-10 items-center gap-2 rounded-full px-6 text-sm font-medium transition-opacity hover:opacity-90",
        icon && "pl-4",
        className
      )}
      style={
        tonal
          ? { background: "var(--m3-surf3)", color: "var(--m3-on)" }
          : { background: "var(--m3-pri)", color: "var(--m3-onpri)" }
      }
      {...props}
    >
      {icon}
      {children}
    </button>
  );
}

/** M3 outlined button — same metrics as filled, hairline container. */
export function OutlinedButton({
  children,
  icon,
  className,
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & { icon?: ReactNode }) {
  return (
    <button
      type="button"
      className={cn(
        "inline-flex h-10 items-center gap-2 rounded-full border px-5 text-sm font-medium transition-colors hover:bg-[var(--m3-surf3)]",
        className
      )}
      style={{ borderColor: "var(--m3-outline)", color: "var(--m3-onv)" }}
      {...props}
    >
      {icon}
      {children}
    </button>
  );
}

/** M3 text button — same metrics, no container. */
export function TextButton({
  children,
  icon,
  className,
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & { icon?: ReactNode }) {
  return (
    <button
      type="button"
      className={cn(
        "inline-flex h-10 items-center gap-2 rounded-full px-4 text-sm font-medium text-[var(--m3-pri)] transition-colors hover:bg-[var(--m3-surf3)]",
        className
      )}
      {...props}
    >
      {icon}
      {children}
    </button>
  );
}

/** M3 icon button — 40px round hit area with a hover state layer. */
export function IconButton({
  children,
  danger = false,
  className,
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & { danger?: boolean }) {
  return (
    <button
      type="button"
      className={cn(
        "flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-[var(--m3-onv)] transition-colors hover:bg-[var(--m3-surf3)]",
        danger && "hover:text-[var(--m3-err)]",
        className
      )}
      {...props}
    >
      {children}
    </button>
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
 * M3 filter chip — 32px tall, 8px radius, hairline outline, tinted with a
 * leading check when selected. Used for genres, dress codes, venue switchers,
 * and list filters, so its geometry sets the rhythm of every chip row.
 */
export function Chip({
  label,
  active,
  onClick,
  className,
  shape = "rounded",
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
        "flex h-8 items-center gap-1.5 text-[13px] font-medium transition-colors border",
        active ? "pl-2.5 pr-3.5" : "px-3.5",
        shape === "pill" ? "rounded-full" : "rounded-lg",
        className
      )}
      style={
        active
          ? {
              borderColor: "var(--m3-pri)",
              background: "color-mix(in srgb, var(--m3-pri) 12%, transparent)",
              color: "var(--m3-pri)",
            }
          : { borderColor: "var(--m3-outline)", color: "var(--m3-onv)" }
      }
    >
      {active && <span className="msi text-[18px] leading-none">check</span>}
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
    <div className="mb-6 flex flex-wrap items-center gap-2">
      {items.map((v) => (
        <Chip
          key={v.id}
          label={v.label}
          active={v.id === selected}
          onClick={() => onSelect(v.id)}
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
