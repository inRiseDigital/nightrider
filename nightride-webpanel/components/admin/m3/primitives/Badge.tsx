import type { ReactNode } from "react";
import { badgeColors, type BadgeType } from "@/lib/admin/tokens";
import { Icon } from "../Icon";

/**
 * The pill used everywhere for status/role/type labels — 26px tall / 8px
 * radius by default, 22px `sm` for compact list rows (e.g. event-queue
 * status pills, flag chips).
 */
export function Badge({
  label,
  tone = "neutral",
  colors,
  icon,
  size = "md",
}: {
  label: ReactNode;
  tone?: BadgeType;
  colors?: { bg: string; fg: string };
  icon?: string;
  size?: "sm" | "md";
}) {
  const { bg, fg } = colors ?? badgeColors(tone);
  const height = size === "sm" ? 22 : 26;
  return (
    <div
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: icon ? 4 : 0,
        height,
        padding: "0 10px",
        borderRadius: 8,
        fontSize: 12,
        fontWeight: 500,
        background: bg,
        color: fg,
        flexShrink: 0,
      }}
    >
      {icon ? <Icon name={icon} size={14} /> : null}
      {label}
    </div>
  );
}
