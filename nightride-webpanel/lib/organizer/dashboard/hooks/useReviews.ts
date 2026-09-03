"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { doc, getDocs, query, serverTimestamp, updateDoc, where } from "firebase/firestore";
import { venueReportsCol } from "../data/refs";
import { describeFirestoreError } from "../data/errors";
import { orderReviews, parseVenueReview } from "../data/engagement";
import type { OrganizerProfile } from "../types";
import { useAsyncAction } from "./useAsyncAction";
import { useLatest } from "./useLatest";

/**
 * `venueReports` for every venue the organizer edits. One-shot `getDocs` per
 * venue id (not a listener — see task-10 brief), refetched after every write.
 * Flagging is a request for admin attention, not a removal: `flaggedByOwner`
 * never hides a report, and only an admin ever deletes one.
 */
export function useReviews(
  venueIds: string[],
  organizer: OrganizerProfile,
  uid: string,
  showSnack: (text: string, tone?: "info" | "error") => void
) {
  const [rawDocs, setRawDocs] = useState<Record<string, Record<string, unknown>>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  // Local composer state — `reply` in `VenueReview` is a draft, never itself
  // persisted. `editingIds` blanks the posted reply in the mapped view while
  // an edit is staged, without writing anything until `sendReviewReply`.
  const [draftReplies, setDraftReplies] = useState<Record<string, string>>({});
  const [editingIds, setEditingIds] = useState<Set<string>>(new Set());

  const venueIdsKey = venueIds.join(",");

  const fetchReviews = useCallback(async () => {
    setLoading(true);
    try {
      const chunks =
        venueIds.length === 0
          ? []
          : await Promise.all(venueIds.map((id) => getDocs(query(venueReportsCol(), where("venueId", "==", id)))));
      const next: Record<string, Record<string, unknown>> = {};
      for (const snap of chunks) {
        snap.forEach((d) => {
          next[d.id] = d.data() as Record<string, unknown>;
        });
      }
      setRawDocs(next);
      setError("");
    } catch (err) {
      setError(describeFirestoreError(err));
    } finally {
      setLoading(false);
    }
    // `venueIds` is re-derived every render from `venues.data.order`; the
    // joined key is the stable dependency so this doesn't refetch on every
    // parent re-render, only when the actual venue set changes.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [venueIdsKey]);

  useEffect(() => {
    fetchReviews();
  }, [fetchReviews]);

  const rawDocsRef = useLatest(rawDocs);
  const { busy, actionError, run } = useAsyncAction(fetchReviews);

  const setReviewReply = useCallback((id: string, value: string) => {
    setDraftReplies((p) => ({ ...p, [id]: value }));
  }, []);

  const toggleReviewFlag = useCallback(
    async (id: string) => {
      const next = !(rawDocsRef.current[id]?.flaggedByOwner === true);
      const ok = await run(async () => {
        await updateDoc(doc(venueReportsCol(), id), { flaggedByOwner: next });
      });
      if (ok) showSnack(next ? "Review reported to Trust & Safety." : "Report withdrawn.");
    },
    [rawDocsRef, run, showSnack]
  );

  const sendReviewReply = useCallback(
    async (id: string) => {
      const text = (draftReplies[id] ?? "").trim();
      if (!text) {
        showSnack("Write a reply first.");
        return;
      }
      const reply = rawDocsRef.current[id]?.reply as { text?: unknown } | null | undefined;
      const hadPosted = typeof reply?.text === "string" && reply.text.length > 0;
      const ok = await run(async () => {
        await updateDoc(doc(venueReportsCol(), id), {
          reply: { text, byUid: uid, byName: organizer.name || "Venue", at: serverTimestamp() },
        });
      });
      if (ok) {
        setDraftReplies((p) => ({ ...p, [id]: "" }));
        setEditingIds((p) => {
          const n = new Set(p);
          n.delete(id);
          return n;
        });
        showSnack(hadPosted ? "Reply updated." : "Reply posted publicly.");
      }
    },
    [draftReplies, rawDocsRef, run, uid, organizer.name, showSnack]
  );

  const editPostedReply = useCallback(
    (id: string) => {
      const reply = rawDocsRef.current[id]?.reply as { text?: unknown } | null | undefined;
      setDraftReplies((p) => ({ ...p, [id]: typeof reply?.text === "string" ? reply.text : "" }));
      setEditingIds((p) => new Set(p).add(id));
    },
    [rawDocsRef]
  );

  const deletePostedReply = useCallback(
    async (id: string) => {
      const ok = await run(async () => {
        await updateDoc(doc(venueReportsCol(), id), { reply: null });
      });
      if (ok) {
        setDraftReplies((p) => ({ ...p, [id]: "" }));
        setEditingIds((p) => {
          const n = new Set(p);
          n.delete(id);
          return n;
        });
        showSnack("Reply removed.");
      }
    },
    [run, showSnack]
  );

  const reviews = useMemo(
    () =>
      orderReviews(rawDocs).map((id) =>
        parseVenueReview(id, rawDocs[id], { draft: draftReplies[id] ?? "", editing: editingIds.has(id) })
      ),
    [rawDocs, draftReplies, editingIds]
  );

  const data = useMemo(() => ({ reviews }), [reviews]);

  return useMemo(
    () => ({
      data,
      loading,
      error,
      busy,
      actionError,
      setReviewReply,
      toggleReviewFlag,
      sendReviewReply,
      editPostedReply,
      deletePostedReply,
    }),
    [data, loading, error, busy, actionError, setReviewReply, toggleReviewFlag, sendReviewReply, editPostedReply, deletePostedReply]
  );
}

export type ReviewsState = ReturnType<typeof useReviews>;
