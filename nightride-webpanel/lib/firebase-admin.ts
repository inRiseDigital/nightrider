import { cert, getApp, getApps, initializeApp, type App } from "firebase-admin/app";
import { getAuth, type Auth } from "firebase-admin/auth";
import { getFirestore, type Firestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

/**
 * Server-only Firebase Admin SDK.
 *
 * Four operations in this product cannot be client writes, and all four live
 * behind route handlers that import this file:
 *
 *   - setting `users/{uid}.isAdmin` (rules pin it against every client)
 *   - deleting KYC objects (storage.rules denies delete to every client)
 *   - deleting an account (a client delete would strand immutable KYC objects)
 *   - the one-off document rewrite of pre-schema data
 *
 * Everything else an admin does is an ordinary client write authorised by
 * `isAdmin`, which is why there is no Cloud Functions deployment anywhere in
 * this project.
 */

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID ?? process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? "";

/**
 * True when the process is pointed at the local emulator suite. The Admin SDK
 * picks the emulators up from these env vars on its own; we read them only to
 * decide whether service-account credentials are required.
 */
export function isEmulator(): boolean {
  return Boolean(process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST);
}

function credentialFromEnv() {
  // A JSON blob in the environment is how this deploys; a file path is how it
  // runs locally against the real project (firebase_service_account.json is
  // gitignored and must stay that way).
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) return undefined;
  const parsed = JSON.parse(raw) as { project_id: string; client_email: string; private_key: string };
  return cert({
    projectId: parsed.project_id,
    clientEmail: parsed.client_email,
    // Newlines survive most secret stores only when escaped.
    privateKey: parsed.private_key.replace(/\\n/g, "\n"),
  });
}

export function getAdminApp(): App {
  if (getApps().length) return getApp();

  if (!PROJECT_ID) {
    throw new Error("FIREBASE_PROJECT_ID is not set — the Admin SDK cannot pick a project.");
  }

  const credential = credentialFromEnv();
  if (!credential && !isEmulator()) {
    throw new Error(
      "No Admin SDK credentials. Set FIREBASE_SERVICE_ACCOUNT_JSON, or point the process at the emulators."
    );
  }

  return initializeApp({
    projectId: PROJECT_ID,
    // Emulators accept application-default credentials, so omitting the
    // credential locally is deliberate rather than an oversight.
    ...(credential ? { credential } : {}),
    storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET ?? `${PROJECT_ID}.appspot.com`,
  });
}

export function adminAuth(): Auth {
  return getAuth(getAdminApp());
}

export function adminDb(): Firestore {
  return getFirestore(getAdminApp());
}

export function adminBucket() {
  return getStorage(getAdminApp()).bucket();
}

export type AdminCaller = { uid: string; email: string | undefined };

/**
 * Verifies the caller's Firebase ID token and confirms `isAdmin` on their user
 * document. `isAdmin` is read from Firestore rather than a custom claim so that
 * there is exactly one place admin-ness is defined — the same field the
 * security rules read.
 *
 * Returns null when the caller is not an authenticated admin. Callers must
 * translate that into a 401/403 themselves; this function never throws for an
 * ordinary auth failure, only for a misconfigured server.
 */
export async function requireAdmin(request: Request): Promise<AdminCaller | null> {
  const header = request.headers.get("authorization") ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7).trim() : "";
  if (!token) return null;

  let decoded;
  try {
    decoded = await adminAuth().verifyIdToken(token, true);
  } catch {
    return null;
  }

  const snap = await adminDb().doc(`users/${decoded.uid}`).get();
  if (!snap.exists || snap.get("isAdmin") !== true) return null;

  return { uid: decoded.uid, email: decoded.email };
}
