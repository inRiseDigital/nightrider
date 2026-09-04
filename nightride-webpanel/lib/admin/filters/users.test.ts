import { describe, expect, it } from "vitest";
import {
  countByModerationState,
  countByRole,
  deriveUserIdentity,
  deriveUserRole,
  matchesUserModerationState,
  matchesUserRole,
  matchesUserSearch,
} from "./users";

describe("deriveUserRole", () => {
  it("admin outranks organizer status", () => {
    expect(deriveUserRole(true, "approved")).toBe("Admin");
    expect(deriveUserRole(true, "none")).toBe("Admin");
  });

  it("non-admin with approved organizer status is Organizer", () => {
    expect(deriveUserRole(false, "approved")).toBe("Organizer");
  });

  it("non-admin with any other organizer status is Party-goer", () => {
    expect(deriveUserRole(false, "none")).toBe("Party-goer");
    expect(deriveUserRole(false, "pending")).toBe("Party-goer");
    expect(deriveUserRole(false, "rejected")).toBe("Party-goer");
    expect(deriveUserRole(false, "revoked")).toBe("Party-goer");
  });
});

describe("deriveUserIdentity", () => {
  it("returns the organizer status for organizers", () => {
    expect(deriveUserIdentity("Organizer", "approved")).toBe("approved");
    expect(deriveUserIdentity("Organizer", "pending")).toBe("pending");
  });

  it("returns 'n/a' for non-organizer roles regardless of stored status", () => {
    expect(deriveUserIdentity("Party-goer", "approved")).toBe("n/a");
    expect(deriveUserIdentity("Admin", "approved")).toBe("n/a");
  });
});

describe("matchesUserSearch", () => {
  const row = { name: "Jamie Cho", email: "jamie.cho@example.com", phone: "+971501234567" };

  it("empty/whitespace search matches everything", () => {
    expect(matchesUserSearch(row, "")).toBe(true);
    expect(matchesUserSearch(row, "  ")).toBe(true);
  });

  it("matches case-insensitively on name", () => {
    expect(matchesUserSearch(row, "JAMIE")).toBe(true);
  });

  it("matches partial email", () => {
    expect(matchesUserSearch(row, "cho@example")).toBe(true);
  });

  it("matches partial phone", () => {
    expect(matchesUserSearch(row, "501234")).toBe(true);
  });

  it("no match returns false", () => {
    expect(matchesUserSearch(row, "nomatch")).toBe(false);
  });
});

describe("matchesUserRole / matchesUserModerationState", () => {
  it("'all' matches anything", () => {
    expect(matchesUserRole("Admin", "all")).toBe(true);
    expect(matchesUserModerationState("banned", "all")).toBe(true);
  });

  it("exact match required otherwise", () => {
    expect(matchesUserRole("Admin", "Admin")).toBe(true);
    expect(matchesUserRole("Admin", "Organizer")).toBe(false);
    expect(matchesUserModerationState("active", "active")).toBe(true);
    expect(matchesUserModerationState("active", "suspended")).toBe(false);
  });
});

describe("countByRole / countByModerationState", () => {
  it("counts matching entries", () => {
    expect(countByRole(["Admin", "Organizer", "Organizer", "Party-goer"], "Organizer")).toBe(2);
    expect(
      countByModerationState(["active", "suspended", "active", "banned", "deactivated"], "active"),
    ).toBe(2);
  });

  it("returns 0 on an empty collection", () => {
    expect(countByRole([], "Admin")).toBe(0);
    expect(countByModerationState([], "active")).toBe(0);
  });

  it("returns 0 when nothing matches", () => {
    expect(countByRole(["Party-goer", "Party-goer"], "Admin")).toBe(0);
  });
});
