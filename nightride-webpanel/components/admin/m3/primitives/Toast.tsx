import { SURFACE, TEXT } from "@/lib/admin/tokens";
import { Icon } from "../Icon";

/**
 * Confirmation strip — `task_alt` icon + message on a `#2A252A` pill. Renders
 * nothing when `message` is null (mirrors the mockup's `hasUserToast` /
 * `hasRoleToast` conditionals).
 */
export function Toast({ message, onDismiss }: { message: string | null; onDismiss?: () => void }) {
  if (message === null) return null;

  return (
    <div
      onClick={onDismiss}
      style={{
        background: SURFACE.hover,
        borderRadius: 12,
        padding: "12px 16px",
        display: "flex",
        alignItems: "center",
        gap: 10,
        fontSize: 13,
        color: TEXT.primary,
        cursor: onDismiss ? "pointer" : "default",
      }}
    >
      <Icon name="task_alt" size={18} color="#7BE0A8" />
      {message}
    </div>
  );
}
