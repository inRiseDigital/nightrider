"use client";

import { ACCENT, MONO, SURFACE, TEXT, badgeColors } from "@/lib/admin/tokens";
import { organizerStatusLabel } from "@/lib/admin/present";
import type { UsersRow, UserDisplayStatus } from "@/lib/admin/useUsers";
import type { Users } from "@/lib/admin/useUsers";
import { Badge, DataTable, FilterBar, SearchInput, SelectFilter, StatTile, type DataTableColumn } from "../primitives";
import { SimulatedBadge } from "../SimulatedBadge";

const ROLE_COLORS: Record<UsersRow["role"], { bg: string; fg: string }> = {
  "Party-goer": badgeColors("neutral"),
  Organizer: badgeColors("info"),
  Admin: { bg: ACCENT.plum, fg: ACCENT.pinkPale },
};

const STATUS_TONE: Record<UserDisplayStatus, "success" | "warning" | "danger" | "neutral"> = {
  Active: "success",
  Suspended: "warning",
  Banned: "danger",
  Deactivated: "neutral",
};

const IDENTITY_ICON: Record<string, string> = {
  none: "remove",
  pending: "hourglass_top",
  approved: "verified_user",
  rejected: "report",
  revoked: "block",
};

const IDENTITY_TONE: Record<string, "success" | "warning" | "danger" | "neutral"> = {
  none: "neutral",
  pending: "warning",
  approved: "success",
  rejected: "danger",
  revoked: "neutral",
};

function initials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  return name.slice(0, 2).toUpperCase();
}

export function UsersList({ vm }: { vm: Users }) {
  const columns: DataTableColumn<UsersRow>[] = [
    {
      key: "avatar",
      label: "",
      width: 40,
      render: (row) => {
        const colors = ROLE_COLORS[row.role];
        return (
          <div
            style={{
              width: 40,
              height: 40,
              borderRadius: "50%",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 13,
              fontWeight: 500,
              background: colors.bg,
              color: colors.fg,
            }}
          >
            {initials(row.name)}
          </div>
        );
      },
    },
    {
      key: "person",
      label: "Person",
      width: 210,
      render: (row) => (
        <div style={{ minWidth: 0 }}>
          <div style={{ fontSize: 14, fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{row.name}</div>
          <div style={{ fontSize: 12, color: TEXT.muted, fontFamily: MONO, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
            {row.email}
          </div>
        </div>
      ),
    },
    {
      key: "role",
      label: "Role",
      width: 110,
      render: (row) => <Badge label={row.role} colors={ROLE_COLORS[row.role]} />,
    },
    {
      key: "city",
      label: "City",
      width: 110,
      render: (row) => <span style={{ fontSize: 13, color: TEXT.secondary }}>{row.city}</span>,
    },
    {
      key: "joined",
      label: "Joined",
      width: 120,
      render: (row) => <span style={{ fontSize: 13, color: TEXT.secondary, fontFamily: MONO }}>{row.joinedLabel}</span>,
    },
    {
      key: "lastActive",
      label: "Last active",
      flex: 1,
      width: 130,
      render: (row) => (
        <span style={{ display: "inline-flex", alignItems: "center", gap: 6, fontSize: 13, color: TEXT.muted }}>
          {row.lastActiveLabel.value}
          <SimulatedBadge />
        </span>
      ),
    },
    {
      key: "identity",
      label: "Identity",
      width: 130,
      render: (row) =>
        row.identity === "n/a" ? (
          <span style={{ fontSize: 13, color: TEXT.muted }}>—</span>
        ) : (
          <Badge
            label={organizerStatusLabel(row.identity)}
            colors={badgeColors(IDENTITY_TONE[row.identity] ?? "neutral")}
            icon={IDENTITY_ICON[row.identity] ?? "help"}
          />
        ),
    },
    {
      key: "status",
      label: "Status",
      width: 110,
      align: "right",
      render: (row) => (
        <div style={{ display: "flex", justifyContent: "flex-end" }}>
          <Badge label={row.displayStatus} colors={badgeColors(STATUS_TONE[row.displayStatus])} />
        </div>
      ),
    },
  ];

  return (
    <div>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 24, background: SURFACE.raised, borderRadius: 16, padding: "16px 24px", marginBottom: 16 }}>
        {vm.stats.map((s) => (
          <StatTile key={s.label} label={s.label} value={s.value} color={badgeColors(s.tone).fg} />
        ))}
      </div>

      <FilterBar>
        <SearchInput value={vm.filter.search} onChange={(e) => vm.setSearch(e.target.value)} placeholder="Search name, email or phone" />
        <SelectFilter value={vm.filter.role} onChange={(e) => vm.setRole(e.target.value as Users["filter"]["role"])}>
          <option value="all">All roles</option>
          <option value="Party-goer">Party-goers</option>
          <option value="Organizer">Organizers</option>
          <option value="Admin">Admins</option>
        </SelectFilter>
        <SelectFilter value={vm.filter.statusFilter} onChange={(e) => vm.setStatusFilter(e.target.value as Users["filter"]["statusFilter"])}>
          <option value="all">Any status</option>
          <option value="Active">Active</option>
          <option value="Suspended">Suspended</option>
          <option value="Banned">Banned</option>
          <option value="Deactivated">Deactivated</option>
        </SelectFilter>
      </FilterBar>

      {vm.error ? (
        <div style={{ background: "#2A1A1C", color: "#FFB4AB", borderRadius: 16, padding: 20, fontSize: 14 }}>Couldn&apos;t load the directory: {vm.error}</div>
      ) : vm.loading ? (
        <div style={{ color: TEXT.muted, fontSize: 14 }}>Loading people…</div>
      ) : (
        <DataTable
          columns={columns}
          rows={vm.rows}
          getRowId={(row) => row.uid}
          minWidth={1120}
          onRowClick={(row) => vm.select(row.uid)}
          activeRowId={vm.selectedId}
          empty="No one matches those filters."
        />
      )}
    </div>
  );
}

// Re-exported so UserDrawer.tsx can reuse the same identity chrome without recomputing it.
export { IDENTITY_ICON, IDENTITY_TONE, STATUS_TONE, ROLE_COLORS };
