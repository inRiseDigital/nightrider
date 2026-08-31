"use client";

import { useOrganizerDashboard, type AccountTab } from "@/lib/organizer/dashboard/store";
import { TabStrip } from "@/components/organizer/dashboard/ui/Primitives";
import { TeamSection } from "@/components/organizer/dashboard/sections/TeamSection";
import { InboxSection } from "@/components/organizer/dashboard/sections/InboxSection";
import { PromotionSection } from "@/components/organizer/dashboard/sections/PromotionSection";
import { SettingsSection } from "@/components/organizer/dashboard/sections/SettingsSection";

const ACCOUNT_TABS: { id: AccountTab; label: string }[] = [
  { id: "team", label: "Team" },
  { id: "inbox", label: "Inbox" },
  { id: "promotion", label: "Promotion" },
  { id: "settings", label: "Settings" },
];

export default function Page() {
  const { accountTab, setAccountTab } = useOrganizerDashboard();

  return (
    <>
      <TabStrip tabs={ACCOUNT_TABS} active={accountTab} onChange={setAccountTab} />
      {accountTab === "team" && <TeamSection />}
      {accountTab === "inbox" && <InboxSection />}
      {accountTab === "promotion" && <PromotionSection />}
      {accountTab === "settings" && <SettingsSection />}
    </>
  );
}
