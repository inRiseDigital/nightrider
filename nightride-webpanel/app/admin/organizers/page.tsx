"use client";

import { useMemo, useState } from "react";
import { Eye, Check, X as XIcon, Pause, Play, Ban, Building2, UserMinus } from "lucide-react";
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
import { PlatformUser } from "@/lib/admin/types";
import { accountStatusVariant, approvalVariant, capitalize } from "@/lib/admin/format";
import { UserDetailDrawer } from "@/components/admin/shared/UserDetailDrawer";
import { AssignClubModal } from "@/components/admin/shared/AssignClubModal";

type ConfirmKind = "deactivate" | "ban" | "removePrivileges" | "reject";

const ORGANIZER_CONFIRM_COPY: Record<ConfirmKind, { title: string; confirmLabel: string; verb: string }> = {
  deactivate: { title: "Deactivate account", confirmLabel: "Deactivate", verb: "deactivate" },
  ban: { title: "Ban account", confirmLabel: "Ban user", verb: "ban" },
  reject: { title: "Reject organizer request", confirmLabel: "Reject", verb: "reject the organizer request from" },
  removePrivileges: {
    title: "Remove organizer privileges",
    confirmLabel: "Remove privileges",
    verb: "remove organizer privileges from",
  },
};

export default function OrganizersPage() {
  const { users, clubs, approveOrganizer, rejectOrganizer, deactivateUser, activateUser, banUser, unbanUser, removeOrganizerAccess } =
    useAdminData();
  const toast = useToast();

  const [search, setSearch] = useState("");
  const [approvalFilter, setApprovalFilter] = useState<"all" | "pending" | "approved" | "rejected">("all");
  const [viewingUser, setViewingUser] = useState<PlatformUser | null>(null);
  const [assigningUser, setAssigningUser] = useState<PlatformUser | null>(null);
  const [confirmAction, setConfirmAction] = useState<{ kind: ConfirmKind; user: PlatformUser } | null>(null);

  const organizers = useMemo(() => users.filter((u) => u.isOrganizer), [users]);
  const clubById = useMemo(() => new Map(clubs.map((c) => [c.id, c])), [clubs]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return organizers.filter((u) => {
      if (approvalFilter !== "all" && u.organizerDetails?.approvalStatus !== approvalFilter) return false;
      if (!q) return true;
      return u.fullName.toLowerCase().includes(q) || u.email.toLowerCase().includes(q);
    });
  }, [organizers, search, approvalFilter]);

  const table = useDataTable({
    rows: filtered,
    sortAccessors: {
      name: (u) => u.fullName.toLowerCase(),
      events: (u) => u.organizerDetails?.eventsCreated ?? 0,
    },
    initialSortKey: "name",
    pageSize: 8,
  });

  const columns: DataTableColumn<PlatformUser>[] = [
    {
      key: "name",
      header: "Organizer",
      sortable: true,
      render: (u) => (
        <div className="flex items-center gap-3">
          <Avatar name={u.fullName} src={u.avatarUrl} />
          <div className="min-w-0">
            <p className="truncate text-sm font-medium text-nr-text-primary">{u.fullName}</p>
            <p className="truncate text-xs text-nr-text-hint">{u.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: "contact",
      header: "Contact",
      render: (u) => (
        <div className="text-sm text-nr-text-secondary">
          <p>{u.phone ?? "—"}</p>
          <p className="text-xs text-nr-text-hint">{u.instagram}</p>
        </div>
      ),
    },
    {
      key: "approval",
      header: "Approval",
      render: (u) => (
        <Badge variant={approvalVariant(u.organizerDetails?.approvalStatus ?? "pending")}>
          {capitalize(u.organizerDetails?.approvalStatus ?? "pending")}
        </Badge>
      ),
    },
    {
      key: "status",
      header: "Account status",
      render: (u) => (
        <Badge variant={accountStatusVariant(u.accountStatus)}>
          {capitalize(u.accountStatus)}
        </Badge>
      ),
    },
    {
      key: "club",
      header: "Assigned club",
      render: (u) => {
        const club = u.organizerDetails?.clubId ? clubById.get(u.organizerDetails.clubId) : undefined;
        return <span className="text-sm text-nr-text-secondary">{club?.name ?? "Unassigned"}</span>;
      },
    },
    {
      key: "events",
      header: "Events",
      sortable: true,
      render: (u) => <span className="text-sm text-nr-text-secondary">{u.organizerDetails?.eventsCreated ?? 0}</span>,
    },
    {
      key: "activity",
      header: "Recent activity",
      render: (u) => (
        <span className="text-sm text-nr-text-secondary">{u.organizerDetails?.recentActivity[0] ?? "No recent activity"}</span>
      ),
    },
    {
      key: "actions",
      header: "",
      headerClassName: "w-10",
      render: (u) => {
        const pending = u.organizerDetails?.approvalStatus === "pending";
        const items: DropdownItem[] = [
          { label: "View details", icon: Eye, onClick: () => setViewingUser(u) },
          { label: "Approve organizer", icon: Check, hidden: !pending, onClick: () => {
            approveOrganizer(u.id);
            toast({ variant: "success", title: "Organizer approved", description: `${u.fullName} is now an approved organizer.` });
          } },
          { label: "Reject organizer", icon: XIcon, hidden: !pending, danger: true, onClick: () => setConfirmAction({ kind: "reject", user: u }) },
          { label: "Assign / change club", icon: Building2, onClick: () => setAssigningUser(u) },
          {
            label: "Activate account",
            icon: Play,
            hidden: u.accountStatus === "active",
            onClick: () => {
              activateUser(u.id);
              toast({ variant: "success", title: "Account activated", description: `${u.fullName}'s account is active again.` });
            },
          },
          {
            label: "Deactivate account",
            icon: Pause,
            hidden: u.accountStatus !== "active",
            onClick: () => setConfirmAction({ kind: "deactivate", user: u }),
          },
          {
            label: "Unban account",
            icon: Play,
            hidden: u.accountStatus !== "banned",
            onClick: () => {
              unbanUser(u.id);
              toast({ variant: "success", title: "Account unbanned", description: `${u.fullName} can access the platform again.` });
            },
          },
          {
            label: "Ban account",
            icon: Ban,
            hidden: u.accountStatus === "banned",
            danger: true,
            onClick: () => setConfirmAction({ kind: "ban", user: u }),
          },
          {
            label: "Remove organizer privileges",
            icon: UserMinus,
            danger: true,
            onClick: () => setConfirmAction({ kind: "removePrivileges", user: u }),
          },
        ];
        return <Dropdown items={items} />;
      },
    },
  ];

  return (
    <div className="space-y-4">
      <Card>
        <div className="flex flex-col gap-3 border-b border-nr-border p-5 sm:flex-row sm:items-center">
          <SearchInput value={search} onChange={setSearch} placeholder="Search organizers..." className="sm:max-w-xs" />
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
          getRowId={(u) => u.id}
          sortKey={table.sortKey}
          sortDir={table.sortDir}
          onSort={table.toggleSort}
          page={table.page}
          pageCount={table.pageCount}
          totalItems={table.totalItems}
          pageSize={table.pageSize}
          onPageChange={table.setPage}
          emptyTitle="No organizers match your filters"
        />
      </Card>

      <UserDetailDrawer user={viewingUser} onClose={() => setViewingUser(null)} />
      <AssignClubModal key={assigningUser?.id ?? "none"} user={assigningUser} onClose={() => setAssigningUser(null)} />

      <ConfirmDialog
        open={!!confirmAction}
        onClose={() => setConfirmAction(null)}
        requireReason
        variant="danger"
        title={confirmAction ? ORGANIZER_CONFIRM_COPY[confirmAction.kind].title : ""}
        description={
          confirmAction
            ? `Are you sure you want to ${ORGANIZER_CONFIRM_COPY[confirmAction.kind].verb} ${confirmAction.user.fullName}?`
            : ""
        }
        confirmLabel={confirmAction ? ORGANIZER_CONFIRM_COPY[confirmAction.kind].confirmLabel : ""}
        onConfirm={(reason) => {
          if (!confirmAction) return;
          const { kind, user } = confirmAction;
          if (kind === "deactivate") {
            deactivateUser(user.id, reason);
            toast({ variant: "warning", title: "Account deactivated", description: `${user.fullName}'s account was deactivated.` });
          } else if (kind === "ban") {
            banUser(user.id, reason);
            toast({ variant: "error", title: "Account banned", description: `${user.fullName} was banned from the platform.` });
          } else if (kind === "reject") {
            rejectOrganizer(user.id, reason);
            toast({ variant: "warning", title: "Organizer request rejected", description: `${user.fullName}'s request was rejected.` });
          } else if (kind === "removePrivileges") {
            removeOrganizerAccess(user.id, reason);
            toast({ variant: "warning", title: "Organizer privileges removed", description: `${user.fullName} is no longer an organizer.` });
          }
          setConfirmAction(null);
        }}
      />
    </div>
  );
}
