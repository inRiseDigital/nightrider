"use client";

import { Anton } from "next/font/google";
import { useState } from "react";
import { AdminDataProvider } from "@/lib/admin/store";
import { ToastProvider } from "@/components/admin/ui/Toast";
import { Sidebar } from "@/components/admin/layout/Sidebar";
import { Topbar } from "@/components/admin/layout/Topbar";

const antonDisplay = Anton({
  weight: "400",
  subsets: ["latin"],
  variable: "--font-nr-display",
});

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  return (
    <div className={`${antonDisplay.variable} min-h-screen bg-nr-bg text-nr-text-primary`}>
      <AdminDataProvider>
        <ToastProvider>
          <div className="flex min-h-screen">
            <Sidebar mobileOpen={mobileNavOpen} onClose={() => setMobileNavOpen(false)} />
            <div className="flex min-w-0 flex-1 flex-col">
              <Topbar onMenuClick={() => setMobileNavOpen(true)} />
              <main className="flex-1 overflow-x-hidden p-4 sm:p-6">{children}</main>
            </div>
          </div>
        </ToastProvider>
      </AdminDataProvider>
    </div>
  );
}
