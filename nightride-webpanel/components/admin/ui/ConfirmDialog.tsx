"use client";

import { useState } from "react";
import { AlertTriangle } from "lucide-react";
import { Modal } from "./Modal";
import { Button } from "./Button";
import { Textarea } from "./Field";

export interface ConfirmDialogProps {
  open: boolean;
  onClose: () => void;
  onConfirm: (reason?: string) => void;
  title: string;
  description: string;
  confirmLabel?: string;
  variant?: "danger" | "primary";
  requireReason?: boolean;
  backendNote?: string;
}

export function ConfirmDialog({
  open,
  onClose,
  onConfirm,
  title,
  description,
  confirmLabel = "Confirm",
  variant = "danger",
  requireReason = false,
  backendNote,
}: ConfirmDialogProps) {
  const [reason, setReason] = useState("");
  const canConfirm = !requireReason || reason.trim().length > 0;

  const handleClose = () => {
    setReason("");
    onClose();
  };

  return (
    <Modal
      open={open}
      onClose={handleClose}
      title={title}
      size="sm"
      footer={
        <>
          <Button variant="ghost" onClick={handleClose}>
            Cancel
          </Button>
          <Button
            variant={variant === "danger" ? "danger" : "primary"}
            disabled={!canConfirm}
            onClick={() => {
              onConfirm(reason.trim() || undefined);
              setReason("");
            }}
          >
            {confirmLabel}
          </Button>
        </>
      }
    >
      <div className="flex gap-3">
        {variant === "danger" && (
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-red-500/10 text-red-400">
            <AlertTriangle size={18} />
          </div>
        )}
        <p className="text-sm text-nr-text-secondary">{description}</p>
      </div>

      {requireReason && (
        <div className="mt-4">
          <Textarea
            label="Reason"
            placeholder="Explain why this action is being taken..."
            value={reason}
            onChange={(e) => setReason(e.target.value)}
          />
        </div>
      )}

      {backendNote && (
        <p className="mt-4 rounded-lg border border-amber-500/20 bg-amber-500/5 p-3 text-xs text-amber-300">
          {backendNote}
        </p>
      )}
    </Modal>
  );
}
