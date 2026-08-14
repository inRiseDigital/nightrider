"use client";

import { useAdminConsole } from "@/lib/admin/useAdminConsole";
import { Sidebar } from "./Sidebar";
import { Topbar } from "./Topbar";
import { Overview } from "./Overview";
import { Placeholder } from "./Placeholder";
import { OrganizerApplications } from "./organizer-applications/OrganizerApplications";
import { DecisionBar } from "./organizer-applications/DecisionBar";

export function AdminConsole() {
  const values = useAdminConsole();

  return (
    <div className="m3-scope" style={{ display: "flex", height: "100vh", width: "100%", fontFamily: "'Roboto', sans-serif" }}>
      <Sidebar nav={values.navGroups} />

      <div style={{ flex: 1, display: "flex", flexDirection: "column", minWidth: 0, minHeight: 0 }}>
        <Topbar title={values.currentTitle} subtitle={values.currentSubtitle} />

        <div style={{ flex: 1, overflowY: "auto", padding: "0 24px 32px" }}>
          {values.isOverview ? <Overview kpis={values.kpis} activity={values.activity} /> : null}
          {values.isOrgApps ? <OrganizerApplications {...values} /> : null}
          {values.isPlaceholder ? <Placeholder title={values.currentTitle} /> : null}
        </div>

        {values.showDecisionBar ? <DecisionBar {...values} /> : null}
      </div>
    </div>
  );
}
