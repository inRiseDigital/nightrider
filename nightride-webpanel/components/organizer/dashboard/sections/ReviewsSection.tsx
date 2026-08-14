"use client";

import { Flag } from "lucide-react";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { starsFor } from "@/lib/organizer/dashboard/format";
import { SlimInput } from "../ui/Primitives";

export function ReviewsSection() {
  const { reviews, setReviewReply, toggleReviewFlag } = useOrganizerDashboard();

  return (
    <div className="flex flex-col gap-3.5">
      {reviews.map((r) => (
        <div key={r.id} className="rounded-lg border border-nr-border bg-nr-surface p-4">
          <div className="mb-2 flex items-center justify-between gap-3">
            <p className="text-[13px] font-semibold text-nr-text-primary">
              {r.author} · <span className="text-nr-accent">{starsFor(r.rating)}</span>
            </p>
            <button
              onClick={() => toggleReviewFlag(r.id)}
              aria-pressed={r.flagged}
              className={`flex items-center gap-1.5 text-[11px] font-semibold ${
                r.flagged ? "text-red-400" : "text-nr-text-hint hover:text-nr-text-secondary"
              }`}
            >
              <Flag size={12} fill={r.flagged ? "currentColor" : "none"} />
              {r.flagged ? "Flagged" : "Flag"}
            </button>
          </div>
          <p className="mb-2.5 text-[13px] text-nr-text-secondary">{r.text}</p>
          <SlimInput
            value={r.reply}
            onChange={(e) => setReviewReply(r.id, e.target.value)}
            placeholder="Write a reply..."
            className="w-full py-2 text-xs"
          />
        </div>
      ))}
    </div>
  );
}
