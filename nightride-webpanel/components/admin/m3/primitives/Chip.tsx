import type { ReactNode } from "react";
import { Hoverable } from "../Hoverable";
import { SURFACE, TEXT } from "@/lib/admin/tokens";

/**
 * Clickable pill for lineup names and quick-reason chips (reject reasons,
 * lineup list). See `{{ eqDetail.reasonChips }}` / `{{ eqDetail.lineup }}`.
 */
export function Chip({ label, onClick, active }: { label: ReactNode; onClick?: () => void; active?: boolean }) {
  const clickable = !!onClick;
  return (
    <Hoverable
      as="div"
      onClick={onClick}
      style={{
        display: "inline-flex",
        alignItems: "center",
        height: 32,
        padding: "0 14px",
        borderRadius: 8,
        fontSize: active ? 13 : 12,
        background: active ? SURFACE.accentCard : SURFACE.hover,
        color: active ? TEXT.primary : TEXT.secondary,
        cursor: clickable ? "pointer" : "default",
      }}
      hoverStyle={clickable ? { background: "#3A333A", color: TEXT.primary } : undefined}
    >
      {label}
    </Hoverable>
  );
}
