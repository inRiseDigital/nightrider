"use client";

import { useState } from "react";
import { SelectActionModal } from "../ui/SelectActionModal";
import { useAdminData } from "@/lib/admin/store";
import { useToast } from "../ui/Toast";
import { PlatformUser } from "@/lib/admin/types";

export function AssignClubModal({ user, onClose }: { user: PlatformUser | null; onClose: () => void }) {
  const { clubs, assignOrganizerClub } = useAdminData();
  const toast = useToast();
  const [clubId, setClubId] = useState(user?.organizerDetails?.clubId ?? "");

  if (!user) return null;

  const availableClubs = clubs.filter((c) => !c.organizerId || c.organizerId === user.id);

  return (
    <SelectActionModal
      open={!!user}
      onClose={onClose}
      title="Assign club"
      description={`Choose which club ${user.fullName} manages.`}
      fieldLabel="Club"
      value={clubId}
      onChange={setClubId}
      options={[{ label: "No club", value: "" }, ...availableClubs.map((c) => ({ label: c.name, value: c.id }))]}
      onConfirm={() => {
        assignOrganizerClub(user.id, clubId || null);
        toast({
          variant: "success",
          title: "Club assigned",
          description: clubId
            ? `${user.fullName} now manages ${clubs.find((c) => c.id === clubId)?.name}.`
            : `${user.fullName} was unassigned from their club.`,
        });
        onClose();
      }}
    />
  );
}
