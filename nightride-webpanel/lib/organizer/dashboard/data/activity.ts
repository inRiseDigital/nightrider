/** `venues/{venueId}/activity/{entryId}` <-> `ActivityEntry`. */
import type { Timestamp } from "firebase/firestore";
import { toTimestampOrNull } from "./venues";
import type { ActivityEntry } from "../types";

/**
 * Formatted in UTC, not the browser's local zone — activity spans every
 * venue an organizer edits, which may sit in different timezones, and there
 * is no single "the" zone to convert to at this call site. UTC keeps the
 * label deterministic regardless of the organizer's or a test runner's zone.
 */
function whenText(ts: Timestamp | null): string {
  if (!ts) return "";
  return ts.toDate().toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
    timeZone: "UTC",
  });
}

export function parseActivityEntry(data: Record<string, unknown> | undefined): ActivityEntry {
  const d = data ?? {};
  return {
    who: typeof d.actorName === "string" ? d.actorName : "",
    what: typeof d.what === "string" ? d.what : "",
    when: whenText(toTimestampOrNull(d.at)),
  };
}
