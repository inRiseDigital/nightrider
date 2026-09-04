/**
 * `DoorStatus` <-> the venue document's `live.status` / `live.crowdLevel` /
 * `live.queueStatus`. UI -> stored is the authoritative direction; stored ->
 * UI prefers the round-trippable `live.doorStatus` and only falls back to a
 * lossy derivation for documents an admin or scraper wrote directly.
 *
 * `live.status` / `crowdLevel` / `queueStatus` are never widened — see the
 * Global Constraints. These types are local to this module rather than added
 * to `types.ts`, which the panel does not model beyond `DoorStatus`.
 */
import type { DoorStatus } from "../types";

export type LiveStatus = "open" | "closed" | "vipOnly" | "soldOut";
export type CrowdLevel = "empty" | "quiet" | "moderate" | "busy" | "packed";
export type QueueStatus = "noQueue" | "short" | "moderate" | "long" | "closed";

const DOOR_STATUSES: readonly DoorStatus[] = ["open", "filling", "capacity", "guestlist", "closed"];

export function isDoorStatus(value: unknown): value is DoorStatus {
  return typeof value === "string" && (DOOR_STATUSES as readonly string[]).includes(value);
}

/** capacity === 0 means UNKNOWN: return "moderate" and never divide by zero. */
export function crowdLevelFor(inVenue: number, capacity: number): CrowdLevel {
  if (capacity === 0) return "moderate";
  if (inVenue <= 0) return "empty";
  const ratio = inVenue / capacity;
  if (ratio < 0.25) return "quiet";
  if (ratio < 0.6) return "moderate";
  if (ratio < 0.9) return "busy";
  return "packed";
}

/** 0 -> noQueue; 1..10 short; 11..30 moderate; >30 long. */
export function queueStatusFor(queueMinutes: number): QueueStatus {
  if (queueMinutes <= 0) return "noQueue";
  if (queueMinutes <= 10) return "short";
  if (queueMinutes <= 30) return "moderate";
  return "long";
}

/** UI `doorStatus` -> stored `live.status`. Authoritative direction. */
export function liveStatusFor(doorStatus: DoorStatus): LiveStatus {
  switch (doorStatus) {
    case "open":
    case "filling":
      return "open";
    case "capacity":
      return "soldOut";
    case "guestlist":
      return "vipOnly";
    case "closed":
      return "closed";
  }
}

/** `capacity` forces `crowdLevel` to "packed"; every other status derives it. */
export function crowdLevelForDoorStatus(doorStatus: DoorStatus, inVenue: number, capacity: number): CrowdLevel {
  return doorStatus === "capacity" ? "packed" : crowdLevelFor(inVenue, capacity);
}

/** `closed` forces `queueStatus` to "closed"; every other status derives it. */
export function queueStatusForDoorStatus(doorStatus: DoorStatus, queueMinutes: number): QueueStatus {
  return doorStatus === "closed" ? "closed" : queueStatusFor(queueMinutes);
}

export function ticketsAvailableFor(doorStatus: DoorStatus): boolean {
  return doorStatus !== "capacity" && doorStatus !== "closed";
}

/** `flashText` capped at 200 chars to match `shapeOk()`'s `flash.text` rule. */
export function offerFor(flashActive: boolean, flashText: string): string {
  return flashActive ? flashText.slice(0, 200) : "";
}

/**
 * Stored `live` -> UI `doorStatus`. Prefers the round-trippable `doorStatus`
 * field; falls back to a lossy derivation from `status`/`crowdLevel` for
 * documents an admin or scraper wrote without it.
 */
export function doorStatusFromLive(live: {
  doorStatus?: unknown;
  status: LiveStatus;
  inVenue: number;
  capacity: number;
}): DoorStatus {
  if (isDoorStatus(live.doorStatus)) return live.doorStatus;
  switch (live.status) {
    case "soldOut":
      return "capacity";
    case "vipOnly":
      return "guestlist";
    case "closed":
      return "closed";
    case "open":
      return live.capacity > 0 && live.inVenue / live.capacity >= 0.9 ? "filling" : "open";
  }
}
