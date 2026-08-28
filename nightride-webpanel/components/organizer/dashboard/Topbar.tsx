"use client";

import Link from "next/link";
import { useRouter, usePathname } from "next/navigation";
import { useState } from "react";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { findNavItem } from "./nav-items";

export function Topbar({ onMenuClick: _onMenuClick }: { onMenuClick: () => void }) {
  const pathname = usePathname();
  const router = useRouter();
  const { organizer, inbox, hasUnreadInbox, venueOrder, openNewEvent } = useOrganizerDashboard();
  const [notifOpen, setNotifOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const [search, setSearch] = useState("");

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
      <header
        className="flex h-[72px] shrink-0 items-center gap-4 px-6 box-border"
        style={{ color: "var(--m3-on)" }}
      >
        <div className="min-w-0">
          <h1 className="truncate text-[22px] font-normal" style={{ color: "var(--m3-on)" }}>
            {nav?.title ?? "Organizer Panel"}
          </h1>
          <p className="mt-0.5 truncate text-xs tracking-wide" style={{ color: "var(--m3-onv)" }}>
            {nav?.subtitle}
          </p>
        </div>

        <div className="flex-1" />

        {isEventsPage && (
          <button
            onClick={() => openNewEvent()}
            className="whitespace-nowrap rounded-full px-4 py-2 text-[13px] font-medium transition-opacity hover:opacity-90"
            style={{ background: "var(--m3-pri)", color: "var(--m3-onpri)" }}
          >
            + New Event
          </button>
        )}

        <div
          className="flex h-11 w-[280px] items-center gap-2 rounded-full px-4 box-border"
          style={{ background: "var(--m3-surf3)" }}
        >
          <span className="msi text-xl" style={{ color: "var(--m3-onv)" }}>
            search
          </span>
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search events, guests, venues"
            className="min-w-0 flex-1 bg-transparent text-sm outline-none"
            style={{ color: "var(--m3-on)" }}
          />
        </div>

        <div className="relative z-50">
          <button
            onClick={() => {
              setNotifOpen((v) => !v);
              setProfileOpen(false);
            }}
            className="relative flex h-12 w-12 items-center justify-center rounded-full transition-colors hover:opacity-80"
            style={{ color: "var(--m3-onv)" }}
            aria-label="Notifications"
          >
            <span className="msi text-2xl">notifications</span>
            {hasUnreadInbox && (
              <span
                className="absolute right-2.5 top-2.5 h-2 w-2 rounded-full"
                style={{ background: "var(--m3-err)" }}
              />
            )}
          </button>
          {notifOpen && (
            <div
              className="absolute right-0 top-[50px] w-[300px] overflow-hidden rounded-xl shadow-2xl"
              style={{ background: "var(--m3-surf2)" }}
            >
              <p
                className="border-b px-3.5 py-3 text-xs font-semibold"
                style={{ borderColor: "var(--m3-outlinev)", color: "var(--m3-on)" }}
              >
                Notifications
              </p>
              {inbox.length === 0 ? (
                <p className="px-3.5 py-3.5 text-xs" style={{ color: "var(--m3-onv)" }}>
                  No messages.
                </p>
              ) : (
                inbox.slice(0, 3).map((m) => (
                  <button
                    key={m.id}
                    onClick={() => {
                      closeMenus();
                      router.push("/organizer/inbox");
                    }}
                    className="block w-full border-b px-3.5 py-2.5 text-left hover:opacity-80"
                    style={{ borderColor: "var(--m3-outlinev)" }}
                  >
                    <span className="block text-xs font-semibold" style={{ color: "var(--m3-on)" }}>
                      {m.subject}
                    </span>
                    <span className="mt-0.5 block text-[11px]" style={{ color: "var(--m3-onv)" }}>
                      {m.from} · {m.date}
                    </span>
                  </button>
                ))
              )}
              <Link
                href="/organizer/inbox"
                onClick={closeMenus}
                className="block px-3.5 py-2.5 text-xs font-semibold hover:opacity-80"
                style={{ color: "var(--m3-pri)" }}
              >
                View all in Inbox
              </Link>
            </div>
          )}
        </div>

        <button
          className="flex h-12 w-12 items-center justify-center rounded-full transition-colors hover:opacity-80"
          style={{ color: "var(--m3-onv)" }}
          aria-label="Help"
        >
          <span className="msi text-2xl">help</span>
        </button>

        <div className="relative z-50">
          <button
            onClick={() => {
              setProfileOpen((v) => !v);
              setNotifOpen(false);
            }}
            className="flex h-10 w-10 items-center justify-center rounded-full font-mono text-[13px] font-semibold"
            style={{ background: "var(--m3-terc)", color: "var(--m3-onterc)" }}
            aria-label="Account menu"
          >
            {organizer.initials}
          </button>
          {profileOpen && (
            <div
              className="absolute right-0 top-[50px] w-[220px] overflow-hidden rounded-xl shadow-2xl"
              style={{ background: "var(--m3-surf2)" }}
            >
              <div className="border-b px-3.5 py-3" style={{ borderColor: "var(--m3-outlinev)" }}>
                <p className="text-[13px] font-semibold" style={{ color: "var(--m3-on)" }}>
                  {organizer.name}
                </p>
                <p className="mt-0.5 text-[11px]" style={{ color: "var(--m3-onv)" }}>
                  {venueOrder.length} venue{venueOrder.length === 1 ? "" : "s"} assigned
                </p>
              </div>
              <Link
                href="/organizer/team"
                onClick={closeMenus}
                className="block px-3.5 py-2.5 text-xs hover:opacity-80"
                style={{ color: "var(--m3-on)" }}
              >
                Team &amp; Access
              </Link>
              <Link
                href="/organizer/settings"
                onClick={closeMenus}
                className="block px-3.5 py-2.5 text-xs hover:opacity-80"
                style={{ color: "var(--m3-on)" }}
              >
                Settings
              </Link>
              <button
                onClick={closeMenus}
                className="block w-full border-t px-3.5 py-2.5 text-left text-xs hover:opacity-80"
                style={{ borderColor: "var(--m3-outlinev)", color: "var(--m3-err)" }}
              >
                Sign out
              </button>
            </div>
          )}
        </div>
      </header>
    </>
  );
}
