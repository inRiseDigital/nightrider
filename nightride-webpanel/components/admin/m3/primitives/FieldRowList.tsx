import type { ReactNode } from "react";
import { MONO, TEXT } from "@/lib/admin/tokens";

/**
 * The label/value record list used for "Venue record" / "Submission" /
 * user-drawer profile panels — see `{{ venue.rows }}`, `{{ eqDetail.facts }}`,
 * `{{ userDrawer.rows }}`.
 */
export function FieldRowList({ rows }: { rows: { label: string; value: ReactNode; mono?: boolean; tone?: string }[] }) {
  return (
    <div style={{ display: "flex", flexDirection: "column" }}>
      {rows.map((r) => (
        <div
          key={r.label}
          style={{ display: "flex", justifyContent: "space-between", gap: 16, padding: "9px 0", borderBottom: "1px solid #241F23", fontSize: 14 }}
        >
          <span style={{ color: TEXT.muted, flexShrink: 0 }}>{r.label}</span>
          <span style={{ textAlign: "right", fontFamily: r.mono ? MONO : "inherit", color: r.tone ?? TEXT.primary, minWidth: 0, wordBreak: "break-word" }}>
            {r.value}
          </span>
        </div>
      ))}
    </div>
  );
}
