"use client";

import { useMemo, useState } from "react";
import { useAdminData } from "@/lib/admin/store";
import { Card } from "@/components/admin/ui/Card";
import { SearchInput } from "@/components/admin/ui/SearchInput";
import { Select } from "@/components/admin/ui/Field";
import { Badge } from "@/components/admin/ui/Badge";
import { DataTable, DataTableColumn } from "@/components/admin/ui/DataTable";
import { useDataTable } from "@/lib/admin/useDataTable";
import { ActivityLogEntry, ActivityTargetType } from "@/lib/admin/types";
import { ACTIVITY_ACTION_LABELS } from "@/lib/admin/constants";
import { capitalize, formatDateTime } from "@/lib/admin/format";

const TARGET_TYPES: ActivityTargetType[] = ["user", "organizer", "admin", "club", "event", "role"];

export default function ActivityLogPage() {
  const { activityLog } = useAdminData();
  const [search, setSearch] = useState("");
  const [targetFilter, setTargetFilter] = useState<"all" | ActivityTargetType>("all");

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return activityLog.filter((entry) => {
      if (targetFilter !== "all" && entry.targetType !== targetFilter) return false;
      if (!q) return true;
      return (
        entry.adminName.toLowerCase().includes(q) ||
        entry.targetLabel.toLowerCase().includes(q) ||
        ACTIVITY_ACTION_LABELS[entry.actionType].toLowerCase().includes(q)
      );
    });
  }, [activityLog, search, targetFilter]);

  const table = useDataTable({
    rows: filtered,
    sortAccessors: { timestamp: (e) => e.timestamp },
    initialSortKey: "timestamp",
    initialSortDir: "desc",
    pageSize: 12,
  });

  const columns: DataTableColumn<ActivityLogEntry>[] = [
    {
      key: "admin",
      header: "Admin",
      render: (e) => <span className="text-sm font-medium text-nr-text-primary">{e.adminName}</span>,
    },
    {
      key: "action",
      header: "Action",
      render: (e) => <span className="text-sm text-nr-text-primary">{ACTIVITY_ACTION_LABELS[e.actionType]}</span>,
    },
    {
      key: "target",
      header: "Affected",
      render: (e) => (
        <div className="flex items-center gap-2">
          <Badge variant="neutral">{e.targetType}</Badge>
          <span className="text-sm text-nr-text-secondary">{e.targetLabel}</span>
        </div>
      ),
    },
    {
      key: "change",
      header: "Change",
      render: (e) =>
        e.previousValue || e.newValue ? (
          <span className="text-sm text-nr-text-secondary">
            {e.previousValue && <span className="line-through opacity-60">{e.previousValue}</span>}
            {e.previousValue && e.newValue && " → "}
            {e.newValue && <span>{e.newValue}</span>}
          </span>
        ) : (
          <span className="text-sm text-nr-text-hint">—</span>
        ),
    },
    {
      key: "reason",
      header: "Reason",
      render: (e) => <span className="text-sm text-nr-text-secondary">{e.reason ?? "—"}</span>,
    },
    {
      key: "timestamp",
      header: "Date & time",
      sortable: true,
      render: (e) => <span className="text-sm text-nr-text-secondary">{formatDateTime(e.timestamp)}</span>,
    },
  ];

  return (
    <Card>
      <div className="flex flex-col gap-3 border-b border-nr-border p-5 sm:flex-row sm:items-center">
        <SearchInput value={search} onChange={setSearch} placeholder="Search by admin, action, or target..." className="sm:max-w-xs" />
        <Select
          value={targetFilter}
          onChange={(e) => setTargetFilter(e.target.value as typeof targetFilter)}
          options={[{ label: "All types", value: "all" }, ...TARGET_TYPES.map((t) => ({ label: capitalize(t), value: t }))]}
          className="sm:w-44"
        />
      </div>
      <DataTable
        columns={columns}
        rows={table.rows}
        getRowId={(e) => e.id}
        sortKey={table.sortKey}
        sortDir={table.sortDir}
        onSort={table.toggleSort}
        page={table.page}
        pageCount={table.pageCount}
        totalItems={table.totalItems}
        pageSize={table.pageSize}
        onPageChange={table.setPage}
        emptyTitle="No activity recorded yet"
        emptyDescription="Actions performed across the admin panel will appear here."
      />
    </Card>
  );
}
