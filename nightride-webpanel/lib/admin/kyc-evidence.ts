import { getDownloadURL, ref as storageRef } from "firebase/storage";
import { getBucket } from "@/lib/firebase";
import { haversineMeters } from "./geo";
import type { GpsObservation, StepId } from "./schema";

function kycPath(uid: string, stepId: StepId, attempt: number, file: string): string {
  return `kyc/${uid}/${stepId}/${attempt}/${file}`;
}

/** null means "not uploaded yet" (or not readable) rather than an error — storage.rules 404s cleanly. */
async function tryGetDownloadURL(path: string): Promise<string | null> {
  try {
    return await getDownloadURL(storageRef(getBucket(), path));
  } catch {
    return null;
  }
}

export async function getNicEvidence(uid: string, attempt: number): Promise<{ front: string | null; back: string | null }> {
  const [front, back] = await Promise.all([
    tryGetDownloadURL(kycPath(uid, "nic", attempt, "front.jpg")),
    tryGetDownloadURL(kycPath(uid, "nic", attempt, "back.jpg")),
  ]);
  return { front, back };
}

export async function getSelfieEvidence(uid: string, attempt: number): Promise<{ capture: string | null }> {
  return { capture: await tryGetDownloadURL(kycPath(uid, "selfie", attempt, "capture.jpg")) };
}

export async function getVideoEvidence(uid: string, attempt: number): Promise<{ walkthrough: string | null; poster: string | null }> {
  const [walkthrough, poster] = await Promise.all([
    tryGetDownloadURL(kycPath(uid, "video", attempt, "walkthrough.mp4")),
    tryGetDownloadURL(kycPath(uid, "video", attempt, "poster.jpg")),
  ]);
  return { walkthrough, poster };
}

export interface GpsCheck {
  hasObservation: boolean;
  distanceM: number | null;
  accuracyM: number | null;
  mocked: boolean | null;
  capturedAt: unknown | null;
  /** null when there's no accepted venue yet to measure against. */
  withinThreshold: boolean | null;
}

const GPS_DISTANCE_THRESHOLD_M = 250;

/**
 * Real GPS check computed at render time, per docs/FIRESTORE_SCHEMA.md: takes
 * the latest observation for the current review attempt (falling back to the
 * latest observation overall — gps.attempt is advisory, not Storage-enforced),
 * and measures it against the accepted venue's geo by haversine. Never
 * auto-decides anything; the admin still clicks Verify/Ask again.
 */
export function computeGpsCheck(attempts: GpsObservation[], attempt: number, venueGeo: { latitude: number; longitude: number } | null): GpsCheck {
  const forAttempt = attempts.filter((a) => a.attempt === attempt);
  const pool = forAttempt.length > 0 ? forAttempt : attempts;
  const latest = pool.length > 0 ? pool[pool.length - 1] : null;

  if (!latest) {
    return { hasObservation: false, distanceM: null, accuracyM: null, mocked: null, capturedAt: null, withinThreshold: null };
  }

  const distanceM = venueGeo ? haversineMeters(latest.point, venueGeo) : null;
  return {
    hasObservation: true,
    distanceM,
    accuracyM: latest.accuracyM,
    mocked: latest.mocked,
    capturedAt: latest.capturedAt,
    withinThreshold: distanceM === null ? null : distanceM <= GPS_DISTANCE_THRESHOLD_M + latest.accuracyM,
  };
}
