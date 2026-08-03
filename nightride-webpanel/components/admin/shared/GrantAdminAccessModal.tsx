"use client";

import { useState } from "react";
import { SelectActionModal } from "../ui/SelectActionModal";
import { useAdminData } from "@/lib/admin/store";
import { useToast } from "../ui/Toast";
import { PlatformUser, AdminAccessLevel } from "@/lib/admin/types";
import { ADMIN_ACCESS_LEVEL_LABELS } from "@/lib/admin/constants";

const ACCESS_LEVELS: AdminAccessLevel[] = ["moderator", "admin", "super_admin"];

export function GrantAdminAccessModal({ user, onClose }: { user: PlatformUser | null; onClose: () => void }) {
  const { grantAdminAccess } = useAdminData();
  const toast = useToast();
  const [accessLevel, setAccessLevel] = useState<AdminAccessLevel>("moderator");

  if (!user) return null;

  return (
    <SelectActionModal
      open={!!user}
      onClose={onClose}
      title="Grant admin access"
      description={`Give ${user.fullName} administrator privileges.`}
      confirmLabel="Grant access"
      fieldLabel="Admin access level"
      fieldHint="Controls which admin-only features this user can access."
      value={accessLevel}
      onChange={setAccessLevel}
      options={ACCESS_LEVELS.map((l) => ({ label: ADMIN_ACCESS_LEVEL_LABELS[l], value: l }))}
      onConfirm={() => {
        grantAdminAccess(user.id, accessLevel);
        toast({
          variant: "success",
          title: "Admin access granted",
          description: `${user.fullName} is now ${ADMIN_ACCESS_LEVEL_LABELS[accessLevel]}.`,
        });
        onClose();
      }}
    />
  );
}
