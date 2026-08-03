"use client";

import { useState } from "react";
import { SelectActionModal } from "../ui/SelectActionModal";
import { useAdminData } from "@/lib/admin/store";
import { useToast } from "../ui/Toast";
import { PlatformUser } from "@/lib/admin/types";

export function PromoteOrganizerModal({ user, onClose }: { user: PlatformUser | null; onClose: () => void }) {
  const { clubs, promoteToOrganizer } = useAdminData();
  const toast = useToast();
  const [clubId, setClubId] = useState("");

  if (!user) return null;

  const unassignedClubs = clubs.filter((c) => !c.organizerId);

  return (
    <SelectActionModal
      open={!!user}
      onClose={onClose}
      title="Promote to organizer"
      description={`Give ${user.fullName} organizer access.`}
      confirmLabel="Promote"
      fieldLabel="Assign club (optional)"
      fieldHint="You can change this later from Organizer Management."
      value={clubId}
      onChange={setClubId}
      options={[{ label: "No club — assign later", value: "" }, ...unassignedClubs.map((c) => ({ label: c.name, value: c.id }))]}
      onConfirm={() => {
        promoteToOrganizer(user.id, clubId || null);
        toast({ variant: "success", title: "Promoted to organizer", description: `${user.fullName} can now manage club content.` });
        onClose();
      }}
    />
  );
}
