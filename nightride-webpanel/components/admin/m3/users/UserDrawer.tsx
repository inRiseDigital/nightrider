"use client";

import { MONO, SURFACE, TEXT, badgeColors } from "@/lib/admin/tokens";
import { organizerStatusLabel } from "@/lib/admin/present";
import type { Users } from "@/lib/admin/useUsers";
import { Badge, ConfirmPanel, Drawer, FieldRowList, SubTabs, Toast, type SubTab } from "../primitives";
import { SimulatedBadge } from "../SimulatedBadge";
import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import { IDENTITY_ICON, IDENTITY_TONE, ROLE_COLORS, STATUS_TONE } from "./UsersList";

const TABS: SubTab[] = [
  { id: "profile", label: "Profile" },
  { id: "activity", label: "Activity" },
];

function initials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  return name.slice(0, 2).toUpperCase();
}

const ACTION_BUTTON_STYLE = {
  height: 40,
  padding: "0 18px",
  borderRadius: 20,
  fontSize: 14,
  fontWeight: 500,
  background: "transparent",
  color: TEXT.primary,
  border: `1px solid #524549`,
  cursor: "pointer" as const,
};

export function UserDrawer({ vm }: { vm: Users }) {
  const detail = vm.detail;
  if (!detail) return null;

  const avatarColors = ROLE_COLORS[detail.role];
  const statusColors = badgeColors(STATUS_TONE[detail.displayStatus]);
  const banned = detail.displayStatus === "Banned";
  const suspended = detail.displayStatus === "Suspended";

  const identityValue =
    detail.identity === "n/a" ? (
      "—"
    ) : (
      <span style={{ display: "inline-flex", alignItems: "center", gap: 6 }}>
        <Badge
          label={organizerStatusLabel(detail.identity)}
          colors={badgeColors(IDENTITY_TONE[detail.identity] ?? "neutral")}
          icon={IDENTITY_ICON[detail.identity] ?? "help"}
          size="sm"
        />
      </span>
    );

  const lastRowLabel = detail.role === "Admin" ? "Access scope" : "Nights out";
  const lastRowValue =
    detail.role === "Admin" ? (
      <span style={{ display: "inline-flex", alignItems: "center", gap: 6 }}>
        {detail.adminScopeLabel?.value ?? "—"}
        <SimulatedBadge />
      </span>
    ) : (
      <span style={{ display: "inline-flex", alignItems: "center", gap: 6 }}>
        {detail.nightsOut.value}
        <SimulatedBadge />
      </span>
    );

  const rows = [
    { label: "Role", value: detail.role },
    { label: "City", value: detail.city },
    { label: "Joined", value: detail.joinedLabel },
    {
      label: "Last active",
      value: (
        <span style={{ display: "inline-flex", alignItems: "center", gap: 6 }}>
          {detail.lastActiveLabel.value}
          <SimulatedBadge />
        </span>
      ),
    },
    { label: "Email", value: detail.email, mono: true },
    { label: "Phone", value: detail.phone, mono: true },
    { label: "Identity", value: identityValue },
    {
      label: "Last device",
      value: (
        <span style={{ display: "inline-flex", alignItems: "center", gap: 6 }}>
          {detail.device.value}
          <SimulatedBadge />
        </span>
      ),
    },
    { label: lastRowLabel, value: lastRowValue },
  ];

  return (
    <Drawer
      open={!!vm.selectedId}
      onClose={() => vm.select(null)}
      width={440}
      header={
        <>
          <div
            style={{
              width: 44,
              height: 44,
              borderRadius: "50%",
              flexShrink: 0,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 15,
              fontWeight: 500,
              background: avatarColors.bg,
              color: avatarColors.fg,
            }}
          >
            {initials(detail.name)}
          </div>
          <div style={{ minWidth: 0, flex: 1 }}>
            <div style={{ fontSize: 18, lineHeight: 1.2, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{detail.name}</div>
            <div
              style={{
                fontSize: 12,
                color: TEXT.muted,
                marginTop: 2,
                fontFamily: MONO,
                overflow: "hidden",
                textOverflow: "ellipsis",
                whiteSpace: "nowrap",
              }}
            >
              {detail.email}
            </div>
          </div>
          <Badge label={detail.displayStatus} colors={statusColors} />
        </>
      }
    >
      <SubTabs tabs={TABS} activeId={vm.tab} onSelect={(id) => vm.setTab(id as "profile" | "activity")} />

      <div style={{ paddingTop: 16 }}>
        {detail.note ? (
          <div
            style={{
              display: "flex",
              gap: 10,
              background: "#42320A",
              color: "#F5C452",
              borderRadius: 12,
              padding: "12px 14px",
              marginBottom: 16,
              fontSize: 13,
              lineHeight: 1.5,
            }}
          >
            <Icon name="info" size={20} style={{ flexShrink: 0 }} />
            {detail.note}
          </div>
        ) : null}

        {vm.tab === "profile" ? (
          <>
            <div style={{ marginBottom: 20 }}>
              <FieldRowList rows={rows} />
            </div>

            {detail.role === "Organizer" ? (
              <Hoverable
                as="button"
                onClick={vm.openOrganizer}
                style={{
                  width: "100%",
                  height: 44,
                  borderRadius: 22,
                  fontSize: 14,
                  fontWeight: 500,
                  background: "#1F4F49",
                  color: "#A5F2E5",
                  border: "none",
                  cursor: "pointer",
                  marginBottom: 20,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: 8,
                }}
              >
                <Icon name="how_to_reg" size={20} />
                Open organizer record
              </Hoverable>
            ) : null}

            <div style={{ fontSize: 12, letterSpacing: "0.09em", textTransform: "uppercase", color: TEXT.muted, marginBottom: 10 }}>
              Account actions
            </div>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
              <Hoverable as="button" onClick={() => void vm.toggleSuspend()} disabled={vm.actionBusy} style={ACTION_BUTTON_STYLE} hoverStyle={{ background: "#FFFFFF14" }}>
                {suspended ? "Lift suspension" : "Suspend 7 days"}
              </Hoverable>
              <Hoverable as="button" onClick={vm.resetPassword} style={ACTION_BUTTON_STYLE} hoverStyle={{ background: "#FFFFFF14" }}>
                Reset password
              </Hoverable>
              <Hoverable
                as="button"
                onClick={vm.openNotice}
                style={{ ...ACTION_BUTTON_STYLE, color: "#A5F2E5", border: "1px solid #3E5F5A" }}
                hoverStyle={{ background: "#FFFFFF0A" }}
              >
                Send notice
              </Hoverable>
              <Hoverable as="button" onClick={vm.exportData} style={ACTION_BUTTON_STYLE} hoverStyle={{ background: "#FFFFFF14" }}>
                Export data
              </Hoverable>
              <Hoverable
                as="button"
                onClick={() => void vm.toggleBan()}
                disabled={vm.actionBusy}
                style={{
                  ...ACTION_BUTTON_STYLE,
                  background: banned ? "transparent" : "#93000A",
                  color: banned ? TEXT.primary : "#FFDAD6",
                  border: banned ? "1px solid #524549" : "none",
                }}
              >
                {banned ? "Lift ban" : "Ban account"}
              </Hoverable>
              <Hoverable
                as="button"
                onClick={vm.askDelete}
                style={{ ...ACTION_BUTTON_STYLE, color: "#FFB4AB", border: "none" }}
                hoverStyle={{ background: "#FFFFFF0A" }}
              >
                Delete account
              </Hoverable>
            </div>

            {vm.noticeOpen ? (
              <div style={{ marginTop: 16, background: "#141114", borderRadius: 12, padding: 14 }}>
                <div style={{ fontSize: 13, fontWeight: 500, color: "#A5F2E5", marginBottom: 10 }}>Notice shown in their app</div>
                <textarea
                  rows={3}
                  value={vm.noticeDraft}
                  onChange={(e) => vm.setNoticeDraft(e.target.value)}
                  placeholder="Write a short message…"
                  style={{
                    width: "100%",
                    background: SURFACE.hover,
                    border: "none",
                    borderRadius: 12,
                    padding: "12px 14px",
                    fontSize: 14,
                    lineHeight: 1.5,
                    color: TEXT.primary,
                    resize: "vertical",
                  }}
                />
                <Hoverable
                  as="button"
                  onClick={() => void vm.sendNotice()}
                  disabled={vm.actionBusy || !vm.noticeDraft.trim()}
                  style={{
                    marginTop: 10,
                    height: 40,
                    padding: "0 22px",
                    borderRadius: 20,
                    fontSize: 14,
                    fontWeight: 500,
                    background: "#1F4F49",
                    color: "#A5F2E5",
                    border: "none",
                    cursor: vm.actionBusy ? "default" : "pointer",
                  }}
                >
                  Send notice
                </Hoverable>
              </div>
            ) : null}

            {vm.confirmDelete ? (
              <div style={{ marginTop: 16 }}>
                <ConfirmPanel
                  tone="danger"
                  body="Deleting removes the profile, saved events and bookings after a 30-day grace period. This cannot be undone."
                  confirmLabel="Delete permanently"
                  cancelLabel="Cancel"
                  onConfirm={() => void vm.confirmDeleteAccount()}
                  onCancel={vm.askDelete}
                  busy={vm.actionBusy}
                />
              </div>
            ) : null}

            {vm.actionError ? (
              <div style={{ marginTop: 16, background: "#2A1A1C", color: "#FFB4AB", borderRadius: 12, padding: "12px 16px", fontSize: 13 }}>
                {vm.actionError}
              </div>
            ) : null}
          </>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            {detail.timeline.value.map((t, i) => (
              <div key={i} style={{ display: "flex", alignItems: "flex-start", gap: 14, padding: "10px 0" }}>
                <div
                  style={{
                    width: 36,
                    height: 36,
                    borderRadius: "50%",
                    flexShrink: 0,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    background: badgeColors(t.tone).bg,
                    color: badgeColors(t.tone).fg,
                  }}
                >
                  <Icon name={t.icon} size={18} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14, lineHeight: 1.4 }}>{t.text}</div>
                  <div style={{ fontSize: 12, color: TEXT.muted, marginTop: 2, fontFamily: MONO }}>{t.timeLabel}</div>
                </div>
              </div>
            ))}
            <div style={{ marginTop: 8 }}>
              <SimulatedBadge />
            </div>
          </div>
        )}
      </div>

      {vm.toast !== null ? (
        <div style={{ marginTop: 16 }}>
          <Toast message={vm.toast} />
        </div>
      ) : null}
    </Drawer>
  );
}
