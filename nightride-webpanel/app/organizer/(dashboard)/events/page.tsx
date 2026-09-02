"use client";

import { useOrganizerDashboard, type EventsTab } from "@/lib/organizer/dashboard/store";
import { TabStrip } from "@/components/organizer/dashboard/ui/Primitives";
import { EventsSection } from "@/components/organizer/dashboard/sections/EventsSection";
import { CalendarSection } from "@/components/organizer/dashboard/sections/CalendarSection";
import { EventEditor } from "@/components/organizer/dashboard/sections/EventEditor";
import { EventDayDialog } from "@/components/organizer/dashboard/sections/EventDayDialog";

const EVENTS_TABS: { id: EventsTab; label: string }[] = [
  { id: "list", label: "List" },
  { id: "calendar", label: "Calendar" },
];

export default function Page() {
  const { eventsTab, setEventsTab } = useOrganizerDashboard();

  return (
    <>
      <TabStrip tabs={EVENTS_TABS} active={eventsTab} onChange={setEventsTab} />
      {eventsTab === "list" ? <EventsSection /> : <CalendarSection />}

      {/* Overlays live at the page level so both tabs can raise them. */}
      <EventEditor />
      <EventDayDialog />
    </>
  );
}
