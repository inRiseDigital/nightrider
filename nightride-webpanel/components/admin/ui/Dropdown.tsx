"use client";

import { ReactNode, useEffect, useRef, useState } from "react";
import { MoreVertical } from "lucide-react";
import { cn } from "./cn";

export interface DropdownItem {
  label: string;
  icon?: React.ComponentType<{ size?: number; className?: string }>;
  onClick: () => void;
  danger?: boolean;
  disabled?: boolean;
  hidden?: boolean;
}

export function Dropdown({
  items,
  trigger,
  align = "right",
}: {
  items: DropdownItem[];
  trigger?: ReactNode;
  align?: "left" | "right";
}) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    function onClickOutside(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", onClickOutside);
    return () => document.removeEventListener("mousedown", onClickOutside);
  }, [open]);

  const visibleItems = items.filter((i) => !i.hidden);

  return (
    <div ref={ref} className="relative inline-block text-left">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="flex h-8 w-8 items-center justify-center rounded-lg text-nr-text-secondary hover:bg-white/5 hover:text-nr-text-primary"
        aria-label="Open actions menu"
      >
        {trigger ?? <MoreVertical size={16} />}
      </button>
      {open && (
        <div
          className={cn(
            "absolute z-30 mt-1 w-56 overflow-hidden rounded-xl border border-nr-border bg-nr-surface-raised py-1 shadow-2xl",
            align === "right" ? "right-0" : "left-0"
          )}
        >
          {visibleItems.map((item) => (
            <button
              key={item.label}
              disabled={item.disabled}
              onClick={() => {
                setOpen(false);
                item.onClick();
              }}
              className={cn(
                "flex w-full items-center gap-2 px-3 py-2 text-left text-sm transition-colors disabled:cursor-not-allowed disabled:opacity-40",
                item.danger
                  ? "text-red-400 hover:bg-red-500/10"
                  : "text-nr-text-primary hover:bg-white/5"
              )}
            >
              {item.icon && <item.icon size={14} />}
              {item.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
