import { Icon } from "../Icon";
import { SimulatedBadge } from "../SimulatedBadge";
import { Chip, FieldRowList } from "../primitives";
import { EventDecisionPanel } from "./EventDecisionPanel";
import { MONO, SURFACE, TEXT, badgeColors } from "@/lib/admin/tokens";
import type { EventQueue } from "@/lib/admin/useEventQueue";

/**
 * Right column of the master-detail layout — event header, flag banners,
 * recurring-series banner, Submission / Assets / Lineup / Ticket tiers
 * cards, then the decision panel. See lines 869-994 of the mockup.
 */
export function EventDetail({ queue }: { queue: EventQueue }) {
  const { detail } = queue;
  if (!detail) return null;

  const statusColors = badgeColors(detail.statusTone);
  const statusLabel = detail.status === "pending" ? "Awaiting review" : detail.status === "approved" ? "Approved" : "Rejected";

  return (
    <div style={{ flex: "1 1 380px", minWidth: 0, display: "flex", flexDirection: "column", gap: 16 }}>
      <div style={{ background: SURFACE.raised, borderRadius: 16, padding: "20px 24px", display: "flex", alignItems: "flex-start", gap: 16, flexWrap: "wrap" }}>
        <div style={{ minWidth: 0, flex: 1 }}>
          <div style={{ fontSize: 22, lineHeight: 1.2 }}>{detail.name}</div>
          <div style={{ fontSize: 13, color: TEXT.secondary, marginTop: 4 }}>
            {detail.venue} · {detail.organizer} · submitted {detail.submittedTimeAgo}
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
            flexShrink: 0,
            background: statusColors.bg,
            color: statusColors.fg,
          }}
        >
          {statusLabel}
        </div>
      </div>

      {detail.flags.length > 0 ? (
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {detail.flags.map((f) => {
            const c = badgeColors(f.tone);
            return (
              <div
                key={f.id}
                style={{ display: "flex", alignItems: "center", gap: 10, borderRadius: 12, padding: "12px 16px", fontSize: 13, background: c.bg, color: c.fg }}
              >
                <Icon name={f.icon} size={20} style={{ flexShrink: 0 }} />
                <span style={{ flex: 1, minWidth: 0 }}>{f.label}</span>
                {f.simulated ? <SimulatedBadge /> : null}
              </div>
            );
          })}
        </div>
      ) : null}

      {detail.hasSeries ? (
        <div style={{ display: "flex", alignItems: "center", gap: 10, background: "#1F4F49", color: "#A5F2E5", borderRadius: 12, padding: "12px 16px", fontSize: 13 }}>
          <Icon name="repeat" size={20} />
          Recurring series — {detail.series}. One decision applies to every date.
        </div>
      ) : null}

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(min(320px, 100%), 1fr))", gap: 16, alignItems: "start" }}>
        <div style={{ background: SURFACE.raised, borderRadius: 16, padding: 20, minWidth: 0 }}>
          <div style={{ fontSize: 16, fontWeight: 500, marginBottom: 12 }}>Submission</div>
          <FieldRowList rows={detail.facts} />
          <div style={{ fontSize: 13, color: TEXT.secondary, lineHeight: 1.55, marginTop: 16 }}>{detail.description}</div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 16, minWidth: 0 }}>
          <div style={{ background: SURFACE.raised, borderRadius: 16, padding: 20 }}>
            <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", gap: 12, marginBottom: 12 }}>
              <div style={{ fontSize: 16, fontWeight: 500 }}>Assets</div>
              <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: TEXT.muted }}>
                {detail.assetPreviews.value.length === 1 ? "1 asset" : `${detail.assetPreviews.value.length} assets`}
                <SimulatedBadge />
              </div>
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(min(110px, 100%), 1fr))", gap: 10 }}>
              {detail.assetPreviews.value.map((pv, i) => (
                <div
                  key={i}
                  style={{
                    aspectRatio: "4 / 3",
                    borderRadius: 12,
                    background: SURFACE.hover,
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    justifyContent: "center",
                    gap: 6,
                    color: TEXT.muted,
                  }}
                >
                  <Icon name={pv.icon} size={22} />
                  <div style={{ fontFamily: MONO, fontSize: 9, letterSpacing: "0.08em" }}>{pv.label.toUpperCase()}</div>
                </div>
              ))}
            </div>
          </div>

          {detail.lineup.length > 0 ? (
            <div style={{ background: SURFACE.raised, borderRadius: 16, padding: 20 }}>
              <div style={{ fontSize: 16, fontWeight: 500, marginBottom: 12 }}>Lineup</div>
              <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
                {detail.lineup.map((name) => (
                  <Chip key={name} label={name} />
                ))}
              </div>
            </div>
          ) : null}

          {detail.tiers.length > 0 ? (
            <div style={{ background: SURFACE.raised, borderRadius: 16, padding: 20 }}>
              <div style={{ fontSize: 16, fontWeight: 500, marginBottom: 8 }}>Ticket tiers</div>
              {detail.tiers.map((t) => (
                <div key={t.name} style={{ display: "flex", alignItems: "center", gap: 12, padding: "10px 0", borderBottom: "1px solid #241F23", fontSize: 14 }}>
                  <div style={{ flex: 1, minWidth: 0 }}>{t.name}</div>
                  <div style={{ fontFamily: MONO, color: "#A5F2E5" }}>{t.price}</div>
                  <div style={{ fontFamily: MONO, color: TEXT.muted, width: 56, textAlign: "right" }}>×{t.qty}</div>
                </div>
              ))}
            </div>
          ) : null}
        </div>
      </div>

      <EventDecisionPanel queue={queue} detail={detail} />
    </div>
  );
}
