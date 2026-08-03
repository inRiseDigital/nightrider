"use client";

import { useState } from "react";
import { Modal } from "@/components/admin/ui/Modal";
import { Button } from "@/components/admin/ui/Button";
import { Input, Textarea } from "@/components/admin/ui/Field";
import { useAdminData } from "@/lib/admin/store";
import { useToast } from "@/components/admin/ui/Toast";
import { Club } from "@/lib/admin/types";

// Keyed by club?.id from the parent, so this component remounts (and re-initializes
// `form` from the latest club) whenever a different club is opened for editing.
export function EditClubModal({ club, onClose }: { club: Club | null; onClose: () => void }) {
  const { editClub } = useAdminData();
  const toast = useToast();
  const [form, setForm] = useState({
    name: club?.name ?? "",
    location: club?.location ?? "",
    contactEmail: club?.contactEmail ?? "",
    contactPhone: club?.contactPhone ?? "",
    description: club?.description ?? "",
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  if (!club) return null;

  const validate = () => {
    const next: Record<string, string> = {};
    if (!form.name.trim()) next.name = "Club name is required.";
    if (!/^\S+@\S+\.\S+$/.test(form.contactEmail)) next.contactEmail = "Enter a valid email address.";
    if (!form.location.trim()) next.location = "Location is required.";
    setErrors(next);
    return Object.keys(next).length === 0;
  };

  const handleSave = () => {
    if (!validate()) return;
    editClub(club.id, form);
    toast({ variant: "success", title: "Club updated", description: `${form.name}'s information was updated.` });
    onClose();
  };

  return (
    <Modal
      open={!!club}
      onClose={onClose}
      title="Edit club information"
      description="Changes are saved to local mock state only."
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={handleSave}>Save changes</Button>
        </>
      }
    >
      <div className="space-y-4">
        <Input label="Club name" value={form.name} error={errors.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
        <Input
          label="Location"
          value={form.location}
          error={errors.location}
          onChange={(e) => setForm({ ...form, location: e.target.value })}
        />
        <Input
          label="Contact email"
          type="email"
          value={form.contactEmail}
          error={errors.contactEmail}
          onChange={(e) => setForm({ ...form, contactEmail: e.target.value })}
        />
        <Input
          label="Contact phone"
          value={form.contactPhone}
          onChange={(e) => setForm({ ...form, contactPhone: e.target.value })}
        />
        <Textarea
          label="Description"
          value={form.description}
          onChange={(e) => setForm({ ...form, description: e.target.value })}
        />
      </div>
    </Modal>
  );
}
