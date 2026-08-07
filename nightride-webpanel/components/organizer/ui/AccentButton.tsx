"use client";

import { ButtonHTMLAttributes, forwardRef } from "react";
import { Loader2 } from "lucide-react";
import { cn } from "./cn";

interface AccentButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  size?: "sm" | "md";
  fullWidth?: boolean;
  loading?: boolean;
}

/** Solid accent-on-black button — the single call to action on every stage. */
export const AccentButton = forwardRef<HTMLButtonElement, AccentButtonProps>(
  ({ className, size = "md", fullWidth, loading, disabled, children, type = "button", ...props }, ref) => (
    <button
      ref={ref}
      type={type}
      disabled={disabled || loading}
      className={cn(
        "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-lg bg-[var(--org-accent)] font-semibold text-nr-bg transition-colors hover:bg-[var(--org-accent-hover)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--org-accent)] disabled:cursor-not-allowed disabled:opacity-50",
        size === "sm" ? "px-4 py-2.5 text-xs" : "px-4 py-2.5 text-sm",
        fullWidth && "w-full",
        className
      )}
      {...props}
    >
      {loading && <Loader2 size={14} className="animate-spin" aria-hidden />}
      {children}
    </button>
  )
);
AccentButton.displayName = "AccentButton";
