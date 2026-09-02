/**
 * Slot-id helpers moved out of `store.tsx` verbatim. `imageSlotStore` itself
 * (browser-stores.ts) stays a client-only localStorage sidecar for this task
 * — a later task replaces it with Cloud Storage uploads under these same ids.
 */
import { GALLERY_SLOT_COUNT } from "../constants";

export function heroSlotId(venueId: string) {
  return `hero-${venueId}`;
}
export function gallerySlotId(venueId: string, index: number) {
  return `gallery-${venueId}-${index}`;
}
export function gallerySlotIds(venueId: string) {
  return Array.from({ length: GALLERY_SLOT_COUNT }, (_, i) => gallerySlotId(venueId, i));
}
export function menuItemSlotId(venueId: string, itemId: string) {
  return `menu-${venueId}-${itemId}`;
}
export function eventSlotIds(eventKey: string) {
  return { cover: `event-img-${eventKey}-cover`, poster: `event-img-${eventKey}-poster` };
}
