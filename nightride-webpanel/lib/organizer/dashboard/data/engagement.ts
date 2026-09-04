/**
 * `venueReports/{reportId}` <-> `VenueReview`, and `users/{uid}/inbox/{messageId}`
 * <-> `InboxMessage`. Both parsers are defensive in the hand-rolled style of
 * `data/venues.ts` — `typeof` guards throughout, so a legacy or partial
 * document degrades to a safe default instead of throwing.
 *
 * `VenueReview`/`InboxMessage` in `types.ts` do not change (existing UI
 * shapes are frozen); everything Firestore-shaped that doesn't fit them —
 * `venueId`, `byUid`, raw `reply.at`/`readAt` timestamps — stays inside the
 * owning hook's raw-doc map rather than being smuggled onto the UI type.
 */
import { Timestamp } from "firebase/firestore";
import type { InboxMessage, InboxType, VenueReview } from "../types";

/** A Firestore `Timestamp` (or anything else) -> "Aug 6", "" if absent/invalid. */
export function shortDate(raw: unknown): string {
  if (!(raw instanceof Timestamp)) return "";
  return raw.toDate().toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

// ---------------------------------------------------------------------------
// Reviews — venueReports/{reportId}
// ---------------------------------------------------------------------------

interface ReviewReply {
  text?: unknown;
  at?: unknown;
}

function replyOf(raw: Record<string, unknown>): ReviewReply | null {
  return raw.reply && typeof raw.reply === "object" ? (raw.reply as ReviewReply) : null;
}

/**
 * `venueReports/{id}` -> `VenueReview`. `overlay.editing` blanks the posted
 * reply in the mapped view while an "Edit" is in progress — client-only,
 * never a Firestore write — so the composer can stage a replacement without
 * touching the persisted reply until `sendReviewReply` actually commits.
 */
export function parseVenueReview(
  id: string,
  raw: Record<string, unknown> | undefined,
  overlay: { draft: string; editing: boolean }
): VenueReview {
  const d = raw ?? {};
  const reply = replyOf(d);
  const postedText = overlay.editing ? "" : typeof reply?.text === "string" ? reply.text : "";
  return {
    id,
    author: typeof d.username === "string" && d.username ? d.username : "Guest",
    rating: typeof d.vibeRating === "number" ? d.vibeRating : 0,
    text: typeof d.comment === "string" ? d.comment : "",
    reply: overlay.draft,
    posted: postedText,
    postedWhen: postedText ? shortDate(reply?.at) : "",
    flagged: d.flaggedByOwner === true,
  };
}

/** Newest report first, by `createdAt`. Undated/legacy docs sort last. */
export function orderReviews(rawDocs: Record<string, Record<string, unknown>>): string[] {
  return Object.keys(rawDocs).sort((a, b) => {
    const an = rawDocs[a]?.createdAt instanceof Timestamp ? (rawDocs[a].createdAt as Timestamp).toMillis() : 0;
    const bn = rawDocs[b]?.createdAt instanceof Timestamp ? (rawDocs[b].createdAt as Timestamp).toMillis() : 0;
    return bn - an;
  });
}

// ---------------------------------------------------------------------------
// Inbox — users/{uid}/inbox/{messageId}
// ---------------------------------------------------------------------------

const INBOX_TYPES: readonly InboxType[] = ["policy", "violation", "appeal"];

/** `users/{uid}/inbox/{id}` -> `InboxMessage`. `open` is passed in — pure client expand state, never derived from `readAt`. */
export function parseInboxMessage(id: string, raw: Record<string, unknown> | undefined, open: boolean): InboxMessage {
  const d = raw ?? {};
  const type = INBOX_TYPES.includes(d.type as InboxType) ? (d.type as InboxType) : "policy";
  return {
    id,
    subject: typeof d.subject === "string" ? d.subject : "",
    from: typeof d.from === "string" ? d.from : "",
    date: shortDate(d.at),
    type,
    body: typeof d.body === "string" ? d.body : "",
    open,
  };
}

/** Newest message first, by `at`. Undated/legacy docs sort last. */
export function orderInbox(rawDocs: Record<string, Record<string, unknown>>): string[] {
  return Object.keys(rawDocs).sort((a, b) => {
    const an = rawDocs[a]?.at instanceof Timestamp ? (rawDocs[a].at as Timestamp).toMillis() : 0;
    const bn = rawDocs[b]?.at instanceof Timestamp ? (rawDocs[b].at as Timestamp).toMillis() : 0;
    return bn - an;
  });
}

/** True once any message in `rawDocs` has no `readAt` — drives the topbar's unread dot. */
export function hasUnread(rawDocs: Record<string, Record<string, unknown>>): boolean {
  return Object.values(rawDocs).some((d) => !(d.readAt instanceof Timestamp));
}
