import { describe, expect, it } from "vitest";
import { displayToRawRole, parseTeamMember, rawToDisplayRole } from "./team";

describe("parseTeamMember", () => {
  // The stored vocabulary is lowercase ('owner' | 'manager' | 'door' — see
  // scripts/seed-emulator/seed.mjs and firestore.rules' `editors` map), NOT
  // the capitalised display strings — exercising the real stored values here
  // is exactly what would have caught the fix-round-1 bug where every real
  // team member rendered as "Door staff".
  it("maps the real seeded roles ('owner'/'manager'/'door') to their display form", () => {
    expect(parseTeamMember("tm1", { name: "Rana Aziz", email: "rana@sirensdubai.com", role: "owner" }).role).toBe(
      "Owner"
    );
    expect(parseTeamMember("tm2", { name: "Marco Reyes", email: "marco@sirensdubai.com", role: "manager" }).role).toBe(
      "Manager"
    );
    expect(parseTeamMember("tm3", { name: "Leila Haddad", email: "leila@sirensdubai.com", role: "door" }).role).toBe(
      "Door staff"
    );
  });

  it("maps a well-formed team document end to end", () => {
    expect(parseTeamMember("m1", { name: "Rana Aziz", email: "rana@sirensdubai.com", role: "owner" })).toEqual({
      id: "m1",
      name: "Rana Aziz",
      email: "rana@sirensdubai.com",
      role: "Owner",
    });
  });

  it("degrades an unrecognised role to 'Door staff' rather than throwing", () => {
    expect(parseTeamMember("m2", { name: "X", email: "x@y.com", role: "superadmin" }).role).toBe("Door staff");
  });

  it("does not accept the display-cased strings as stored values (they aren't what's stored)", () => {
    expect(parseTeamMember("m4", { name: "X", email: "x@y.com", role: "Owner" }).role).toBe("Door staff");
  });

  it("defaults every field for a missing document", () => {
    expect(parseTeamMember("m3", undefined)).toEqual({ id: "m3", name: "", email: "", role: "Door staff" });
  });
});

describe("rawToDisplayRole / displayToRawRole round-trip", () => {
  it("round-trips all three real roles in both directions", () => {
    const pairs: [string, "Owner" | "Manager" | "Door staff"][] = [
      ["owner", "Owner"],
      ["manager", "Manager"],
      ["door", "Door staff"],
    ];
    for (const [raw, display] of pairs) {
      expect(rawToDisplayRole(raw)).toBe(display);
      expect(displayToRawRole(display)).toBe(raw);
    }
  });
});
