"use client";

import { useMemo, useState } from "react";
import { Eye, Check, X as XIcon, Pencil, Pause, Play, Trash2 } from "lucide-react";
import { useAdminData } from "@/lib/admin/store";
import { useToast } from "@/components/admin/ui/Toast";
import { Card } from "@/components/admin/ui/Card";
import { SearchInput } from "@/components/admin/ui/SearchInput";
import { Select } from "@/components/admin/ui/Field";
import { Badge } from "@/components/admin/ui/Badge";
import { Avatar } from "@/components/admin/ui/Avatar";
import { Dropdown, DropdownItem } from "@/components/admin/ui/Dropdown";
import { DataTable, DataTableColumn } from "@/components/admin/ui/DataTable";
import { ConfirmDialog } from "@/components/admin/ui/ConfirmDialog";
import { useDataTable } from "@/lib/admin/useDataTable";
import { Club } from "@/lib/admin/types";
import { approvalVariant, capitalize, clubStatusVariant, formatDate } from "@/lib/admin/format";
import { ClubDetailDrawer } from "./_components/ClubDetailDrawer";
import { EditClubModal } from "./_components/EditClubModal";

type ConfirmKind = "reject" | "deactivate" | "activate" | "delete";

const CLUB_CONFIRM_COPY: Record<
  ConfirmKind,
  { title: string; confirmLabel: string; description: (name: string) => string; backendNote?: string }
> = {
  reject: {
    title: "Reject submitted changes",
    confirmLabel: "Reject",
    description: (name) => `Are you sure you want to reject the submitted changes for ${name}?`,
  },
  deactivate: {
    title: "Deactivate club",
    confirmLabel: "Deactivate",
    description: (name) => `Are you sure you want to deactivate ${name}?`,
  },
  activate: {
    title: "Activate club",
    confirmLabel: "Activate",
    description: (name) => `Are you sure you want to activate ${name}?`,
  },
  delete: {
    title: "Delete club",
    confirmLabel: "Delete club",
    description: (name) => `This will remove ${name} from the local mock list.`,
    backendNote: "In a future backend implementation, this action should also delete the club record from the database.",
  },
};

export default function ClubsPage() {
  const { clubs, approveClub, rejectClub, setClubStatus, deleteClub } = useAdminData();
  const toast = useToast();

  const [search, setSearch] = useState("");
  const [approvalFilter, setApprovalFilter] = useState<"all" | "pending" | "approved" | "rejected">("all");
  const [viewingClub, setViewingClub] = useState<Club | null>(null);
  const [editingClub, setEditingClub] = useState<Club | null>(null);
  const [confirmAction, setConfirmAction] = useState<{ kind: ConfirmKind; club: Club } | null>(null);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return clubs.filter((c) => {
      if (approvalFilter !== "all" && c.approvalStatus !== approvalFilter) return false;
      if (!q) return true;
      return c.name.toLowerCase().includes(q) || (c.organizerName ?? "").toLowerCase().includes(q);
    });
  }, [clubs, search, approvalFilter]);

  const table = useDataTable({
    rows: filtered,
    sortAccessors: {
      name: (c) => c.name.toLowerCase(),
      updated: (c) => c.lastUpdatedAt,
      events: (c) => c.upcomingEventsCount,
    },
    initialSortKey: "name",
    pageSize: 8,
  });

  const columns: DataTableColumn<Club>[] = [
    {
      key: "name",
      header: "Club",
      sortable: true,
      render: (c) => (
        <div className="flex items-center gap-3">
          <Avatar name={c.name} src={c.logoUrl} />
          <div className="min-w-0">
            <p className="truncate text-sm font-medium text-nr-text-primary">{c.name}</p>
            <p className="truncate text-xs text-nr-text-hint">{c.location}</p>
          </div>
        </div>
      ),
    },
    {
      key: "organizer",
      header: "Organizer",
      render: (c) => <span className="text-sm text-nr-text-secondary">{c.organizerName ?? "Unassigned"}</span>,
    },
    {
      key: "status",
      header: "Status",
      render: (c) => <Badge variant={clubStatusVariant(c.status)}>{capitalize(c.status)}</Badge>,
    },
    {
      key: "approval",
      header: "Approval",
      render: (c) => (
        <Badge variant={approvalVariant(c.approvalStatus)}>{capitalize(c.approvalStatus)}</Badge>
      ),
    },
    {
      key: "contact",
      header: "Contact",
      render: (c) => (
        <div className="text-sm text-nr-text-secondary">
          <p>{c.contactEmail}</p>
          <p className="text-xs text-nr-text-hint">{c.contactPhone}</p>
        </div>
      ),
    },
    {
      key: "events",
      header: "Upcoming events",
      sortable: true,
      render: (c) => <span className="text-sm text-nr-text-secondary">{c.upcomingEventsCount}</span>,
    },
    {
      key: "updated",
      header: "Last updated",
      sortable: true,
      render: (c) => <span className="text-sm text-nr-text-secondary">{formatDate(c.lastUpdatedAt)}</span>,
    },
    {
      key: "actions",
      header: "",
      headerClassName: "w-10",
      render: (c) => {
        const pending = c.approvalStatus === "pending";
        const items: DropdownItem[] = [
          { label: "View details", icon: Eye, onClick: () => setViewingClub(c) },
          { label: "Approve club information", icon: Check, hidden: !pending, onClick: () => {
            approveClub(c.id);
            toast({ variant: "success", title: "Club approved", description: `${c.name}'s information was approved.` });
          } },
          { label: "Reject submitted changes", icon: XIcon, hidden: !pending, danger: true, onClick: () => setConfirmAction({ kind: "reject", club: c }) },
          { label: "Edit club information", icon: Pencil, onClick: () => setEditingClub(c) },
          {
            label: "Activate club",
            icon: Play,
            hidden: c.status === "active",
            onClick: () => setConfirmAction({ kind: "activate", club: c }),
          },
          {
            label: "Deactivate club",
            icon: Pause,
            hidden: c.status !== "active",
            danger: true,
            onClick: () => setConfirmAction({ kind: "deactivate", club: c }),
          },
          { label: "Delete club", icon: Trash2, danger: true, onClick: () => setConfirmAction({ kind: "delete", club: c }) },
        ];
        return <Dropdown items={items} />;
      },
    },
  ];

  return (
    <div className="space-y-4">
      <Card>
        <div className="flex flex-col gap-3 border-b border-nr-border p-5 sm:flex-row sm:items-center">
          <SearchInput value={search} onChange={setSearch} placeholder="Search clubs or organizers..." className="sm:max-w-xs" />
          <Select
            value={approvalFilter}
            onChange={(e) => setApprovalFilter(e.target.value as typeof approvalFilter)}
            options={[
              { label: "All approval statuses", value: "all" },
              { label: "Pending", value: "pending" },
              { label: "Approved", value: "approved" },
              { label: "Rejected", value: "rejected" },
            ]}
            className="sm:w-52"
          />
        </div>
        <DataTable
          columns={columns}
          rows={table.rows}
          getRowId={(c) => c.id}
          sortKey={table.sortKey}
          sortDir={table.sortDir}
          onSort={table.toggleSort}
          page={table.page}
          pageCount={table.pageCount}
          totalItems={table.totalItems}
          pageSize={table.pageSize}
          onPageChange={table.setPage}
          emptyTitle="No clubs match your filters"
        />
      </Card>

      <ClubDetailDrawer club={viewingClub} onClose={() => setViewingClub(null)} />
      <EditClubModal key={editingClub?.id ?? "none"} club={editingClub} onClose={() => setEditingClub(null)} />

      <ConfirmDialog
        open={!!confirmAction}
        onClose={() => setConfirmAction(null)}
        requireReason={confirmAction?.kind !== "activate"}
        variant={confirmAction?.kind === "activate" ? "primary" : "danger"}
        title={confirmAction ? CLUB_CONFIRM_COPY[confirmAction.kind].title : ""}
        description={confirmAction ? CLUB_CONFIRM_COPY[confirmAction.kind].description(confirmAction.club.name) : ""}
        confirmLabel={confirmAction ? CLUB_CONFIRM_COPY[confirmAction.kind].confirmLabel : ""}
        backendNote={confirmAction ? CLUB_CONFIRM_COPY[confirmAction.kind].backendNote : undefined}
        onConfirm={(reason) => {
          if (!confirmAction) return;
          const { kind, club } = confirmAction;
          if (kind === "reject") {
            rejectClub(club.id, reason);
            toast({ variant: "warning", title: "Changes rejected", description: `${club.name}'s submitted changes were rejected.` });
          } else if (kind === "deactivate") {
            setClubStatus(club.id, "deactivated", reason);
            toast({ variant: "warning", title: "Club deactivated", description: `${club.name} is now deactivated.` });
          } else if (kind === "activate") {
            setClubStatus(club.id, "active");
            toast({ variant: "success", title: "Club activated", description: `${club.name} is now active.` });
          } else if (kind === "delete") {
            deleteClub(club.id, reason);
            toast({ variant: "error", title: "Club deleted", description: `${club.name} was removed from local state.` });
          }
          setConfirmAction(null);
        }}
      />
    </div>
  );
}
