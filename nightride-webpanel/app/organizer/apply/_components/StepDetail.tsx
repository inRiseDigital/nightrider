"use client";

import { useState } from "react";
import { AccentButton } from "@/components/organizer/ui/AccentButton";
import { ErrorNote } from "@/components/organizer/ui/AuthCard";
import { RequiresAppLabel, StepThumb } from "@/components/organizer/ui/StepMedia";
import { TextField } from "@/components/organizer/ui/TextField";
import { useApplicationActions, useApplicationState } from "@/lib/organizer/store";
import type { StepView, VenueAddressDraft, VideoScript } from "@/lib/organizer/types";
import { VenueLocationPicker } from "./VenueLocationPicker";

/**
 * The body of an opened step — shared by the checklist (inline) and timeline
 * (panel below the rail) layouts. Behaviour is dispatched on `step.kind`:
 * 'address' is a typed form, 'upload' is a real Storage upload (video only),
 * 'app' is informational — nic, selfie, and gps are captured and uploaded by
 * the Night Ride mobile app, which this webpanel does not touch.
 */
export function StepDetail({ step }: { step: StepView }) {
  const { busy, error, application, uploadProgress } = useApplicationState();
  const { submitVenueAddress, uploadVideo } = useApplicationActions();

  if (step.kind === "app") {
    return <AppStepPanel step={step} />;
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

  // kind === "upload": the walkthrough video, the one step still uploaded here
  return (
    <UploadPanel
      step={step}
      busy={busy}
      error={error}
      progress={uploadProgress[step.id] ?? 0}
      onUploadVideo={(file) => void uploadVideo(file)}
    />
  );
}

/**
 * nic / selfie / gps. Read-only: the applicant does the work in the app and
 * this panel reflects whatever the app wrote — the advisory `uploaded` flag
 * for nic/selfie (which derive.ts turns into 'submitted'), or an admin's own
 * verdict once they have looked.
 */
function AppStepPanel({ step }: { step: StepView }) {
  // Only gps is ever locked, and only until its venue address is accepted.
  const locked = step.status === "pending";
  const settled = step.status === "accepted" || step.awaitingReview;

  return (
    <div className="flex flex-col items-start gap-3">
      <p className="text-[13px] text-nr-text-secondary">
        {locked ? "Locked until an admin accepts your venue address." : step.detail}
      </p>
      {step.note && <AdminNote note={step.note} />}
      {!locked && <RequiresAppLabel />}
      {step.awaitingReview && (
        <p className="text-xs" style={{ color: "var(--ter)" }}>
          Captured in the app — wait for review.
        </p>
      )}
      {step.status === "accepted" && (
        <p className="text-xs" style={{ color: "var(--suc)" }}>Accepted.</p>
      )}
      {/* The tile stands in for media that has not arrived yet, so it goes
          once the applicant's own claim (or an admin) says it has. */}
      {step.thumbLabel && !settled && <StepThumb label={step.thumbLabel} />}
    </div>
  );
}

/**
 * The walkthrough script an admin wrote for this venue. Read-only here — the
 * applicant records against it, they do not edit it.
 */
function ScriptCard({ script }: { script: VideoScript }) {
  return (
    <div className="w-full rounded-xl border border-nr-border bg-nr-surface p-3">
      <div className="mb-2 flex flex-wrap items-center gap-2">
        <p className="text-[11px] font-semibold uppercase tracking-wide text-nr-text-secondary">
          Your walkthrough script
        </p>
        {script.revision > 0 && (
          <span
            className="rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide"
            style={{ background: "var(--warnc)", color: "var(--onwarnc)" }}
          >
            Revised
          </span>
        )}
      </div>
      {script.format === "list" ? (
        <ol className="ml-4 flex list-decimal flex-col gap-1.5 text-[13px] text-nr-text-secondary">
          {script.lines.map((line, i) => (
            <li key={i}>{line}</li>
          ))}
        </ol>
      ) : (
        <div className="flex flex-col gap-2 text-[13px] text-nr-text-secondary">
          {script.lines.map((line, i) => (
            <p key={i}>{line}</p>
          ))}
        </div>
      )}
    </div>
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
    <div className="flex flex-col gap-1">
      <p className="text-xs text-nr-text-hint">
        {draft.address}, {draft.city} {draft.countryCode}
      </p>
      {draft.geo && (
        <p className="font-mono text-xs text-nr-text-hint">
          Pinned: {draft.geo.latitude.toFixed(5)}, {draft.geo.longitude.toFixed(5)}
        </p>
      )}
    </div>
  );
}

type Geo = VenueAddressDraft["geo"];

/** Exact compare is right here: both sides come from the same picker/parse path. */
function sameGeo(a: Geo, b: Geo): boolean {
  if (!a || !b) return a === b;
  return a.latitude === b.latitude && a.longitude === b.longitude;
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
  const [geo, setGeo] = useState<VenueAddressDraft["geo"]>(draft?.geo ?? null);

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
          // A browser pin is advisory — it can't run geolocator's mocked-
          // location check the way the mobile `gps` step does (see the StepId
          // doc comment in lib/organizer/types.ts). It is still the applicant's
          // own claim about where the venue is, which is what an admin needs to
          // review; the mobile fix is what verifies it later.
          geo,
          // `placeId` only means anything alongside the geo it was resolved
          // for. Nothing here resolves places, so a moved pin invalidates an
          // id the mobile app wrote; an untouched pin keeps it.
          placeId: sameGeo(geo, draft?.geo ?? null) ? draft?.placeId ?? "" : "",
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
      <VenueLocationPicker geo={geo} onChange={setGeo} disabled={busy} />
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
  onChange,
}: {
  label: string;
  accept: string;
  onChange: (file: File | null) => void;
}) {
  return (
    <label className="flex flex-col gap-1 text-xs text-nr-text-secondary">
      {label}
      <input
        type="file"
        accept={accept}
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
  onUploadVideo,
}: {
  step: StepView;
  busy: boolean;
  error: string;
  progress: number;
  onUploadVideo: (file: File) => void;
}) {
  const [video, setVideo] = useState<File | null>(null);

  // The step is unlocked in every sense except the one that matters: the
  // applicant has finished the other four and there is no script to record
  // against yet. Saying so beats leaving them at a locked step.
  if (step.awaitingScript) {
    return (
      <div className="flex flex-col items-start gap-2">
        <p className="text-[13px] text-nr-text-secondary">
          That&apos;s everything we needed from you for now. An admin is writing the walkthrough script for
          your venue — it appears here, and this step unlocks the moment it does.
        </p>
        {step.note && <AdminNote note={step.note} />}
      </div>
    );
  }

  if (step.awaitingReview) {
    return (
      <div className="flex flex-col items-start gap-2">
        <p className="text-[13px] text-nr-text-secondary">{step.detail}</p>
        <p className="text-xs" style={{ color: "var(--ter)" }}>This step is already submitted — wait for review.</p>
        {step.script && <ScriptCard script={step.script} />}
        {step.note && <AdminNote note={step.note} />}
      </div>
    );
  }

  if (!step.canAct) {
    return (
      <div className="flex flex-col items-start gap-2">
        <p className="text-[13px] text-nr-text-secondary">{step.detail}</p>
        {step.status === "accepted" && <p className="text-xs" style={{ color: "var(--suc)" }}>Accepted.</p>}
        {step.script && <ScriptCard script={step.script} />}
      </div>
    );
  }

  return (
    <form
      className="flex w-full flex-col gap-3"
      onSubmit={(e) => {
        e.preventDefault();
        if (video) onUploadVideo(video);
      }}
    >
      <p className="text-[13px] text-nr-text-secondary">{step.detail}</p>
      {step.note && <AdminNote note={step.note} />}
      {step.script && <ScriptCard script={step.script} />}

      <FilePicker label="Walkthrough video" accept="video/mp4" onChange={setVideo} />

      <p className="text-[11px] text-nr-text-hint">MP4, up to 60 seconds, 30 MB max.</p>

      {error && <ErrorNote>{error}</ErrorNote>}

      {busy && progress > 0 && <ProgressBar progress={progress} />}

      <AccentButton type="submit" size="sm" loading={busy} disabled={!video}>
        Upload
      </AccentButton>
    </form>
  );
}
