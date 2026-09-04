import { describe, expect, it } from "vitest";
import {
  eventSlotIds,
  gallerySlotId,
  gallerySlotIds,
  heroSlotId,
  menuItemSlotId,
  parseSlotId,
  storagePathForSlot,
} from "./images";

/**
 * The T12 brief's contract table, verbatim — every row exercised both ways
 * (slot id -> parsed shape -> Storage path), including the
 * `gallery~{venueId}~{i}` -> `photos[i+1]` off-by-one this task's brief
 * flags as the most likely thing to get wrong.
 */
describe("parseSlotId / storagePathForSlot — the contract table", () => {
  it("hero~{venueId} -> venuePhotos/{venueId}/hero.jpg", () => {
    const slot = parseSlotId(heroSlotId("v1"));
    expect(slot).toEqual({ kind: "hero", venueId: "v1" });
    expect(storagePathForSlot(slot!)).toBe("venuePhotos/v1/hero.jpg");
  });

  it("hero~{venueId} still parses when venueId itself contains hyphens (admin-created slug ids, e.g. admin-sunset-rooftop-melbourne)", () => {
    const slot = parseSlotId(heroSlotId("admin-sunset-rooftop-melbourne"));
    expect(slot).toEqual({ kind: "hero", venueId: "admin-sunset-rooftop-melbourne" });
    expect(storagePathForSlot(slot!)).toBe("venuePhotos/admin-sunset-rooftop-melbourne/hero.jpg");
  });

  it("gallery~{venueId}~{i} -> venuePhotos/{venueId}/gallery/{i}.jpg, index 0 (-> photos[1])", () => {
    const slot = parseSlotId(gallerySlotId("v1", 0));
    expect(slot).toEqual({ kind: "gallery", venueId: "v1", index: 0 });
    expect(storagePathForSlot(slot!)).toBe("venuePhotos/v1/gallery/0.jpg");
  });

  it("gallery index 1..3 round-trip too — the off-by-one is in how a caller maps index -> photos[i+1], not here, but every index must parse cleanly", () => {
    for (const i of [1, 2, 3]) {
      const slot = parseSlotId(gallerySlotId("v1", i));
      expect(slot).toEqual({ kind: "gallery", venueId: "v1", index: i });
      expect(storagePathForSlot(slot!)).toBe(`venuePhotos/v1/gallery/${i}.jpg`);
    }
  });

  it("gallerySlotIds(venueId) enumerates exactly the 4 gallery slots (photos[1..4]), index 0-based", () => {
    const ids = gallerySlotIds("v1");
    expect(ids).toEqual(["gallery~v1~0", "gallery~v1~1", "gallery~v1~2", "gallery~v1~3"]);
    // The off-by-one this brief calls out by name: slot index `i` is
    // `photos[i + 1]` — `photos[0]` is the hero, never a gallery slot.
    ids.forEach((id, i) => {
      const slot = parseSlotId(id);
      expect(slot).toEqual({ kind: "gallery", venueId: "v1", index: i });
      const photosIndex = (slot as { index: number }).index + 1;
      expect(photosIndex).toBe(i + 1);
      expect(photosIndex).not.toBe(0); // never aliases the hero slot
    });
  });

  it("menu~{venueId}~{itemId} -> venuePhotos/{venueId}/menu/{itemId}.jpg", () => {
    const slot = parseSlotId(menuItemSlotId("v1", "item-abc"));
    expect(slot).toEqual({ kind: "menu", venueId: "v1", itemId: "item-abc" });
    expect(storagePathForSlot(slot!)).toBe("venuePhotos/v1/menu/item-abc.jpg");
  });

  it("menu item ids containing hyphens (nextMenuId's actual shape) still parse", () => {
    // `nextMenuId` in useVenues.ts produces ids like `item-l8x2n1-3`.
    const itemId = "item-l8x2n1-3";
    const slot = parseSlotId(menuItemSlotId("v1", itemId));
    expect(slot).toEqual({ kind: "menu", venueId: "v1", itemId });
    expect(storagePathForSlot(slot!)).toBe(`venuePhotos/v1/menu/${itemId}.jpg`);
  });

  it("menu~{venueId}~{itemId} still parses when both venueId and itemId contain hyphens", () => {
    const venueId = "admin-sunset-rooftop-melbourne";
    const itemId = "item-l8x2n1-3";
    const slot = parseSlotId(menuItemSlotId(venueId, itemId));
    expect(slot).toEqual({ kind: "menu", venueId, itemId });
    expect(storagePathForSlot(slot!)).toBe(`venuePhotos/${venueId}/menu/${itemId}.jpg`);
  });

  it("event~{eventId}~cover -> eventMedia/{eventId}/cover.jpg", () => {
    const slots = eventSlotIds("ev1");
    const slot = parseSlotId(slots.cover);
    expect(slot).toEqual({ kind: "event", eventId: "ev1", field: "cover" });
    expect(storagePathForSlot(slot!)).toBe("eventMedia/ev1/cover.jpg");
  });

  it("event~{eventId}~poster -> eventMedia/{eventId}/poster.jpg", () => {
    const slots = eventSlotIds("ev1");
    const slot = parseSlotId(slots.poster);
    expect(slot).toEqual({ kind: "event", eventId: "ev1", field: "poster" });
    expect(storagePathForSlot(slot!)).toBe("eventMedia/ev1/poster.jpg");
  });

  it("eventSlotIds has no `-img-` infix (the pre-T12 localStorage-only slot ids did, and never lined up with a Storage path)", () => {
    const slots = eventSlotIds("ev1");
    expect(slots).toEqual({ cover: "event~ev1~cover", poster: "event~ev1~poster" });
  });

  it("rejects an unrecognized slot id rather than guessing", () => {
    expect(parseSlotId("nonsense")).toBeNull();
    expect(parseSlotId("hero~")).toBeNull();
    expect(parseSlotId("gallery~v1~notanumber")).toBeNull();
    expect(parseSlotId("event~ev1~thumbnail")).toBeNull();
  });
});
