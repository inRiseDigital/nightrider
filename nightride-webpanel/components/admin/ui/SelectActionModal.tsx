"use client";

import { Modal } from "./Modal";
import { Button } from "./Button";
import { Select } from "./Field";

export function SelectActionModal<T extends string>({
  open,
  onClose,
  title,
  description,
  confirmLabel = "Save",
  fieldLabel,
  fieldHint,
  value,
  onChange,
  options,
  onConfirm,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  description: string;
  confirmLabel?: string;
  fieldLabel: string;
  fieldHint?: string;
  value: T;
  onChange: (value: T) => void;
  options: { label: string; value: T }[];
  onConfirm: () => void;
}) {
  return (
    <Modal
      open={open}
      onClose={onClose}
      title={title}
      description={description}
      size="sm"
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={onConfirm}>{confirmLabel}</Button>
        </>
      }
    >
      <Select
        label={fieldLabel}
        value={value}
        onChange={(e) => onChange(e.target.value as T)}
        options={options}
        hint={fieldHint}
      />
    </Modal>
  );
}
