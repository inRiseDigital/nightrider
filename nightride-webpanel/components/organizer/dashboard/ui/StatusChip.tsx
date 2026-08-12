import { cn } from "@/components/admin/ui/cn";

/**
 * Monospace status pill — translucent fill, solid text, subtle ring.
 * Callers pass the fill/text/ring classes from the status maps in
 * `lib/organizer/dashboard/constants.ts`.
 */
export function StatusChip({
  label,
  className,
  size = "md",
}: {
  label: string;
  className: string;
  size?: "sm" | "md";
}) {
  return (
    <span
      className={cn(
        "inline-flex shrink-0 items-center whitespace-nowrap rounded-md font-mono font-semibold uppercase ring-1 ring-inset",
        size === "sm" ? "px-2 py-0.5 text-[10px]" : "px-2.5 py-1 text-[11px]",
        className
      )}
    >
      {label}
    </span>
  );
}
