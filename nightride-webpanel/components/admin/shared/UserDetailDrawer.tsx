"use client";

import { useState } from "react";
import { PlatformUser } from "@/lib/admin/types";
import { useAdminData } from "@/lib/admin/store";
import { Drawer } from "@/components/admin/ui/Drawer";
import { Avatar } from "@/components/admin/ui/Avatar";
import { Badge } from "@/components/admin/ui/Badge";
import { Button } from "@/components/admin/ui/Button";
import { Textarea } from "@/components/admin/ui/Field";
import { DetailRow } from "@/components/admin/ui/DetailRow";
import { PermissionBadgeList } from "@/components/admin/ui/PermissionBadgeList";
import { formatDate, formatDateTime, accountStatusVariant, capitalize, verificationVariant } from "@/lib/admin/format";
import { ROLE_LABELS } from "@/lib/admin/constants";

export function UserDetailDrawer({ user, onClose }: { user: PlatformUser | null; onClose: () => void }) {
  const { clubs, rolePermissions, addAdminNote } = useAdminData();
  const [note, setNote] = useState("");

  if (!user) return null;

  const club = user.organizerDetails?.clubId ? clubs.find((c) => c.id === user.organizerDetails?.clubId) : undefined;
  const permissions = rolePermissions[user.role];

  return (
    <Drawer open={!!user} onClose={onClose} title={user.fullName} subtitle={user.email}>
      <div className="space-y-6">
        <div className="flex items-center gap-3">
          <Avatar name={user.fullName} src={user.avatarUrl} size={56} />
          <div>
            <p className="font-medium text-nr-text-primary">{user.fullName}</p>
            <p className="text-xs text-nr-text-hint">{user.id}</p>
          </div>
        </div>

        <div className="flex flex-wrap gap-2">
          <Badge variant="info">{ROLE_LABELS[user.role]}</Badge>
          <Badge variant={verificationVariant(user.verificationStatus)}>
            {user.verificationStatus === "verified" ? "Verified" : "Unverified"}
          </Badge>
          <Badge variant={accountStatusVariant(user.accountStatus)}>{capitalize(user.accountStatus)}</Badge>
        </div>

        <section>
          <h3 className="mb-2 text-xs font-medium uppercase tracking-wider text-nr-text-hint">Personal information</h3>
          <dl className="space-y-1.5 text-sm">
            <DetailRow label="Email" value={user.email} />
            <DetailRow label="Phone" value={user.phone ?? "—"} />
            <DetailRow label="Instagram" value={user.instagram ?? "—"} />
            <DetailRow label="City" value={user.city ?? "—"} />
            <DetailRow label="Registered" value={formatDate(user.registeredAt)} />
            <DetailRow label="Last active" value={formatDate(user.lastActiveAt)} />
          </dl>
        </section>

        {club && (
          <section>
            <h3 className="mb-2 text-xs font-medium uppercase tracking-wider text-nr-text-hint">Assigned club</h3>
            <div className="flex items-center gap-2 rounded-lg border border-nr-border p-3">
              <Avatar name={club.name} src={club.logoUrl} size={32} />
              <div>
                <p className="text-sm text-nr-text-primary">{club.name}</p>
                <p className="text-xs text-nr-text-hint">{club.location}</p>
              </div>
            </div>
          </section>
        )}

        {user.organizerDetails && (
          <section>
            <h3 className="mb-2 text-xs font-medium uppercase tracking-wider text-nr-text-hint">Organizer activity</h3>
            <p className="text-sm text-nr-text-secondary">{user.organizerDetails.eventsCreated} events created</p>
            <ul className="mt-2 space-y-1 text-sm text-nr-text-secondary">
              {user.organizerDetails.recentActivity.map((a, i) => (
                <li key={i}>&bull; {a}</li>
              ))}
            </ul>
          </section>
        )}

        {user.adminDetails && (
          <section>
            <h3 className="mb-2 text-xs font-medium uppercase tracking-wider text-nr-text-hint">Admin access</h3>
            <dl className="space-y-1.5 text-sm">
              <DetailRow label="Granted" value={formatDateTime(user.adminDetails.grantedAt)} />
              <DetailRow label="Granted by" value={user.adminDetails.grantedBy} />
            </dl>
          </section>
        )}

        <section>
          <h3 className="mb-2 text-xs font-medium uppercase tracking-wider text-nr-text-hint">
            Permissions ({ROLE_LABELS[user.role]})
          </h3>
          <PermissionBadgeList permissions={permissions} />
        </section>

        <section>
          <h3 className="mb-2 text-xs font-medium uppercase tracking-wider text-nr-text-hint">Admin notes</h3>
          <div className="space-y-2">
            <Textarea
              placeholder="Add an internal note about this user..."
              value={note}
              onChange={(e) => setNote(e.target.value)}
            />
            <Button
              size="sm"
              variant="secondary"
              disabled={!note.trim()}
              onClick={() => {
                addAdminNote(user.id, note.trim());
                setNote("");
              }}
            >
              Add note
            </Button>
          </div>
          <ul className="mt-3 space-y-2">
            {user.adminNotes.map((n) => (
              <li key={n.id} className="rounded-lg border border-nr-border p-3 text-sm">
                <p className="text-nr-text-primary">{n.note}</p>
                <p className="mt-1 text-xs text-nr-text-hint">
                  {n.author} &middot; {formatDateTime(n.createdAt)}
                </p>
              </li>
            ))}
            {user.adminNotes.length === 0 && (
              <p className="text-sm text-nr-text-hint">No notes yet.</p>
            )}
          </ul>
        </section>
      </div>
    </Drawer>
  );
}
