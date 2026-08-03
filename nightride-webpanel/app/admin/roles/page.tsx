"use client";

import { Fragment, useEffect, useMemo, useState } from "react";
import { RotateCcw, Save, Undo2 } from "lucide-react";
import { useAdminData, cloneRolePermissions } from "@/lib/admin/store";
import { useToast } from "@/components/admin/ui/Toast";
import { Card, CardHeader } from "@/components/admin/ui/Card";
import { Button } from "@/components/admin/ui/Button";
import { Checkbox } from "@/components/admin/ui/Field";
import { ROLES, ROLE_LABELS, PERMISSION_GROUPS, PERMISSION_LABELS, DEFAULT_ROLE_PERMISSIONS } from "@/lib/admin/constants";
import { PermissionKey, Role } from "@/lib/admin/types";
import { cn } from "@/components/admin/ui/cn";

export default function RolesPage() {
  const { rolePermissions: saved, saveRolePermissions } = useAdminData();
  const toast = useToast();
  const [draft, setDraft] = useState(() => cloneRolePermissions(saved));

  useEffect(() => {
    setDraft(cloneRolePermissions(saved));
  }, [saved]);

  const changedCells = useMemo(() => {
    const set = new Set<string>();
    for (const role of ROLES) {
      for (const key of Object.keys(draft[role]) as PermissionKey[]) {
        if (draft[role][key] !== saved[role][key]) set.add(`${role}:${key}`);
      }
    }
    return set;
  }, [draft, saved]);

  const hasChanges = changedCells.size > 0;

  const toggle = (role: Role, key: PermissionKey) => {
    setDraft((prev) => ({ ...prev, [role]: { ...prev[role], [key]: !prev[role][key] } }));
  };

  const handleSave = () => {
    saveRolePermissions(draft);
    toast({ variant: "success", title: "Permissions saved", description: "The role permission matrix has been updated." });
  };

  const handleReset = () => setDraft(cloneRolePermissions(saved));

  const handleRestoreDefaults = () => {
    setDraft(cloneRolePermissions(DEFAULT_ROLE_PERMISSIONS));
    toast({ variant: "info", title: "Defaults loaded", description: "Review the changes below, then save to apply them." });
  };

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader
          title="Role permission matrix"
          description="Toggle which features each role can access. Changes are highlighted until saved."
          action={
            <div className="flex gap-2">
              <Button variant="ghost" size="sm" onClick={handleRestoreDefaults}>
                <RotateCcw size={14} /> Restore defaults
              </Button>
              <Button variant="secondary" size="sm" disabled={!hasChanges} onClick={handleReset}>
                <Undo2 size={14} /> Reset changes
              </Button>
              <Button size="sm" disabled={!hasChanges} onClick={handleSave}>
                <Save size={14} /> Save changes
              </Button>
            </div>
          }
        />

        <div className="overflow-x-auto">
          <table className="w-full min-w-[640px] text-left text-sm">
            <thead>
              <tr className="border-b border-nr-border">
                <th className="w-72 px-5 py-3 text-xs font-medium uppercase tracking-wider text-nr-text-hint">
                  Permission
                </th>
                {ROLES.map((role) => (
                  <th key={role} className="px-5 py-3 text-center text-xs font-medium uppercase tracking-wider text-nr-text-hint">
                    {ROLE_LABELS[role]}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {PERMISSION_GROUPS.map((group) => (
                <Fragment key={group.label}>
                  <tr className="bg-white/[0.02]">
                    <td colSpan={ROLES.length + 1} className="px-5 py-2 text-xs font-medium text-nr-text-secondary">
                      {group.label}
                    </td>
                  </tr>
                  {group.keys.map((key) => (
                    <tr key={key} className="border-b border-nr-border last:border-b-0">
                      <td className="px-5 py-3 text-sm text-nr-text-primary">{PERMISSION_LABELS[key]}</td>
                      {ROLES.map((role) => {
                        const changed = changedCells.has(`${role}:${key}`);
                        return (
                          <td key={role} className="px-5 py-3 text-center">
                            <span
                              className={cn(
                                "inline-flex items-center justify-center rounded-md p-1.5",
                                changed && "ring-1 ring-nr-accent/60 bg-nr-accent/10"
                              )}
                            >
                              <Checkbox
                                checked={draft[role][key]}
                                onChange={() => toggle(role, key)}
                                aria-label={`${PERMISSION_LABELS[key]} for ${ROLE_LABELS[role]}`}
                              />
                            </span>
                          </td>
                        );
                      })}
                    </tr>
                  ))}
                </Fragment>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      {hasChanges && (
        <p className="text-sm text-nr-text-secondary">
          <span className="mr-1 inline-block h-2 w-2 rounded-full bg-nr-accent align-middle" />
          {changedCells.size} permission{changedCells.size === 1 ? "" : "s"} changed — remember to save.
        </p>
      )}
    </div>
  );
}
