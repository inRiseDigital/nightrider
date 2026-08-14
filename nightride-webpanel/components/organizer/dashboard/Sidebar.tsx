"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { X } from "lucide-react";
import { cn } from "@/components/admin/ui/cn";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { ORGANIZER_NAV_GROUPS } from "./nav-items";

export function Sidebar({ mobileOpen, onClose }: { mobileOpen: boolean; onClose: () => void }) {
  const pathname = usePathname();
  const { events } = useOrganizerDashboard();

  const liveCount = events.filter(
    (e) => e.status === "live" || e.status === "scheduled"
  ).length;

  const content = (
    <nav className="flex h-full flex-col overflow-y-auto px-4 py-6">
      <div className="mb-5 flex items-start justify-between border-b border-nr-border px-2 pb-6">
        <Link href="/organizer/dashboard" onClick={onClose}>
          <span className="font-display text-[22px] leading-none tracking-wide">
            <span className="text-nr-accent">NIGHT</span>
            <span className="text-nr-text-primary">RITE</span>
          </span>
          <span className="mt-1.5 block font-mono text-[11px] tracking-[0.15em] text-nr-text-hint">
            ORGANIZER PANEL
          </span>
        </Link>
        <button
          onClick={onClose}
          className="text-nr-text-hint hover:text-nr-text-primary md:hidden"
          aria-label="Close navigation"
        >
          <X size={20} />
        </button>
      </div>

      {ORGANIZER_NAV_GROUPS.map((group) => (
        <div key={group.label} className="mb-5">
          <p className="px-2 pb-2 font-mono text-[10px] tracking-[0.15em] text-nr-text-hint">
            {group.label}
          </p>
          {group.items.map((item) => {
            const active = pathname === item.href || pathname?.startsWith(item.href + "/");
            const badge = item.badge === "liveEvents" ? String(liveCount) : null;
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onClose}
                aria-current={active ? "page" : undefined}
                className="mb-0.5 flex items-center justify-between gap-2.5 rounded-lg px-2.5 py-2.5 transition-colors hover:bg-white/5"
              >
                <span className="flex items-center gap-2.5">
                  <span
                    className={cn(
                      "h-1.5 w-1.5 shrink-0 rounded-sm",
                      active ? "bg-nr-accent" : "bg-nr-border"
                    )}
                  />
                  <span
                    className={cn(
                      "text-sm font-medium",
                      active ? "text-nr-text-primary" : "text-nr-text-secondary"
                    )}
                  >
                    {item.label}
                  </span>
                </span>
                {badge && (
                  <span className="rounded-full border border-nr-accent/30 bg-nr-accent/10 px-1.5 py-0.5 font-mono text-[10px] font-bold text-nr-accent">
                    {badge}
                  </span>
                )}
              </Link>
            );
          })}
        </div>
      ))}
    </nav>
  );

  return (
    <>
      <aside className="hidden w-[260px] shrink-0 border-r border-nr-border bg-nr-surface md:block">
        {content}
      </aside>
      {mobileOpen && (
        <div className="fixed inset-0 z-40 flex md:hidden">
          <div className="absolute inset-0 bg-black/70" onClick={onClose} />
          <div className="relative w-[260px] border-r border-nr-border bg-nr-surface">{content}</div>
        </div>
      )}
    </>
  );
}
