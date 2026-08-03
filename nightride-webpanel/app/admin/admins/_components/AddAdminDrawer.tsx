"use client";

import { useMemo, useState } from "react";
import { ArrowLeft, ShieldCheck } from "lucide-react";
import { Drawer } from "@/components/admin/ui/Drawer";
import { Button } from "@/components/admin/ui/Button";
import { SearchInput } from "@/components/admin/ui/SearchInput";
import { Select, Checkbox } from "@/components/admin/ui/Field";
import { Avatar } from "@/components/admin/ui/Avatar";
import { Badge } from "@/components/admin/ui/Badge";
import { PermissionBadgeList } from "@/components/admin/ui/PermissionBadgeList";
import { useAdminData } from "@/lib/admin/store";
import { useToast } from "@/components/admin/ui/Toast";
import { AdminAccessLevel, PlatformUser } from "@/lib/admin/types";
import { ADMIN_ACCESS_LEVEL_LABELS } from "@/lib/admin/constants";

const ACCESS_LEVELS: AdminAccessLevel[] = ["moderator", "admin", "super_admin"];

export function AddAdminDrawer({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { users, rolePermissions, grantAdminAccess } = useAdminData();
  const toast = useToast();
  const [step, setStep] = useState<1 | 2>(1);
  const [search, setSearch] = useState("");
  const [selectedUser, setSelectedUser] = useState<PlatformUser | null>(null);
  const [accessLevel, setAccessLevel] = useState<AdminAccessLevel>("moderator");
  const [confirmed, setConfirmed] = useState(false);

  const candidates = useMemo(() => {
    const q = search.trim().toLowerCase();
    return users
      .filter((u) => !u.isAdmin)
      .filter((u) => !q || u.fullName.toLowerCase().includes(q) || u.email.toLowerCase().includes(q))
      .slice(0, 20);
  }, [users, search]);

  const reset = () => {
    setStep(1);
    setSearch("");
    setSelectedUser(null);
    setAccessLevel("moderator");
    setConfirmed(false);
  };

  const handleClose = () => {
    reset();
    onClose();
  };

  const handleGrant = () => {
    if (!selectedUser) return;
    grantAdminAccess(selectedUser.id, accessLevel);
    toast({
      variant: "success",
      title: "Admin access granted",
      description: `${selectedUser.fullName} is now ${ADMIN_ACCESS_LEVEL_LABELS[accessLevel]}.`,
    });
    handleClose();
  };

  return (
    <Drawer
      open={open}
      onClose={handleClose}
      title="Add admin"
      subtitle={step === 1 ? "Step 1 of 2 — select a user" : "Step 2 of 2 — access & confirmation"}
      footer={
        step === 1 ? (
          <>
            <Button variant="ghost" onClick={handleClose}>
              Cancel
            </Button>
            <Button disabled={!selectedUser} onClick={() => setStep(2)}>
              Continue
            </Button>
          </>
        ) : (
          <>
            <Button variant="ghost" onClick={() => setStep(1)}>
              <ArrowLeft size={14} /> Back
            </Button>
            <Button disabled={!confirmed} onClick={handleGrant}>
              Grant admin access
            </Button>
          </>
        )
      }
    >
      {step === 1 ? (
        <div className="space-y-3">
          <SearchInput value={search} onChange={setSearch} placeholder="Search users by name or email..." />
          <ul className="space-y-1.5">
            {candidates.map((u) => (
              <li key={u.id}>
                <button
                  onClick={() => setSelectedUser(u)}
                  className={`flex w-full items-center gap-3 rounded-lg border p-2.5 text-left transition-colors ${
                    selectedUser?.id === u.id
                      ? "border-nr-primary bg-nr-primary/10"
                      : "border-nr-border hover:border-nr-primary-light/40"
                  }`}
                >
                  <Avatar name={u.fullName} src={u.avatarUrl} size={32} />
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm text-nr-text-primary">{u.fullName}</p>
                    <p className="truncate text-xs text-nr-text-hint">{u.email}</p>
                  </div>
                  <Badge variant="neutral">{u.role}</Badge>
                </button>
              </li>
            ))}
            {candidates.length === 0 && <p className="py-6 text-center text-sm text-nr-text-hint">No matching users.</p>}
          </ul>
        </div>
      ) : (
        selectedUser && (
          <div className="space-y-5">
            <div className="flex items-center gap-3 rounded-lg border border-nr-border p-3">
              <Avatar name={selectedUser.fullName} src={selectedUser.avatarUrl} size={40} />
              <div>
                <p className="text-sm font-medium text-nr-text-primary">{selectedUser.fullName}</p>
                <p className="text-xs text-nr-text-hint">{selectedUser.email}</p>
              </div>
            </div>

            <Select
              label="Admin access level"
              value={accessLevel}
              onChange={(e) => setAccessLevel(e.target.value as AdminAccessLevel)}
              options={ACCESS_LEVELS.map((l) => ({ label: ADMIN_ACCESS_LEVEL_LABELS[l], value: l }))}
            />

            <div>
              <p className="mb-2 text-xs font-medium uppercase tracking-wider text-nr-text-hint">
                Permissions granted to the Admin role
              </p>
              <PermissionBadgeList permissions={rolePermissions.admin} />
            </div>

            <label className="flex items-start gap-2 rounded-lg border border-nr-primary-light/20 bg-nr-primary-light/5 p-3">
              <Checkbox checked={confirmed} onChange={setConfirmed} aria-label="Confirm granting admin access" />
              <span className="text-sm text-nr-text-secondary">
                <ShieldCheck size={14} className="mb-0.5 mr-1 inline text-nr-primary-light" />
                I confirm I want to grant <strong className="text-nr-text-primary">{selectedUser.fullName}</strong> admin
                access at the {ADMIN_ACCESS_LEVEL_LABELS[accessLevel]} level.
              </span>
            </label>
          </div>
        )
      )}
    </Drawer>
  );
}
