"use client";

import { useOrganizerDashboard, type HomeTab } from "@/lib/organizer/dashboard/store";
import { TabStrip } from "@/components/organizer/dashboard/ui/Primitives";
import { LiveOperationsSection } from "@/components/organizer/dashboard/sections/LiveOperationsSection";
import { ActivitySection } from "@/components/organizer/dashboard/sections/ActivitySection";

const HOME_TABS: { id: HomeTab; label: string }[] = [
  { id: "tonight", label: "Live operations" },
  { id: "activity", label: "Recent activity" },
];

export default function Page() {
  const { homeTab, setHomeTab } = useOrganizerDashboard();

  return (
    <>
      <TabStrip tabs={HOME_TABS} active={homeTab} onChange={setHomeTab} />
      {homeTab === "tonight" ? <LiveOperationsSection /> : <ActivitySection />}
    </>
  );
}
