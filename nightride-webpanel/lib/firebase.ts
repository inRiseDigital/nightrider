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

/**
 * Local Firebase emulator suite (see Nightride/scripts/emulators.sh). Off by
 * default — set NEXT_PUBLIC_USE_FIREBASE_EMULATOR=true in .env.local to point
 * this webpanel at localhost instead of the real `nightride-a9173` project.
 * Guarded by a module-scoped flag because connect*Emulator() throws if called
 * more than once per SDK instance, and Next's client-side fast refresh can
 * re-run this module.
 */
const USE_EMULATOR = process.env.NEXT_PUBLIC_USE_FIREBASE_EMULATOR === "true";
let emulatorsConnected = false;

function connectEmulatorsOnce(auth: Auth, db: Firestore, storage: FirebaseStorage) {
  if (!USE_EMULATOR || emulatorsConnected) return;
  emulatorsConnected = true;
  try {
    connectAuthEmulator(auth, "http://127.0.0.1:9099", { disableWarnings: true });
    connectFirestoreEmulator(db, "127.0.0.1", 8080);
    connectStorageEmulator(storage, "127.0.0.1", 9199);
  } catch {
    // Already connected in this SDK instance (e.g. fast-refresh re-run) — ignore.
  }
}

export function getFirebaseAuth(): Auth {
  const app = getFirebaseApp();
  const auth = getAuth(app);
  connectEmulatorsOnce(auth, getFirestore(app), getStorage(app));
  return auth;
}

export function getDb(): Firestore {
  const app = getFirebaseApp();
  const db = getFirestore(app);
  connectEmulatorsOnce(getAuth(app), db, getStorage(app));
  return db;
}

/**
 * Avatar uploads and KYC review both read from Cloud Storage. Reads of
 * `kyc/**` succeed for an admin because storage.rules cross-checks
 * `users/{uid}.isAdmin`; deletes never do, from any client — those go through
 * `/api/admin/kyc`, which holds the Admin SDK.
 */
export function getBucket(): FirebaseStorage {
  const app = getFirebaseApp();
  const storage = getStorage(app);
  connectEmulatorsOnce(getAuth(app), getFirestore(app), storage);
  return storage;
}
