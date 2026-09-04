import type { ChangeEventHandler, ReactNode } from "react";
import { BORDER, SURFACE, TEXT } from "@/lib/admin/tokens";
import { Icon } from "../Icon";

/**
 * Flex-wrap filter row that sits above list screens — search field + select
 * filters, plus an optional right-aligned trailing slot (used for the audit
 * count label: `{{ auditCountLabel }}`).
 */
export function FilterBar({ children, trailing }: { children: ReactNode; trailing?: ReactNode }) {
  return (
    <div style={{ display: "flex", flexWrap: "wrap", gap: 12, alignItems: "center", marginBottom: 16 }}>
      {children}
      {trailing ? <div style={{ marginLeft: "auto", flexShrink: 0 }}>{trailing}</div> : null}
    </div>
  );
}

export function SearchInput({
  value,
  onChange,
  placeholder,
  maxWidth = 380,
}: {
  value: string;
  onChange: ChangeEventHandler<HTMLInputElement>;
  placeholder?: string;
  maxWidth?: number;
}) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 8,
        flex: 1,
        minWidth: 240,
        maxWidth,
        height: 48,
        padding: "0 16px",
        borderRadius: 24,
        background: SURFACE.hover,
      }}
    >
      <Icon name="search" size={20} color={TEXT.secondary} />
      <input
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        style={{ flex: 1, minWidth: 0, height: "100%", background: "transparent", border: "none", color: TEXT.primary, fontSize: 14 }}
      />
    </div>
  );
}

export function SelectFilter({
  value,
  onChange,
  children,
}: {
  value: string;
  onChange: ChangeEventHandler<HTMLSelectElement>;
  children: ReactNode;
}) {
  return (
    <select
      value={value}
      onChange={onChange}
      style={{
        height: 48,
        padding: "0 14px",
        borderRadius: 12,
        background: SURFACE.raised,
        border: `1px solid ${BORDER.strong}`,
        color: TEXT.primary,
        fontSize: 14,
        cursor: "pointer",
      }}
    >
      {children}
    </select>
  );
}
