import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import type { AdminConsoleValues } from "@/lib/admin/useAdminConsole";

export function OrgAppsList({
  verifyStrip,
  orgGroups,
  orgSearch,
  orgFilter,
  onSearchChange,
  onFilterChange,
}: Pick<AdminConsoleValues, "verifyStrip" | "orgGroups" | "orgSearch" | "orgFilter" | "onSearchChange" | "onFilterChange">) {
  return (
    <>
      {verifyStrip.length > 0 ? (
        <div style={{ background: "#2A1A22", borderRadius: 16, padding: 20, marginBottom: 16 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 4 }}>
            <Icon name="how_to_reg" size={20} color="#FFB1C4" />
            <div style={{ fontSize: 16, fontWeight: 500 }}>Waiting on you</div>
          </div>
          <div style={{ fontSize: 13, color: "#CFC0C5", marginBottom: 16 }}>
            New sign-ups whose identity has not been reviewed yet
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, 320px)", gap: 12 }}>
            {verifyStrip.map((v) => (
              <div
                key={v.id}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                  padding: "12px 12px 12px 16px",
                  borderRadius: 16,
                  background: "#1B181B",
                }}
              >
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
                  {v.initials}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                    {v.name}
                  </div>
                  <div style={{ fontSize: 12, color: "#9A8C91" }}>Submitted {v.submitted}</div>
                </div>
                <Hoverable
                  as="button"
                  onClick={v.review}
                  style={{
                    height: 40,
                    padding: "0 20px",
                    borderRadius: 20,
                    fontSize: 14,
                    fontWeight: 500,
                    background: "#8E1049",
                    color: "#FFD9E2",
                    border: "none",
                    cursor: "pointer",
                    flexShrink: 0,
                  }}
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
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 8,
            flex: 1,
            minWidth: 240,
            maxWidth: 420,
            height: 48,
            padding: "0 16px",
            borderRadius: 24,
            background: "#2A252A",
          }}
        >
          <Icon name="search" size={20} color="#CFC0C5" />
          <input
            value={orgSearch}
            onChange={onSearchChange}
            placeholder="Search organizers"
            style={{ flex: 1, minWidth: 0, height: "100%", background: "transparent", border: "none", color: "#EDE0E4", fontSize: 14 }}
          />
        </div>
        <select
          value={orgFilter}
          onChange={onFilterChange}
          style={{
            height: 48,
            padding: "0 14px",
            borderRadius: 12,
            background: "#1B181B",
            border: "1px solid #524549",
            color: "#EDE0E4",
            fontSize: 14,
            cursor: "pointer",
          }}
        >
          <option value="all">All approval statuses</option>
          <option value="Pending">Pending</option>
          <option value="Approved">Approved</option>
          <option value="Rejected">Rejected</option>
        </select>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 28 }}>
        {orgGroups.map((grp) => (
          <div key={grp.label}>
            <div style={{ display: "flex", alignItems: "baseline", gap: 10, marginBottom: 12 }}>
              <div style={{ fontSize: 16, fontWeight: 500 }}>{grp.label}</div>
              <div style={{ fontSize: 13, color: "#9A8C91" }}>{grp.note}</div>
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, 300px)", gap: 16 }}>
              {grp.orgs.map((org) => (
                <Hoverable
                  key={org.id}
                  onClick={org.open}
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
                        background: org.avatarBg,
                        color: org.avatarFg,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        fontWeight: 500,
                        fontSize: 14,
                        flexShrink: 0,
                      }}
                    >
                      {org.initials}
                    </div>
                    <div style={{ minWidth: 0 }}>
                      <div style={{ fontSize: 15, fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                        {org.name}
                      </div>
                      <div style={{ fontSize: 12, color: "#9A8C91", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                        {org.email}
                      </div>
                    </div>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13, color: "#CFC0C5", minWidth: 0 }}>
                    <Icon name="place" size={18} color="#9A8C91" />
                    <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{org.address}</span>
                  </div>
                  <div style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>
                    <div
                      style={{
                        display: "inline-flex",
                        alignItems: "center",
                        height: 26,
                        padding: "0 10px",
                        borderRadius: 8,
                        fontSize: 12,
                        fontWeight: 500,
                        background: org.statusBg,
                        color: org.statusFg,
                      }}
                    >
                      {org.status}
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
                        background: org.nicBg,
                        color: org.nicFg,
                      }}
                    >
                      <Icon name={org.nicIcon} size={14} />
                      {org.nicLabel}
                    </div>
                  </div>
                  <div style={{ fontSize: 12, color: "#9A8C91" }}>Submitted {org.submitted}</div>
                </Hoverable>
              ))}
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
