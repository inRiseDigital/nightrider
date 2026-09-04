"use client";

import { useEffect, useRef } from "react";

/**
 * A ref that always holds the latest `value`, so a stable callback can read
 * current state without listing it in a dep array — and without that state
 * propagating into every memo built on top of the callback.
 */
export function useLatest<T>(value: T) {
  const ref = useRef(value);
  useEffect(() => {
    ref.current = value;
  });
  return ref;
}
