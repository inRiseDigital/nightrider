"use client";

import { useUsers } from "@/lib/admin/useUsers";
import type { AdminNav } from "@/lib/admin/useAdminNav";
import { UsersList } from "./UsersList";
import { UserDrawer } from "./UserDrawer";

/**
 * Container for the "Users & organizers" directory — wires useUsers() to the
 * table + drawer. `nav.openApplicant` is passed through as the callback the
 * hook exposes for "Open organizer record" (see useUsers.ts's `openOrganizer`)
 * rather than the drawer reaching into nav directly.
 */
export function UsersDirectory({ nav }: { nav: AdminNav }) {
  const vm = useUsers(nav.openApplicant);

  return (
    <div>
      <UsersList vm={vm} />
      <UserDrawer vm={vm} />
    </div>
  );
}
