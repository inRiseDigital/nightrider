"use client";

import type { CSSProperties, ReactNode } from "react";
import { Hoverable } from "../Hoverable";
import { BORDER, SURFACE, TEXT } from "@/lib/admin/tokens";
import { EmptyState } from "./EmptyState";

export type DataTableColumn<Row> = {
  key: string;
  label: string;
  width?: number;
  flex?: number;
  align?: "left" | "right";
  render: (row: Row) => ReactNode;
};

/**
 * Generic table used for the users / venues / roles / audit list screens —
 * an uppercase 11px 0.09em header row, flex rows with a 1px hairline bottom
 * border and a hover background. `minWidth` opts a table into the
 * horizontal-scroll pattern the mockup uses for wide tables (venues, roles,
 * audit).
 */
export function DataTable<Row>({
  columns,
  rows,
  getRowId,
  minWidth,
  onRowClick,
  activeRowId,
  empty = "Nothing to show.",
}: {
  columns: DataTableColumn<Row>[];
  rows: Row[];
  getRowId: (row: Row) => string;
  minWidth?: number;
  onRowClick?: (row: Row) => void;
  activeRowId?: string | null;
  empty?: string;
}) {
  const cellStyle = (col: DataTableColumn<Row>): CSSProperties => ({
    width: col.width,
    flex: col.flex,
    minWidth: col.flex ? col.width ?? 0 : undefined,
    flexShrink: col.width && !col.flex ? 0 : undefined,
    textAlign: col.align === "right" ? "right" : "left",
  });

  return (
    <div style={{ background: SURFACE.raised, borderRadius: 16, overflowX: minWidth ? "auto" : undefined, overflowY: minWidth ? "hidden" : undefined }}>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 16,
          padding: "10px 20px",
          fontSize: 11,
          letterSpacing: "0.09em",
          textTransform: "uppercase",
          color: TEXT.muted,
          borderBottom: `1px solid ${BORDER.hairline}`,
          minWidth,
        }}
      >
        {columns.map((col) => (
          <div key={col.key} style={cellStyle(col)}>
            {col.label}
          </div>
        ))}
      </div>

      {rows.map((row) => {
        const id = getRowId(row);
        const clickable = !!onRowClick;
        return (
          <Hoverable
            key={id}
            as="div"
            onClick={clickable ? () => onRowClick(row) : undefined}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 16,
              padding: "12px 20px",
              cursor: clickable ? "pointer" : "default",
              background: activeRowId === id ? SURFACE.hover : "transparent",
              borderBottom: `1px solid ${BORDER.hairline}`,
              minWidth,
              transition: "background-color 120ms linear",
            }}
            hoverStyle={clickable ? { background: SURFACE.hover } : undefined}
          >
            {columns.map((col) => (
              <div key={col.key} style={cellStyle(col)}>
                {col.render(row)}
              </div>
            ))}
          </Hoverable>
        );
      })}

      {rows.length === 0 ? <EmptyState message={empty} /> : null}
    </div>
  );
}
