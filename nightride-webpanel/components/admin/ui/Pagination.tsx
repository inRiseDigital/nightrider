"use client";

import { ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "./Button";

export function Pagination({
  page,
  pageCount,
  totalItems,
  pageSize,
  onPageChange,
}: {
  page: number;
  pageCount: number;
  totalItems: number;
  pageSize: number;
  onPageChange: (page: number) => void;
}) {
  if (totalItems === 0) return null;
  const start = (page - 1) * pageSize + 1;
  const end = Math.min(page * pageSize, totalItems);

  return (
    <div className="flex flex-col items-center justify-between gap-3 border-t border-nr-border px-5 py-3 sm:flex-row">
      <p className="text-xs text-nr-text-secondary">
        Showing <span className="text-nr-text-primary">{start}</span>–
        <span className="text-nr-text-primary">{end}</span> of{" "}
        <span className="text-nr-text-primary">{totalItems}</span>
      </p>
      <div className="flex items-center gap-2">
        <Button variant="ghost" size="sm" disabled={page <= 1} onClick={() => onPageChange(page - 1)}>
          <ChevronLeft size={14} /> Prev
        </Button>
        <span className="text-xs text-nr-text-secondary">
          Page {page} of {pageCount}
        </span>
        <Button variant="ghost" size="sm" disabled={page >= pageCount} onClick={() => onPageChange(page + 1)}>
          Next <ChevronRight size={14} />
        </Button>
      </div>
    </div>
  );
}
