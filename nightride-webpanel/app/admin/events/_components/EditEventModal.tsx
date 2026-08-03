"use client";

import { useState } from "react";
import { Modal } from "@/components/admin/ui/Modal";
import { Button } from "@/components/admin/ui/Button";
import { Input, Textarea } from "@/components/admin/ui/Field";
import { useAdminData } from "@/lib/admin/store";
import { useToast } from "@/components/admin/ui/Toast";
import { EventRecord } from "@/lib/admin/types";

function toLocalInputValue(iso: string) {
  const d = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

// Keyed by event?.id from the parent, so this component remounts (and re-initializes
// `form` from the latest event) whenever a different event is opened for editing.
export function EditEventModal({ event, onClose }: { event: EventRecord | null; onClose: () => void }) {
  const { editEvent } = useAdminData();
  const toast = useToast();
  const [form, setForm] = useState({
    title: event?.title ?? "",
    dateTime: event ? toLocalInputValue(event.dateTime) : "",
    location: event?.location ?? "",
    description: event?.description ?? "",
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  if (!event) return null;

  const validate = () => {
    const next: Record<string, string> = {};
    if (!form.title.trim()) next.title = "Event title is required.";
    if (!form.dateTime) next.dateTime = "Date and time is required.";
    if (!form.location.trim()) next.location = "Location is required.";
    setErrors(next);
    return Object.keys(next).length === 0;
  };

  const handleSave = () => {
    if (!validate()) return;
    editEvent(event.id, {
      title: form.title,
      dateTime: new Date(form.dateTime).toISOString(),
      location: form.location,
      description: form.description,
    });
    toast({ variant: "success", title: "Event updated", description: `${form.title} was updated.` });
    onClose();
  };

  return (
    <Modal
      open={!!event}
      onClose={onClose}
      title="Edit event"
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
        <Input label="Event title" value={form.title} error={errors.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
        <Input
          label="Date & time"
          type="datetime-local"
          value={form.dateTime}
          error={errors.dateTime}
          onChange={(e) => setForm({ ...form, dateTime: e.target.value })}
        />
        <Input
          label="Location"
          value={form.location}
          error={errors.location}
          onChange={(e) => setForm({ ...form, location: e.target.value })}
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
