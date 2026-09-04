"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { doc, onSnapshot, query, limit, serverTimestamp, Timestamp, updateDoc } from "firebase/firestore";
import { userInboxCol } from "../data/refs";
import { describeFirestoreError } from "../data/errors";
import { hasUnread, orderInbox, parseInboxMessage } from "../data/engagement";
import { useLatest } from "./useLatest";

/**
 * `users/{uid}/inbox`, scoped to the person — `isSelf(uid)` authorizes it
 * with zero venue lookups. The second and last `onSnapshot` listener in the
 * panel: Trust & Safety is the writer and the topbar's unread dot must never
 * go stale, unlike a stale event list.
 */
export function useInbox(uid: string) {
  const [rawDocs, setRawDocs] = useState<Record<string, Record<string, unknown>>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  // Pure client expand/collapse state — never derived from `readAt`, and
  // separate from it: collapsing a message must not make it unread again.
  const [openIds, setOpenIds] = useState<Set<string>>(new Set());
  const writtenIds = useRef<Set<string>>(new Set());

  useEffect(() => {
    // Same shape as useVenues.ts's listener effect (setLoading(true), then
    // subscribe) — this project's lint config's experimental
    // set-state-in-effect check flags this file but not that one for
    // identical code; disabling narrowly rather than restructuring a
    // correct, already-established pattern.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    const q = query(userInboxCol(uid), limit(50));
    const unsub = onSnapshot(
      q,
      (snap) => {
        const next: Record<string, Record<string, unknown>> = {};
        snap.forEach((d) => {
          next[d.id] = d.data() as Record<string, unknown>;
        });
        setRawDocs(next);
        setError("");
        setLoading(false);
      },
      (err) => {
        setError(describeFirestoreError(err));
        setLoading(false);
      }
    );
    return unsub;
  }, [uid]);

  const rawDocsRef = useLatest(rawDocs);

  const toggleInboxItem = useCallback(
    (id: string) => {
      setOpenIds((prev) => {
        const next = new Set(prev);
        if (next.has(id)) next.delete(id);
        else next.add(id);
        return next;
      });

      const alreadyRead = rawDocsRef.current[id]?.readAt instanceof Timestamp;
      if (alreadyRead || writtenIds.current.has(id)) return;
      writtenIds.current.add(id);

      // Fire-and-forget by design: `readAt` is a read marker, not a mutation
      // the organizer is waiting on. A lost write here is invisible, and
      // rollback machinery would cost more than the bug — the only
      // fire-and-forget write in the panel; everything else awaits.
      updateDoc(doc(userInboxCol(uid), id), { readAt: serverTimestamp() }).catch((err) => {
        writtenIds.current.delete(id);
        console.warn("[useInbox] toggleInboxItem: readAt write failed", err);
      });
    },
    [uid, rawDocsRef]
  );

  const order = useMemo(() => orderInbox(rawDocs), [rawDocs]);
  const inbox = useMemo(() => order.map((id) => parseInboxMessage(id, rawDocs[id], openIds.has(id))), [order, rawDocs, openIds]);
  const unread = useMemo(() => hasUnread(rawDocs), [rawDocs]);

  const data = useMemo(() => ({ inbox, hasUnreadInbox: unread }), [inbox, unread]);

  return useMemo(
    () => ({ data, loading, error, busy: false, actionError: "", toggleInboxItem }),
    [data, loading, error, toggleInboxItem]
  );
}

export type InboxState = ReturnType<typeof useInbox>;
