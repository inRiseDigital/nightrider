import { OrgAppsList } from "./OrgAppsList";
import { OrgDetail } from "./OrgDetail";
import { VenueDetail } from "./VenueDetail";
import type { AdminConsoleValues } from "@/lib/admin/useAdminConsole";

export function OrganizerApplications(props: AdminConsoleValues) {
  if (props.isOrgList) {
    return <OrgAppsList {...props} />;
  }
  if (props.isOrgDetail) {
    return <OrgDetail {...props} />;
  }
  if (props.isVenueDetail) {
    return <VenueDetail {...props} />;
  }
  return null;
}
