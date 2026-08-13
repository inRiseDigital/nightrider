import { getApp, getApps, initializeApp, type FirebaseApp, type FirebaseOptions } from "firebase/app";
import { getAuth, type Auth } from "firebase/auth";
import { getFirestore, type Firestore } from "firebase/firestore";
import { getStorage, type FirebaseStorage } from "firebase/storage";

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

export function getFirebaseAuth(): Auth {
  return getAuth(getFirebaseApp());
}

export function getDb(): Firestore {
  return getFirestore(getFirebaseApp());
}

/**
 * Avatar uploads and KYC review both read from Cloud Storage. Reads of
 * `kyc/**` succeed for an admin because storage.rules cross-checks
 * `users/{uid}.isAdmin`; deletes never do, from any client — those go through
 * `/api/admin/kyc`, which holds the Admin SDK.
 */
export function getBucket(): FirebaseStorage {
  return getStorage(getFirebaseApp());
}
