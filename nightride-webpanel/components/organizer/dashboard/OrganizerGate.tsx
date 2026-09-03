"use client";

import { useEffect } from "react";
import { useRouter, usePathname } from "next/navigation";
import { Loader2 } from "lucide-react";
import { useOrganizerAuth } from "@/lib/organizer/dashboard/auth";
import { Card, FilledButton } from "./ui/Primitives";

/**
 * Gates the organizer dashboard on `useOrganizerAuth()`. Every non-"approved"
 * status renders inside the same M3 shell chrome as the dashboard itself —
 * this component is mounted inside the `.organizer-m3` wrapper (see
 * `app/organizer/(dashboard)/layout.tsx`), so it inherits that theme rather
 * than needing to reproduce it.
 */
export function OrganizerGate({ children }: { children: React.ReactNode }) {
  const { status, rejectionReason } = useOrganizerAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (status === "signed-out") {
      router.replace(`/organizer/login?next=${encodeURIComponent(pathname)}`);
    }
  }, [status, pathname, router]);

  if (status === "approved") return <>{children}</>;

  if (status === "unconfigured") {
    return (
      <Shell>
        <Card className="max-w-md text-center">
          <p className="text-sm" style={{ color: "var(--m3-on)" }}>
            Firebase is not configured. Copy .env.example to .env.local and fill in the
            NEXT_PUBLIC_FIREBASE_* values.
          </p>
        </Card>
      </Shell>
    );
  }

  if (status === "pending") {
    return (
      <Shell>
        <Card className="max-w-md text-center">
          <p className="text-sm" style={{ color: "var(--m3-on)" }}>
            Your organizer application is still being reviewed.
          </p>
          <FilledButton
            className="mx-auto mt-4"
            onClick={() => router.push("/organizer/apply")}
          >
            View application status
          </FilledButton>
        </Card>
      </Shell>
    );
  }

  if (status === "rejected") {
    return (
      <Shell>
        <Card className="max-w-md text-center">
          <p className="text-sm" style={{ color: "var(--m3-on)" }}>
            {rejectionReason || "Your organizer application was not approved."}
          </p>
          <FilledButton className="mx-auto mt-4" onClick={() => router.push("/organizer/apply")}>
            Apply again
          </FilledButton>
        </Card>
      </Shell>
    );
  }

  // "loading" and "signed-out" — the redirect above fires for signed-out; a
  // spinner covers the brief instant before it does.
  return (
    <Shell>
      <Loader2 size={24} className="animate-spin" style={{ color: "var(--m3-onv)" }} aria-label="Loading" />
    </Shell>
  );
}

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-0 w-full flex-1 items-center justify-center">{children}</div>
  );
}
