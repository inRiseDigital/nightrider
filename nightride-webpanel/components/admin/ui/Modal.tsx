"use client";

import { ReactNode, useEffect } from "react";
import { X } from "lucide-react";
import { cn } from "./cn";

export function Modal({
  open,
  onClose,
  title,
  description,
  children,
  footer,
  size = "md",
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  description?: string;
  children: ReactNode;
  footer?: ReactNode;
  size?: "sm" | "md" | "lg";
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;

  const sizeClasses = { sm: "max-w-sm", md: "max-w-lg", lg: "max-w-2xl" };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={onClose} />
      <div
        role="dialog"
        aria-modal="true"
        className={cn(
          "relative w-full rounded-2xl border border-nr-border bg-nr-surface-raised shadow-2xl",
          sizeClasses[size]
        )}
      >
        <div className="flex items-start justify-between gap-4 border-b border-nr-border p-5">
          <div>
            <h2 className="font-display text-lg tracking-wide text-nr-text-primary">{title}</h2>
            {description && <p className="mt-1 text-sm text-nr-text-secondary">{description}</p>}
          </div>
          <button
            onClick={onClose}
            className="shrink-0 text-nr-text-hint hover:text-nr-text-primary"
            aria-label="Close dialog"
          >
            <X size={18} />
          </button>
        </div>
        <div className="max-h-[70vh] overflow-y-auto p-5">{children}</div>
        {footer && <div className="flex justify-end gap-2 border-t border-nr-border p-4">{footer}</div>}
      </div>
    </div>
  );
}
