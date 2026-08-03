"use client";

import { useState } from "react";
import { AlertTriangle } from "lucide-react";
import { Modal } from "@/components/admin/ui/Modal";
import { Button } from "@/components/admin/ui/Button";
import { Select, Textarea } from "@/components/admin/ui/Field";
import { useAdminData } from "@/lib/admin/store";
import { useToast } from "@/components/admin/ui/Toast";
import { EventRecord, EventStatus } from "@/lib/admin/types";
import { EVENT_STATUS_LABELS } from "@/lib/admin/format";

const STATUS_ORDER: EventStatus[] = [
  "draft",
  "scheduled",
  "starting_soon",
  "ongoing",
  "completed",
  "cancelled",
  "emergency_closure",
];

export function ChangeStatusModal({ event, onClose }: { event: EventRecord | null; onClose: () => void }) {
  const { changeEventStatus } = useAdminData();
  const toast = useToast();
  const [status, setStatus] = useState<EventStatus>(event?.status ?? "draft");
  const [reason, setReason] = useState("");

  if (!event) return null;

  const isEmergency = status === "emergency_closure";

  return (
    <Modal
      open={!!event}
      onClose={onClose}
      title="Change event status"
      description={event.title}
      size="sm"
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button
            variant={isEmergency ? "danger" : "primary"}
            disabled={status === event.status}
            onClick={() => {
              changeEventStatus(event.id, status, reason || undefined);
              toast({
                variant: isEmergency ? "error" : "success",
                title: "Event status changed",
                description: `${event.title} is now ${EVENT_STATUS_LABELS[status]}.`,
              });
              onClose();
            }}
          >
            Update status
          </Button>
        </>
      }
    >
      <div className="space-y-4">
        <Select
          label="Status"
          value={status}
          onChange={(e) => setStatus(e.target.value as EventStatus)}
          options={STATUS_ORDER.map((s) => ({ label: EVENT_STATUS_LABELS[s], value: s }))}
        />
        {isEmergency && (
          <div className="flex gap-2 rounded-lg border border-red-500/20 bg-red-500/5 p-3 text-sm text-red-300">
            <AlertTriangle size={16} className="mt-0.5 shrink-0" />
            <p>Publishing an emergency closure will immediately flag this event to attendees.</p>
          </div>
        )}
        <Textarea label="Reason (optional)" value={reason} onChange={(e) => setReason(e.target.value)} />
      </div>
    </Modal>
  );
}
