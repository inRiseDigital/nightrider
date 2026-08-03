"use client";

import { ReactNode, useEffect } from "react";
import { X } from "lucide-react";

export function Drawer({
  open,
  onClose,
  title,
  subtitle,
  children,
  footer,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  subtitle?: string;
  children: ReactNode;
  footer?: ReactNode;
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

  return (
    <div className="fixed inset-0 z-50 flex justify-end">
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={onClose} />
      <div className="relative flex h-full w-full max-w-md flex-col border-l border-nr-border bg-nr-surface-raised shadow-2xl sm:max-w-lg">
        <div className="flex items-start justify-between gap-4 border-b border-nr-border p-5">
          <div className="min-w-0">
            <h2 className="truncate font-display text-lg tracking-wide text-nr-text-primary">{title}</h2>
            {subtitle && <p className="mt-1 truncate text-sm text-nr-text-secondary">{subtitle}</p>}
          </div>
          <button onClick={onClose} className="shrink-0 text-nr-text-hint hover:text-nr-text-primary" aria-label="Close">
            <X size={18} />
          </button>
        </div>
        <div className="flex-1 overflow-y-auto p-5">{children}</div>
        {footer && <div className="flex justify-end gap-2 border-t border-nr-border p-4">{footer}</div>}
      </div>
    </div>
  );
}
