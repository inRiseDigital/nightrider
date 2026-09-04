"use client";

import type { ReactNode } from "react";
import { Hoverable } from "../Hoverable";
import { SURFACE, TEXT } from "@/lib/admin/tokens";

const TONE_CHROME: Record<"danger" | "warning", { titleColor: string; confirmBg: string; confirmFg: string; confirmHoverBg: string }> = {
  danger: { titleColor: "#FFB4AB", confirmBg: "#93000A", confirmFg: "#FFDAD6", confirmHoverBg: "#A80010" },
  warning: { titleColor: "#F5C452", confirmBg: "#5C1218", confirmFg: "#FFB4AB", confirmHoverBg: "#711720" },
};

/**
 * Expand-in-place destructive confirm panel — the "why is this being
 * rejected" / "confirm revoke" pattern: a `#1F1B1F` card that appears inline
 * rather than a modal.
 */
export function ConfirmPanel({
  tone,
  title,
  body,
  confirmLabel,
  cancelLabel = "Cancel",
  onConfirm,
  onCancel,
  busy,
  children,
}: {
  tone: "danger" | "warning";
  /** Omit when the mockup has no heading above the body — e.g. the user drawer's delete confirm. */
  title?: string;
  body?: ReactNode;
  confirmLabel: string;
  cancelLabel?: string;
  onConfirm: () => void;
  onCancel: () => void;
  busy?: boolean;
  children?: ReactNode;
}) {
  const chrome = TONE_CHROME[tone];
  return (
    <div style={{ background: SURFACE.overlay, borderRadius: 16, padding: "16px 20px", display: "flex", flexDirection: "column", gap: 14 }}>
      {title ? <div style={{ fontSize: 14, fontWeight: 500, color: chrome.titleColor }}>{title}</div> : null}
      {body ? <div style={{ fontSize: 13, color: TEXT.secondary, lineHeight: 1.5 }}>{body}</div> : null}
      {children}
      <div style={{ display: "flex", gap: 8 }}>
        <Hoverable
          as="button"
          onClick={onConfirm}
          disabled={busy}
          style={{
            height: 40,
            padding: "0 22px",
            borderRadius: 20,
            fontSize: 14,
            fontWeight: 500,
            background: chrome.confirmBg,
            color: chrome.confirmFg,
            border: "none",
            cursor: busy ? "default" : "pointer",
            transition: "background-color 120ms linear",
          }}
          hoverStyle={{ background: chrome.confirmHoverBg }}
        >
          {confirmLabel}
        </Hoverable>
        <Hoverable
          as="button"
          onClick={onCancel}
          disabled={busy}
          style={{
            height: 40,
            padding: "0 18px",
            borderRadius: 20,
            fontSize: 14,
            fontWeight: 500,
            background: "transparent",
            color: TEXT.secondary,
            border: "none",
            cursor: busy ? "default" : "pointer",
          }}
          hoverStyle={{ background: "#FFFFFF14" }}
        >
          {cancelLabel}
        </Hoverable>
      </div>
    </div>
  );
}
