"use client";

import { Check } from "lucide-react";
import { cn } from "@/components/organizer/ui/cn";
import { checkPasswordRules } from "@/lib/organizer/validation";

/**
 * Shows every password rule at once rather than surfacing them one failure at a
 * time — the error box only ever names the first unmet rule.
 */
export function PasswordRequirements({ password }: { password: string }) {
  const rules = checkPasswordRules(password);

  return (
    <ul className="mt-2 grid grid-cols-2 gap-x-3 gap-y-1" aria-label="Password requirements">
      {rules.map((rule) => (
        <li
          key={rule.id}
          className={cn(
            "flex items-center gap-1.5 font-mono text-[10px] transition-colors",
            rule.met ? "text-emerald-400" : "text-nr-text-hint"
          )}
        >
          {rule.met ? (
            <Check size={11} strokeWidth={3} className="shrink-0" aria-hidden />
          ) : (
            <span className="h-[3px] w-[3px] shrink-0 rounded-full bg-current" aria-hidden />
          )}
          <span>{rule.label}</span>
          <span className="sr-only">{rule.met ? " — met" : " — not met"}</span>
        </li>
      ))}
    </ul>
  );
}
