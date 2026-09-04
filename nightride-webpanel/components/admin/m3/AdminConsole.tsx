"use client";

import { useAdminNav } from "@/lib/admin/useAdminNav";
import { useAdminAuth } from "@/lib/admin/auth";
import { Sidebar } from "./Sidebar";
import { Topbar } from "./Topbar";
import { Overview } from "./Overview";
import { Placeholder } from "./Placeholder";
import { OrganizerApplications } from "./organizer-applications/OrganizerApplications";
import { RolesAccess } from "./roles/RolesAccess";
import { AuditLog } from "./audit/AuditLog";

export function AdminConsole() {
  const nav = useAdminNav();
  const { displayName, user, signOut } = useAdminAuth();

  return (
    <div className="m3-scope" style={{ display: "flex", height: "100vh", width: "100%", fontFamily: "'Roboto', sans-serif" }}>
      <Sidebar nav={nav.navGroups} adminName={displayName} adminEmail={user?.email ?? null} onSignOut={() => void signOut()} />

      <div style={{ flex: 1, display: "flex", flexDirection: "column", minWidth: 0, minHeight: 0 }}>
        <Topbar title={nav.currentTitle} subtitle={nav.currentSubtitle} />

        {nav.isOrgApps ? (
          <OrganizerApplications nav={nav} />
        ) : (
          <div style={{ flex: 1, overflowY: "auto", padding: "0 24px 32px" }}>
            {nav.isOverview ? <Overview /> : null}
            {nav.isRoles ? <RolesAccess /> : null}
            {nav.isAudit ? <AuditLog /> : null}
            {nav.isPlaceholder ? <Placeholder title={nav.currentTitle} /> : null}
          </div>
        )}
      </div>
    </div>
  );
}
