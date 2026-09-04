import { TEXT } from "@/lib/admin/tokens";
import { Icon } from "../Icon";

/**
 * Centered muted message used for empty table/list states, e.g.
 * "No one matches those filters." / "No entries in that window."
 */
export function EmptyState({ message, icon }: { message: string; icon?: string }) {
  return (
    <div
      style={{
        padding: "48px 24px",
        textAlign: "center",
        fontSize: 14,
        color: TEXT.muted,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 10,
      }}
    >
      {icon ? <Icon name={icon} size={28} /> : null}
      {message}
    </div>
  );
}
