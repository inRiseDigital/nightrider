"use client";

import { useCallback, useEffect, useRef } from "react";
import { useLatest } from "./useLatest";

const DEBOUNCE_MS = 800;

/**
 * Debounces a field-level write by 800ms, coalescing keystrokes into one
 * commit. Flushes immediately on blur (call `flush` from the field's
 * `onBlur`) and on unmount, so a write is never silently dropped.
 */
export function useDebouncedWrite<T>(write: (value: T) => void) {
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pending = useRef<{ value: T } | null>(null);
  const writeRef = useLatest(write);

  const flush = useCallback(() => {
    if (timer.current) {
      clearTimeout(timer.current);
      timer.current = null;
    }
    if (pending.current) {
      writeRef.current(pending.current.value);
      pending.current = null;
    }
  }, [writeRef]);

  const schedule = useCallback(
    (value: T) => {
      pending.current = { value };
      if (timer.current) clearTimeout(timer.current);
      timer.current = setTimeout(flush, DEBOUNCE_MS);
    },
    [flush]
  );

  useEffect(() => flush, [flush]);

  return { schedule, flush };
}
