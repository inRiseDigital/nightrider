"use client";

import { useEffect, useState } from "react";
import { NAV_GROUPS_DEF, SECTION_TITLES } from "./m3-data";
import { getOverviewCounts } from "./firestore";

export type OrgScreen = "list" | "detail" | "venue";

/**
 * Top-level client-side "routing" state — which nav section is selected, and
 * (within Organizer applications) which of list/detail/venue is showing.
 * Deliberately not real Next.js routes: the design is a single-page shell
 * with in-place screen switching, same as the source design.
 */
export type VenuesScreen = "list" | "detail";

export function useAdminNav() {
  const [selected, setSelected] = useState("overview");
  const [orgScreen, setOrgScreen] = useState<OrgScreen>("list");
  const [activeUid, setActiveUid] = useState<string | null>(null);
  const [activeVenueId, setActiveVenueId] = useState<string | null>(null);
  const [counts, setCounts] = useState<Record<string, number>>({});

  // Directory > Venues, and Content review > Event queue, each keep their
  // own "list vs. detail" screen state and deep-link target, independent of
  // the org-apps venue drill-in above (`activeVenueId`).
  const [venuesScreen, setVenuesScreen] = useState<VenuesScreen>("list");
  const [activeGlobalVenueId, setActiveGlobalVenueId] = useState<string | null>(null);
  const [activeEventId, setActiveEventId] = useState<string | null>(null);

  useEffect(() => {
    getOverviewCounts()
      .then((c) => setCounts((prev) => ({ ...prev, "org-apps": c.pendingApplications })))
      .catch(() => {});
  }, [orgScreen, selected]);

  function select(id: string) {
    setSelected(id);
    setOrgScreen("list");
    setActiveUid(null);
    setActiveVenueId(null);
    setVenuesScreen("list");
    setActiveGlobalVenueId(null);
    setActiveEventId(null);
  }
  function openApplicant(uid: string) {
    setSelected("org-apps");
    setOrgScreen("detail");
    setActiveUid(uid);
  }
  function backToList() {
    setOrgScreen("list");
    setActiveUid(null);
  }
  function openVenue(venueId: string) {
    setOrgScreen("venue");
    setActiveVenueId(venueId);
  }
  function backToApplicant() {
    setOrgScreen("detail");
    setActiveVenueId(null);
  }

  /** Deep-link into Directory > Venues, opening a specific venue's detail screen. */
  function openVenueInDirectory(venueId: string) {
    setSelected("venues");
    setVenuesScreen("detail");
    setActiveGlobalVenueId(venueId);
  }

  /** Deep-link into the Event review queue, opening a specific event. */
  function openEventInQueue(eventId: string) {
    setSelected("event-queue");
    setActiveEventId(eventId);
  }

  const navGroups = NAV_GROUPS_DEF.map((g) => ({
    label: g.label,
    items: g.items.map((item) => {
      const showsPendingCount = !!(item as { showsPendingCount?: boolean }).showsPendingCount;
      const count = showsPendingCount ? counts[item.id] ?? 0 : (item as { count?: number }).count;
      return {
        id: item.id,
        label: item.label,
        icon: item.icon,
        count,
        showCount: showsPendingCount ? (count ?? 0) > 0 : !!count,
        active: selected === item.id,
        select: () => select(item.id),
      };
    }),
  }));

  const [currentTitle, currentSubtitle] = SECTION_TITLES[selected] || SECTION_TITLES.overview;

  const isOverview = selected === "overview";
  const isOrgApps = selected === "org-apps";
  const isVenues = selected === "venues";
  const isEventQueue = selected === "event-queue";
  const isUsers = selected === "users";
  const isRoles = selected === "roles";
  const isAudit = selected === "audit";

  return {
    selected,
    orgScreen,
    activeUid,
    activeVenueId,
    navGroups,
    currentTitle,
    currentSubtitle,
    isOverview,
    isOrgApps,
    isVenues,
    isEventQueue,
    isUsers,
    isRoles,
    isAudit,
    // Placeholder until each section's screen is built out — flip to false
    // there as each lands.
    isPlaceholder: isVenues || isEventQueue || isUsers || isRoles || isAudit,
    openApplicant,
    backToList,
    openVenue,
    backToApplicant,
    venuesScreen,
    activeGlobalVenueId,
    activeEventId,
    openVenueInDirectory,
    openEventInQueue,
  };
}

export type AdminNav = ReturnType<typeof useAdminNav>;
