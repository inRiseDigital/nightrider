"use client";

import { useState } from "react";
import { SelectActionModal } from "../ui/SelectActionModal";
import { useAdminData } from "@/lib/admin/store";
import { useToast } from "../ui/Toast";
import { PlatformUser, Role } from "@/lib/admin/types";
import { ROLES, ROLE_LABELS } from "@/lib/admin/constants";

export function ChangeRoleModal({ user, onClose }: { user: PlatformUser | null; onClose: () => void }) {
  const { changeUserRole, promoteToOrganizer, grantAdminAccess } = useAdminData();
  const toast = useToast();
  const [role, setRole] = useState<Role>(user?.role ?? "user");

  if (!user) return null;

  const handleSave = () => {
    if (role === user.role) {
      onClose();
      return;
    }
    if (role === "organizer") {
      promoteToOrganizer(user.id);
    } else if (role === "admin") {
      grantAdminAccess(user.id, "admin");
    } else {
      changeUserRole(user.id, role);
    }
    toast({ variant: "success", title: "Role updated", description: `${user.fullName} is now ${ROLE_LABELS[role]}.` });
    onClose();
  };

  return (
    <SelectActionModal
      open={!!user}
      onClose={onClose}
      title="Change role"
      description={`Update the role for ${user.fullName}.`}
      confirmLabel="Save changes"
      fieldLabel="Role"
      value={role}
      onChange={setRole}
      options={ROLES.map((r) => ({ label: ROLE_LABELS[r], value: r }))}
      onConfirm={handleSave}
    />
  );
}
