"use client";

import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { onAuthStateChanged, signOut as firebaseSignOut, type User } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { getDb, getFirebaseAuth } from "@/lib/firebase";

type AdminAuthStatus = "loading" | "signed-out" | "not-admin" | "admin";

interface AdminAuthState {
  status: AdminAuthStatus;
  user: User | null;
  displayName: string | null;
  signOut: () => Promise<void>;
}

const AdminAuthContext = createContext<AdminAuthState | null>(null);

export function AdminAuthProvider({ children }: { children: ReactNode }) {
  const [status, setStatus] = useState<AdminAuthStatus>("loading");
  const [user, setUser] = useState<User | null>(null);
  const [displayName, setDisplayName] = useState<string | null>(null);

  useEffect(() => {
    const auth = getFirebaseAuth();
    return onAuthStateChanged(auth, async (nextUser) => {
      if (!nextUser) {
        setUser(null);
        setDisplayName(null);
        setStatus("signed-out");
        return;
      }
      setUser(nextUser);
      try {
        const snap = await getDoc(doc(getDb(), "users", nextUser.uid));
        const isAdmin = snap.exists() && snap.data().isAdmin === true;
        setDisplayName((snap.exists() && (snap.data().displayName as string)) || nextUser.email || null);
        setStatus(isAdmin ? "admin" : "not-admin");
      } catch {
        setStatus("not-admin");
      }
    });
  }, []);

  const value: AdminAuthState = {
    status,
    user,
    displayName,
    signOut: () => firebaseSignOut(getFirebaseAuth()),
  };

  return <AdminAuthContext.Provider value={value}>{children}</AdminAuthContext.Provider>;
}

export function useAdminAuth(): AdminAuthState {
  const ctx = useContext(AdminAuthContext);
  if (!ctx) throw new Error("useAdminAuth must be used within AdminAuthProvider");
  return ctx;
}
