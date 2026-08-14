"use client";

import { useState } from "react";
import { AccentButton } from "@/components/organizer/ui/AccentButton";
import { ErrorNote } from "@/components/organizer/ui/AuthCard";
import { RequiresAppPill, StepThumb } from "@/components/organizer/ui/StepMedia";
import { TextField } from "@/components/organizer/ui/TextField";
import { useApplicationActions, useApplicationState } from "@/lib/organizer/store";
import type { StepView, VenueAddressDraft } from "@/lib/organizer/types";

/**
 * The body of an opened step — shared by the checklist (inline) and timeline
 * (panel below the rail) layouts. Behaviour is dispatched on `step.kind`:
 * 'address' is a typed form, 'upload' is a real Storage upload, 'app' (gps
 * only) is informational — that capture only happens in the Night Ride mobile
 * app, which this webpanel does not touch.
 */
export function StepDetail({ step }: { step: StepView }) {
  const { busy, error, application, uploadProgress } = useApplicationState();
  const { submitVenueAddress, uploadNic, uploadSelfie, uploadVideo } = useApplicationActions();

  if (step.kind === "app") {
    return (
      <div className="flex flex-col items-start gap-3">
        <p className="text-[13px] text-nr-text-secondary">
          {step.status === "pending"
            ? "Locked until an admin accepts your venue address."
            : step.detail}
        </p>
        {step.status !== "pending" && <RequiresAppPill />}
        {step.thumbLabel && <StepThumb label={step.thumbLabel} />}
        {step.note && <AdminNote note={step.note} />}
      </div>
    );
  }

  if (step.kind === "address") {
    return (
      <VenueAddressPanel
        step={step}
        draft={application.steps.venueAddress}
        busy={busy}
        error={error}
        onSubmit={(draft) => void submitVenueAddress(draft)}
      />
    );
  }

  // kind === "upload": nic / selfie / video
  return (
    <UploadPanel
      step={step}
      busy={busy}
      error={error}
      progress={uploadProgress[step.id] ?? 0}
      onUploadNic={(front, back) => void uploadNic(front, back)}
      onUploadSelfie={(file) => void uploadSelfie(file)}
      onUploadVideo={(file) => void uploadVideo(file)}
    />
  );
}

function AdminNote({ note }: { note: string }) {
  return (
    <p
      className="rounded-lg border px-3 py-2 text-xs"
      style={{ borderColor: "var(--warn)", background: "var(--warnc)", color: "var(--onwarnc)" }}
    >
      {note}
    </p>
  );
}

function AddressSummary({ draft }: { draft: VenueAddressDraft | null }) {
  if (!draft || !draft.address) return null;
  return (
    <p className="text-xs text-nr-text-hint">
      {draft.address}, {draft.city} {draft.countryCode}
    </p>
  );
}

function VenueAddressPanel({
  step,
  draft,
  busy,
  error,
  onSubmit,
}: {
  step: StepView;
  draft: VenueAddressDraft | null;
  busy: boolean;
  error: string;
  onSubmit: (draft: VenueAddressDraft) => void;
}) {
  const [address, setAddress] = useState(draft?.address ?? "");
  const [city, setCity] = useState(draft?.city ?? "");
  const [countryCode, setCountryCode] = useState(draft?.countryCode ?? "");

  if (step.awaitingReview) {
    return (
      <div className="flex flex-col items-start gap-2">
        <p className="text-[13px] text-nr-text-secondary">{step.detail}</p>
        <p className="text-xs" style={{ color: "var(--ter)" }}>Submitted — waiting on an admin to confirm this address.</p>
        <AddressSummary draft={draft} />
      </div>
    );
  }

  if (!step.canAct) {
    return (
      <div className="flex flex-col items-start gap-2">
        <p className="text-[13px] text-nr-text-secondary">{step.detail}</p>
        <AddressSummary draft={draft} />
        {step.status === "accepted" && <p className="text-xs" style={{ color: "var(--suc)" }}>Accepted.</p>}
      </div>
    );
  }

  return (
    <form
      className="flex w-full flex-col gap-3"
      onSubmit={(e) => {
        e.preventDefault();
        onSubmit({
          address: address.trim(),
          city: city.trim(),
          countryCode: countryCode.trim().toUpperCase(),
          // Lat/long is captured on the Night Ride mobile app, which can use
          // geolocator's mocked-location check (see StepId 'gps' doc comment
          // in lib/organizer/types.ts) — this webpanel can't verify a manually
          // typed pin, so it no longer collects one. Preserve whatever the
          // mobile app already wrote rather than clobbering it back to null
          // when the applicant only edits the street address here.
          geo: draft?.geo ?? null,
          placeId: draft?.placeId ?? "",
        });
      }}
    >
      <p className="text-[13px] text-nr-text-secondary">{step.detail}</p>
      {step.note && <AdminNote note={step.note} />}

      <TextField id="venue-address" label="Street address" value={address} onChange={(e) => setAddress(e.target.value)} />
      <TextField id="venue-city" label="City" value={city} onChange={(e) => setCity(e.target.value)} />
      <TextField
        id="venue-country"
        label="Country code (ISO-2)"
        mono
        maxLength={2}
        value={countryCode}
        onChange={(e) => setCountryCode(e.target.value)}
      />
      {error && <ErrorNote>{error}</ErrorNote>}

      <AccentButton type="submit" size="sm" loading={busy}>
        Save address
      </AccentButton>
    </form>
  );
}

function ProgressBar({ progress }: { progress: number }) {
  return (
    <div className="h-1.5 w-full overflow-hidden rounded-full bg-nr-border">
      <div
        className="h-full bg-[var(--org-accent)] transition-[width]"
        style={{ width: `${Math.round(progress * 100)}%` }}
      />
    </div>
  );
}

function FilePicker({
  label,
  accept,
  capture,
  onChange,
}: {
  label: string;
  accept: string;
  capture?: boolean;
  onChange: (file: File | null) => void;
}) {
  return (
    <label className="flex flex-col gap-1 text-xs text-nr-text-secondary">
      {label}
      <input
        type="file"
        accept={accept}
        {...(capture ? { capture: "environment" } : {})}
        onChange={(e) => onChange(e.target.files?.[0] ?? null)}
        className="rounded-lg border border-nr-border bg-nr-surface-raised px-3 py-2 text-xs text-nr-text-primary file:mr-3 file:rounded file:border-0 file:bg-[var(--org-accent)] file:px-2.5 file:py-1 file:text-nr-bg"
      />
    </label>
  );
}

function UploadPanel({
  step,
  busy,
  error,
  progress,
  onUploadNic,
  onUploadSelfie,
  onUploadVideo,
}: {
  step: StepView;
  busy: boolean;
  error: string;
  progress: number;
  onUploadNic: (front: File, back: File) => void;
  onUploadSelfie: (file: File) => void;
  onUploadVideo: (file: File) => void;
}) {
  const isNic = step.id === "nic";
  const isVideo = step.id === "video";
  const accept = isVideo ? "video/mp4" : "image/jpeg,image/png";

  const [front, setFront] = useState<File | null>(null);
  const [back, setBack] = useState<File | null>(null);
  const [single, setSingle] = useState<File | null>(null);

  if (step.awaitingReview) {
    return (
      <div className="flex flex-col items-start gap-2">
        <p className="text-[13px] text-nr-text-secondary">{step.detail}</p>
        <p className="text-xs" style={{ color: "var(--ter)" }}>This step is already submitted — wait for review.</p>
        {step.note && <AdminNote note={step.note} />}
      </div>
    );
  }

  if (!step.canAct) {
    return (
      <div className="flex flex-col items-start gap-2">
        <p className="text-[13px] text-nr-text-secondary">{step.detail}</p>
        {step.status === "accepted" && <p className="text-xs" style={{ color: "var(--suc)" }}>Accepted.</p>}
      </div>
    );
  }

  const ready = isNic ? Boolean(front && back) : Boolean(single);

  return (
    <form
      className="flex w-full flex-col gap-3"
      onSubmit={(e) => {
        e.preventDefault();
        if (isNic) {
          if (front && back) onUploadNic(front, back);
        } else if (isVideo) {
          if (single) onUploadVideo(single);
        } else if (single) {
          onUploadSelfie(single);
        }
      }}
    >
      <p className="text-[13px] text-nr-text-secondary">{step.detail}</p>
      {step.note && <AdminNote note={step.note} />}

      {isNic ? (
        <>
          <FilePicker label="Front of ID" accept={accept} onChange={setFront} />
          <FilePicker label="Back of ID" accept={accept} onChange={setBack} />
        </>
      ) : (
        <FilePicker
          label={isVideo ? "Walkthrough video" : "Selfie"}
          accept={accept}
          capture={!isNic}
          onChange={setSingle}
        />
      )}

      <p className="text-[11px] text-nr-text-hint">
        {isVideo ? "MP4, up to 60 seconds, 30 MB max." : "JPEG or PNG, 6 MB max."}
      </p>

      {error && <ErrorNote>{error}</ErrorNote>}

      {busy && progress > 0 && <ProgressBar progress={progress} />}

      <AccentButton type="submit" size="sm" loading={busy} disabled={!ready}>
        Upload
      </AccentButton>
    </form>
  );
}
