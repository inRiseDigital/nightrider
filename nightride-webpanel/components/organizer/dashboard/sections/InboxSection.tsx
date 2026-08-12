"use client";

import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { INBOX_TYPE_STYLES } from "@/lib/organizer/dashboard/constants";
import { StatusChip } from "../ui/StatusChip";

export function InboxSection() {
  const { inbox, toggleInboxItem } = useOrganizerDashboard();

  return (
    <div className="overflow-hidden rounded-lg border border-nr-border bg-nr-surface">
      {inbox.map((m) => {
        const type = INBOX_TYPE_STYLES[m.type];
        return (
          <div key={m.id} className="border-b border-nr-border/60 last:border-b-0">
            <button
              onClick={() => toggleInboxItem(m.id)}
              aria-expanded={m.open}
              className="flex w-full items-center gap-3.5 px-[18px] py-3.5 text-left hover:bg-white/[0.02]"
            >
              <StatusChip label={type.label} className={type.className} size="sm" />
              <span className="min-w-0 flex-1">
                <span className="block text-[13px] font-semibold text-nr-text-primary">
                  {m.subject}
                </span>
                <span className="mt-px block text-[11px] text-nr-text-hint">
                  {m.from} · {m.date}
                </span>
              </span>
            </button>
            {m.open && (
              <p className="bg-nr-surface-raised px-[18px] py-3.5 text-xs text-nr-text-secondary">
                {m.body}
              </p>
            )}
          </div>
        );
      })}
    </div>
  );
}
