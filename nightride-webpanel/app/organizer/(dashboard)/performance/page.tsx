"use client";

import { useOrganizerDashboard, type AudienceTab } from "@/lib/organizer/dashboard/store";
import { TabStrip } from "@/components/organizer/dashboard/ui/Primitives";
import { PerformanceSection } from "@/components/organizer/dashboard/sections/PerformanceSection";
import { ReviewsSection } from "@/components/organizer/dashboard/sections/ReviewsSection";
import { AiVisibilitySection } from "@/components/organizer/dashboard/sections/AiVisibilitySection";

const AUDIENCE_TABS: { id: AudienceTab; label: string }[] = [
  { id: "performance", label: "Performance" },
  { id: "reviews", label: "Reviews" },
  { id: "ai-visibility", label: "AI Visibility" },
];

export default function Page() {
  const { audienceTab, setAudienceTab } = useOrganizerDashboard();

  return (
    <>
      <TabStrip tabs={AUDIENCE_TABS} active={audienceTab} onChange={setAudienceTab} />
      {audienceTab === "performance" && <PerformanceSection />}
      {audienceTab === "reviews" && <ReviewsSection />}
      {audienceTab === "ai-visibility" && <AiVisibilitySection />}
    </>
  );
}
