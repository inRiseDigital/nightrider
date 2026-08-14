import { OrgDetailHeader } from "./OrgDetailHeader";
import { VerificationFlow } from "./VerificationFlow";
import { ExistingOrgDetail } from "./ExistingOrgDetail";
import type { AdminConsoleValues } from "@/lib/admin/useAdminConsole";

export function OrgDetail(
  props: Pick<
    AdminConsoleValues,
    | "detail"
    | "backToList"
    | "deactivateHandler"
    | "reactivateHandler"
    | "banHandler"
    | "unbanHandler"
    | "toggleMoreMenuHandler"
    | "resetPasswordHandler"
    | "viewAuditLogHandler"
    | "toggleAddStepHandler"
    | "confirmMatchHandler"
    | "flagMismatchHandler"
    | "togglePhotoHandler"
    | "onInstructionsChange"
    | "sendInstructionsHandler"
    | "instructionPresets"
  >,
) {
  const { detail } = props;
  return (
    <>
      <OrgDetailHeader {...props} />
      {detail.isNewApp ? <VerificationFlow {...props} /> : null}
      {detail.isExistingOrg ? <ExistingOrgDetail {...props} /> : null}
    </>
  );
}
