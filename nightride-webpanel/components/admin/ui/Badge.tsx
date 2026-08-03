import { ReactNode } from "react";
import { cn } from "./cn";
import { BadgeVariant } from "@/lib/admin/format";

const VARIANT_CLASSES: Record<BadgeVariant, string> = {
  success: "bg-emerald-500/10 text-emerald-400 ring-emerald-500/30",
  warning: "bg-amber-500/10 text-amber-400 ring-amber-500/30",
  danger: "bg-red-500/10 text-red-400 ring-red-500/30",
  neutral: "bg-white/5 text-nr-text-secondary ring-white/10",
  info: "bg-nr-primary-light/10 text-nr-primary-light ring-nr-primary-light/30",
  accent: "bg-nr-accent/10 text-nr-accent ring-nr-accent/30",
};

export function Badge({
  variant = "neutral",
  children,
  className,
}: {
  variant?: BadgeVariant;
  children: ReactNode;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 whitespace-nowrap rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset",
        VARIANT_CLASSES[variant],
        className
      )}
    >
      {children}
    </span>
  );
}
