"use client";

import { useState } from "react";
import { Modal } from "@/components/admin/ui/Modal";
import { Button } from "@/components/admin/ui/Button";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { FieldLabel, SlimInput, Toggle } from "../ui/Primitives";

/** Checks completed during the organizer application — read-only here by design. */
const VERIFICATION_ROWS = [
  { label: "NIC / ID Scan", detail: "Government ID front + back, verified Jun 14, 2026" },
  { label: "Live Selfie", detail: "Matched to ID on file" },
];

const DEFAULT_PREFERENCES = [
  {
    id: "guestList",
    label: "Guest list notifications",
    desc: "Push me when an RSVP list passes 80% of capacity.",
    on: true,
  },
  {
    id: "autoPublish",
    label: "Auto-publish recurring nights",
    desc: "Weekly residencies publish without re-review.",
    on: false,
  },
  {
    id: "crowdData",
    label: "Share anonymised crowd data",
    desc: "Helps the assistant recommend your venue more accurately.",
    on: true,
  },
  {
    id: "payoutTwoFactor",
    label: "Two-factor on payouts",
    desc: "Require SMS confirmation for any payout change.",
    on: true,
  },
];

export function SettingsSection() {
  const {
    accountEmail,
    accountPhone,
    startChangeField,
    changeField,
    changeStage,
    changeValue,
    setChangeValue,
    changeOtp,
    setChangeOtp,
    changeError,
    cancelChangeField,
    submitNewValue,
    submitOtp,
  } = useOrganizerDashboard();

  const [preferences, setPreferences] = useState(DEFAULT_PREFERENCES);
  const [removalRequested, setRemovalRequested] = useState(false);

  const fieldLabel = changeField === "phone" ? "phone number" : "email";
  const placeholder = changeField === "phone" ? "+971 50 000 0000" : "you@example.com";

  const accountRows = [
    { label: "Email", value: accountEmail, field: "email" as const },
    { label: "Phone", value: accountPhone, field: "phone" as const },
  ];

  return (
    <>
      <div className="flex max-w-[600px] flex-col gap-4">
        <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
          <FieldLabel className="mb-3.5">Preferences</FieldLabel>
          {preferences.map((p) => (
            <div
              key={p.id}
              className="flex items-center justify-between gap-4 border-b border-[var(--m3-outlinev)] py-3 last:border-b-0"
            >
              <div className="min-w-0">
                <p className="text-sm text-[var(--m3-on)]">{p.label}</p>
                <p className="mt-0.5 text-xs text-[var(--m3-onv)]">{p.desc}</p>
              </div>
              <Toggle
                checked={p.on}
                label={p.label}
                onChange={() =>
                  setPreferences((prev) =>
                    prev.map((row) => (row.id === p.id ? { ...row, on: !row.on } : row))
                  )
                }
              />
            </div>
          ))}
        </div>

        <div className="rounded-lg border border-red-500/30 bg-[var(--m3-surf1)] p-[18px]">
          <p className="text-sm font-medium text-red-400">Leave the organizer program</p>
          <p className="my-1.5 text-xs leading-relaxed text-[var(--m3-onv)]">
            Your venues stay listed but you lose publishing access. Admin approval is required to
            rejoin.
          </p>
          <button
            onClick={() => setRemovalRequested(true)}
            disabled={removalRequested}
            className="mt-2 rounded-full px-4 py-2 text-[13px] font-semibold text-white disabled:opacity-60"
            style={{ background: removalRequested ? "var(--m3-outline)" : "#dc2626" }}
          >
            {removalRequested ? "Request sent" : "Request removal"}
          </button>
        </div>

        <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
          <FieldLabel className="mb-3.5">Account</FieldLabel>
          {accountRows.map((row) => (
            <div
              key={row.field}
              className="flex items-center justify-between gap-3 border-b border-[var(--m3-outlinev)] py-2.5 last:border-b-0"
            >
              <div className="min-w-0">
                <p className="text-xs text-[var(--m3-onv)]">{row.label}</p>
                <p className="mt-0.5 truncate font-mono text-[13px] text-[var(--m3-on)]">
                  {row.value}
                </p>
              </div>
              <button
                onClick={() => startChangeField(row.field)}
                className="shrink-0 text-xs font-semibold text-[var(--m3-ter)] hover:text-[var(--m3-warn)]"
              >
                Change
              </button>
            </div>
          ))}
        </div>

        <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
          <FieldLabel className="mb-1">Identity verification</FieldLabel>
          <p className="mb-3.5 text-[11px] text-[var(--m3-outline)]">
            Completed during your organizer application. To redo any of these, apply through the
            mobile app.
          </p>
          {VERIFICATION_ROWS.map((v) => (
            <div
              key={v.label}
              className="flex flex-wrap items-center justify-between gap-3 border-b border-[var(--m3-outlinev)] py-2.5 last:border-b-0"
            >
              <div>
                <p className="text-[13px] text-[var(--m3-on)]">{v.label}</p>
                <p className="mt-0.5 text-[11px] text-[var(--m3-outline)]">{v.detail}</p>
              </div>
              <div className="flex shrink-0 items-center gap-2">
                <span className="rounded-full border border-emerald-500/30 bg-emerald-500/10 px-2.5 py-0.5 font-mono text-[10px] font-bold tracking-wider text-emerald-400">
                  VERIFIED
                </span>
                <span className="rounded-full border border-[var(--m3-outlinev)] px-2.5 py-0.5 font-mono text-[10px] tracking-wider text-[var(--m3-outline)]">
                  IMMUTABLE
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>

      <Modal
        open={!!changeField}
        onClose={cancelChangeField}
        title={changeStage === "edit" ? `Change ${fieldLabel}` : "Enter verification code"}
        size="sm"
        footer={
          <>
            <Button variant="ghost" onClick={cancelChangeField}>
              Cancel
            </Button>
            <Button onClick={changeStage === "edit" ? submitNewValue : submitOtp}>
              {changeStage === "edit" ? "Send code" : "Confirm"}
            </Button>
          </>
        }
      >
        {changeStage === "edit" ? (
          <div>
            <FieldLabel className="mb-1.5">New {fieldLabel}</FieldLabel>
            <SlimInput
              mono
              autoFocus
              value={changeValue}
              onChange={(e) => setChangeValue(e.target.value)}
              placeholder={placeholder}
              className="w-full"
            />
          </div>
        ) : (
          <div>
            <p className="mb-3 text-xs leading-relaxed text-[var(--m3-onv)]">
              We sent a code to {changeValue}. Enter it to confirm the change.
            </p>
            <SlimInput
              mono
              autoFocus
              inputMode="numeric"
              value={changeOtp}
              onChange={(e) => setChangeOtp(e.target.value)}
              placeholder="Code"
              className="w-full"
            />
          </div>
        )}
        {changeError && <p className="mt-3 text-xs text-red-400">{changeError}</p>}
      </Modal>
    </>
  );
}
