"use client";

import { useEffect, useState } from "react";
import { getOverviewCounts, listRecentLogs, type OverviewCounts } from "./firestore";
import type { LogEntry } from "./schema";

const LOG_META: Record<string, { icon: string; color: string; fill: string; label: string }> = {
  "event.publish": { icon: "event_available", color: "#7BE0A8", fill: "#0F3D28", label: "Event published" },
  "event.archive": { icon: "archive", color: "#CFC0C5", fill: "#2A252A", label: "Event archived" },
  "organizer.approve": { icon: "how_to_reg", color: "#7BE0A8", fill: "#0F3D28", label: "Organizer approved" },
  "organizer.reject": { icon: "cancel", color: "#FFB4AB", fill: "#5C1218", label: "Organizer rejected" },
  "organizer.revoke": { icon: "person_remove", color: "#FFB4AB", fill: "#5C1218", label: "Organizer account removed" },
  "venue.create": { icon: "storefront", color: "#A5F2E5", fill: "#1F4F49", label: "Venue created" },
  "report.delete": { icon: "flag", color: "#F5C452", fill: "#42320A", label: "Report removed" },
  "kyc.needsInfo": { icon: "help", color: "#F5C452", fill: "#42320A", label: "Asked for more info" },
  "kyc.accept": { icon: "check_circle", color: "#7BE0A8", fill: "#0F3D28", label: "Verification step accepted" },
};

export interface ActivityRow {
  id: string;
  icon: string;
  color: string;
  fill: string;
  status: string;
  text: string;
  time: string;
}

function timeAgo(ts: unknown): string {
  const date = ts && typeof ts === "object" && "toDate" in ts ? (ts as { toDate: () => Date }).toDate() : null;
  if (!date) return "";
  const diffMs = Date.now() - date.getTime();
  const mins = Math.floor(diffMs / 60000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

function toActivityRow(log: LogEntry): ActivityRow {
  const meta = LOG_META[log.action] ?? { icon: "info", color: "#CFC0C5", fill: "#2A252A", label: log.action };
  return {
    id: log.id,
    icon: meta.icon,
    color: meta.color,
    fill: meta.fill,
    status: meta.label,
    text: log.summary || meta.label,
    time: timeAgo(log.at),
  };
}

export function useOverviewData() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [counts, setCounts] = useState<OverviewCounts | null>(null);
  const [activity, setActivity] = useState<ActivityRow[]>([]);

  useEffect(() => {
    let cancelled = false;
    // No setLoading(true) here — the useState(true) default above already
    // covers this mount-only effect ([] deps), so there's nothing to reset.
    Promise.all([getOverviewCounts(), listRecentLogs(8)])
      .then(([c, logs]) => {
        if (cancelled) return;
        setCounts(c);
        setActivity(logs.map(toActivityRow));
        setError(null);
      })
      .catch((err) => {
        if (cancelled) return;
        setError(err instanceof Error ? err.message : "Failed to load dashboard data.");
      })
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, []);

  return { loading, error, counts, activity };
}
