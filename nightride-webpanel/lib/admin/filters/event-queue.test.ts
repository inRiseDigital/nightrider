import { describe, expect, it } from "vitest";
import {
  countByStatus,
  deriveEventQueueStatus,
  hasDangerFlag,
  matchesEventQueueSearch,
  matchesEventQueueStatus,
} from "./event-queue";
import type { EventDoc, EventModerationFlag, EventStatus } from "../schema";
import type { EventQueueFlag } from "../view-models";

function eventWith(flag: EventModerationFlag, status: EventStatus): EventDoc {
  return {
    moderation: { flag, requestedAt: null, eta: null, reviewedBy: null, note: "" },
    status,
  } as EventDoc;
}

describe("deriveEventQueueStatus", () => {
  it("rejected flag always wins, regardless of status", () => {
    expect(deriveEventQueueStatus(eventWith("rejected", "published"))).toBe("rejected");
    expect(deriveEventQueueStatus(eventWith("rejected", "draft"))).toBe("rejected");
  });

  it("published status is approved even with a pending flag", () => {
    expect(deriveEventQueueStatus(eventWith("pending", "published"))).toBe("approved");
  });

  it("clean flag is approved regardless of status", () => {
    expect(deriveEventQueueStatus(eventWith("clean", "draft"))).toBe("approved");
  });

  it("pending flag with a non-published status is pending", () => {
    expect(deriveEventQueueStatus(eventWith("pending", "in_review"))).toBe("pending");
  });

  it("empty-string flag with a non-published status is pending", () => {
    expect(deriveEventQueueStatus(eventWith("", "scheduled"))).toBe("pending");
    expect(deriveEventQueueStatus(eventWith("", "draft"))).toBe("pending");
  });

  it("unknown/unexpected flag value falls through to pending when not published", () => {
    expect(deriveEventQueueStatus(eventWith("weird" as EventModerationFlag, "cancelled"))).toBe("pending");
  });
});

describe("matchesEventQueueSearch", () => {
  const row = { name: "Neon Nights", venueName: "Club Neon", organizerName: "Jamie Cho" };

  it("empty/whitespace search matches everything", () => {
    expect(matchesEventQueueSearch(row, "")).toBe(true);
    expect(matchesEventQueueSearch(row, "  ")).toBe(true);
  });

  it("matches case-insensitively across name, venue and organizer", () => {
    expect(matchesEventQueueSearch(row, "NEON")).toBe(true);
    expect(matchesEventQueueSearch(row, "jamie")).toBe(true);
  });

  it("no match returns false", () => {
    expect(matchesEventQueueSearch(row, "tokyo")).toBe(false);
  });
});

describe("matchesEventQueueStatus", () => {
  it("'all' matches any status", () => {
    expect(matchesEventQueueStatus("pending", "all")).toBe(true);
    expect(matchesEventQueueStatus("approved", "all")).toBe(true);
  });

  it("exact match required otherwise", () => {
    expect(matchesEventQueueStatus("pending", "pending")).toBe(true);
    expect(matchesEventQueueStatus("pending", "approved")).toBe(false);
  });
});

describe("hasDangerFlag", () => {
  it("true when any flag has danger tone", () => {
    const flags: EventQueueFlag[] = [
      { label: "New organizer", tone: "info" } as EventQueueFlag,
      { label: "Duplicate venue", tone: "danger" } as EventQueueFlag,
    ];
    expect(hasDangerFlag(flags)).toBe(true);
  });

  it("false when no flags are danger tone", () => {
    const flags: EventQueueFlag[] = [{ label: "New organizer", tone: "info" } as EventQueueFlag];
    expect(hasDangerFlag(flags)).toBe(false);
  });

  it("false on an empty flags list", () => {
    expect(hasDangerFlag([])).toBe(false);
  });
});

describe("countByStatus", () => {
  it("counts matching entries", () => {
    expect(countByStatus(["pending", "approved", "pending", "rejected"], "pending")).toBe(2);
  });

  it("returns 0 on empty collection or no match", () => {
    expect(countByStatus([], "pending")).toBe(0);
    expect(countByStatus(["approved", "approved"], "rejected")).toBe(0);
  });
});
