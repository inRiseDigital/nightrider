"use client";

import { useMemo, useState } from "react";
import { Eye, ShieldMinus, UserPlus } from "lucide-react";
import { useAdminData } from "@/lib/admin/store";
import { useToast } from "@/components/admin/ui/Toast";
import { Card } from "@/components/admin/ui/Card";
import { SearchInput } from "@/components/admin/ui/SearchInput";
import { Badge } from "@/components/admin/ui/Badge";
import { Avatar } from "@/components/admin/ui/Avatar";
import { Button } from "@/components/admin/ui/Button";
import { Dropdown, DropdownItem } from "@/components/admin/ui/Dropdown";
import { DataTable, DataTableColumn } from "@/components/admin/ui/DataTable";
import { ConfirmDialog } from "@/components/admin/ui/ConfirmDialog";
import { useDataTable } from "@/lib/admin/useDataTable";
import { PlatformUser } from "@/lib/admin/types";
import { ADMIN_ACCESS_LEVEL_LABELS } from "@/lib/admin/constants";
import { accountStatusVariant, capitalize, formatDateTime } from "@/lib/admin/format";
import { UserDetailDrawer } from "@/components/admin/shared/UserDetailDrawer";
import { AddAdminDrawer } from "./_components/AddAdminDrawer";

export default function AdminsPage() {
  const { users, activityLog, currentAdmin, removeAdminAccess } = useAdminData();
  const toast = useToast();

  const [search, setSearch] = useState("");
  const [viewingUser, setViewingUser] = useState<PlatformUser | null>(null);
  const [addOpen, setAddOpen] = useState(false);
  const [removingUser, setRemovingUser] = useState<PlatformUser | null>(null);

  const admins = useMemo(() => users.filter((u) => u.isAdmin), [users]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return admins;
    return admins.filter((u) => u.fullName.toLowerCase().includes(q) || u.email.toLowerCase().includes(q));
  }, [admins, search]);

  const latestActivityByAdminId = useMemo(() => {
    const map = new Map<string, (typeof activityLog)[number]>();
    for (const entry of activityLog) {
      if (!map.has(entry.adminId)) map.set(entry.adminId, entry);
    }
    return map;
  }, [activityLog]);

  const table = useDataTable({
    rows: filtered,
    sortAccessors: {
      name: (u) => u.fullName.toLowerCase(),
      granted: (u) => u.adminDetails?.grantedAt ?? "",
    },
    initialSortKey: "name",
    pageSize: 8,
  });

  const columns: DataTableColumn<PlatformUser>[] = [
    {
      key: "name",
      header: "Admin",
      sortable: true,
      render: (u) => (
        <div className="flex items-center gap-3">
          <Avatar name={u.fullName} src={u.avatarUrl} />
          <div className="min-w-0">
            <p className="truncate text-sm font-medium text-nr-text-primary">
              {u.fullName} {u.id === currentAdmin.id && <span className="text-xs text-nr-text-hint">(you)</span>}
            </p>
            <p className="truncate text-xs text-nr-text-hint">{u.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: "level",
      header: "Access level",
      render: (u) => <Badge variant="info">{u.adminDetails ? ADMIN_ACCESS_LEVEL_LABELS[u.adminDetails.accessLevel] : "—"}</Badge>,
    },
    {
      key: "granted",
      header: "Granted",
      sortable: true,
      render: (u) => <span className="text-sm text-nr-text-secondary">{u.adminDetails ? formatDateTime(u.adminDetails.grantedAt) : "—"}</span>,
    },
    {
      key: "grantedBy",
      header: "Granted by",
      render: (u) => <span className="text-sm text-nr-text-secondary">{u.adminDetails?.grantedBy ?? "—"}</span>,
    },
    {
      key: "status",
      header: "Status",
      render: (u) => (
        <Badge variant={accountStatusVariant(u.accountStatus)}>{capitalize(u.accountStatus)}</Badge>
      ),
    },
    {
      key: "activity",
      header: "Recent activity",
      render: (u) => {
        const last = latestActivityByAdminId.get(u.id);
        return <span className="text-sm text-nr-text-secondary">{last ? last.targetLabel : "No activity yet"}</span>;
      },
    },
    {
      key: "actions",
      header: "",
      headerClassName: "w-10",
      render: (u) => {
        const items: DropdownItem[] = [
          { label: "View details", icon: Eye, onClick: () => setViewingUser(u) },
          {
            label: u.id === currentAdmin.id ? "Remove admin access (not allowed)" : "Remove admin access",
            icon: ShieldMinus,
            danger: true,
            disabled: u.id === currentAdmin.id,
            onClick: () => setRemovingUser(u),
          },
        ];
        return <Dropdown items={items} />;
      },
    },
  ];

  return (
    <div className="space-y-4">
      <Card>
        <div className="flex flex-col gap-3 border-b border-nr-border p-5 sm:flex-row sm:items-center sm:justify-between">
          <SearchInput value={search} onChange={setSearch} placeholder="Search admins..." className="sm:max-w-xs" />
          <Button onClick={() => setAddOpen(true)}>
            <UserPlus size={16} /> Add admin
          </Button>
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
          emptyTitle="No admins match your search"
        />
      </Card>

      <UserDetailDrawer user={viewingUser} onClose={() => setViewingUser(null)} />
      <AddAdminDrawer open={addOpen} onClose={() => setAddOpen(false)} />

      <ConfirmDialog
        open={!!removingUser}
        onClose={() => setRemovingUser(null)}
        requireReason
        variant="danger"
        title="Remove admin access"
        description={`Are you sure you want to remove admin access from ${removingUser?.fullName}?`}
        confirmLabel="Remove access"
        onConfirm={(reason) => {
          if (!removingUser) return;
          removeAdminAccess(removingUser.id, reason);
          toast({ variant: "warning", title: "Admin access removed", description: `${removingUser.fullName} is no longer an admin.` });
          setRemovingUser(null);
        }}
      />
    </div>
  );
}
