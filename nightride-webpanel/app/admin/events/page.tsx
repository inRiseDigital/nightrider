"use client";

import { useMemo, useState } from "react";
import { Eye, Pencil, RefreshCcw, Ban, Trash2 } from "lucide-react";
import { useAdminData } from "@/lib/admin/store";
import { useToast } from "@/components/admin/ui/Toast";
import { Card } from "@/components/admin/ui/Card";
import { SearchInput } from "@/components/admin/ui/SearchInput";
import { Select } from "@/components/admin/ui/Field";
import { Badge } from "@/components/admin/ui/Badge";
import { Tabs } from "@/components/admin/ui/Tabs";
import { Dropdown, DropdownItem } from "@/components/admin/ui/Dropdown";
import { DataTable, DataTableColumn } from "@/components/admin/ui/DataTable";
import { ConfirmDialog } from "@/components/admin/ui/ConfirmDialog";
import { useDataTable } from "@/lib/admin/useDataTable";
import { EventRecord, EventStatus } from "@/lib/admin/types";
import { EVENT_STATUS_LABELS, eventStatusVariant, formatDateTime } from "@/lib/admin/format";
import { EventDetailDrawer } from "./_components/EventDetailDrawer";
import { EditEventModal } from "./_components/EditEventModal";
import { ChangeStatusModal } from "./_components/ChangeStatusModal";

const CANCELLED_STATUSES: EventStatus[] = ["cancelled", "emergency_closure"];
const ACTIVE_STATUSES: EventStatus[] = ["draft", "scheduled", "starting_soon", "ongoing", "completed"];

export default function EventsPage() {
  const { events, cancelEvent, deleteEvent } = useAdminData();
  const toast = useToast();

  const [tab, setTab] = useState<"active" | "cancelled">("active");
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<"all" | EventStatus>("all");
  const [viewingEvent, setViewingEvent] = useState<EventRecord | null>(null);
  const [editingEvent, setEditingEvent] = useState<EventRecord | null>(null);
  const [changingStatusEvent, setChangingStatusEvent] = useState<EventRecord | null>(null);
  const [cancellingEvent, setCancellingEvent] = useState<EventRecord | null>(null);
  const [deletingEvent, setDeletingEvent] = useState<EventRecord | null>(null);

  const scoped = useMemo(
    () => events.filter((e) => (tab === "active" ? !CANCELLED_STATUSES.includes(e.status) : CANCELLED_STATUSES.includes(e.status))),
    [events, tab]
  );

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return scoped.filter((e) => {
      if (statusFilter !== "all" && e.status !== statusFilter) return false;
      if (!q) return true;
      return e.title.toLowerCase().includes(q) || e.clubName.toLowerCase().includes(q) || e.organizerName.toLowerCase().includes(q);
    });
  }, [scoped, search, statusFilter]);

  const table = useDataTable({
    rows: filtered,
    sortAccessors: {
      title: (e) => e.title.toLowerCase(),
      date: (e) => e.dateTime,
      attendees: (e) => e.attendeesCount,
    },
    initialSortKey: "date",
    pageSize: 8,
  });

  const statusOptions = tab === "active" ? ACTIVE_STATUSES : CANCELLED_STATUSES;

  const columns: DataTableColumn<EventRecord>[] = [
    {
      key: "title",
      header: "Event",
      sortable: true,
      render: (e) => (
        <div className="min-w-0">
          <p className="truncate text-sm font-medium text-nr-text-primary">{e.title}</p>
          <p className="truncate text-xs text-nr-text-hint">{e.location}</p>
        </div>
      ),
    },
    { key: "club", header: "Club", render: (e) => <span className="text-sm text-nr-text-secondary">{e.clubName}</span> },
    { key: "organizer", header: "Organizer", render: (e) => <span className="text-sm text-nr-text-secondary">{e.organizerName}</span> },
    {
      key: "date",
      header: "Date & time",
      sortable: true,
      render: (e) => <span className="text-sm text-nr-text-secondary">{formatDateTime(e.dateTime)}</span>,
    },
    {
      key: "status",
      header: "Status",
      render: (e) => <Badge variant={eventStatusVariant(e.status)}>{EVENT_STATUS_LABELS[e.status]}</Badge>,
    },
    {
      key: "attendees",
      header: "Attendees",
      sortable: true,
      render: (e) => <span className="text-sm text-nr-text-secondary">{e.attendeesCount}</span>,
    },
    {
      key: "created",
      header: "Created",
      render: (e) => <span className="text-sm text-nr-text-secondary">{formatDateTime(e.createdAt)}</span>,
    },
    {
      key: "actions",
      header: "",
      headerClassName: "w-10",
      render: (e) => {
        const isCancelled = CANCELLED_STATUSES.includes(e.status);
        const items: DropdownItem[] = [
          { label: "View details", icon: Eye, onClick: () => setViewingEvent(e) },
          { label: "Edit event", icon: Pencil, hidden: isCancelled, onClick: () => setEditingEvent(e) },
          { label: "Change status", icon: RefreshCcw, hidden: isCancelled, onClick: () => setChangingStatusEvent(e) },
          { label: "Cancel event", icon: Ban, hidden: isCancelled, danger: true, onClick: () => setCancellingEvent(e) },
          { label: "Delete event", icon: Trash2, danger: true, onClick: () => setDeletingEvent(e) },
        ];
        return <Dropdown items={items} />;
      },
    },
  ];

  return (
    <div className="space-y-4">
      <Card>
        <Tabs
          tabs={[
            { key: "active", label: "Active", count: events.filter((e) => !CANCELLED_STATUSES.includes(e.status)).length },
            { key: "cancelled", label: "Cancelled", count: events.filter((e) => CANCELLED_STATUSES.includes(e.status)).length },
          ]}
          active={tab}
          onChange={(k) => {
            setTab(k as "active" | "cancelled");
            setStatusFilter("all");
          }}
        />
        <div className="flex flex-col gap-3 border-b border-nr-border p-5 sm:flex-row sm:items-center">
          <SearchInput value={search} onChange={setSearch} placeholder="Search events, clubs, organizers..." className="sm:max-w-xs" />
          <Select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as typeof statusFilter)}
            options={[{ label: "All statuses", value: "all" }, ...statusOptions.map((s) => ({ label: EVENT_STATUS_LABELS[s], value: s }))]}
            className="sm:w-52"
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
          emptyTitle={tab === "active" ? "No active events match your filters" : "No cancelled events"}
        />
      </Card>

      <EventDetailDrawer event={viewingEvent} onClose={() => setViewingEvent(null)} />
      <EditEventModal key={`edit-${editingEvent?.id ?? "none"}`} event={editingEvent} onClose={() => setEditingEvent(null)} />
      <ChangeStatusModal key={`status-${changingStatusEvent?.id ?? "none"}`} event={changingStatusEvent} onClose={() => setChangingStatusEvent(null)} />

      <ConfirmDialog
        open={!!cancellingEvent}
        onClose={() => setCancellingEvent(null)}
        requireReason
        variant="danger"
        title="Cancel event"
        description={`Are you sure you want to cancel "${cancellingEvent?.title}"? It will move to the Cancelled tab.`}
        confirmLabel="Cancel event"
        onConfirm={(reason) => {
          if (!cancellingEvent || !reason) return;
          cancelEvent(cancellingEvent.id, reason);
          toast({ variant: "warning", title: "Event cancelled", description: `${cancellingEvent.title} was cancelled.` });
          setCancellingEvent(null);
        }}
      />

      <ConfirmDialog
        open={!!deletingEvent}
        onClose={() => setDeletingEvent(null)}
        variant="danger"
        title="Delete event"
        description={`This will remove "${deletingEvent?.title}" from the local mock list.`}
        confirmLabel="Delete event"
        backendNote="In a future backend implementation, this action should also delete the event record from the database."
        onConfirm={(reason) => {
          if (!deletingEvent) return;
          deleteEvent(deletingEvent.id, reason);
          toast({ variant: "error", title: "Event deleted", description: `${deletingEvent.title} was removed from local state.` });
          setDeletingEvent(null);
        }}
      />
    </div>
  );
}
