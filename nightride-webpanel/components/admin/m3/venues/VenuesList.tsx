"use client";

import type { ChangeEvent } from "react";
import { DataTable, FilterBar, SearchInput, SelectFilter, StatTile } from "../primitives";
import type { DataTableColumn } from "../primitives";
import { Icon } from "../Icon";
import { badgeColors, MONO, TEXT } from "@/lib/admin/tokens";
import type { BadgeType } from "@/lib/admin/tokens";
import type { VenueRow, VenuesViewModel } from "@/lib/admin/view-models";

const CITIES = ["Dubai", "Tokyo", "London", "Melbourne"];

function statColor(tone: BadgeType): string {
  return tone === "neutral" ? TEXT.primary : badgeColors(tone).fg;
}

function verifyChip(row: VenueRow): { label: string; tone: BadgeType; icon: string } {
  if (row.verifyState === "failed") return { label: "Check failed", tone: "danger", icon: "error" };
  if (row.verifyState === "verified") return { label: "Verified", tone: "success", icon: "verified" };
  return { label: `${row.openChecksCount} check${row.openChecksCount === 1 ? "" : "s"} open`, tone: "warning", icon: "hourglass_top" };
}

/**
 * The Venues directory list screen — stat strip, search/city/verification
 * filters, and the venue table. Row click opens the detail screen via
 * `venues.select`.
 */
export function VenuesList({ venues }: { venues: VenuesViewModel }) {
  const columns: DataTableColumn<VenueRow>[] = [
    {
      key: "venue",
      label: "Venue",
      width: 220,
      render: (row) => (
        <div style={{ minWidth: 0 }}>
          <div style={{ fontSize: 14, fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{row.name}</div>
          <div style={{ fontSize: 12, color: TEXT.muted }}>{row.city}</div>
        </div>
      ),
    },
    {
      key: "organizer",
      label: "Organizer",
      width: 150,
      render: (row) => (
        <div style={{ fontSize: 13, color: TEXT.secondary, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{row.organizer}</div>
      ),
    },
    {
      key: "address",
      label: "Address",
      flex: 1,
      width: 120,
      render: (row) => (
        <div style={{ fontSize: 13, color: TEXT.muted, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{row.address}</div>
      ),
    },
    {
      key: "capacity",
      label: "Cap.",
      width: 70,
      align: "right",
      render: (row) => (
        <span style={{ fontSize: 13, fontFamily: MONO, color: TEXT.secondary }}>
          {row.capacity || "—"}
        </span>
      ),
    },
    {
      key: "events",
      label: "Events",
      width: 70,
      align: "right",
      render: (row) => <span style={{ fontSize: 13, fontFamily: MONO, color: TEXT.secondary }}>{row.eventCount}</span>,
    },
    {
      key: "verification",
      label: "Verification",
      width: 150,
      render: (row) => {
        const chip = verifyChip(row);
        const { bg, fg } = badgeColors(chip.tone);
        return (
          <div style={{ display: "inline-flex", alignItems: "center", gap: 5, height: 26, padding: "0 10px", borderRadius: 8, fontSize: 12, fontWeight: 500, background: bg, color: fg }}>
            <Icon name={chip.icon} size={14} />
            {chip.label}
          </div>
        );
      },
    },
    {
      key: "state",
      label: "State",
      width: 90,
      align: "right",
      render: (row) => (
        <div style={{ display: "flex", justifyContent: "flex-end" }}>
          <div
            style={{
              display: "inline-flex",
              alignItems: "center",
              height: 26,
              padding: "0 10px",
              borderRadius: 8,
              fontSize: 12,
              fontWeight: 500,
              background: row.suspended ? "#42320A" : "#0F3D28",
              color: row.suspended ? "#F5C452" : "#7BE0A8",
            }}
          >
            {row.suspended ? "Suspended" : "Live"}
          </div>
        </div>
      ),
    },
  ];

  return (
    <>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 24, background: "#1B181B", borderRadius: 16, padding: "16px 24px", marginBottom: 16 }}>
        {venues.stats.map((s) => (
          <StatTile key={s.label} value={s.value} label={s.label} color={statColor(s.tone)} />
        ))}
      </div>

      <FilterBar>
        <SearchInput
          value={venues.filter.search}
          onChange={(e: ChangeEvent<HTMLInputElement>) => venues.setSearch(e.target.value)}
          placeholder="Search venue, organizer or address"
        />
        <SelectFilter value={venues.filter.city} onChange={(e: ChangeEvent<HTMLSelectElement>) => venues.setCity(e.target.value)}>
          <option value="all">All cities</option>
          {CITIES.map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </SelectFilter>
        <SelectFilter value={venues.filter.verifyState} onChange={(e: ChangeEvent<HTMLSelectElement>) => venues.setVerifyState(e.target.value as VenuesViewModel["filter"]["verifyState"])}>
          <option value="all">Any verification state</option>
          <option value="verified">Fully verified</option>
          <option value="checksOpen">Checks open</option>
          <option value="failed">Check failed</option>
          <option value="suspended">Suspended</option>
        </SelectFilter>
      </FilterBar>

      <DataTable
        columns={columns}
        rows={venues.rows}
        getRowId={(row) => row.id}
        minWidth={1010}
        onRowClick={(row) => venues.select(row.id)}
        empty="No venues match those filters."
      />
    </>
  );
}

