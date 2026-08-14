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
export function useAdminNav() {
  const [selected, setSelected] = useState("overview");
  const [orgScreen, setOrgScreen] = useState<OrgScreen>("list");
  const [activeUid, setActiveUid] = useState<string | null>(null);
  const [activeVenueId, setActiveVenueId] = useState<string | null>(null);
  const [pendingCount, setPendingCount] = useState(0);

  useEffect(() => {
    getOverviewCounts()
      .then((c) => setPendingCount(c.pendingApplications))
      .catch(() => {});
  }, [orgScreen, selected]);

  function select(id: string) {
    setSelected(id);
    setOrgScreen("list");
    setActiveUid(null);
    setActiveVenueId(null);
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

  const navGroups = NAV_GROUPS_DEF.map((g) => ({
    label: g.label,
    items: g.items.map((item) => ({
      id: item.id,
      label: item.label,
      icon: item.icon,
      count: item.id === "org-apps" ? pendingCount : (item as { count?: number }).count,
      showCount: item.id === "org-apps" ? pendingCount > 0 : !!(item as { count?: number }).count,
      active: selected === item.id,
      select: () => select(item.id),
    })),
  }));

  const [currentTitle, currentSubtitle] = SECTION_TITLES[selected] || SECTION_TITLES.overview;

  return {
    selected,
    orgScreen,
    activeUid,
    activeVenueId,
    navGroups,
    currentTitle,
    currentSubtitle,
    isOverview: selected === "overview",
    isOrgApps: selected === "org-apps",
    isPlaceholder: selected !== "overview" && selected !== "org-apps",
    openApplicant,
    backToList,
    openVenue,
    backToApplicant,
  };
}

export type AdminNav = ReturnType<typeof useAdminNav>;
