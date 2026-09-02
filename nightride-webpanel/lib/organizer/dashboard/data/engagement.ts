/** `venueReports/{reportId}` <-> `VenueReview`, `users/{uid}/inbox/{id}` <-> `InboxMessage`. */
import type { Timestamp } from "firebase/firestore";
import { toTimestampOrNull } from "./venues";
import type { InboxMessage, InboxType, VenueReview } from "../types";

function shortDate(ts: Timestamp | null): string {
  return ts ? ts.toDate().toLocaleDateString("en-US", { month: "short", day: "numeric" }) : "";
}

export function parseVenueReview(id: string, data: Record<string, unknown> | undefined): VenueReview {
  const d = data ?? {};
  const reply = (d.reply ?? null) as { text?: string; at?: unknown } | null;
  return {
    id,
    author: typeof d.username === "string" ? `@${d.username}` : "",
    rating: typeof d.vibeRating === "number" ? d.vibeRating : 0,
    text: typeof d.comment === "string" ? d.comment : "",
    reply: "",
    posted: typeof reply?.text === "string" ? reply.text : "",
    postedWhen: reply ? shortDate(toTimestampOrNull(reply.at)) : "",
    flagged: d.flaggedByOwner === true,
  };
}

/** Only `reply`/`flaggedByOwner` are writable — `onlyTouched(['reply', 'flaggedByOwner'])`. */
export function toVenueReviewFields(ui: VenueReview): Record<string, unknown> {
  return {
    flaggedByOwner: ui.flagged,
    reply: ui.posted ? { text: ui.posted } : null,
  };
}

const INBOX_TYPES: readonly InboxType[] = ["policy", "violation", "appeal"];

export function parseInboxMessage(id: string, data: Record<string, unknown> | undefined): InboxMessage {
  const d = data ?? {};
  return {
    id,
    subject: typeof d.subject === "string" ? d.subject : "",
    from: typeof d.from === "string" ? d.from : "",
    date: shortDate(toTimestampOrNull(d.at)),
    type: typeof d.type === "string" && (INBOX_TYPES as readonly string[]).includes(d.type) ? (d.type as InboxType) : "policy",
    body: typeof d.body === "string" ? d.body : "",
    open: d.readAt != null,
  };
}
