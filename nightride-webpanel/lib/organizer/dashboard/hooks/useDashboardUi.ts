"use client";

import { useCallback, useMemo, useRef, useState, useSyncExternalStore } from "react";
import { imageSlotStore } from "../browser-stores";

export type HomeTab = "tonight" | "activity";
export type AudienceTab = "performance" | "reviews" | "ai-visibility";
export type AccountTab = "team" | "inbox" | "promotion" | "settings";
export type Toast = { id: number; text: string; tone: "info" | "error" };

/**
 * Pure cross-cutting UI state that no single domain owns: the destination tab
 * strips, the snackbar, and the localStorage-backed image slots (used by both
 * the venue and event editors, so they don't belong to either domain).
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

  const images = useSyncExternalStore(imageSlotStore.subscribe, imageSlotStore.getSnapshot, imageSlotStore.getServerSnapshot);
  const [confirmRemoveSlotId, setConfirmRemoveSlotId] = useState<string | null>(null);

  const setImage = useCallback((slotId: string, dataUrl: string) => imageSlotStore.set(slotId, dataUrl), []);
  const requestRemoveImage = useCallback((slotId: string) => setConfirmRemoveSlotId(slotId), []);
  const cancelRemoveImage = useCallback(() => setConfirmRemoveSlotId(null), []);
  const confirmRemoveImage = useCallback(() => {
    if (confirmRemoveSlotId) imageSlotStore.remove(confirmRemoveSlotId);
    setConfirmRemoveSlotId(null);
  }, [confirmRemoveSlotId]);

  const data = useMemo(
    () => ({ homeTab, audienceTab, accountTab, snack, images, confirmRemoveSlotId }),
    [homeTab, audienceTab, accountTab, snack, images, confirmRemoveSlotId]
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
      setImage,
      requestRemoveImage,
      cancelRemoveImage,
      confirmRemoveImage,
    }),
    [data, showSnack, dismissSnack, setImage, requestRemoveImage, cancelRemoveImage, confirmRemoveImage]
  );
}

export type DashboardUiState = ReturnType<typeof useDashboardUi>;
