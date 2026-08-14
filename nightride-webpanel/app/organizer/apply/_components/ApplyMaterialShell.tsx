"use client";

import { useEffect, useState, type CSSProperties, type ReactNode } from "react";
import { Roboto, Roboto_Mono } from "next/font/google";
import { cn } from "@/components/organizer/ui/cn";

const roboto = Roboto({ weight: ["400", "500", "700"], subsets: ["latin"], variable: "--font-roboto" });
const robotoMono = Roboto_Mono({ weight: ["400", "500"], subsets: ["latin"], variable: "--font-roboto-mono" });

type Theme = "dark" | "light";

const THEME_STORAGE_KEY = "nr-organizer-apply-theme";

/**
 * Material 3 shell for the organizer application flow. Owns the light/dark
 * toggle and font swap (Anton stays for the wordmark, Roboto replaces Geist
 * for body/mono text) — both scoped to this route via .apply-material in
 * material.css, so /organizer/login and the dashboard are unaffected.
 */
export function ApplyMaterialShell({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>(() => {
    if (typeof window === "undefined") return "dark";
    const stored = window.localStorage.getItem(THEME_STORAGE_KEY);
    return stored === "dark" || stored === "light" ? stored : "dark";
  });

  useEffect(() => {
    window.localStorage.setItem(THEME_STORAGE_KEY, theme);
  }, [theme]);

  return (
    <div
      data-theme={theme}
      suppressHydrationWarning
      className={cn(
        "apply-material flex h-full min-h-0 flex-1 flex-col overflow-hidden",
        roboto.variable,
        robotoMono.variable
      )}
      style={{ "--font-sans": "var(--font-roboto)", "--font-mono": "var(--font-roboto-mono)" } as CSSProperties}
    >
      <header className="flex h-16 shrink-0 items-center justify-between px-6" style={{ background: "var(--surf2)" }}>
        <div className="flex items-center gap-3.5">
          <div className="font-display text-[22px] tracking-[0.04em]">
            <span style={{ color: "var(--pri)" }}>NIGHT</span>
            <span style={{ color: "var(--on)" }}>RIDE</span>
          </div>
          <div className="h-[22px] w-px" style={{ background: "var(--outlinev)" }} />
          <div className="text-base" style={{ color: "var(--onv)" }}>
            Organizer application
          </div>
        </div>

        <div className="flex items-center gap-0.5 rounded-full p-1" style={{ background: "var(--surf3)" }}>
          <ThemePill label="Dark" active={theme === "dark"} onClick={() => setTheme("dark")} />
          <ThemePill label="Light" active={theme === "light"} onClick={() => setTheme("light")} />
        </div>
      </header>

      {children}
    </div>
  );
}

function ThemePill({ label, active, onClick }: { label: string; active: boolean; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="rounded-full px-4 py-1.5 text-[13px] font-medium transition-colors"
      style={{
        background: active ? "var(--pri)" : "transparent",
        color: active ? "var(--onpri)" : "var(--onv)",
      }}
    >
      {label}
    </button>
  );
}
