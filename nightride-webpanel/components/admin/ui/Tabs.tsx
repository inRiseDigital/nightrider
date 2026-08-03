"use client";

import { cn } from "./cn";

export function Tabs({
  tabs,
  active,
  onChange,
}: {
  tabs: { key: string; label: string; count?: number }[];
  active: string;
  onChange: (key: string) => void;
}) {
  return (
    <div className="flex gap-1 overflow-x-auto border-b border-nr-border px-2">
      {tabs.map((t) => (
        <button
          key={t.key}
          onClick={() => onChange(t.key)}
          className={cn(
            "relative flex shrink-0 items-center gap-2 px-4 py-3 text-sm font-medium transition-colors",
            active === t.key ? "text-nr-text-primary" : "text-nr-text-secondary hover:text-nr-text-primary"
          )}
        >
          {t.label}
          {t.count !== undefined && (
            <span className="rounded-full bg-white/5 px-1.5 py-0.5 text-[11px] text-nr-text-secondary">
              {t.count}
            </span>
          )}
          {active === t.key && (
            <span className="absolute inset-x-3 -bottom-px h-0.5 rounded-full bg-nr-primary" />
          )}
        </button>
      ))}
    </div>
  );
}

