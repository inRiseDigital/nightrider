"use client";

import Link from "next/link";
import { useRouter, usePathname } from "next/navigation";
import { useState } from "react";
import { Bell, Menu } from "lucide-react";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { findNavItem } from "./nav-items";

export function Topbar({ onMenuClick }: { onMenuClick: () => void }) {
  const pathname = usePathname();
  const router = useRouter();
  const { organizer, inbox, hasUnreadInbox, venueOrder, openNewEvent } = useOrganizerDashboard();
  const [notifOpen, setNotifOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);

  const nav = findNavItem(pathname);
  const isEventsPage = pathname === "/organizer/events";
  const closeMenus = () => {
    setNotifOpen(false);
    setProfileOpen(false);
  };

  return (
    <>
      {(notifOpen || profileOpen) && (
        <div className="fixed inset-0 z-40" onClick={closeMenus} aria-hidden />
      )}
      <header className="flex h-[72px] shrink-0 items-center justify-between gap-4 border-b border-nr-border bg-nr-bg px-5 sm:px-7">
        <div className="flex min-w-0 items-center gap-3">
          <button
            onClick={onMenuClick}
            className="text-nr-text-secondary hover:text-nr-text-primary md:hidden"
            aria-label="Open navigation"
          >
            <Menu size={22} />
          </button>
          <div className="min-w-0">
            <h1 className="truncate font-display text-xl uppercase tracking-wide text-nr-text-primary">
              {nav?.title ?? "Organizer Panel"}
            </h1>
            <p className="truncate text-xs text-nr-text-hint">{nav?.subtitle}</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          {isEventsPage && (
            <button
              onClick={() => openNewEvent()}
              className="whitespace-nowrap rounded-lg bg-nr-accent px-4 py-2.5 text-[13px] font-semibold text-nr-bg transition-colors hover:bg-nr-accent/80"
            >
              + New Event
            </button>
          )}

          <div className="relative z-50">
            <button
              onClick={() => {
                setNotifOpen((v) => !v);
                setProfileOpen(false);
              }}
              className="relative flex h-[34px] w-[34px] items-center justify-center rounded-lg border border-nr-border bg-nr-surface-raised text-nr-text-secondary hover:text-nr-text-primary"
              aria-label="Notifications"
            >
              <Bell size={15} />
              {hasUnreadInbox && (
                <span className="absolute right-1.5 top-1.5 h-1.5 w-1.5 rounded-full bg-nr-primary" />
              )}
            </button>
            {notifOpen && (
              <div className="absolute right-0 top-[42px] w-[300px] overflow-hidden rounded-lg border border-nr-border bg-nr-surface shadow-2xl">
                <p className="border-b border-nr-border px-3.5 py-3 text-xs font-semibold text-nr-text-primary">
                  Notifications
                </p>
                {inbox.length === 0 ? (
                  <p className="px-3.5 py-3.5 text-xs text-nr-text-hint">No messages.</p>
                ) : (
                  inbox.slice(0, 3).map((m) => (
                    <button
                      key={m.id}
                      onClick={() => {
                        closeMenus();
                        router.push("/organizer/inbox");
                      }}
                      className="block w-full border-b border-nr-border/60 px-3.5 py-2.5 text-left hover:bg-white/5"
                    >
                      <span className="block text-xs font-semibold text-nr-text-primary">
                        {m.subject}
                      </span>
                      <span className="mt-0.5 block text-[11px] text-nr-text-hint">
                        {m.from} · {m.date}
                      </span>
                    </button>
                  ))
                )}
                <Link
                  href="/organizer/inbox"
                  onClick={closeMenus}
                  className="block px-3.5 py-2.5 text-xs font-semibold text-nr-primary-light hover:bg-white/5"
                >
                  View all in Inbox
                </Link>
              </div>
            )}
          </div>

          <div className="relative z-50">
            <button
              onClick={() => {
                setProfileOpen((v) => !v);
                setNotifOpen(false);
              }}
              className="flex h-[34px] w-[34px] items-center justify-center rounded-full bg-nr-accent font-mono text-[13px] font-semibold text-nr-bg"
              aria-label="Account menu"
            >
              {organizer.initials}
            </button>
            {profileOpen && (
              <div className="absolute right-0 top-[42px] w-[220px] overflow-hidden rounded-lg border border-nr-border bg-nr-surface shadow-2xl">
                <div className="border-b border-nr-border px-3.5 py-3">
                  <p className="text-[13px] font-semibold text-nr-text-primary">{organizer.name}</p>
                  <p className="mt-0.5 text-[11px] text-nr-text-secondary">
                    {venueOrder.length} venue{venueOrder.length === 1 ? "" : "s"} assigned
                  </p>
                </div>
                <Link
                  href="/organizer/team"
                  onClick={closeMenus}
                  className="block px-3.5 py-2.5 text-xs text-nr-text-primary hover:bg-white/5"
                >
                  Team &amp; Access
                </Link>
                <Link
                  href="/organizer/settings"
                  onClick={closeMenus}
                  className="block px-3.5 py-2.5 text-xs text-nr-text-primary hover:bg-white/5"
                >
                  Settings
                </Link>
                <button
                  onClick={closeMenus}
                  className="block w-full border-t border-nr-border px-3.5 py-2.5 text-left text-xs text-red-400 hover:bg-white/5"
                >
                  Sign out
                </button>
              </div>
            )}
          </div>
        </div>
      </header>
    </>
  );
}
