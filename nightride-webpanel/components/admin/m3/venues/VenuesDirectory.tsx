"use client";

import { useEffect, useRef } from "react";
import { VenuesList } from "./VenuesList";
import { VenueDetailGlobal } from "./VenueDetailGlobal";
import { useVenues } from "@/lib/admin/useVenues";
import type { AdminNav } from "@/lib/admin/useAdminNav";

/**
 * Entry point for the Directory > Venues section — owns `useVenues` and
 * switches between the list and detail screens, same shape as
 * organizer-applications/OrganizerApplications.tsx. `nav.activeGlobalVenueId`
 * / `nav.venuesScreen` are the deep-link seam other sections use
 * (`openVenueInDirectory`); this syncs the hook's own `selectedId` to that
 * whenever it points somewhere new, then drives selection itself from there
 * on (row click / back link) via `venues.select`.
 */
export function VenuesDirectory({ nav }: { nav: AdminNav }) {
  const venues = useVenues();
  const lastDeepLink = useRef<string | null>(null);

  useEffect(() => {
    if (nav.venuesScreen === "detail" && nav.activeGlobalVenueId && nav.activeGlobalVenueId !== lastDeepLink.current) {
      lastDeepLink.current = nav.activeGlobalVenueId;
      venues.select(nav.activeGlobalVenueId);
    }
    if (nav.venuesScreen === "list") {
      lastDeepLink.current = null;
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [nav.venuesScreen, nav.activeGlobalVenueId]);

  return (
    <div style={{ flex: 1, overflowY: "auto", padding: "0 24px 32px" }}>
      {venues.selectedId ? <VenueDetailGlobal venues={venues} nav={nav} /> : <VenuesList venues={venues} />}
    </div>
  );
}
