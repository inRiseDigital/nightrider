import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import { SimulatedBadge } from "../SimulatedBadge";
import { useApplicantsList } from "@/lib/admin/useApplicantsList";
import { initialsFor, organizerStatusColors, organizerStatusLabel, timeAgo } from "@/lib/admin/present";
import { mockFaceMatch } from "@/lib/admin/mock-overlay";
import type { UserRecord } from "@/lib/admin/schema";

function addressFor(user: UserRecord): string {
  const app = user.organizerApplication;
  return app?.profile.venueName || app?.steps.venueAddress?.address || "No venue address yet";
}

function ApplicantCard({ user, onOpen }: { user: UserRecord; onOpen: () => void }) {
  const colors = organizerStatusColors(user.organizerStatus);
  const face = mockFaceMatch(user.uid);
  const pending = user.organizerStatus === "none";

  return (
    <Hoverable
      onClick={onOpen}
      style={{
        background: "#1B181B",
        borderRadius: 16,
        padding: 16,
        display: "flex",
        flexDirection: "column",
        gap: 14,
        cursor: "pointer",
        transition: "background-color 120ms linear",
      }}
      hoverStyle={{ background: "#2A252A" }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <div
          style={{
            width: 40,
            height: 40,
            borderRadius: "50%",
            background: pending ? "#8E1049" : "#1F4F49",
            color: pending ? "#FFD9E2" : "#A5F2E5",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontWeight: 500,
            fontSize: 14,
            flexShrink: 0,
          }}
        >
          {initialsFor(user.displayName, user.email)}
        </div>
        <div style={{ minWidth: 0 }}>
          <div style={{ fontSize: 15, fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
            {user.displayName || user.email}
          </div>
          <div style={{ fontSize: 12, color: "#9A8C91", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{user.email}</div>
        </div>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13, color: "#CFC0C5", minWidth: 0 }}>
        <Icon name="place" size={18} color="#9A8C91" />
        <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{addressFor(user)}</span>
      </div>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 6, alignItems: "center" }}>
        <div style={{ display: "inline-flex", alignItems: "center", height: 26, padding: "0 10px", borderRadius: 8, fontSize: 12, fontWeight: 500, background: colors.bg, color: colors.fg }}>
          {organizerStatusLabel(user.organizerStatus)}
        </div>
        <div
          style={{
            display: "inline-flex",
            alignItems: "center",
            gap: 4,
            height: 26,
            padding: "0 10px",
            borderRadius: 8,
            fontSize: 12,
            fontWeight: 500,
            background: face.mismatch ? "#5C1218" : "#0F3D28",
            color: face.mismatch ? "#FFB4AB" : "#7BE0A8",
          }}
        >
          <Icon name={face.mismatch ? "report" : "verified_user"} size={14} />
          {face.mismatch ? "Face mismatch" : "Face matched"}
        </div>
        <SimulatedBadge />
      </div>
      <div style={{ fontSize: 12, color: "#9A8C91" }}>Applied {timeAgo(user.applicationSubmittedAt)}</div>
    </Hoverable>
  );
}

export function OrgAppsList({ onOpen }: { onOpen: (uid: string) => void }) {
  const { loading, error, search, setSearch, filter, setFilter, untriaged, pending, approved, rejected } = useApplicantsList();

  if (error) {
    return <div style={{ background: "#2A1A1C", color: "#FFB4AB", borderRadius: 16, padding: 20 }}>Couldn&apos;t load applicants: {error}</div>;
  }

  const groups = [
    { label: "Pending review", note: "An admin has picked these up", users: pending },
    { label: "Approved", note: "Cleared to publish events", users: approved },
    { label: "Rejected", note: "Declined applications", users: rejected },
  ].filter((g) => g.users.length > 0);

  return (
    <>
      {untriaged.length > 0 ? (
        <div style={{ background: "#2A1A22", borderRadius: 16, padding: 20, marginBottom: 16 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 4 }}>
            <Icon name="how_to_reg" size={20} color="#FFB1C4" />
            <div style={{ fontSize: 16, fontWeight: 500 }}>Waiting on you</div>
          </div>
          <div style={{ fontSize: 13, color: "#CFC0C5", marginBottom: 16 }}>New sign-ups nobody has picked up yet</div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, 320px)", gap: 12 }}>
            {untriaged.map((u) => (
              <div key={u.uid} style={{ display: "flex", alignItems: "center", gap: 12, padding: "12px 12px 12px 16px", borderRadius: 16, background: "#1B181B" }}>
                <div
                  style={{
                    width: 40,
                    height: 40,
                    borderRadius: "50%",
                    background: "#8E1049",
                    color: "#FFD9E2",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontWeight: 500,
                    fontSize: 14,
                    flexShrink: 0,
                  }}
                >
                  {initialsFor(u.displayName, u.email)}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                    {u.displayName || u.email}
                  </div>
                  <div style={{ fontSize: 12, color: "#9A8C91" }}>Applied {timeAgo(u.applicationSubmittedAt)}</div>
                </div>
                <Hoverable
                  as="button"
                  onClick={() => onOpen(u.uid)}
                  style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#8E1049", color: "#FFD9E2", border: "none", cursor: "pointer", flexShrink: 0 }}
                  hoverStyle={{ background: "#A81456" }}
                >
                  Review
                </Hoverable>
              </div>
            ))}
          </div>
        </div>
      ) : null}

      <div style={{ display: "flex", flexWrap: "wrap", gap: 12, alignItems: "center", marginBottom: 16 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, flex: 1, minWidth: 240, maxWidth: 420, height: 48, padding: "0 16px", borderRadius: 24, background: "#2A252A" }}>
          <Icon name="search" size={20} color="#CFC0C5" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search organizers"
            style={{ flex: 1, minWidth: 0, height: "100%", background: "transparent", border: "none", color: "#EDE0E4", fontSize: 14 }}
          />
        </div>
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          style={{ height: 48, padding: "0 14px", borderRadius: 12, background: "#1B181B", border: "1px solid #524549", color: "#EDE0E4", fontSize: 14, cursor: "pointer" }}
        >
          <option value="all">All statuses</option>
          <option value="Untriaged">Untriaged</option>
          <option value="Pending">Pending</option>
          <option value="Approved">Approved</option>
          <option value="Rejected">Rejected</option>
        </select>
      </div>

      {loading ? (
        <div style={{ color: "#9A8C91", fontSize: 14 }}>Loading applicants…</div>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: 28 }}>
          {groups.length === 0 && untriaged.length === 0 ? (
            <div style={{ background: "#1B181B", borderRadius: 16, padding: 40, textAlign: "center", color: "#9A8C91" }}>
              No organizer applications yet.
            </div>
          ) : null}
          {groups.map((grp) => (
            <div key={grp.label}>
              <div style={{ display: "flex", alignItems: "baseline", gap: 10, marginBottom: 12 }}>
                <div style={{ fontSize: 16, fontWeight: 500 }}>{grp.label}</div>
                <div style={{ fontSize: 13, color: "#9A8C91" }}>
                  {grp.users.length} · {grp.note}
                </div>
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, 300px)", gap: 16 }}>
                {grp.users.map((u) => (
                  <ApplicantCard key={u.uid} user={u} onOpen={() => onOpen(u.uid)} />
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
