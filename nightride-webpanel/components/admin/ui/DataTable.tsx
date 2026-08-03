"use client";

import { ReactNode } from "react";
import { ArrowDown, ArrowUp, ArrowUpDown } from "lucide-react";
import { cn } from "./cn";
import { TableSkeleton } from "./Skeleton";
import { EmptyState } from "./EmptyState";
import { Pagination } from "./Pagination";
import { SortDirection } from "@/lib/admin/useDataTable";

export interface DataTableColumn<T> {
  key: string;
  header: string;
  render: (row: T) => ReactNode;
  sortable?: boolean;
  className?: string;
  headerClassName?: string;
}

export function DataTable<T>({
  columns,
  rows,
  getRowId,
  loading,
  emptyTitle = "No results found",
  emptyDescription = "Try adjusting your search or filters.",
  sortKey,
  sortDir,
  onSort,
  page,
  pageCount,
  totalItems,
  pageSize,
  onPageChange,
}: {
  columns: DataTableColumn<T>[];
  rows: T[];
  getRowId: (row: T) => string;
  loading?: boolean;
  emptyTitle?: string;
  emptyDescription?: string;
  sortKey?: string;
  sortDir?: SortDirection;
  onSort?: (key: string) => void;
  page: number;
  pageCount: number;
  totalItems: number;
  pageSize: number;
  onPageChange: (page: number) => void;
}) {
  if (loading) return <TableSkeleton cols={columns.length} />;
  if (rows.length === 0) return <EmptyState title={emptyTitle} description={emptyDescription} />;

  return (
    <div className="flex flex-col">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[720px] text-left text-sm">
          <thead>
            <tr className="border-b border-nr-border">
              {columns.map((col) => (
                <th
                  key={col.key}
                  className={cn(
                    "whitespace-nowrap px-5 py-3 text-xs font-medium uppercase tracking-wider text-nr-text-hint",
                    col.headerClassName
                  )}
                >
                  {col.sortable ? (
                    <button
                      onClick={() => onSort?.(col.key)}
                      className="flex items-center gap-1 hover:text-nr-text-primary"
                    >
                      {col.header}
                      {sortKey === col.key ? (
                        sortDir === "asc" ? (
                          <ArrowUp size={12} />
                        ) : (
                          <ArrowDown size={12} />
                        )
                      ) : (
                        <ArrowUpDown size={12} className="opacity-40" />
                      )}
                    </button>
                  ) : (
                    col.header
                  )}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-nr-border">
            {rows.map((row) => (
              <tr key={getRowId(row)} className="transition-colors hover:bg-white/[0.02]">
                {columns.map((col) => (
                  <td key={col.key} className={cn("px-5 py-3 align-middle", col.className)}>
                    {col.render(row)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination page={page} pageCount={pageCount} totalItems={totalItems} pageSize={pageSize} onPageChange={onPageChange} />
    </div>
  );
}
