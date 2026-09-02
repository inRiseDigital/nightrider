"use client";

import { useCallback, useMemo, useState } from "react";
import { MOCK_REVIEWS } from "../mock-data";
import type { VenueReview } from "../types";

/** `venueReports` for the organizer's venues. */
export function useReviews(showSnack: (text: string, tone?: "info" | "error") => void) {
  const [reviews, setReviews] = useState<VenueReview[]>(MOCK_REVIEWS);

  const setReviewReply = useCallback((id: string, value: string) => {
    setReviews((p) => p.map((r) => (r.id === id ? { ...r, reply: value } : r)));
  }, []);

  const toggleReviewFlag = useCallback(
    (id: string) => {
      const wasFlagged = reviews.find((r) => r.id === id)?.flagged;
      setReviews((p) => p.map((r) => (r.id === id ? { ...r, flagged: !r.flagged } : r)));
      showSnack(wasFlagged ? "Report withdrawn." : "Review reported to Trust & Safety.");
    },
    [reviews, showSnack]
  );

  const sendReviewReply = useCallback(
    (id: string) => {
      const target = reviews.find((r) => r.id === id);
      if (!target?.reply.trim()) {
        showSnack("Write a reply first.");
        return;
      }
      const today = new Date().toLocaleDateString("en-US", { month: "short", day: "numeric" });
      setReviews((p) => p.map((r) => (r.id === id && r.reply.trim() ? { ...r, posted: r.reply.trim(), postedWhen: today, reply: "" } : r)));
      showSnack(target.posted ? "Reply updated." : "Reply posted publicly.");
    },
    [reviews, showSnack]
  );

  const editPostedReply = useCallback((id: string) => {
    setReviews((p) => p.map((r) => (r.id === id ? { ...r, reply: r.posted, posted: "", postedWhen: "" } : r)));
  }, []);

  const deletePostedReply = useCallback(
    (id: string) => {
      setReviews((p) => p.map((r) => (r.id === id ? { ...r, posted: "", postedWhen: "" } : r)));
      showSnack("Reply removed.");
    },
    [showSnack]
  );

  const data = useMemo(() => ({ reviews }), [reviews]);

  return useMemo(
    () => ({ data, loading: false, error: null, busy: false, actionError: "", setReviewReply, toggleReviewFlag, sendReviewReply, editPostedReply, deletePostedReply }),
    [data, setReviewReply, toggleReviewFlag, sendReviewReply, editPostedReply, deletePostedReply]
  );
}

export type ReviewsState = ReturnType<typeof useReviews>;
