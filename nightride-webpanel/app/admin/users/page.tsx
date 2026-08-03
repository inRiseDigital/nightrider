"use client";

import { useMemo, useState } from "react";
import {
  Eye,
  ShieldCheck,
  ShieldOff,
  Play,
  Pause,
  Ban,
  UserCog,
  UserMinus,
  ShieldPlus,
  ShieldMinus,
  Repeat,
} from "lucide-react";
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
import { PlatformUser, Role } from "@/lib/admin/types";
import { ROLES, ROLE_LABELS } from "@/lib/admin/constants";
import { accountStatusVariant, capitalize, formatDate, verificationVariant } from "@/lib/admin/format";
import { UserDetailDrawer } from "@/components/admin/shared/UserDetailDrawer";
import { ChangeRoleModal } from "@/components/admin/shared/ChangeRoleModal";
import { PromoteOrganizerModal } from "@/components/admin/shared/PromoteOrganizerModal";
import { GrantAdminAccessModal } from "@/components/admin/shared/GrantAdminAccessModal";

type ConfirmKind = "deactivate" | "ban" | "removeOrganizer" | "removeAdmin";

const USER_CONFIRM_COPY: Record<ConfirmKind, { title: string; confirmLabel: string; verb: string }> = {
  deactivate: { title: "Deactivate account", confirmLabel: "Deactivate", verb: "deactivate" },
  ban: { title: "Ban account", confirmLabel: "Ban user", verb: "ban" },
  removeOrganizer: {
    title: "Remove organizer access",
    confirmLabel: "Remove access",
    verb: "remove organizer access for",
  },
  removeAdmin: {
    title: "Remove admin access",
    confirmLabel: "Remove admin access",
    verb: "remove admin access for",
  },
};

export default function UsersPage() {
  const {
    users,
    clubs,
    currentAdmin,
    verifyUser,
    unverifyUser,
    activateUser,
    deactivateUser,
    banUser,
    unbanUser,
    removeOrganizerAccess,
    removeAdminAccess,
  } = useAdminData();
  const toast = useToast();

  const [search, setSearch] = useState("");
  const [roleFilter, setRoleFilter] = useState<"all" | Role>("all");
  const [verificationFilter, setVerificationFilter] = useState<"all" | "verified" | "unverified">("all");
  const [statusFilter, setStatusFilter] = useState<"all" | "active" | "deactivated" | "banned">("all");

  const [viewingUser, setViewingUser] = useState<PlatformUser | null>(null);
  const [changingRoleUser, setChangingRoleUser] = useState<PlatformUser | null>(null);
  const [promotingUser, setPromotingUser] = useState<PlatformUser | null>(null);
  const [grantingAdminUser, setGrantingAdminUser] = useState<PlatformUser | null>(null);
  const [confirmAction, setConfirmAction] = useState<{ kind: ConfirmKind; user: PlatformUser } | null>(null);

  const clubById = useMemo(() => new Map(clubs.map((c) => [c.id, c])), [clubs]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return users.filter((u) => {
      if (roleFilter !== "all" && u.role !== roleFilter) return false;
      if (verificationFilter !== "all" && u.verificationStatus !== verificationFilter) return false;
      if (statusFilter !== "all" && u.accountStatus !== statusFilter) return false;
      if (!q) return true;
      return (
        u.fullName.toLowerCase().includes(q) ||
        u.email.toLowerCase().includes(q) ||
        u.id.toLowerCase().includes(q)
      );
    });
  }, [users, search, roleFilter, verificationFilter, statusFilter]);

  const table = useDataTable({
    rows: filtered,
    sortAccessors: {
      name: (u) => u.fullName.toLowerCase(),
      registered: (u) => u.registeredAt,
      lastActive: (u) => u.lastActiveAt,
    },
    initialSortKey: "name",
    pageSize: 8,
  });

  const columns: DataTableColumn<PlatformUser>[] = [
    {
      key: "name",
      header: "User",
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
      key: "id",
      header: "User ID",
      render: (u) => <span className="text-xs text-nr-text-hint">{u.id}</span>,
    },
    {
      key: "role",
      header: "Role",
      render: (u) => <Badge variant="info">{ROLE_LABELS[u.role]}</Badge>,
    },
    {
      key: "verification",
      header: "Verification",
      render: (u) => (
        <Badge variant={verificationVariant(u.verificationStatus)}>
          {u.verificationStatus === "verified" ? "Verified" : "Unverified"}
        </Badge>
      ),
    },
    {
      key: "status",
      header: "Status",
      render: (u) => (
        <Badge variant={accountStatusVariant(u.accountStatus)}>
          {capitalize(u.accountStatus)}
        </Badge>
      ),
    },
    {
      key: "club",
      header: "Club",
      render: (u) => {
        const club = u.organizerDetails?.clubId ? clubById.get(u.organizerDetails.clubId) : undefined;
        return <span className="text-sm text-nr-text-secondary">{club?.name ?? "—"}</span>;
      },
    },
    {
      key: "registered",
      header: "Registered",
      sortable: true,
      render: (u) => <span className="text-sm text-nr-text-secondary">{formatDate(u.registeredAt)}</span>,
    },
    {
      key: "lastActive",
      header: "Last active",
      sortable: true,
      render: (u) => <span className="text-sm text-nr-text-secondary">{formatDate(u.lastActiveAt)}</span>,
    },
    {
      key: "actions",
      header: "",
      headerClassName: "w-10",
      render: (u) => {
        const items: DropdownItem[] = [
          { label: "View details", icon: Eye, onClick: () => setViewingUser(u) },
          { label: "Change role", icon: Repeat, onClick: () => setChangingRoleUser(u) },
          {
            label: "Mark as verified",
            icon: ShieldCheck,
            hidden: u.verificationStatus === "verified",
            onClick: () => {
              verifyUser(u.id);
              toast({ variant: "success", title: "User verified", description: `${u.fullName} is now verified.` });
            },
          },
          {
            label: "Mark as unverified",
            icon: ShieldOff,
            hidden: u.verificationStatus === "unverified",
            onClick: () => {
              unverifyUser(u.id);
              toast({ variant: "info", title: "User unverified", description: `${u.fullName} is now unverified.` });
            },
          },
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
            label: "Promote to organizer",
            icon: UserCog,
            hidden: u.isOrganizer,
            onClick: () => setPromotingUser(u),
          },
          {
            label: "Remove organizer access",
            icon: UserMinus,
            hidden: !u.isOrganizer,
            danger: true,
            onClick: () => setConfirmAction({ kind: "removeOrganizer", user: u }),
          },
          {
            label: "Give admin access",
            icon: ShieldPlus,
            hidden: u.isAdmin,
            onClick: () => setGrantingAdminUser(u),
          },
          {
            label: u.id === currentAdmin.id ? "Remove admin access (not allowed)" : "Remove admin access",
            icon: ShieldMinus,
            hidden: !u.isAdmin,
            danger: true,
            disabled: u.id === currentAdmin.id,
            onClick: () => setConfirmAction({ kind: "removeAdmin", user: u }),
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
          <SearchInput value={search} onChange={setSearch} placeholder="Search by name, email, or ID..." className="sm:max-w-xs" />
          <Select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value as "all" | Role)}
            options={[{ label: "All roles", value: "all" }, ...ROLES.map((r) => ({ label: ROLE_LABELS[r], value: r }))]}
            className="sm:w-44"
          />
          <Select
            value={verificationFilter}
            onChange={(e) => setVerificationFilter(e.target.value as typeof verificationFilter)}
            options={[
              { label: "All verification", value: "all" },
              { label: "Verified", value: "verified" },
              { label: "Unverified", value: "unverified" },
            ]}
            className="sm:w-44"
          />
          <Select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as typeof statusFilter)}
            options={[
              { label: "All statuses", value: "all" },
              { label: "Active", value: "active" },
              { label: "Deactivated", value: "deactivated" },
              { label: "Banned", value: "banned" },
            ]}
            className="sm:w-44"
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
          emptyTitle="No users match your filters"
          emptyDescription="Try clearing search or filters."
        />
      </Card>

      <UserDetailDrawer user={viewingUser} onClose={() => setViewingUser(null)} />
      <ChangeRoleModal key={`role-${changingRoleUser?.id ?? "none"}`} user={changingRoleUser} onClose={() => setChangingRoleUser(null)} />
      <PromoteOrganizerModal key={`promote-${promotingUser?.id ?? "none"}`} user={promotingUser} onClose={() => setPromotingUser(null)} />
      <GrantAdminAccessModal key={`grant-${grantingAdminUser?.id ?? "none"}`} user={grantingAdminUser} onClose={() => setGrantingAdminUser(null)} />

      <ConfirmDialog
        open={!!confirmAction}
        onClose={() => setConfirmAction(null)}
        requireReason
        variant="danger"
        title={confirmAction ? USER_CONFIRM_COPY[confirmAction.kind].title : ""}
        description={
          confirmAction
            ? `Are you sure you want to ${USER_CONFIRM_COPY[confirmAction.kind].verb} ${confirmAction.user.fullName}?`
            : ""
        }
        confirmLabel={confirmAction ? USER_CONFIRM_COPY[confirmAction.kind].confirmLabel : ""}
        onConfirm={(reason) => {
          if (!confirmAction) return;
          const { kind, user } = confirmAction;
          if (kind === "deactivate") {
            deactivateUser(user.id, reason);
            toast({ variant: "warning", title: "Account deactivated", description: `${user.fullName}'s account was deactivated.` });
          } else if (kind === "ban") {
            banUser(user.id, reason);
            toast({ variant: "error", title: "Account banned", description: `${user.fullName} was banned from the platform.` });
          } else if (kind === "removeOrganizer") {
            removeOrganizerAccess(user.id, reason);
            toast({ variant: "warning", title: "Organizer access removed", description: `${user.fullName} is no longer an organizer.` });
          } else if (kind === "removeAdmin") {
            removeAdminAccess(user.id, reason);
            toast({ variant: "warning", title: "Admin access removed", description: `${user.fullName} is no longer an admin.` });
          }
          setConfirmAction(null);
        }}
      />
    </div>
  );
}
