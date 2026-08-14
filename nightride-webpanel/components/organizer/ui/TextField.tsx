"use client";

import { InputHTMLAttributes, forwardRef } from "react";
import { cn } from "./cn";

interface TextFieldProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  mono?: boolean;
}

export const TextField = forwardRef<HTMLInputElement, TextFieldProps>(
  ({ label, mono, className, id, ...props }, ref) => (
    <div>
      {label && (
        <label htmlFor={id} className="mb-1.5 block text-xs text-nr-text-secondary">
          {label}
        </label>
      )}
      <input
        ref={ref}
        id={id}
        className={cn(
          "w-full rounded-lg border border-nr-border bg-nr-surface-raised px-3 py-2.5 text-sm text-nr-text-primary transition-colors placeholder:text-nr-text-hint focus:border-[var(--org-accent)] focus:outline-none",
          mono && "font-mono",
          className
        )}
        {...props}
      />
    </div>
  )
);
TextField.displayName = "TextField";
