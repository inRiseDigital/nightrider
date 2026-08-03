"use client";

import { useMemo, useRef, useState } from "react";

export type SortDirection = "asc" | "desc";

interface UseDataTableOptions<T> {
  rows: T[];
  sortAccessors: Record<string, (row: T) => string | number>;
  initialSortKey?: string;
  initialSortDir?: SortDirection;
  pageSize?: number;
}

export function useDataTable<T>({
  rows,
  sortAccessors,
  initialSortKey,
  initialSortDir = "asc",
  pageSize = 10,
}: UseDataTableOptions<T>) {
  const [sortKey, setSortKey] = useState<string | undefined>(initialSortKey);
  const [sortDir, setSortDir] = useState<SortDirection>(initialSortDir);
  const [page, setPage] = useState(1);

  // Read through a ref instead of depending on `sortAccessors` directly — callers pass a
  // fresh object literal every render, which would otherwise defeat this memo entirely.
  const sortAccessorsRef = useRef(sortAccessors);
  sortAccessorsRef.current = sortAccessors;

  const sorted = useMemo(() => {
    const accessor = sortKey ? sortAccessorsRef.current[sortKey] : undefined;
    if (!accessor) return rows;
    const copy = [...rows];
    copy.sort((a, b) => {
      const av = accessor(a);
      const bv = accessor(b);
      if (av < bv) return sortDir === "asc" ? -1 : 1;
      if (av > bv) return sortDir === "asc" ? 1 : -1;
      return 0;
    });
    return copy;
  }, [rows, sortKey, sortDir]);

  const pageCount = Math.max(1, Math.ceil(sorted.length / pageSize));
  const safePage = Math.min(page, pageCount);
  const paginated = sorted.slice((safePage - 1) * pageSize, safePage * pageSize);

  function toggleSort(key: string) {
    if (sortKey !== key) {
      setSortKey(key);
      setSortDir("asc");
    } else {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    }
    setPage(1);
  }

  return {
    rows: paginated,
    totalItems: sorted.length,
    page: safePage,
    pageCount,
    pageSize,
    setPage,
    sortKey,
    sortDir,
    toggleSort,
  };
}
