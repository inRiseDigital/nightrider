import { PermissionKey } from "@/lib/admin/types";
import { PERMISSION_GROUPS, PERMISSION_LABELS } from "@/lib/admin/constants";
import { Badge } from "./Badge";

export function PermissionBadgeList({
  permissions,
}: {
  permissions: Record<PermissionKey, boolean>;
}) {
  return (
    <div className="space-y-3">
      {PERMISSION_GROUPS.map((group) => (
        <div key={group.label}>
          <p className="mb-1 text-xs text-nr-text-hint">{group.label}</p>
          <div className="flex flex-wrap gap-1.5">
            {group.keys.map((key) => (
              <Badge key={key} variant={permissions[key] ? "success" : "neutral"}>
                {PERMISSION_LABELS[key]}
              </Badge>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}
