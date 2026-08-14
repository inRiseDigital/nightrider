"use client";

import { useState } from "react";
import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";
import { initialsFor, organizerStatusColors, organizerStatusLabel, timeAgo } from "@/lib/admin/present";
import type { ApplicantDetail } from "@/lib/admin/useApplicantDetail";

export function OrgDetailHeader({ detail, onBack }: { detail: ApplicantDetail; onBack: () => void }) {
  const { user, ban, busy } = detail;
  const [confirmBanOpen, setConfirmBanOpen] = useState(false);
  if (!user) return null;

  const isDecided = user.organizerStatus === "approved" || user.organizerStatus === "rejected";
  const colors = organizerStatusColors(user.organizerStatus);

  return (
    <div style={{ display: "flex", alignItems: "center", gap: 12, flexWrap: "wrap", padding: "4px 0 16px" }}>
      <Hoverable
        onClick={onBack}
        style={{ display: "inline-flex", alignItems: "center", gap: 8, height: 40, padding: "0 16px 0 12px", borderRadius: 20, cursor: "pointer", color: "#CFC0C5", fontSize: 14, fontWeight: 500 }}
        hoverStyle={{ background: "#2A252A", color: "#EDE0E4" }}
      >
        <Icon name="arrow_back" size={20} />
        Organizers
      </Hoverable>
      <div
        style={{
          width: 44,
          height: 44,
          borderRadius: "50%",
          background: "#8E1049",
          color: "#FFD9E2",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 15,
          fontWeight: 500,
          flexShrink: 0,
          marginLeft: 4,
        }}
      >
        {initialsFor(user.displayName, user.email)}
      </div>
      <div style={{ minWidth: 0 }}>
        <div style={{ fontSize: 20, fontWeight: 400, lineHeight: 1.2 }}>{user.displayName || user.email}</div>
        <div style={{ fontSize: 13, color: "#CFC0C5", marginTop: 2, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
          {user.email} {user.phone ? `· ${user.phone}` : ""}
        </div>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 8, marginLeft: "auto", flexShrink: 0, position: "relative" }}>
        <div style={{ display: "inline-flex", alignItems: "center", height: 32, padding: "0 12px", borderRadius: 8, fontSize: 13, fontWeight: 500, background: colors.bg, color: colors.fg }}>
          {organizerStatusLabel(user.organizerStatus)}
        </div>
        <div style={{ fontFamily: "'Roboto Mono', monospace", fontSize: 12, color: "#9A8C91" }}>Applied {timeAgo(user.applicationSubmittedAt)}</div>

        {isDecided ? (
          <Hoverable
            as="button"
            onClick={() => setConfirmBanOpen(true)}
            disabled={busy}
            style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#93000A", color: "#FFDAD6", border: "none", cursor: "pointer" }}
            hoverStyle={{ background: "#A80010" }}
          >
            Ban
          </Hoverable>
        ) : null}
      </div>

      {confirmBanOpen ? (
        <div
          onClick={() => setConfirmBanOpen(false)}
          style={{ position: "fixed", inset: 0, zIndex: 60, background: "rgba(0,0,0,0.6)", display: "flex", alignItems: "center", justifyContent: "center", padding: 24 }}
        >
          <div onClick={(e) => e.stopPropagation()} style={{ width: "100%", maxWidth: 420, background: "#2A252A", borderRadius: 24, padding: 24 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 10, color: "#FFB4AB" }}>
              <Icon name="warning" size={22} />
              <div style={{ fontSize: 18, fontWeight: 500 }}>Ban {user.displayName || user.email}?</div>
            </div>
            <div style={{ fontSize: 13, color: "#CFC0C5", lineHeight: 1.6, marginBottom: 18 }}>
              This permanently deletes the account: Firestore profile, KYC evidence in Storage, and the Firebase Auth
              user. It cannot be undone. There is no partial suspend in this schema — this is the only real
              &quot;remove this organizer&quot; mechanism, and it runs through the Admin SDK (requires{" "}
              <code style={{ background: "#1B181B", padding: "1px 5px", borderRadius: 4 }}>netlify dev</code>).
            </div>
            <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
              <Hoverable
                as="button"
                onClick={() => setConfirmBanOpen(false)}
                style={{ height: 40, padding: "0 18px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: "#CFC0C5", border: "none", cursor: "pointer" }}
                hoverStyle={{ background: "#FFFFFF14" }}
              >
                Cancel
              </Hoverable>
              <button
                onClick={() => {
                  setConfirmBanOpen(false);
                  void ban();
                }}
                disabled={busy}
                style={{ height: 40, padding: "0 20px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "#93000A", color: "#FFDAD6", border: "none", cursor: "pointer" }}
              >
                {busy ? "Deleting…" : "Delete account"}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
