"use client";

import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { INBOX_TYPE_STYLES } from "@/lib/organizer/dashboard/constants";
import { StatusChip } from "../ui/StatusChip";

export function InboxSection() {
  const { inbox, inboxLoading, inboxError, toggleInboxItem } = useOrganizerDashboard();

  if (inboxLoading) {
    return (
      <div className="flex h-40 items-center justify-center text-[13px] text-[var(--m3-onv)]">
        Loading inbox…
      </div>
    );
  }

  if (inboxError) {
    return (
      <div className="max-w-[480px] rounded-lg bg-[var(--m3-surf1)] p-5 text-[13px]" style={{ color: "var(--m3-err)" }}>
        {inboxError}
      </div>
    );
  }

  if (inbox.length === 0) {
    return (
      <div className="max-w-[480px] rounded-lg bg-[var(--m3-surf1)] p-5 text-[13px] text-[var(--m3-onv)]">
        No messages.
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)]">
      {inbox.map((m) => {
        const type = INBOX_TYPE_STYLES[m.type];
        return (
          <div key={m.id} className="border-b border-[var(--m3-outlinev)] last:border-b-0">
            <button
              onClick={() => toggleInboxItem(m.id)}
              aria-expanded={m.open}
              className="flex w-full items-center gap-3.5 px-[18px] py-3.5 text-left hover:bg-white/[0.02]"
            >
              <StatusChip label={type.label} className={type.className} size="sm" />
              <span className="min-w-0 flex-1">
                <span className="block text-[13px] font-semibold text-[var(--m3-on)]">
                  {m.subject}
                </span>
                <span className="mt-px block text-[11px] text-[var(--m3-outline)]">
                  {m.from} · {m.date}
                </span>
              </span>
            </button>
            {m.open && (
              <p className="bg-[var(--m3-surf2)] px-[18px] py-3.5 text-xs text-[var(--m3-onv)]">
                {m.body}
              </p>
            )}
          </div>
        );
      })}
    </div>
  );
}
