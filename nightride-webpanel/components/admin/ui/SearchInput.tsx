"use client";

import { Search } from "lucide-react";
import { cn } from "./cn";

export function SearchInput({
  value,
  onChange,
  placeholder = "Search...",
  className,
}: {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  className?: string;
}) {
  return (
    <div className={cn("relative", className)}>
      <Search size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-nr-text-hint" />
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full rounded-lg border border-nr-border bg-nr-surface-raised py-2 pl-9 pr-3 text-sm text-nr-text-primary placeholder:text-nr-text-hint focus:border-nr-primary-light focus:outline-none focus:ring-1 focus:ring-nr-primary-light"
      />
    </div>
  );
}
