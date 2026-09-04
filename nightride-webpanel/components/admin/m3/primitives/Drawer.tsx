"use client";

import type { ReactNode } from "react";
import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import { SURFACE, TEXT } from "@/lib/admin/tokens";

/**
 * Right-side overlay panel used for the user detail drawer, and reusable for
 * later drawers. Backdrop click closes; content click does not propagate.
 */
export function Drawer({
  open,
  onClose,
  header,
  children,
  width = 440,
}: {
  open: boolean;
  onClose: () => void;
  header: ReactNode;
  children: ReactNode;
  width?: number;
}) {
  if (!open) return null;

  return (
    <div style={{ position: "fixed", inset: 0, zIndex: 70, display: "flex", justifyContent: "flex-end" }}>
      <div onClick={onClose} style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.55)" }} />
      <div
        style={{
          position: "relative",
          width: "100%",
          maxWidth: width,
          height: "100%",
          background: SURFACE.raised,
          boxShadow: "-4px 0 16px rgba(0,0,0,0.4)",
          display: "flex",
          flexDirection: "column",
          animation: "m3rise 160ms ease-out",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "16px 16px 12px 20px", flexShrink: 0 }}>
          <div style={{ minWidth: 0, flex: 1, display: "flex", alignItems: "center", gap: 12 }}>{header}</div>
          <Hoverable
            as="button"
            onClick={onClose}
            style={{
              width: 40,
              height: 40,
              borderRadius: "50%",
              background: "transparent",
              border: "none",
              color: TEXT.secondary,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              flexShrink: 0,
            }}
            hoverStyle={{ background: SURFACE.hover }}
          >
            <Icon name="close" size={22} />
          </Hoverable>
        </div>
        <div style={{ flex: 1, overflowY: "auto", padding: "16px 20px 20px" }}>{children}</div>
      </div>
    </div>
  );
}
