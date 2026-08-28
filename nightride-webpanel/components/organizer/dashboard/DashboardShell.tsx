"use client";

import { useState, type ReactNode } from "react";
import { Modal } from "@/components/admin/ui/Modal";
import { Button } from "@/components/admin/ui/Button";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { Sidebar } from "./Sidebar";
import { Topbar } from "./Topbar";

/**
 * Sidebar + topbar chrome shared by every organizer dashboard route.
 *
 * The remove-image confirmation lives here rather than in `ImageSlot` so a
 * single dialog serves every slot on the page, matching the design.
 */
export function DashboardShell({ children }: { children: ReactNode }) {
  const [drawerOpen, setDrawerOpen] = useState(false);
  const { confirmRemoveSlotId, cancelRemoveImage, confirmRemoveImage } = useOrganizerDashboard();

  return (
    <div className="flex h-full min-h-0 w-full">
      <Sidebar
        drawerOpen={drawerOpen}
        onOpen={() => setDrawerOpen(true)}
        onClose={() => setDrawerOpen(false)}
      />
      <div className="flex min-w-0 flex-1 flex-col">
        <Topbar onMenuClick={() => setDrawerOpen(true)} />
        <main className="flex-1 overflow-y-auto p-5 sm:p-7">{children}</main>
      </div>

      <Modal
        open={!!confirmRemoveSlotId}
        onClose={cancelRemoveImage}
        title="Remove this image?"
        size="sm"
        footer={
          <>
            <Button variant="ghost" onClick={cancelRemoveImage}>
              Never mind
            </Button>
            <Button variant="danger" onClick={confirmRemoveImage}>
              Remove image
            </Button>
          </>
        }
      >
        <p className="text-sm text-[var(--m3-onv)]">
          This can&apos;t be undone. The photo will be removed from your venue listing.
        </p>
      </Modal>
    </div>
  );
}
