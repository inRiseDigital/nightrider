"use client";

import { Flag, Reply } from "lucide-react";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { starsFor } from "@/lib/organizer/dashboard/format";

/** "@mira_k" → "MK", so the avatar reads like the design's initials chip. */
function initialsFor(author: string) {
  const cleaned = author.replace(/^@/, "").replace(/[._-]+/g, " ");
  const parts = cleaned.split(" ").filter(Boolean);
  const letters = parts.length > 1 ? parts[0][0] + parts[1][0] : cleaned.slice(0, 2);
  return letters.toUpperCase();
}

export function ReviewsSection() {
  const {
    reviews,
    reviewsLoading,
    reviewsError,
    reviewsActionError,
    profile,
    setReviewReply,
    toggleReviewFlag,
    sendReviewReply,
    editPostedReply,
    deletePostedReply,
  } = useOrganizerDashboard();

  if (reviewsLoading) {
    return (
      <div className="flex h-40 items-center justify-center text-[13px] text-[var(--m3-onv)]">
        Loading reviews…
      </div>
    );
  }

  if (reviewsError) {
    return (
      <div className="max-w-[480px] rounded-xl bg-[var(--m3-surf1)] p-5 text-[13px]" style={{ color: "var(--m3-err)" }}>
        {reviewsError}
      </div>
    );
  }

  if (reviews.length === 0) {
    return (
      <div className="max-w-[480px] rounded-xl bg-[var(--m3-surf1)] p-5 text-[13px] text-[var(--m3-onv)]">
        No reviews yet.
      </div>
    );
  }

  return (
    <div className="flex max-w-[820px] flex-col gap-4">
      {reviewsActionError && (
        <p
          className="rounded-xl bg-[var(--m3-surf1)] px-4 py-3 text-[13px]"
          style={{ color: "var(--m3-err)" }}
        >
          {reviewsActionError}
        </p>
      )}
      {reviews.map((r) => {
        const canSend = r.reply.trim().length > 0;
        return (
          <div key={r.id} className="rounded-xl bg-[var(--m3-surf1)] p-5">
            <div className="flex items-center gap-3">
              <div
                className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-sm font-medium"
                style={{ background: "var(--m3-terc)", color: "var(--m3-onterc)" }}
              >
                {initialsFor(r.author)}
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-medium text-[var(--m3-on)]">{r.author}</p>
                <p className="font-mono text-xs text-[var(--m3-onv)]">{starsFor(r.rating)}</p>
              </div>
              <button
                onClick={() => toggleReviewFlag(r.id)}
                aria-pressed={r.flagged}
                className="flex h-8 shrink-0 items-center gap-1.5 rounded-lg border px-3 text-[13px] font-medium transition-colors"
                style={
                  r.flagged
                    ? { borderColor: "var(--m3-err)", color: "var(--m3-err)" }
                    : { borderColor: "var(--m3-outline)", color: "var(--m3-onv)" }
                }
              >
                <Flag size={15} fill={r.flagged ? "currentColor" : "none"} />
                {r.flagged ? "Flagged" : "Flag"}
              </button>
            </div>

            <p className="my-3.5 text-sm leading-[21px] tracking-[0.25px] text-[var(--m3-onv)]">
              {r.text}
            </p>

            {r.posted && (
              <div className="mb-3.5 flex gap-3 rounded-xl bg-[var(--m3-surf3)] px-4 py-3.5">
                <Reply size={17} className="mt-0.5 shrink-0" color="var(--m3-pri)" />
                <div className="min-w-0 flex-1">
                  <p className="text-xs font-medium tracking-[0.4px] text-[var(--m3-onv)]">
                    {profile.name} replied · {r.postedWhen}
                  </p>
                  <p className="mt-1.5 text-sm leading-[21px] text-[var(--m3-on)]">{r.posted}</p>
                  <div className="mt-2.5 flex gap-4">
                    <button
                      onClick={() => editPostedReply(r.id)}
                      className="text-[13px] font-medium text-[var(--m3-pri)] hover:underline"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => deletePostedReply(r.id)}
                      className="text-[13px] font-medium text-[var(--m3-err)] hover:underline"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            )}

            <div className="flex items-center gap-3">
              <input
                value={r.reply}
                onChange={(e) => setReviewReply(r.id, e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && canSend) sendReviewReply(r.id);
                }}
                placeholder="Reply publicly as the venue…"
                className="min-w-0 flex-1 rounded-full border-none px-4 py-3 text-sm outline-none"
                style={{ background: "var(--m3-surf3)", color: "var(--m3-on)" }}
              />
              <button
                onClick={() => sendReviewReply(r.id)}
                disabled={!canSend}
                className="h-10 shrink-0 rounded-full px-5 text-sm font-medium transition-opacity"
                style={{
                  background: "var(--m3-pric)",
                  color: "var(--m3-onpric)",
                  opacity: canSend ? 1 : 0.38,
                }}
              >
                {r.posted ? "Update" : "Send"}
              </button>
            </div>
          </div>
        );
      })}
    </div>
  );
}
