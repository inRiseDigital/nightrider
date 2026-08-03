"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { X } from "lucide-react";
import { cn } from "../ui/cn";
import { ADMIN_NAV_ITEMS } from "./nav-items";

export function Sidebar({ mobileOpen, onClose }: { mobileOpen: boolean; onClose: () => void }) {
  const pathname = usePathname();

  const content = (
    <nav className="flex h-full flex-col">
      <div className="flex items-center justify-between px-5 py-6">
        <Link href="/admin/dashboard" className="flex items-center gap-2">
          <span className="font-display text-xl tracking-widest text-nr-text-primary">
            NIGHT<span className="text-nr-primary">RIDE</span>
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
      <p className="px-5 pb-2 text-xs font-medium uppercase tracking-wider text-nr-text-hint">Admin Panel</p>
      <div className="flex-1 space-y-1 overflow-y-auto px-3">
        {ADMIN_NAV_ITEMS.map((item) => {
          const active = pathname === item.href || pathname?.startsWith(item.href + "/");
          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={onClose}
              className={cn(
                "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                active
                  ? "bg-nr-primary/10 text-nr-primary-light"
                  : "text-nr-text-secondary hover:bg-white/5 hover:text-nr-text-primary"
              )}
            >
              <item.icon size={18} />
              {item.label}
            </Link>
          );
        })}
      </div>
      <div className="px-5 py-4 text-xs text-nr-text-hint">
        Frontend prototype &middot; mock data only
      </div>
    </nav>
  );

  return (
    <>
      <aside className="hidden w-64 shrink-0 border-r border-nr-border bg-nr-surface md:flex">{content}</aside>
      {mobileOpen && (
        <div className="fixed inset-0 z-40 flex md:hidden">
          <div className="absolute inset-0 bg-black/70" onClick={onClose} />
          <div className="relative w-64 border-r border-nr-border bg-nr-surface">{content}</div>
        </div>
      )}
    </>
  );
}
