"use client";

import { useOrganizerDashboard, type AudienceTab } from "@/lib/organizer/dashboard/store";
import { TabStrip } from "@/components/organizer/dashboard/ui/Primitives";
import { PerformanceSection } from "@/components/organizer/dashboard/sections/PerformanceSection";
import { AiVisibilitySection } from "@/components/organizer/dashboard/sections/AiVisibilitySection";

// Reviews is disabled — kept out of the tab strip and never rendered, but
// "reviews" stays a valid AudienceTab value (store.tsx) so nothing else that
// touches audienceTab needs to change.
const AUDIENCE_TABS: { id: AudienceTab; label: string }[] = [
  { id: "performance", label: "Performance" },
  { id: "ai-visibility", label: "AI Visibility" },
];

export default function Page() {
  const { audienceTab, setAudienceTab } = useOrganizerDashboard();

  return (
    <>
      <TabStrip tabs={AUDIENCE_TABS} active={audienceTab} onChange={setAudienceTab} />
      {audienceTab === "performance" && <PerformanceSection />}
      {audienceTab === "ai-visibility" && <AiVisibilitySection />}
    </>
  );
}
