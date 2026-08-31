"use client";

import { useOrganizerDashboard, type HomeTab } from "@/lib/organizer/dashboard/store";
import { TabStrip } from "@/components/organizer/dashboard/ui/Primitives";
import { TonightSection } from "@/components/organizer/dashboard/sections/TonightSection";
import { OverviewSection } from "@/components/organizer/dashboard/sections/OverviewSection";
import { ActivitySection } from "@/components/organizer/dashboard/sections/ActivitySection";

const HOME_TABS: { id: HomeTab; label: string }[] = [
  { id: "tonight", label: "Tonight" },
  { id: "activity", label: "Activity" },
];

export default function Page() {
  const { homeTab, setHomeTab } = useOrganizerDashboard();

  return (
    <>
      <TabStrip tabs={HOME_TABS} active={homeTab} onChange={setHomeTab} />
      {homeTab === "tonight" ? (
        <div className="flex flex-col gap-5">
          <TonightSection />
          <OverviewSection />
        </div>
      ) : (
        <ActivitySection />
      )}
    </>
  );
}
