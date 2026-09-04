"use client";

import { useEffect } from "react";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";

/** How long a message sits before it clears itself. */
const AUTO_DISMISS_MS = 5000;

/**
 * M3 snackbar — one instance for the whole dashboard, anchored bottom-left
 * clear of the nav rail. Every mutation that changes something a guest or
 * teammate would notice confirms itself here.
 */
export function Snackbar() {
  const { snack, dismissSnack } = useOrganizerDashboard();

  useEffect(() => {
    if (!snack) return;
    const timer = setTimeout(dismissSnack, AUTO_DISMISS_MS);
    return () => clearTimeout(timer);
  }, [snack, dismissSnack]);

  if (!snack) return null;
  const isError = snack.tone === "error";

  return (
    <div
      role="status"
      aria-live="polite"
      className="fixed bottom-6 left-[112px] z-[80] flex min-w-[344px] max-w-[520px] items-center gap-4 rounded px-4 py-3.5 shadow-[0_4px_12px_rgba(0,0,0,0.5)]"
      style={
        isError
          ? { background: "var(--m3-errc)", color: "var(--m3-onerrc)" }
          : { background: "var(--m3-on)", color: "#1B1B1C" }
      }
    >
      <p className="flex-1 text-sm leading-5 tracking-[0.25px]">{snack.text}</p>
      <button
        type="button"
        onClick={dismissSnack}
        className="shrink-0 text-sm font-medium"
        style={{ color: isError ? "var(--m3-onerrc)" : "var(--m3-pric)" }}
      >
        Dismiss
      </button>
    </div>
  );
}
