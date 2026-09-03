import { describe, expect, it } from "vitest";
import { parseMenuSection, toMenuSectionFields } from "./venues";
import { MOCK_VENUES } from "../mock-data";

describe("parseMenuSection(toMenuSectionFields(section)) round-trip", () => {
  const section = MOCK_VENUES.sirens.menu[0];

  it("preserves name and items", () => {
    const fields = toMenuSectionFields(section);
    const back = parseMenuSection(section.id, fields);
    expect(back).toEqual(section);
  });

  it("defends against a missing/malformed doc", () => {
    expect(parseMenuSection("s1", undefined)).toEqual({ id: "s1", name: "", items: [] });
    expect(parseMenuSection("s2", { name: 42, items: "not-a-list" })).toEqual({
      id: "s2",
      name: "",
      items: [],
    });
  });

  it("drops malformed items rather than throwing", () => {
    const back = parseMenuSection("s3", { name: "Drinks", items: [{ id: "ok" }, { noId: true }, null] });
    expect(back.items).toEqual([
      { id: "ok", name: "", price: 0, desc: "", size: "", serves: "", tags: [], nights: [], soldOut: false },
    ]);
  });
});
