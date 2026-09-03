import { describe, expect, it } from "vitest";
import { parseTeamMember } from "./team";

describe("parseTeamMember", () => {
  it("maps a well-formed team document", () => {
    expect(parseTeamMember("m1", { name: "Rana Aziz", email: "rana@sirensdubai.com", role: "Owner" })).toEqual({
      id: "m1",
      name: "Rana Aziz",
      email: "rana@sirensdubai.com",
      role: "Owner",
    });
  });

  it("degrades an unrecognised role to 'Door staff' rather than throwing", () => {
    expect(parseTeamMember("m2", { name: "X", email: "x@y.com", role: "superadmin" }).role).toBe("Door staff");
  });

  it("defaults every field for a missing document", () => {
    expect(parseTeamMember("m3", undefined)).toEqual({ id: "m3", name: "", email: "", role: "Door staff" });
  });
});
