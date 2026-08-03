"use client";

import { Club } from "@/lib/admin/types";
import { Drawer } from "@/components/admin/ui/Drawer";
import { Avatar } from "@/components/admin/ui/Avatar";
import { Badge } from "@/components/admin/ui/Badge";
import { DetailRow } from "@/components/admin/ui/DetailRow";
import { formatDate, approvalVariant, capitalize, clubStatusVariant } from "@/lib/admin/format";

export function ClubDetailDrawer({ club, onClose }: { club: Club | null; onClose: () => void }) {
  if (!club) return null;

  return (
    <Drawer open={!!club} onClose={onClose} title={club.name} subtitle={club.location}>
      <div className="space-y-6">
        <div className="flex items-center gap-3">
          <Avatar name={club.name} src={club.logoUrl} size={56} />
          <div>
            <p className="font-medium text-nr-text-primary">{club.name}</p>
            <p className="text-xs text-nr-text-hint">{club.id}</p>
          </div>
        </div>

        <div className="flex flex-wrap gap-2">
          <Badge variant={clubStatusVariant(club.status)}>{capitalize(club.status)}</Badge>
          <Badge variant={approvalVariant(club.approvalStatus)}>{capitalize(club.approvalStatus)}</Badge>
        </div>

        <section>
          <h3 className="mb-2 text-xs font-medium uppercase tracking-wider text-nr-text-hint">Details</h3>
          <p className="text-sm text-nr-text-secondary">{club.description}</p>
        </section>

        <section>
          <h3 className="mb-2 text-xs font-medium uppercase tracking-wider text-nr-text-hint">Contact & organizer</h3>
          <dl className="space-y-1.5 text-sm">
            <DetailRow label="Organizer" value={club.organizerName ?? "Unassigned"} />
            <DetailRow label="Email" value={club.contactEmail} />
            <DetailRow label="Phone" value={club.contactPhone} />
            <DetailRow label="Location" value={club.location} />
          </dl>
        </section>

        <section>
          <h3 className="mb-2 text-xs font-medium uppercase tracking-wider text-nr-text-hint">Activity</h3>
          <dl className="space-y-1.5 text-sm">
            <DetailRow label="Upcoming events" value={String(club.upcomingEventsCount)} />
            <DetailRow label="Created" value={formatDate(club.createdAt)} />
            <DetailRow label="Last updated" value={formatDate(club.lastUpdatedAt)} />
          </dl>
        </section>
      </div>
    </Drawer>
  );
}
