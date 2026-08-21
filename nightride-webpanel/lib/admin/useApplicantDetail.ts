"use client";

import { useCallback, useEffect, useState } from "react";
import {
  acceptSimpleStep,
  acceptVenueAddressStep,
  approveApplication,
  banOrganizerAccount,
  getAdminReviewDoc,
  getUserRecord,
  getVenueDoc,
  listTransferCandidates,
  listVenuesByOwner,
  pickUpApplication,
  publishVideoScript,
  rejectApplication,
  requestStepInfo,
} from "./firestore";
import { getNicEvidence, getSelfieEvidence, getVideoEvidence, computeGpsCheck, type GpsCheck } from "./kyc-evidence";
import { deriveDisplayStepStatus } from "./schema";
import type { AdminReviewDoc, StepId, UserRecord, Venue } from "./schema";
import { VIDEO_SCRIPT_TEMPLATES } from "@/lib/organizer/constants";
import type { VideoScript } from "@/lib/organizer/types";

export interface StepEvidence {
  nic: { front: string | null; back: string | null };
  selfie: { capture: string | null };
  video: { walkthrough: string | null; poster: string | null };
  gps: GpsCheck;
}

export function useApplicantDetail(uid: string | null) {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [user, setUser] = useState<UserRecord | null>(null);
  const [review, setReview] = useState<AdminReviewDoc | null>(null);
  const [venues, setVenues] = useState<Venue[]>([]);
  const [venueGeo, setVenueGeo] = useState<{ latitude: number; longitude: number } | null>(null);
  const [evidence, setEvidence] = useState<StepEvidence | null>(null);
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState("");

  // UI-only state
  const [openStepId, setOpenStepId] = useState<StepId>("nic");
  const [askAgainOpenFor, setAskAgainOpenFor] = useState<StepId | null>(null);
  const [askAgainDraft, setAskAgainDraft] = useState("");
  const [rejectBoxOpen, setRejectBoxOpen] = useState(false);
  const [rejectDraft, setRejectDraft] = useState("");
  const [moreMenuOpen, setMoreMenuOpen] = useState(false);
  const [photoRevealed, setPhotoRevealed] = useState(false);
  const [scriptEditorOpen, setScriptEditorOpen] = useState(false);
  const [scriptFormat, setScriptFormat] = useState<VideoScript["format"]>("list");
  // One line of the textarea per script entry — the split happens on submit.
  const [scriptDraft, setScriptDraft] = useState("");

  const load = useCallback(async () => {
    if (!uid) return;
    setLoading(true);
    setError(null);
    try {
      const [u, r] = await Promise.all([getUserRecord(uid), getAdminReviewDoc(uid)]);
      if (!u) throw new Error("This user no longer exists.");
      setUser(u);
      setReview(r);

      // "pending" means a human has it — mark that the moment an admin opens
      // an untriaged application, per docs/FIRESTORE_SCHEMA.md.
      if (u.organizerStatus === "none") {
        await pickUpApplication(uid);
        u.organizerStatus = "pending";
      }

      const venueId = r?.steps.venueAddress.venueId ?? null;
      const [ownedVenues, acceptedVenue] = await Promise.all([
        listVenuesByOwner(uid),
        venueId ? getVenueDoc(venueId) : Promise.resolve(null),
      ]);
      setVenues(ownedVenues);
      setVenueGeo(acceptedVenue?.geo ?? ownedVenues[0]?.geo ?? null);

      const attempts = u.organizerApplication?.steps.gps.attempts ?? [];
      const [nic, selfie, video] = await Promise.all([
        getNicEvidence(uid, r?.steps.nic.attempt ?? 0),
        getSelfieEvidence(uid, r?.steps.selfie.attempt ?? 0),
        getVideoEvidence(uid, r?.steps.video.attempt ?? 0),
      ]);
      setEvidence({
        nic,
        selfie,
        video,
        gps: computeGpsCheck(attempts, r?.steps.gps.attempt ?? 0, acceptedVenue?.geo ?? null),
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load this application.");
    } finally {
      setLoading(false);
    }
  }, [uid]);

  useEffect(() => {
    setOpenStepId("nic");
    setAskAgainOpenFor(null);
    setRejectBoxOpen(false);
    setMoreMenuOpen(false);
    setPhotoRevealed(false);
    setScriptEditorOpen(false);
    void load();
  }, [load]);

  async function runAction(fn: () => Promise<void>) {
    setBusy(true);
    setActionError("");
    try {
      await fn();
      await load();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : "That action failed.");
    } finally {
      setBusy(false);
    }
  }

  function verifyStep(stepId: StepId) {
    return runAction(async () => {
      if (stepId === "venueAddress") {
        if (!user || !review) return;
        await acceptVenueAddressStep(user, review);
      } else {
        await acceptSimpleStep(uid as string, stepId);
      }
    });
  }

  function openAskAgain(stepId: StepId) {
    setAskAgainOpenFor(stepId);
    setAskAgainDraft(review?.steps[stepId]?.note ?? "");
  }
  function cancelAskAgain() {
    setAskAgainOpenFor(null);
  }
  function submitAskAgain() {
    const stepId = askAgainOpenFor;
    if (!stepId || !uid || !review) return;
    return runAction(async () => {
      await requestStepInfo(uid, stepId, askAgainDraft.trim(), review.steps[stepId].attempt);
      setAskAgainOpenFor(null);
    });
  }

  /** Seeds the editor from whatever is already published, or from nothing. */
  function openScriptEditor() {
    const existing = review?.steps.video.script ?? null;
    setScriptFormat(existing?.format ?? "list");
    setScriptDraft(existing ? existing.lines.join("\n") : "");
    setScriptEditorOpen(true);
  }
  function closeScriptEditor() {
    setScriptEditorOpen(false);
  }
  /** Replaces the draft wholesale — the admin edits from there. */
  function applyScriptTemplate(templateId: string) {
    const template = VIDEO_SCRIPT_TEMPLATES.find((t) => t.id === templateId);
    if (!template) return;
    setScriptFormat(template.format);
    setScriptDraft(template.lines.join("\n"));
  }
  function submitScript() {
    if (!uid || !review) return;
    return runAction(async () => {
      await publishVideoScript(uid, review, { format: scriptFormat, lines: scriptDraft.split("\n") });
      setScriptEditorOpen(false);
    });
  }

  function approve() {
    if (!uid) return;
    return runAction(() => approveApplication(uid));
  }
  function submitReject() {
    if (!uid || !rejectDraft.trim()) return;
    return runAction(async () => {
      await rejectApplication(uid, rejectDraft.trim());
      setRejectBoxOpen(false);
      setRejectDraft("");
    });
  }
  function ban() {
    if (!uid) return;
    return runAction(() => banOrganizerAccount(uid));
  }

  async function getTransferCandidates() {
    if (!uid) return [];
    return listTransferCandidates(uid);
  }

  return {
    loading,
    error,
    user,
    review,
    venues,
    venueGeo,
    evidence,
    busy,
    actionError,
    openStepId,
    setOpenStepId,
    askAgainOpenFor,
    askAgainDraft,
    setAskAgainDraft,
    openAskAgain,
    cancelAskAgain,
    submitAskAgain,
    rejectBoxOpen,
    setRejectBoxOpen,
    rejectDraft,
    setRejectDraft,
    submitReject,
    moreMenuOpen,
    setMoreMenuOpen,
    photoRevealed,
    setPhotoRevealed,
    scriptEditorOpen,
    scriptFormat,
    setScriptFormat,
    scriptDraft,
    setScriptDraft,
    openScriptEditor,
    closeScriptEditor,
    applyScriptTemplate,
    submitScript,
    verifyStep,
    approve,
    ban,
    getTransferCandidates,
    refresh: load,
  };
}

export type ApplicantDetail = ReturnType<typeof useApplicantDetail>;

export function stepApplicantClaim(user: UserRecord, stepId: StepId): boolean {
  const app = user.organizerApplication;
  if (!app) return false;
  if (stepId === "venueAddress") return app.steps.venueAddress !== null;
  if (stepId === "gps") return app.steps.gps.attempts.length > 0;
  return app.steps[stepId].uploaded;
}

export function displayStatusFor(user: UserRecord, review: AdminReviewDoc, stepId: StepId) {
  return deriveDisplayStepStatus(review.steps[stepId].status, stepApplicantClaim(user, stepId));
}

/**
 * Whether the applicant has finished everything a script is normally written
 * after — mirrors `videoPrerequisitesMet` in lib/organizer/derive.ts, which is
 * what makes the applicant's own video step say "waiting for an admin". This is
 * advice, not a gate: an admin who wants to send a script early still can.
 */
export function videoScriptReady(user: UserRecord, review: AdminReviewDoc): boolean {
  const prerequisites: StepId[] = ["nic", "selfie", "venueAddress", "gps"];
  return prerequisites.every(
    (id) => stepApplicantClaim(user, id) || review.steps[id].status === "accepted",
  );
}
