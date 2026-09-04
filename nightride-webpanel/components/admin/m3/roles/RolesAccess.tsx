"use client";

import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import { SimulatedBadge } from "../SimulatedBadge";
import { Badge, DataTable, Toast, type DataTableColumn } from "../primitives";
import { AddAdminForm } from "./AddAdminForm";
import { useRoles } from "@/lib/admin/useRoles";
import { ACCENT, SURFACE, TEXT, MONO, badgeColors } from "@/lib/admin/tokens";
import type { AdminRow } from "@/lib/admin/view-models";

const LOCKED_ROLE_COLORS = { bg: ACCENT.plum, fg: ACCENT.pinkPale };
const OPEN_ROLE_COLORS = badgeColors("info");

function roleLabel(row: AdminRow): string {
  return row.locked ? "Super admin" : row.displayLevel.value;
}

function statusColors(row: AdminRow) {
  if (row.statusLabel === "Revoked") return badgeColors("neutral");
  const label = typeof row.statusLabel === "string" ? row.statusLabel : row.statusLabel.value;
  return badgeColors(label === "Invite pending" ? "warning" : "success");
}

function statusText(row: AdminRow): string {
  return typeof row.statusLabel === "string" ? row.statusLabel : row.statusLabel.value;
}

export function RolesAccess() {
  const vm = useRoles();

  const columns: DataTableColumn<AdminRow>[] = [
    {
      key: "avatar",
      label: "",
      width: 40,
      render: (row) => {
        const colors = row.locked ? LOCKED_ROLE_COLORS : OPEN_ROLE_COLORS;
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
            {row.initials}
          </div>
        );
      },
    },
    {
      key: "admin",
      label: "Admin",
      width: 220,
      render: (row) => (
        <div style={{ minWidth: 0 }}>
          <div style={{ fontSize: 14, fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{row.name}</div>
          <div style={{ fontSize: 12, color: TEXT.muted, fontFamily: MONO, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{row.email}</div>
        </div>
      ),
    },
    {
      key: "level",
      label: "Level",
      width: 120,
      render: (row) => {
        const colors = row.locked ? LOCKED_ROLE_COLORS : OPEN_ROLE_COLORS;
        return (
          <span style={{ display: "inline-flex", alignItems: "center", gap: 6 }}>
            <Badge label={roleLabel(row)} colors={colors} icon={row.locked ? "lock" : undefined} />
            <SimulatedBadge />
          </span>
        );
      },
    },
    {
      key: "cities",
      label: "City scope",
      width: 140,
      render: (row) => (
        <span style={{ display: "inline-flex", alignItems: "center", gap: 6, fontSize: 13, color: TEXT.secondary }}>
          {row.cityScopeLabel.value}
          <SimulatedBadge />
        </span>
      ),
    },
    {
      key: "added",
      label: "Added",
      flex: 1,
      width: 140,
      render: (row) => <span style={{ fontSize: 12, color: TEXT.muted }}>{row.addedLabel.value}</span>,
    },
    {
      key: "lastActive",
      label: "Last active",
      width: 120,
      render: (row) => <span style={{ fontSize: 13, color: TEXT.secondary }}>{row.lastActiveLabel.value}</span>,
    },
    {
      key: "status",
      label: "Status",
      width: 230,
      align: "right",
      render: (row) => {
        const colors = statusColors(row);
        const confirmOpen = vm.confirmRevokeId === row.uid;
        return (
          <div style={{ display: "flex", alignItems: "center", justifyContent: "flex-end", gap: 8 }}>
            <Badge label={statusText(row)} colors={colors} />
            {row.locked ? (
              <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: TEXT.muted, whiteSpace: "nowrap" }}>
                <Icon name="shield" size={16} />
                Protected
              </div>
            ) : confirmOpen ? (
              <div style={{ display: "flex", gap: 6 }}>
                <Hoverable
                  as="button"
                  onClick={() => void vm.revokeAdmin(row.uid)}
                  disabled={vm.actionBusy}
                  style={{ height: 34, padding: "0 14px", borderRadius: 17, fontSize: 13, fontWeight: 500, background: "#93000A", color: "#FFDAD6", border: "none", cursor: vm.actionBusy ? "default" : "pointer" }}
                >
                  Confirm
                </Hoverable>
                <Hoverable
                  as="button"
                  onClick={vm.cancelRevoke}
                  style={{ height: 34, padding: "0 12px", borderRadius: 17, fontSize: 13, fontWeight: 500, background: "transparent", color: TEXT.secondary, border: "none", cursor: "pointer" }}
                  hoverStyle={{ background: "#FFFFFF14" }}
                >
                  Keep
                </Hoverable>
              </div>
            ) : (
              <Hoverable
                as="button"
                onClick={() => vm.askRevoke(row.uid)}
                style={{ height: 34, padding: "0 14px", borderRadius: 17, fontSize: 13, fontWeight: 500, background: "transparent", color: TEXT.primary, border: "1px solid #524549", cursor: "pointer", whiteSpace: "nowrap" }}
                hoverStyle={{ background: "#FFFFFF14" }}
              >
                {row.statusLabel === "Revoked" ? "Restore access" : "Revoke access"}
              </Hoverable>
            )}
          </div>
        );
      },
    },
  ];

  return (
    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))", gap: 16, alignItems: "start" }}>
      <div style={{ gridColumn: "1 / -1", background: SURFACE.accentCard, borderRadius: 16, padding: "20px 24px", display: "flex", alignItems: "center", gap: 16, flexWrap: "wrap" }}>
        <div style={{ minWidth: 0, flex: 1 }}>
          <div style={{ fontSize: 16, fontWeight: 500 }}>Console access</div>
          <div style={{ fontSize: 13, color: TEXT.secondary, marginTop: 2 }}>
            Every admin has the same powers — only the scope of cities differs. {vm.activeCountLabel} today.
          </div>
        </div>
        <Hoverable
          as="button"
          onClick={vm.toggleAddAdmin}
          style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: ACCENT.pinkStrong, color: ACCENT.pinkPale, border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: 8, flexShrink: 0 }}
          hoverStyle={{ background: ACCENT.pinkHover }}
        >
          <Icon name="person_add" size={20} />
          Add admin
        </Hoverable>
      </div>

      {vm.addAdminOpen ? (
        <AddAdminForm draft={vm.newAdminDraft} setDraft={vm.setNewAdminDraft} onSubmit={vm.createAdmin} onCancel={vm.toggleAddAdmin} />
      ) : null}

      {vm.toast !== null ? (
        <div style={{ gridColumn: "1 / -1" }}>
          <Toast message={vm.toast} />
        </div>
      ) : null}

      {vm.actionError ? (
        <div style={{ gridColumn: "1 / -1", background: "#2A1A1C", color: "#FFB4AB", borderRadius: 12, padding: "12px 16px", fontSize: 13 }}>{vm.actionError}</div>
      ) : null}

      <div style={{ gridColumn: "1 / -1" }}>
        {vm.error ? (
          <div style={{ background: "#2A1A1C", color: "#FFB4AB", borderRadius: 16, padding: 20, fontSize: 14 }}>Couldn&apos;t load the admin roster: {vm.error}</div>
        ) : vm.loading ? (
          <div style={{ color: TEXT.muted, fontSize: 14 }}>Loading admins…</div>
        ) : (
          <DataTable
            columns={columns}
            rows={vm.rows}
            getRowId={(row) => row.uid}
            minWidth={1150}
            rowStyle={(row) => ({ opacity: row.statusLabel === "Revoked" ? 0.55 : 1 })}
            empty="No admins yet."
          />
        )}
      </div>

      <div style={{ background: SURFACE.raised, borderRadius: 16, padding: "20px 24px" }}>
        <div style={{ fontSize: 15, fontWeight: 500, marginBottom: 12 }}>Every admin can</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {vm.adminCapabilities.map((text) => (
            <div key={text} style={{ display: "flex", alignItems: "flex-start", gap: 10, fontSize: 13, color: TEXT.secondary, lineHeight: 1.5 }}>
              <Icon name="check" size={18} color="#A5F2E5" style={{ flexShrink: 0 }} />
              {text}
            </div>
          ))}
        </div>
      </div>

      <div style={{ background: SURFACE.raised, borderRadius: 16, padding: "20px 24px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 12 }}>
          <Icon name="lock" size={20} color={ACCENT.pink} />
          <div style={{ fontSize: 15, fontWeight: 500 }}>The super admin</div>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {vm.superAdminOnlyCapabilities.map((text) => (
            <div key={text} style={{ display: "flex", alignItems: "flex-start", gap: 10, fontSize: 13, color: TEXT.secondary, lineHeight: 1.5 }}>
              <Icon name="shield" size={18} color={ACCENT.pink} style={{ flexShrink: 0 }} />
              {text}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
