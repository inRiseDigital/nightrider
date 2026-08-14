import { getApp, getApps, initializeApp, type FirebaseApp, type FirebaseOptions } from "firebase/app";
import { connectAuthEmulator, getAuth, type Auth } from "firebase/auth";
import { connectFirestoreEmulator, getFirestore, type Firestore } from "firebase/firestore";
import { connectStorageEmulator, getStorage, type FirebaseStorage } from "firebase/storage";

/**
 * Firebase web config for the `nightride-a9173` project — the same project the
 * Flutter app uses (see Nightride/lib/firebase_options.dart). These values are
 * public by design (they ship to every browser); access is controlled by
 * firestore.rules, not by keeping them secret.
 */
const firebaseConfig: FirebaseOptions = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY ?? "",
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN ?? "",
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? "",
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET ?? "",
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID ?? "",
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID ?? "",
};

export function isFirebaseConfigured() {
  return Boolean(firebaseConfig.apiKey && firebaseConfig.projectId && firebaseConfig.appId);
}

/**
 * Mirrors the Flutter app's `--dart-define=USE_FIREBASE_EMULATOR=true` (see
 * root LOCAL_DEV.md) — same `nightride-a9173` project id either way, only the
 * transport changes. `NEXT_PUBLIC_` so it's readable client-side; set it in
 * `.env.local`, not `.env.example`, since it should never be on by default.
 */
function isUsingEmulator() {
  return process.env.NEXT_PUBLIC_USE_FIREBASE_EMULATOR === "true";
}

/**
 * Initialised lazily rather than at module scope so that importing anything
 * from this file stays safe during SSR and static prerendering — `/organizer`
 * pages are prerendered at build time, where no Firebase config is needed.
 */
export function getFirebaseApp(): FirebaseApp {
  if (!isFirebaseConfigured()) {
    throw new Error(
      "Firebase is not configured. Copy .env.example to .env.local and fill in the NEXT_PUBLIC_FIREBASE_* values."
    );
  }
  return getApps().length ? getApp() : initializeApp(firebaseConfig);
}

// connectXEmulator() throws if called twice on the same instance — Next's Fast
// Refresh (and StrictMode double-invocation) can re-run these getters, so each
// service tracks whether it's already been pointed at the emulator.
let authEmulatorConnected = false;
let firestoreEmulatorConnected = false;
let storageEmulatorConnected = false;

export function getFirebaseAuth(): Auth {
  const auth = getAuth(getFirebaseApp());
  if (isUsingEmulator() && !authEmulatorConnected) {
    connectAuthEmulator(auth, "http://localhost:9099", { disableWarnings: true });
    authEmulatorConnected = true;
  }
  return auth;
}

export function getDb(): Firestore {
  const db = getFirestore(getFirebaseApp());
  if (isUsingEmulator() && !firestoreEmulatorConnected) {
    connectFirestoreEmulator(db, "localhost", 8080);
    firestoreEmulatorConnected = true;
  }
  return db;
}

/**
 * Avatar uploads and KYC review both read from Cloud Storage. Reads of
 * `kyc/**` succeed for an admin because storage.rules cross-checks
 * `users/{uid}.isAdmin`; deletes never do, from any client — those go through
 * `/api/admin/kyc`, which holds the Admin SDK.
 */
export function getBucket(): FirebaseStorage {
  const storage = getStorage(getFirebaseApp());
  if (isUsingEmulator() && !storageEmulatorConnected) {
    connectStorageEmulator(storage, "localhost", 9199);
    storageEmulatorConnected = true;
  }
  return storage;
}
