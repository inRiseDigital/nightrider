"use client";

import { EventRecord } from "@/lib/admin/types";
import { Drawer } from "@/components/admin/ui/Drawer";
import { Badge } from "@/components/admin/ui/Badge";
import { DetailRow } from "@/components/admin/ui/DetailRow";
import { EVENT_STATUS_LABELS, eventStatusVariant, formatDateTime } from "@/lib/admin/format";

export function EventDetailDrawer({ event, onClose }: { event: EventRecord | null; onClose: () => void }) {
  if (!event) return null;

  return (
    <Drawer open={!!event} onClose={onClose} title={event.title} subtitle={event.clubName}>
      <div className="space-y-6">
        <Badge variant={eventStatusVariant(event.status)}>{EVENT_STATUS_LABELS[event.status]}</Badge>

        <section>
          <h3 className="mb-2 text-xs font-medium uppercase tracking-wider text-nr-text-hint">Event information</h3>
          <dl className="space-y-1.5 text-sm">
            <DetailRow label="Club" value={event.clubName} />
            <DetailRow label="Organizer" value={event.organizerName} />
            <DetailRow label="Date & time" value={formatDateTime(event.dateTime)} />
            <DetailRow label="Location" value={event.location} />
            <DetailRow label="Attendees" value={String(event.attendeesCount)} />
            <DetailRow label="Created" value={formatDateTime(event.createdAt)} />
          </dl>
          <p className="mt-3 text-sm text-nr-text-secondary">{event.description}</p>
        </section>

        {event.cancellationReason && (
          <section>
            <h3 className="mb-2 text-xs font-medium uppercase tracking-wider text-nr-text-hint">Cancellation reason</h3>
            <p className="rounded-lg border border-red-500/20 bg-red-500/5 p-3 text-sm text-red-300">
              {event.cancellationReason}
            </p>
          </section>
        )}

        <section>
          <h3 className="mb-2 text-xs font-medium uppercase tracking-wider text-nr-text-hint">Status history</h3>
          <ul className="space-y-2">
            {event.statusHistory.map((h, i) => (
              <li key={i} className="flex items-start justify-between gap-3 rounded-lg border border-nr-border p-3 text-sm">
                <div>
                  <Badge variant={eventStatusVariant(h.status)}>{EVENT_STATUS_LABELS[h.status]}</Badge>
                  <p className="mt-1 text-xs text-nr-text-hint">by {h.changedBy}</p>
                  {h.reason && <p className="mt-1 text-xs text-nr-text-secondary">{h.reason}</p>}
                </div>
                <span className="shrink-0 text-xs text-nr-text-hint">{formatDateTime(h.changedAt)}</span>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </Drawer>
  );
}
