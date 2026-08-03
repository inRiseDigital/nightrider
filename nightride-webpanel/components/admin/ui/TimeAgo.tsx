"use client";

import { useEffect, useState } from "react";
import { formatDateTime, relativeTime } from "@/lib/admin/format";

// Renders the absolute timestamp on first paint (matches SSR output) then swaps to a
// relative label after mount, since "x minutes ago" is inherently non-deterministic
// between server render time and client hydration time.
export function TimeAgo({ iso }: { iso: string }) {
  const [label, setLabel] = useState(() => formatDateTime(iso));

  useEffect(() => {
    setLabel(relativeTime(iso));
  }, [iso]);

  return <span>{label}</span>;
}
