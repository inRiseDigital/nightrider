"use client";

import { useCallback, useMemo, useState } from "react";
import { MOCK_INBOX } from "../mock-data";
import type { InboxMessage } from "../types";

/** `users/{uid}/inbox`. Admin-create, recipient update limited to `readAt`. */
export function useInbox() {
  const [inbox, setInbox] = useState<InboxMessage[]>(MOCK_INBOX);

  const toggleInboxItem = useCallback((id: string) => {
    setInbox((p) => p.map((m) => (m.id === id ? { ...m, open: !m.open } : m)));
  }, []);

  const hasUnreadInbox = inbox.some((m) => !m.open);
  const data = useMemo(() => ({ inbox, hasUnreadInbox }), [inbox, hasUnreadInbox]);

  return useMemo(
    () => ({ data, loading: false, error: null, busy: false, actionError: "", toggleInboxItem }),
    [data, toggleInboxItem]
  );
}

export type InboxState = ReturnType<typeof useInbox>;
