"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";

export type HomeTab = "tonight" | "activity";
export type AudienceTab = "performance" | "reviews" | "ai-visibility";
export type AccountTab = "team" | "inbox" | "promotion" | "settings";
export type Toast = { id: number; text: string; tone: "info" | "error" };

const LEGACY_IMAGE_STORAGE_KEY = "nr-organizer-image-slots";

/**
 * Pure cross-cutting UI state that no single domain owns: the destination tab
 * strips, the snackbar, and — as of T12 — which image slot (if any) has a
 * pending remove confirmation.
 *
 * The image slots THEMSELVES are no longer state this hook owns: T12 moved
 * them off the `localStorage`-backed `imageSlotStore` (browser-stores.ts)
 * onto Cloud Storage, with the resulting URL living on the owning Firestore
 * document. `images` (slot id -> `https` URL) is now derived in `store.tsx`
 * from the loaded venue/event documents, not stored here — one source of
 * truth. `confirmRemoveSlotId` survives as pure "which slot is the remove
 * dialog open for" UI state; `store.tsx`'s `confirmRemoveImage` does the
 * actual Storage delete + Firestore patch once confirmed, since only it has
 * access to the venues/events hooks that own those documents.
 */
export function useDashboardUi() {
  const [homeTab, setHomeTab] = useState<HomeTab>("tonight");
  const [audienceTab, setAudienceTab] = useState<AudienceTab>("performance");
  const [accountTab, setAccountTab] = useState<AccountTab>("team");

  const [snack, setSnack] = useState<Toast | null>(null);
  const snackIdRef = useRef(0);

  const showSnack = useCallback((text: string, tone: "info" | "error" = "info") => {
    snackIdRef.current += 1;
    setSnack({ id: snackIdRef.current, text, tone });
  }, []);
  const dismissSnack = useCallback(() => setSnack(null), []);

  const [confirmRemoveSlotId, setConfirmRemoveSlotId] = useState<string | null>(null);
  const requestRemoveImage = useCallback((slotId: string) => setConfirmRemoveSlotId(slotId), []);
  const cancelRemoveImage = useCallback(() => setConfirmRemoveSlotId(null), []);

  // Existing `nr-organizer-image-slots` entries are base64 blobs with no
  // owner attribution, keyed by `venue-${Date.now()}` ids from the old mock
  // flow — uploading them on first sign-in would push unattributed blobs to
  // public Storage. Discard, don't migrate; tell the organizer once.
  const discardedLegacyImages = useRef(false);
  useEffect(() => {
    if (discardedLegacyImages.current) return;
    discardedLegacyImages.current = true;
    try {
      if (window.localStorage.getItem(LEGACY_IMAGE_STORAGE_KEY) === null) return;
      window.localStorage.removeItem(LEGACY_IMAGE_STORAGE_KEY);
      showSnack("Images now upload to Night Ride — please re-add any photos you dropped in before.");
    } catch {
      // Private mode / quota errors reading or clearing localStorage are
      // non-fatal — there is nothing left to migrate either way.
    }
  }, [showSnack]);

  const data = useMemo(
    () => ({ homeTab, audienceTab, accountTab, snack, confirmRemoveSlotId }),
    [homeTab, audienceTab, accountTab, snack, confirmRemoveSlotId]
  );

  return useMemo(
    () => ({
      data,
      loading: false,
      error: null,
      busy: false,
      actionError: "",
      setHomeTab,
      setAudienceTab,
      setAccountTab,
      showSnack,
      dismissSnack,
      requestRemoveImage,
      cancelRemoveImage,
    }),
    [data, showSnack, dismissSnack, requestRemoveImage, cancelRemoveImage]
  );
}

export type DashboardUiState = ReturnType<typeof useDashboardUi>;
