import { Timestamp } from "firebase/firestore";
import { describe, expect, it } from "vitest";
import {
  auditActionType,
  auditTypeTone,
  initialsFor,
  matchesAuditActor,
  matchesAuditSearch,
  matchesAuditType,
  withinAuditRange,
} from "./audit";
import type { AuditActionKind } from "../view-models";

const NOW = new Date("2026-09-04T12:00:00Z").getTime();
const at = (iso: string) => Timestamp.fromDate(new Date(iso));
const hoursAgo = (h: number) => Timestamp.fromMillis(NOW - h * 3_600_000);
const daysAgo = (d: number) => Timestamp.fromMillis(NOW - d * 86_400_000);

describe("withinAuditRange", () => {
  it("treats a null timestamp as within range only for 'all'", () => {
    expect(withinAuditRange(null, "all", NOW)).toBe(true);
    expect(withinAuditRange(null, "24h", NOW)).toBe(false);
    expect(withinAuditRange(null, "7d", NOW)).toBe(false);
    expect(withinAuditRange(null, "30d", NOW)).toBe(false);
  });

  it("'all' includes anything, however old", () => {
    expect(withinAuditRange(daysAgo(3650), "all", NOW)).toBe(true);
  });

  it("24h includes just-now and excludes exactly 24h ago", () => {
    expect(withinAuditRange(hoursAgo(0), "24h", NOW)).toBe(true);
    expect(withinAuditRange(hoursAgo(23), "24h", NOW)).toBe(true);
    expect(withinAuditRange(hoursAgo(24), "24h", NOW)).toBe(false);
    expect(withinAuditRange(hoursAgo(25), "24h", NOW)).toBe(false);
  });

  it("7d includes up to just under 7 days, excludes exactly 7 days", () => {
    expect(withinAuditRange(daysAgo(6), "7d", NOW)).toBe(true);
    expect(withinAuditRange(daysAgo(7), "7d", NOW)).toBe(false);
    expect(withinAuditRange(daysAgo(8), "7d", NOW)).toBe(false);
  });

  it("30d includes up to just under 30 days, excludes exactly 30 days", () => {
    expect(withinAuditRange(daysAgo(29), "30d", NOW)).toBe(true);
    expect(withinAuditRange(daysAgo(30), "30d", NOW)).toBe(false);
    expect(withinAuditRange(daysAgo(31), "30d", NOW)).toBe(false);
  });

  it("defaults nowMs to the real clock when not supplied", () => {
    // Freshly-minted timestamp must read as within 24h against the real clock.
    expect(withinAuditRange(Timestamp.fromDate(new Date()), "24h")).toBe(true);
  });

  it("a future timestamp (negative age) still reads as within range", () => {
    expect(withinAuditRange(at("2026-09-05T00:00:00Z"), "24h", NOW)).toBe(true);
  });
});

describe("matchesAuditSearch", () => {
  const row = { actionLabel: "Approved organizer", target: "Club Neon", actorLabel: "Jamie Cho" };

  it("empty/whitespace search matches everything", () => {
    expect(matchesAuditSearch(row, "")).toBe(true);
    expect(matchesAuditSearch(row, "   ")).toBe(true);
  });

  it("matches case-insensitively across action, target and actor", () => {
    expect(matchesAuditSearch(row, "APPROVED")).toBe(true);
    expect(matchesAuditSearch(row, "neon")).toBe(true);
    expect(matchesAuditSearch(row, "jamie")).toBe(true);
  });

  it("partial matches count", () => {
    expect(matchesAuditSearch(row, "cho")).toBe(true);
  });

  it("no match returns false", () => {
    expect(matchesAuditSearch(row, "rejected")).toBe(false);
  });
});

describe("matchesAuditActor / matchesAuditType", () => {
  it("'all' matches any actor or type", () => {
    expect(matchesAuditActor("Jamie Cho", "all")).toBe(true);
    expect(matchesAuditType("Review", "all")).toBe(true);
  });

  it("exact match required otherwise", () => {
    expect(matchesAuditActor("Jamie Cho", "Jamie Cho")).toBe(true);
    expect(matchesAuditActor("Jamie Cho", "System")).toBe(false);
    expect(matchesAuditType("Review", "Review")).toBe(true);
    expect(matchesAuditType("Review", "Venue")).toBe(false);
  });
});

describe("auditActionType — action to badge mapping", () => {
  const cases: Array<[AuditActionKind, string]> = [
    ["event.publish", "Review"],
    ["event.archive", "Review"],
    ["event.flag", "Review"],
    ["event.submitted", "Review"],
    ["report.delete", "Review"],
    ["organizer.approve", "Organizer"],
    ["organizer.reject", "Organizer"],
    ["organizer.revoke", "Organizer"],
    ["organizer.submitted", "Organizer"],
    ["kyc.needsInfo", "Organizer"],
    ["kyc.script", "Organizer"],
    ["kyc.accept", "Venue"],
    ["venue.create", "Venue"],
    ["venue.suspend", "Venue"],
    ["venue.unsuspend", "Venue"],
    ["venue.transfer", "Venue"],
    ["venue.checkApprove", "Venue"],
    ["venue.checkFail", "Venue"],
    ["account.suspend", "Account"],
    ["account.unsuspend", "Account"],
    ["account.ban", "Account"],
    ["account.unban", "Account"],
    ["account.passwordReset", "Account"],
    ["role.admin.add", "Access"],
    ["role.admin.revoke", "Access"],
    ["role.admin.scopeChange", "Access"],
  ];

  it.each(cases)("%s -> %s", (action, expected) => {
    expect(auditActionType(action)).toBe(expected);
  });

  it("falls back to 'Review' for an unknown action kind", () => {
    expect(auditActionType("something.unknown" as AuditActionKind)).toBe("Review");
  });
});

describe("auditTypeTone", () => {
  it("maps every badge type to its tone", () => {
    expect(auditTypeTone("Review")).toBe("info");
    expect(auditTypeTone("Venue")).toBe("neutral");
    expect(auditTypeTone("Organizer")).toBe("success");
    expect(auditTypeTone("Account")).toBe("danger");
    expect(auditTypeTone("Access")).toBe("warning");
  });

  it("falls back to 'neutral' for an unrecognized type", () => {
    expect(auditTypeTone("Nonsense" as never)).toBe("neutral");
  });
});

describe("initialsFor", () => {
  it("returns empty string for 'System'", () => {
    expect(initialsFor("System")).toBe("");
  });

  it("builds initials from a full name", () => {
    expect(initialsFor("Jamie Cho")).toBe("JC");
  });

  it("uppercases and handles a single name", () => {
    expect(initialsFor("madonna")).toBe("M");
  });

  it("collapses extra whitespace between words", () => {
    expect(initialsFor("  Jamie   Cho  ")).toBe("JC");
  });

  it("returns empty string for an empty actor label", () => {
    expect(initialsFor("")).toBe("");
  });

  it("uses every word's first letter for a multi-word name", () => {
    expect(initialsFor("Ana De La Cruz")).toBe("ADLC");
  });
});
