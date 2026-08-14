import { OrganizerApplicationProvider } from "@/lib/organizer/store";
import { ApplicationFlow } from "./_components/ApplicationFlow";

export default function OrganizerApplyPage() {
  return (
    <OrganizerApplicationProvider>
      <ApplicationFlow />
    </OrganizerApplicationProvider>
  );
}
