"use client";

import { useState } from "react";
import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import { SimulatedBadge } from "../SimulatedBadge";
import { Badge, FieldRowList, MapTile, SubTabs } from "../primitives";
import { ACCENT, BORDER, MONO, SURFACE, TEXT, badgeColors } from "@/lib/admin/tokens";
import type { VenueCheck, VenueCheckKey, VenueCheckState, VenuesViewModel } from "@/lib/admin/view-models";
import type { AdminNav } from "@/lib/admin/useAdminNav";

const CHECK_STATE_CHROME: Record<VenueCheckState, { label: string; icon: string; tone: "success" | "warning" | "danger" }> = {
  verified: { label: "Verified", icon: "check_circle", tone: "success" },
  pending: { label: "Awaiting review", icon: "hourglass_top", tone: "warning" },
  failed: { label: "Failed", icon: "cancel", tone: "danger" },
};

function CheckPanel({ check, venueId, busy, onSetState }: { check: VenueCheck; venueId: string; busy: boolean; onSetState: (venueId: string, key: VenueCheckKey, state: VenueCheckState) => void }) {
  const chrome = CHECK_STATE_CHROME[check.state];
  const { bg, fg } = badgeColors(chrome.tone);
  return (
    <div style={{ background: SURFACE.base, borderRadius: 12, padding: "14px 16px", display: "flex", flexDirection: "column", gap: 10 }}>
      <div style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
        <Icon name={check.icon} size={22} color={TEXT.secondary} style={{ flexShrink: 0 }} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 14, fontWeight: 500 }}>{check.title}</div>
          <div style={{ fontSize: 12, color: TEXT.muted, marginTop: 2 }}>{check.meta}</div>
        </div>
        <Badge label={chrome.label} icon={chrome.icon} colors={{ bg, fg }} />
      </div>
      {check.state !== "verified" ? (
        <div style={{ display: "flex", gap: 8 }}>
          <Hoverable
            as="button"
            disabled={busy}
            onClick={() => onSetState(venueId, check.key, "verified")}
            style={{ height: 36, padding: "0 16px", borderRadius: 18, fontSize: 13, fontWeight: 500, background: ACCENT.pink, color: ACCENT.pinkDeep, border: "none", cursor: busy ? "default" : "pointer" }}
          >
            Approve check
          </Hoverable>
          <Hoverable
            as="button"
            disabled={busy}
            onClick={() => onSetState(venueId, check.key, "failed")}
            style={{ height: 36, padding: "0 16px", borderRadius: 18, fontSize: 13, fontWeight: 500, background: "transparent", color: "#FFB4AB", border: "1px solid #6B3438", cursor: busy ? "default" : "pointer" }}
            hoverStyle={{ background: "#FFFFFF0A" }}
          >
            Mark failed
          </Hoverable>
        </div>
      ) : null}
    </div>
  );
}

/**
 * The Venues directory detail screen — a global (cross-organizer) sibling of
 * organizer-applications/VenueDetail.tsx: header + suspend toggle,
 * verification banner, venue record card, verification checks, and an
 * Events / Review history sub-tab card.
 */
export function VenueDetailGlobal({ venues, nav }: { venues: VenuesViewModel; nav: AdminNav }) {
  const [tab, setTab] = useState<"events" | "history">("events");
  const detail = venues.detail;

  if (venues.loading && !detail) return <div style={{ color: TEXT.muted, fontSize: 14 }}>Loading venue…</div>;
  if (!detail) return <div style={{ background: "#2A1A1C", color: "#FFB4AB", borderRadius: 16, padding: 20 }}>{venues.error || "That venue no longer exists."}</div>;

  const allVerified = detail.verifyState === "verified";

  return (
    <>
      <div style={{ display: "flex", alignItems: "center", gap: 12, flexWrap: "wrap", padding: "4px 0 16px" }}>
        <Hoverable
          onClick={() => venues.select(null)}
          style={{ display: "inline-flex", alignItems: "center", gap: 8, height: 40, padding: "0 16px 0 12px", borderRadius: 20, cursor: "pointer", color: TEXT.secondary, fontSize: 14, fontWeight: 500 }}
          hoverStyle={{ background: SURFACE.hover, color: TEXT.primary }}
        >
          <Icon name="arrow_back" size={20} />
          Venues
        </Hoverable>
        <div style={{ minWidth: 0, marginLeft: 4 }}>
          <div style={{ fontSize: 20, lineHeight: 1.2 }}>{detail.name}</div>
          <div style={{ fontSize: 13, color: TEXT.secondary, marginTop: 2 }}>
            {detail.city} · managed by {detail.organizer}
          </div>
        </div>
        <div
          style={{
            display: "inline-flex",
            alignItems: "center",
            height: 32,
            padding: "0 12px",
            borderRadius: 8,
            fontSize: 13,
            fontWeight: 500,
            background: detail.suspended ? "#42320A" : "#0F3D28",
            color: detail.suspended ? "#F5C452" : "#7BE0A8",
            marginLeft: 4,
          }}
        >
          {detail.suspended ? "Suspended" : "Live"}
        </div>
        <Hoverable
          as="button"
          disabled={venues.actionBusy}
          onClick={() => void venues.toggleSuspend(detail.id)}
          style={{
            marginLeft: "auto",
            height: 40,
            padding: "0 20px",
            borderRadius: 20,
            fontSize: 14,
            fontWeight: 500,
            background: "transparent",
            color: TEXT.primary,
            border: `1px solid ${BORDER.strong}`,
            cursor: venues.actionBusy ? "default" : "pointer",
            flexShrink: 0,
          }}
          hoverStyle={{ background: "#FFFFFF14" }}
        >
          {detail.suspended ? "Un-suspend venue" : "Suspend venue"}
        </Hoverable>
      </div>

      {venues.actionError ? <div style={{ color: "#FFB4AB", fontSize: 13, marginBottom: 12 }}>{venues.actionError}</div> : null}

      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 12,
          borderRadius: 12,
          padding: "14px 16px",
          marginBottom: 16,
          fontSize: 13,
          background: allVerified ? "#0F3D28" : "#42320A",
          color: allVerified ? "#7BE0A8" : "#F5C452",
        }}
      >
        <Icon name={allVerified ? "verified" : "pending"} size={20} />
        {allVerified ? "All checks passed — organizer can publish events here." : "Events cannot go live until every check passes."}
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(min(330px, 100%), 1fr))", gap: 16, alignItems: "start" }}>
        <div style={{ background: SURFACE.raised, borderRadius: 16, overflow: "hidden", minWidth: 0 }}>
          <MapTile city={detail.city} height={200} />
          <div style={{ padding: "16px 20px" }}>
            <div style={{ fontSize: 16, fontWeight: 500, marginBottom: 8 }}>Venue record</div>
            <FieldRowList
              rows={[
                { label: "Organizer", value: detail.organizer },
                { label: "City", value: detail.city },
                { label: "Address", value: detail.address },
                { label: "Capacity", value: detail.capacity ? String(detail.capacity) : "Unknown", mono: true },
                {
                  label: "Licence number",
                  value: (
                    <span style={{ display: "inline-flex", alignItems: "center", gap: 6 }}>
                      {detail.licenceNumber.value}
                      <SimulatedBadge />
                    </span>
                  ),
                  mono: true,
                },
                {
                  label: "Licence expiry",
                  value: (
                    <span style={{ display: "inline-flex", alignItems: "center", gap: 6 }}>
                      {detail.licenceExpiryLabel.value}
                      <SimulatedBadge />
                    </span>
                  ),
                },
                { label: "Opening hours", value: detail.openingHours },
                { label: "Contact phone", value: detail.phone, mono: true },
                { label: "Verified on", value: detail.verifiedOnLabel },
              ]}
            />
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 16, minWidth: 0 }}>
          <div style={{ background: SURFACE.raised, borderRadius: 16, padding: 20 }}>
            <div style={{ fontSize: 16, fontWeight: 500, marginBottom: 4 }}>Verification</div>
            <div style={{ fontSize: 13, color: TEXT.muted, marginBottom: 14 }}>Submitted by the organizer — approve each check</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              {detail.checks.map((check) => (
                <CheckPanel key={check.key} check={check} venueId={detail.id} busy={venues.actionBusy} onSetState={venues.setCheckState} />
              ))}
            </div>
          </div>

          <div style={{ background: SURFACE.raised, borderRadius: 16, overflow: "hidden" }}>
            <SubTabs tabs={[{ id: "events", label: "Events" }, { id: "history", label: "Review history" }]} activeId={tab} onSelect={(id) => setTab(id as "events" | "history")} />

            {tab === "events" ? (
              <div>
                {detail.events.map((e) => (
                  <Hoverable
                    key={e.id}
                    onClick={() => nav.openEventInQueue(e.id)}
                    style={{ display: "flex", alignItems: "center", gap: 12, padding: "12px 20px", cursor: "pointer", borderBottom: `1px solid ${BORDER.hairline}` }}
                    hoverStyle={{ background: SURFACE.hover }}
                  >
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 14, fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{e.name}</div>
                      <div style={{ fontSize: 12, color: TEXT.muted, fontFamily: MONO }}>{e.dateLabel}</div>
                    </div>
                    <Badge label={e.status} tone={e.statusTone} />
                  </Hoverable>
                ))}
                {detail.events.length > 0 ? (
                  <div style={{ padding: "12px 20px", fontSize: 12, color: TEXT.muted }}>
                    {detail.events.length === 1 ? "1 event" : `${detail.events.length} events`} published or submitted here
                  </div>
                ) : (
                  <div style={{ padding: "24px 20px", fontSize: 13, color: TEXT.muted, textAlign: "center" }}>No events at this venue yet.</div>
                )}
              </div>
            ) : (
              <div style={{ padding: "8px 20px 16px" }}>
                <div style={{ display: "flex", justifyContent: "flex-end", padding: "8px 0 4px" }}>
                  <SimulatedBadge />
                </div>
                {detail.history.value.map((h) => {
                  const { bg, fg } = badgeColors(h.tone);
                  return (
                    <div key={h.id} style={{ display: "flex", alignItems: "flex-start", gap: 14, padding: "10px 0" }}>
                      <div style={{ width: 36, height: 36, borderRadius: "50%", flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center", background: bg, color: fg }}>
                        <Icon name={h.icon} size={18} />
                      </div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: 14, lineHeight: 1.4 }}>{h.text}</div>
                        <div style={{ fontSize: 12, color: TEXT.muted, marginTop: 2, fontFamily: MONO }}>
                          {h.actorLabel} · {h.timeLabel}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </div>
    </>
  );
}
