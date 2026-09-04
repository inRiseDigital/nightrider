"use client";

import { useCallback, useState } from "react";
import { describeFirestoreError } from "../data/errors";

/**
 * `runAction` from `lib/admin/useVenueDetail.ts`, hoisted for every domain
 * hook to share, with one change: it returns a boolean. That matters because
 * `commitEvent` used to close the editor unconditionally — once the write
 * can fail, that would discard the organizer's work on a permission error.
 * Every dialog-closing mutation becomes `if (await run(...)) close();`.
 */
export function useAsyncAction(reload?: () => Promise<void>) {
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState("");

  const run = useCallback(
    async (fn: () => Promise<void>): Promise<boolean> => {
      setBusy(true);
      setActionError("");
      try {
        await fn();
        await reload?.();
        return true;
      } catch (err) {
        setActionError(describeFirestoreError(err));
        return false;
      } finally {
        setBusy(false);
      }
    },
    [reload]
  );

  return { busy, actionError, clearActionError: () => setActionError(""), run };
}
