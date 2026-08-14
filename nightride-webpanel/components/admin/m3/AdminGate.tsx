"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAdminAuth } from "@/lib/admin/auth";
import { Icon } from "./Icon";

export function AdminGate({ children }: { children: React.ReactNode }) {
  const { status } = useAdminAuth();
  const router = useRouter();

  useEffect(() => {
    if (status === "signed-out" || status === "not-admin") router.replace("/admin/login");
  }, [status, router]);

  if (status !== "admin") {
    return (
      <div className="m3-scope" style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div style={{ textAlign: "center", color: "#9A8C91" }}>
          <Icon name={status === "not-admin" ? "block" : "hourglass_empty"} size={32} />
          <div style={{ marginTop: 10, fontSize: 14 }}>
            {status === "not-admin" ? "This account doesn't have admin access." : "Checking your session…"}
          </div>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
