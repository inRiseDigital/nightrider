/**
 * Slot-id helpers plus the Storage side of every organizer image slot.
 *
 * A slot id (`hero-{venueId}`, `gallery-{venueId}-{i}`, `menu-{venueId}-{itemId}`,
 * `event-{eventId}-cover`/`-poster`) is the shared-identity mechanism between
 * an editor tile and its live-preview counterpart — six components depend on
 * these helpers and none of that changes here. What changes (T12) is what a
 * slot *resolves to*: an `https` download URL on the owning Firestore
 * document, not a base64 blob in `localStorage`. This module owns Storage
 * only — `parseSlotId`/`storagePathForSlot` are pure, and `uploadSlotImage`/
 * `deleteSlotImage` never touch Firestore; `store.tsx`'s `commitSlotImage`/
 * `removeSlotImage` own writing the resulting URL onto the right document.
 */
import { deleteObject, getDownloadURL, ref as storageRef } from "firebase/storage";
// Relative, not "@/" — see the note in application-service.ts: vitest has no
// path-alias resolution configured, and `images.test.ts` needs this module
// (and its `uploadResumable`/`resizeImageFile` import below) to load.
import { getBucket } from "../../../firebase";
import { resizeImageFile, uploadResumable, type UploadProgressHandler } from "../../application-service";
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
/**
 * `event-{eventId}-cover`/`-poster` — no `-img-` infix. Matches the T12
 * brief's contract table exactly; earlier (localStorage-only) slot ids used
 * `event-img-{eventKey}-...`, which never lined up with a Storage path.
 */
export function eventSlotIds(eventId: string) {
  return { cover: `event-${eventId}-cover`, poster: `event-${eventId}-poster` };
}

// ---------------------------------------------------------------------------
// Slot id <-> Storage path — the T12 brief's contract table, verbatim.
//
//   hero-{venueId}              venuePhotos/{venueId}/hero.jpg           venues.photos[0]
//   gallery-{venueId}-{i}       venuePhotos/{venueId}/gallery/{i}.jpg    venues.photos[i+1]
//   menu-{venueId}-{itemId}     venuePhotos/{venueId}/menu/{itemId}.jpg  menuSections.items[].image
//   event-{eventId}-cover       eventMedia/{eventId}/cover.jpg           events.coverImage
//   event-{eventId}-poster      eventMedia/{eventId}/poster.jpg          events.posterImage
//
// Venue/event ids are Firestore auto-ids (no hyphens) or `osm_{osmId}`
// (hyphen-free too), so a leading `[^-]+` capture is safe; a menu item id
// (`nextMenuId` in useVenues.ts) DOES contain hyphens, so it takes the
// greedy remainder instead.
// ---------------------------------------------------------------------------

export type ParsedSlot =
  | { kind: "hero"; venueId: string }
  | { kind: "gallery"; venueId: string; index: number }
  | { kind: "menu"; venueId: string; itemId: string }
  | { kind: "event"; eventId: string; field: "cover" | "poster" };

export function parseSlotId(slotId: string): ParsedSlot | null {
  let m: RegExpExecArray | null;
  if ((m = /^hero-([^-]+)$/.exec(slotId))) return { kind: "hero", venueId: m[1] };
  if ((m = /^gallery-([^-]+)-(\d+)$/.exec(slotId)))
    return { kind: "gallery", venueId: m[1], index: Number(m[2]) };
  if ((m = /^menu-([^-]+)-(.+)$/.exec(slotId))) return { kind: "menu", venueId: m[1], itemId: m[2] };
  if ((m = /^event-([^-]+)-(cover|poster)$/.exec(slotId)))
    return { kind: "event", eventId: m[1], field: m[2] as "cover" | "poster" };
  return null;
}

export function storagePathForSlot(slot: ParsedSlot): string {
  switch (slot.kind) {
    case "hero":
      return `venuePhotos/${slot.venueId}/hero.jpg`;
    case "gallery":
      return `venuePhotos/${slot.venueId}/gallery/${slot.index}.jpg`;
    case "menu":
      return `venuePhotos/${slot.venueId}/menu/${slot.itemId}.jpg`;
    case "event":
      return `eventMedia/${slot.eventId}/${slot.field}.jpg`;
  }
}

const MAX_UPLOAD_BYTES = 6 * 1024 * 1024;
const ALLOWED_MIME_TYPES = new Set(["image/jpeg", "image/png", "image/webp"]);

/** `storage.rules`' codes, given applicant-facing copy — mirrors `lib/organizer/errors.ts`'s KYC mapper, but for replaceable image content rather than immutable evidence. */
function describeSlotStorageError(err: unknown): string {
  const code =
    typeof err === "object" && err !== null && "code" in err ? String((err as { code: unknown }).code) : "";
  switch (code) {
    case "storage/unauthorized":
      return "You don't have permission to upload images for this listing.";
    case "storage/canceled":
      return "Upload canceled.";
    case "storage/retry-limit-exceeded":
      return "Upload failed after repeated retries. Check your connection and try again.";
    case "storage/quota-exceeded":
      return "Storage quota exceeded. Contact the Night Ride team.";
    case "storage/unauthenticated":
      return "You're signed out. Sign in again and retry the upload.";
    default:
      return err instanceof Error && err.message ? err.message : "Upload failed. Try again.";
  }
}

/**
 * Resizes `file` (see `resizeImageFile`), uploads it to the slot's Storage
 * path, and returns the resulting `https` download URL. Never writes to
 * Firestore — the caller (`store.tsx`'s `commitSlotImage`) owns patching the
 * URL onto the owning document, per the brief's ordering constraint for
 * event media and the "route through `updateVenueListing`" ruling for venue
 * photos.
 */
export async function uploadSlotImage(
  slotId: string,
  file: File,
  onProgress?: UploadProgressHandler
): Promise<string> {
  const slot = parseSlotId(slotId);
  if (!slot) throw new Error(`Unrecognized image slot: ${slotId}`);
  if (!ALLOWED_MIME_TYPES.has(file.type)) {
    throw new Error("Only JPEG, PNG, or WEBP images are allowed.");
  }

  const resized = await resizeImageFile(file);
  if (resized.size > MAX_UPLOAD_BYTES) {
    throw new Error("That image is too large even after resizing. Try a smaller photo.");
  }

  const path = storagePathForSlot(slot);
  try {
    await uploadResumable(path, resized, "image/jpeg", onProgress);
  } catch (err) {
    throw new Error(describeSlotStorageError(err));
  }
  return getDownloadURL(storageRef(getBucket(), path));
}

/**
 * Deletes the Storage object backing `slotId`. Tolerates the object already
 * being gone (a second remove, or a slot that was never actually uploaded).
 */
export async function deleteSlotImage(slotId: string): Promise<void> {
  const slot = parseSlotId(slotId);
  if (!slot) return;
  try {
    await deleteObject(storageRef(getBucket(), storagePathForSlot(slot)));
  } catch (err) {
    const code =
      typeof err === "object" && err !== null && "code" in err ? String((err as { code: unknown }).code) : "";
    if (code === "storage/object-not-found") return;
    throw new Error(describeSlotStorageError(err));
  }
}
