"use client";

import { OrgAppsList } from "./OrgAppsList";
import { OrgDetailHeader } from "./OrgDetailHeader";
import { VerificationFlow } from "./VerificationFlow";
import { ExistingOrgDetail } from "./ExistingOrgDetail";
import { DecisionBar } from "./DecisionBar";
import { VenueDetail } from "./VenueDetail";
import { useApplicantDetail } from "@/lib/admin/useApplicantDetail";
import type { AdminNav } from "@/lib/admin/useAdminNav";

export function OrganizerApplications({ nav }: { nav: AdminNav }) {
  const { orgScreen, activeUid, activeVenueId, openApplicant, backToList, openVenue, backToApplicant } = nav;
  const detail = useApplicantDetail(orgScreen === "list" ? null : activeUid);

  const isNewApp = detail.user ? detail.user.organizerStatus === "none" || detail.user.organizerStatus === "pending" : false;
  const showDecisionBar = orgScreen === "detail" && isNewApp;

  return (
    <>
      <div style={{ flex: 1, overflowY: "auto", padding: "0 24px 32px" }}>
        {orgScreen === "list" ? <OrgAppsList onOpen={openApplicant} /> : null}

        {orgScreen === "detail" ? (
          detail.loading ? (
            <div style={{ color: "#9A8C91", fontSize: 14 }}>Loading application…</div>
          ) : detail.error || !detail.user ? (
            <div style={{ background: "#2A1A1C", color: "#FFB4AB", borderRadius: 16, padding: 20 }}>{detail.error || "Not found."}</div>
          ) : (
            <>
              <OrgDetailHeader detail={detail} onBack={backToList} />
              {isNewApp ? <VerificationFlow detail={detail} /> : <ExistingOrgDetail detail={detail} onOpenVenue={openVenue} />}
            </>
          )
        ) : null}

        {orgScreen === "venue" && activeVenueId ? <VenueDetail venueId={activeVenueId} onBack={backToApplicant} /> : null}
      </div>

      {showDecisionBar ? <DecisionBar detail={detail} /> : null}
    </>
  );
}
