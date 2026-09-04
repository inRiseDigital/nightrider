"use client";

// Audit log section — read-only. Markup ported 1:1 from
// docs/design/admin-dashboard-v3.dc.html lines 1290-1351 (`isAudit`).

import { Icon } from "../Icon";
import { DataTable, type DataTableColumn } from "../primitives/DataTable";
import { FilterBar, SearchInput, SelectFilter } from "../primitives/FilterBar";
import { Badge } from "../primitives/Badge";
import { useAudit } from "@/lib/admin/useAudit";
import type { AuditRow } from "@/lib/admin/view-models";
import { badgeColors } from "@/lib/admin/tokens";
import { MONO, TEXT } from "@/lib/admin/tokens";

const PERSON_AVATAR = badgeColors("info");
const SYSTEM_AVATAR = { bg: "#2A252A", fg: "#9A8C91" };

function ActorCell({ row }: { row: AuditRow }) {
  const colors = row.isSystemActor ? SYSTEM_AVATAR : PERSON_AVATAR;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 10, minWidth: 0 }}>
      <div
        style={{
          width: 28,
          height: 28,
          borderRadius: "50%",
          flexShrink: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 11,
          fontWeight: 500,
          background: colors.bg,
          color: colors.fg,
        }}
      >
        {row.isSystemActor ? <Icon name="bolt" size={16} /> : row.actorInitials}
      </div>
      <div style={{ fontSize: 13, color: TEXT.primary, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
        {row.actorLabel}
      </div>
    </div>
  );
}

const COLUMNS: DataTableColumn<AuditRow>[] = [
  {
    key: "when",
    label: "When",
    width: 170,
    render: (r) => <span style={{ fontSize: 12, color: TEXT.muted, fontFamily: MONO }}>{r.timeLabel}</span>,
  },
  {
    key: "actor",
    label: "Actor",
    width: 190,
    render: (r) => <ActorCell row={r} />,
  },
  {
    key: "action",
    label: "Action",
    width: 240,
    render: (r) => <span style={{ fontSize: 13, color: TEXT.primary }}>{r.actionLabel}</span>,
  },
  {
    key: "target",
    label: "Target",
    flex: 1,
    width: 160,
    render: (r) => (
      <span style={{ fontSize: 13, color: TEXT.secondary, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", display: "block" }}>
        {r.target}
      </span>
    ),
  },
  {
    key: "type",
    label: "Type",
    width: 110,
    align: "right",
    render: (r) => (
      <div style={{ display: "flex", justifyContent: "flex-end" }}>
        <Badge label={r.type} tone={r.tone} />
      </div>
    ),
  },
];

export function AuditLog() {
  const { loading, error, rows, countLabel, actors, filter, setActor, setType, setRange, setSearch } = useAudit();

  if (error) {
    return <div style={{ background: "#2A1A1C", color: "#FFB4AB", borderRadius: 16, padding: 20 }}>Couldn&apos;t load the audit log: {error}</div>;
  }

  return (
    <>
      <FilterBar trailing={<div style={{ fontSize: 12, color: TEXT.muted, fontFamily: MONO }}>{countLabel}</div>}>
        <SearchInput value={filter.search} onChange={(e) => setSearch(e.target.value)} placeholder="Search action or target" maxWidth={340} />
        <SelectFilter value={filter.actor} onChange={(e) => setActor(e.target.value)}>
          <option value="all">Anyone</option>
          {actors.map((a) => (
            <option key={a} value={a}>
              {a}
            </option>
          ))}
        </SelectFilter>
        <SelectFilter value={filter.type} onChange={(e) => setType(e.target.value as typeof filter.type)}>
          <option value="all">All action types</option>
          <option value="Review">Content review</option>
          <option value="Organizer">Organizer</option>
          <option value="Venue">Venue</option>
          <option value="Account">Account</option>
          <option value="Access">Admin access</option>
        </SelectFilter>
        <SelectFilter value={filter.range} onChange={(e) => setRange(e.target.value as typeof filter.range)}>
          <option value="24h">Last 24 hours</option>
          <option value="7d">Last 7 days</option>
          <option value="30d">Last 30 days</option>
          <option value="all">All time</option>
        </SelectFilter>
      </FilterBar>

      {loading ? (
        <div style={{ color: TEXT.muted, fontSize: 14 }}>Loading audit log…</div>
      ) : (
        <DataTable columns={COLUMNS} rows={rows} getRowId={(r) => r.id} minWidth={980} empty="No entries in that window." />
      )}
    </>
  );
}
