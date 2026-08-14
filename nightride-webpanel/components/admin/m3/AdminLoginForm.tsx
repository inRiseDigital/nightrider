"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { signInWithEmailAndPassword } from "firebase/auth";
import { getFirebaseAuth, isFirebaseConfigured } from "@/lib/firebase";
import { describeAdminError } from "@/lib/admin/errors";
import { useAdminAuth } from "@/lib/admin/auth";
import { Icon } from "./Icon";

export function AdminLoginForm() {
  const router = useRouter();
  const { status } = useAdminAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (status === "admin") router.replace("/admin");
  }, [status, router]);

  async function submit() {
    if (!email.trim()) {
      setError("Enter your email.");
      return;
    }
    if (!password) {
      setError("Enter your password.");
      return;
    }
    if (!isFirebaseConfigured()) {
      setError("Firebase is not configured. Copy .env.example to .env.local and fill in the NEXT_PUBLIC_FIREBASE_* values.");
      return;
    }
    setBusy(true);
    setError("");
    try {
      await signInWithEmailAndPassword(getFirebaseAuth(), email.trim(), password);
      // AdminAuthProvider picks up the new user and the effect above redirects
      // once it confirms isAdmin — this just waits.
    } catch (err) {
      setError(describeAdminError(err));
      setBusy(false);
    }
  }

  return (
    <div className="m3-scope" style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", padding: 24 }}>
      <div style={{ width: "100%", maxWidth: 380, background: "#1B181B", borderRadius: 24, padding: "32px 28px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 28 }}>
          <div
            style={{
              width: 44,
              height: 44,
              borderRadius: 12,
              background: "#8E1049",
              color: "#FFD9E2",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              flexShrink: 0,
            }}
          >
            <Icon name="nightlife" size={24} />
          </div>
          <div>
            <div style={{ fontSize: 17, fontWeight: 500 }}>Night Ride</div>
            <div style={{ fontSize: 12, color: "#9A8C91" }}>Admin console</div>
          </div>
        </div>

        <form
          noValidate
          style={{ display: "flex", flexDirection: "column", gap: 14 }}
          onSubmit={(e) => {
            e.preventDefault();
            void submit();
          }}
        >
          <div>
            <label htmlFor="admin-email" style={{ display: "block", fontSize: 12, color: "#9A8C91", marginBottom: 6 }}>
              Email
            </label>
            <input
              id="admin-email"
              type="email"
              autoComplete="email"
              placeholder="admin@nightride.app"
              value={email}
              onChange={(e) => {
                setEmail(e.target.value);
                setError("");
              }}
              style={{ width: "100%", height: 48, borderRadius: 12, background: "#2A252A", border: "none", padding: "0 16px", fontSize: 14, color: "#EDE0E4" }}
            />
          </div>
          <div>
            <label htmlFor="admin-password" style={{ display: "block", fontSize: 12, color: "#9A8C91", marginBottom: 6 }}>
              Password
            </label>
            <input
              id="admin-password"
              type="password"
              autoComplete="current-password"
              placeholder="••••••••"
              value={password}
              onChange={(e) => {
                setPassword(e.target.value);
                setError("");
              }}
              style={{ width: "100%", height: 48, borderRadius: 12, background: "#2A252A", border: "none", padding: "0 16px", fontSize: 14, color: "#EDE0E4" }}
            />
          </div>

          {error ? (
            <div style={{ background: "#2A1A1C", color: "#FFB4AB", borderRadius: 12, padding: "10px 14px", fontSize: 13 }}>{error}</div>
          ) : null}

          <button
            type="submit"
            disabled={busy}
            style={{
              marginTop: 4,
              height: 48,
              borderRadius: 24,
              fontSize: 14,
              fontWeight: 500,
              background: "#FFB1C4",
              color: "#650430",
              border: "none",
              cursor: busy ? "default" : "pointer",
              opacity: busy ? 0.7 : 1,
            }}
          >
            {busy ? "Signing in…" : "Sign in"}
          </button>
        </form>
      </div>
    </div>
  );
}
