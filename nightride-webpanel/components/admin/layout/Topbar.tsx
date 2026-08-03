"use client";

import { usePathname } from "next/navigation";
import { Menu, ChevronDown } from "lucide-react";
import { useState } from "react";
import { useAdminData } from "@/lib/admin/store";
import { Avatar } from "../ui/Avatar";
import { ADMIN_NAV_ITEMS } from "./nav-items";
import { ADMIN_ACCESS_LEVEL_LABELS } from "@/lib/admin/constants";

export function Topbar({ onMenuClick }: { onMenuClick: () => void }) {
  const pathname = usePathname();
  const { currentAdmin } = useAdminData();
  const [open, setOpen] = useState(false);

  const current = ADMIN_NAV_ITEMS.find(
    (item) => pathname === item.href || pathname?.startsWith(item.href + "/")
  );

  return (
    <header className="flex items-center justify-between gap-4 border-b border-nr-border bg-nr-bg/80 px-4 py-4 backdrop-blur sm:px-6">
      <div className="flex items-center gap-3">
        <button
          onClick={onMenuClick}
          className="text-nr-text-secondary hover:text-nr-text-primary md:hidden"
          aria-label="Open navigation"
        >
          <Menu size={22} />
        </button>
        <h1 className="font-display text-lg tracking-wide text-nr-text-primary sm:text-xl">
          {current?.label ?? "Admin Panel"}
        </h1>
      </div>

      <div className="relative">
        <button
          onClick={() => setOpen((v) => !v)}
          className="flex items-center gap-2 rounded-full border border-nr-border py-1 pl-1 pr-2.5 hover:border-nr-primary-light/40"
        >
          <Avatar name={currentAdmin.fullName} src={currentAdmin.avatarUrl} size={30} />
          <span className="hidden text-sm font-medium text-nr-text-primary sm:inline">
            {currentAdmin.fullName}
          </span>
          <ChevronDown size={14} className="text-nr-text-hint" />
        </button>
        {open && (
          <div className="absolute right-0 z-30 mt-2 w-56 rounded-xl border border-nr-border bg-nr-surface-raised p-3 shadow-2xl">
            <p className="text-sm font-medium text-nr-text-primary">{currentAdmin.fullName}</p>
            <p className="truncate text-xs text-nr-text-secondary">{currentAdmin.email}</p>
            <p className="mt-2 inline-block rounded-full bg-nr-primary/10 px-2 py-0.5 text-xs text-nr-primary-light">
              {currentAdmin.adminDetails ? ADMIN_ACCESS_LEVEL_LABELS[currentAdmin.adminDetails.accessLevel] : "Admin"}
            </p>
            <p className="mt-3 text-xs text-nr-text-hint">Mock session &middot; no real auth is wired up.</p>
          </div>
        )}
      </div>
    </header>
  );
}
