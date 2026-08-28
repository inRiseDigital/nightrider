"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { ORGANIZER_NAV_GROUPS } from "./nav-items";

/**
 * 88px Material icon rail + slide-out drawer, per the design's nav pattern.
 *
 * The rail shows one icon per nav group (its first item is the rail
 * destination); the hamburger button always opens the full grouped drawer.
 * `drawerOpen` is lifted to DashboardShell since both the rail's own
 * hamburger and the topbar's mobile menu button open the same drawer.
 */
export function Sidebar({
  drawerOpen,
  onOpen,
  onClose,
}: {
  drawerOpen: boolean;
  onOpen: () => void;
  onClose: () => void;
}) {
  const pathname = usePathname();
  const { events, organizer, openNewEvent } = useOrganizerDashboard();
  const isActiveHref = (href: string) => pathname === href || pathname?.startsWith(href + "/");
  const liveCount = events.filter((e) => e.status === "live" || e.status === "scheduled").length;

  const drawer = (
    <nav className="flex h-full w-[300px] flex-col overflow-y-auto px-3 py-4 sm:w-[344px]">
      <div className="mb-2 flex items-center gap-3 px-4 pb-5 pt-2">
        <span className="font-display text-xl tracking-wide">
          <span style={{ color: "var(--m3-pri)" }}>NIGHT</span>
          <span style={{ color: "var(--m3-on)" }}>RIDE</span>
        </span>
        <span
          className="rounded-full px-2 py-0.5 text-xs tracking-wide"
          style={{ background: "var(--m3-surf3)", color: "var(--m3-onv)" }}
        >
          Organizer
        </span>
      </div>

      {ORGANIZER_NAV_GROUPS.map((group) => (
        <div key={group.label} className="mb-3">
          <p
            className="px-4 pb-2 text-[11px] font-medium uppercase tracking-widest"
            style={{ color: "var(--m3-onv)" }}
          >
            {group.label}
          </p>
          {group.items.map((item) => {
            const active = isActiveHref(item.href);
            const badge = item.badge === "liveEvents" ? String(liveCount) : null;
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onClose}
                aria-current={active ? "page" : undefined}
                className="mb-0.5 flex h-14 items-center gap-3 rounded-full px-4 transition-colors hover:opacity-90"
                style={{
                  background: active ? "var(--m3-surf3)" : "transparent",
                  color: active ? "var(--m3-pri)" : "var(--m3-on)",
                }}
              >
                <span className="msi text-[22px]">{item.icon}</span>
                <span className="flex-1 text-sm font-medium">{item.label}</span>
                {badge && (
                  <span className="font-mono text-xs" style={{ color: "var(--m3-onv)" }}>
                    {badge}
                  </span>
                )}
              </Link>
            );
          })}
          <div className="mx-4 mt-2 h-px" style={{ background: "var(--m3-outlinev)" }} />
        </div>
      ))}
    </nav>
  );

  const rail = (
    <div
      className="flex h-full w-[88px] shrink-0 flex-col items-center py-3"
      style={{ background: "var(--m3-surf)" }}
    >
      <button
        onClick={onOpen}
        title="All sections"
        aria-label="Open navigation"
        className="mb-2 flex h-12 w-12 items-center justify-center rounded-full transition-colors hover:opacity-80"
        style={{ color: "var(--m3-onv)" }}
      >
        <span className="msi text-2xl">menu</span>
      </button>

      <button
        onClick={() => openNewEvent()}
        title="New event"
        aria-label="New event"
        className="mb-5 flex h-14 w-14 items-center justify-center rounded-2xl shadow-md transition-shadow hover:shadow-lg"
        style={{ background: "var(--m3-pric)", color: "var(--m3-onpric)" }}
      >
        <span className="msi text-2xl">add</span>
      </button>

      {ORGANIZER_NAV_GROUPS.map((group) => {
        const rep = group.items[0];
        const active = group.items.some((it) => isActiveHref(it.href));
        return (
          <Link
            key={group.label}
            href={rep.href}
            title={group.label}
            className="mb-3 flex w-full flex-col items-center gap-1 px-1"
          >
            <span
              className="flex h-8 w-14 items-center justify-center rounded-full transition-colors"
              style={{
                background: active ? "var(--m3-pri)" : "transparent",
                color: active ? "var(--m3-onpri)" : "var(--m3-onv)",
              }}
            >
              <span className="msi text-2xl">{group.icon}</span>
            </span>
            <span
              className="text-center text-[11px] font-medium leading-tight tracking-wide"
              style={{ color: active ? "var(--m3-on)" : "var(--m3-onv)" }}
            >
              {group.label.charAt(0) + group.label.slice(1).toLowerCase()}
            </span>
          </Link>
        );
      })}

      <div className="flex-1" />
      <div
        className="flex h-10 w-10 items-center justify-center rounded-full text-sm font-medium"
        style={{ background: "var(--m3-terc)", color: "var(--m3-onterc)" }}
      >
        {organizer.initials}
      </div>
    </div>
  );

  return (
    <>
      <aside className="w-[88px] shrink-0" style={{ background: "var(--m3-surf)" }}>
        {rail}
      </aside>
      {drawerOpen && (
        <div className="fixed inset-0 z-40 flex">
          <div className="absolute inset-0 bg-black/55" onClick={onClose} />
          <div
            className="relative h-full rounded-r-2xl"
            style={{ background: "var(--m3-surf1)" }}
          >
            {drawer}
          </div>
        </div>
      )}
    </>
  );
}
