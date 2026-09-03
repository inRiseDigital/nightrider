import { describe, expect, it } from "vitest";
import { parseMenuSection, toMenuSectionFields } from "./venues";
import type { MenuSection } from "../types";

const section: MenuSection = {
  id: "ms1",
  name: "Bottle service & tables",
  items: [
    {
      id: "mi1",
      name: "Skyline table — Grey Goose",
      price: 3200,
      desc: "Reserved terrace table with skyline view, two mixers per bottle.",
      size: "1.5L magnum",
      serves: "6",
      tags: ["Signature"],
      nights: [4, 5],
      soldOut: false,
      image: "",
    },
    {
      id: "mi2",
      name: "Dom Pérignon 2013",
      price: 2900,
      desc: "Served with sparklers on request.",
      size: "75cl",
      serves: "4",
      tags: [],
      nights: [],
      soldOut: false,
      image: "",
    },
    {
      id: "mi3",
      name: "Booth minimum — main deck",
      price: 1500,
      desc: "Minimum spend, redeemable against anything on the menu.",
      size: "",
      serves: "8",
      tags: [],
      nights: [3, 4, 5],
      soldOut: true,
      image: "",
    },
  ],
};

describe("parseMenuSection(toMenuSectionFields(section)) round-trip", () => {

  it("preserves name and items", () => {
    const fields = toMenuSectionFields(section);
    const back = parseMenuSection(section.id, fields);
    // Every item in the fixture already sets `image` explicitly, so
    // `parseMenuItem`'s round trip produces objects structurally identical
    // to `section` — `toEqual`, not `toMatchObject`.
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
    expect(back.items).toMatchObject([
      { id: "ok", name: "", price: 0, desc: "", size: "", serves: "", tags: [], nights: [], soldOut: false },
    ]);
    expect(back.items[0].image).toBe("");
  });
});
