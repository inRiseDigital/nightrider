"use client";

import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { onAuthStateChanged, signOut as firebaseSignOut, type User } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { getDb, getFirebaseAuth, isFirebaseConfigured } from "@/lib/firebase";
import { initialsOf } from "./format";
import type { OrganizerProfile } from "./types";

export type OrganizerAuthStatus =
  | "loading" // the auth listener has not reported yet
  | "unconfigured" // isFirebaseConfigured() === false
  | "signed-out"
  | "pending" // organizerStatus 'none' | 'pending'
  | "rejected" // organizerStatus 'rejected' | 'revoked'
  | "approved"; // organizerStatus === 'approved' — the only state that renders the dashboard

export interface OrganizerAuthState {
  status: OrganizerAuthStatus;
  uid: string | null;
  user: User | null;
  organizer: OrganizerProfile; // replaces MOCK_ORGANIZER
  rejectionReason: string; // for the 'rejected' card, "" otherwise
  refreshOrganizer: () => Promise<void>; // after Settings changes email or phone
  signOut: () => Promise<void>;
}

const EMPTY_ORGANIZER: OrganizerProfile = { name: "", initials: "", email: "", phone: "" };

const OrganizerAuthContext = createContext<OrganizerAuthState | null>(null);

function organizerFrom(data: Record<string, unknown> | undefined, user: User): OrganizerProfile {
  const displayName = typeof data?.displayName === "string" ? data.displayName : "";
  const email = typeof data?.email === "string" ? data.email : user.email || "";
  const phone = typeof data?.phone === "string" ? data.phone : "";
  const name = displayName || email;
  return { name, initials: initialsOf(name), email, phone };
}

function statusFrom(organizerStatus: unknown): OrganizerAuthStatus {
  switch (organizerStatus) {
    case "approved":
      return "approved";
    case "rejected":
    case "revoked":
      return "rejected";
    case "none":
    case "pending":
    default:
      return "pending";
  }
}

export function OrganizerAuthProvider({ children }: { children: ReactNode }) {
  const [status, setStatus] = useState<OrganizerAuthStatus>(
    isFirebaseConfigured() ? "loading" : "unconfigured"
  );
  const [uid, setUid] = useState<string | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [organizer, setOrganizer] = useState<OrganizerProfile>(EMPTY_ORGANIZER);
  const [rejectionReason, setRejectionReason] = useState("");

  async function loadOrganizer(nextUser: User) {
    const snap = await getDoc(doc(getDb(), "users", nextUser.uid));
    const data = snap.exists() ? (snap.data() as Record<string, unknown>) : undefined;
    setOrganizer(organizerFrom(data, nextUser));
    const nextStatus = statusFrom(data?.organizerStatus);

    if (nextStatus === "rejected") {
      try {
        const reviewSnap = await getDoc(doc(getDb(), "users", nextUser.uid, "private", "organizerReview"));
        const reviewData = reviewSnap.exists() ? (reviewSnap.data() as Record<string, unknown>) : undefined;
        setRejectionReason(typeof reviewData?.rejectionReason === "string" ? reviewData.rejectionReason : "");
      } catch {
        setRejectionReason("");
      }
    } else {
      setRejectionReason("");
    }

    setStatus(nextStatus);
  }

  useEffect(() => {
    // Config is read once from env at module load and can't change at
    // runtime, so the lazy initial state above already covers this case —
    // nothing to subscribe to.
    if (!isFirebaseConfigured()) return;

    const auth = getFirebaseAuth();
    return onAuthStateChanged(auth, async (nextUser) => {
      if (!nextUser) {
        setUid(null);
        setUser(null);
        setOrganizer(EMPTY_ORGANIZER);
        setRejectionReason("");
        setStatus("signed-out");
        return;
      }
      setUid(nextUser.uid);
      setUser(nextUser);
      try {
        await loadOrganizer(nextUser);
      } catch {
        setStatus("pending");
      }
    });
  }, []);

  const value: OrganizerAuthState = {
    status,
    uid,
    user,
    organizer,
    rejectionReason,
    refreshOrganizer: async () => {
      const currentUser = getFirebaseAuth().currentUser;
      if (currentUser) await loadOrganizer(currentUser);
    },
    signOut: () => firebaseSignOut(getFirebaseAuth()),
  };

  return <OrganizerAuthContext.Provider value={value}>{children}</OrganizerAuthContext.Provider>;
}

export function useOrganizerAuth(): OrganizerAuthState {
  const ctx = useContext(OrganizerAuthContext);
  if (!ctx) throw new Error("useOrganizerAuth must be used within OrganizerAuthProvider");
  return ctx;
}
