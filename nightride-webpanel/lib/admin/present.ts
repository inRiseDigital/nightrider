import type { Timestamp } from "firebase/firestore";
import { badgeColors, type BadgeType } from "./m3-data";
import type { OrganizerStatus, StepId, StepStatus } from "./schema";

export function initialsFor(displayName: string, email: string): string {
  const source = displayName.trim() || email.trim();
  if (!source) return "?";
  const parts = source.split(/\s+/).filter(Boolean);
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  return source.slice(0, 2).toUpperCase();
}

export function timeAgo(ts: Timestamp | null): string {
  if (!ts) return "—";
  const date = ts.toDate();
  const diffMs = Date.now() - date.getTime();
  const mins = Math.floor(diffMs / 60000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days}d ago`;
  const months = Math.floor(days / 30);
  if (months < 12) return `${months}mo ago`;
  return `${Math.floor(months / 12)}y ago`;
}

export function formatTimestamp(ts: Timestamp | null): string {
  if (!ts) return "—";
  return ts.toDate().toLocaleString("en-US", { month: "short", day: "numeric", year: "numeric", hour: "numeric", minute: "2-digit" });
}

const STATUS_LABELS: Record<OrganizerStatus, string> = {
  none: "Untriaged",
  pending: "Pending",
  approved: "Approved",
  rejected: "Rejected",
  revoked: "Revoked",
};

const STATUS_TONE: Record<OrganizerStatus, BadgeType> = {
  none: "warning",
  pending: "info",
  approved: "success",
  rejected: "danger",
  revoked: "neutral",
};

export function organizerStatusLabel(status: OrganizerStatus): string {
  return STATUS_LABELS[status] ?? status;
}

export function organizerStatusColors(status: OrganizerStatus) {
  return badgeColors(STATUS_TONE[status] ?? "neutral");
}

export const STEP_ORDER: StepId[] = ["nic", "selfie", "venueAddress", "gps", "video"];

export const STEP_DEFS: Record<StepId, { tabLabel: string; icon: string; title: string }> = {
  nic: { tabLabel: "NIC", icon: "badge", title: "NIC document" },
  selfie: { tabLabel: "Live capture", icon: "face", title: "Live face capture" },
  venueAddress: { tabLabel: "Venue", icon: "storefront", title: "Venue address" },
  gps: { tabLabel: "GPS", icon: "my_location", title: "On-site GPS check" },
  video: { tabLabel: "Video", icon: "videocam", title: "Video walkthrough" },
};

const STEP_STATUS_CHROME: Record<StepStatus, { label: string; icon: string; type: BadgeType }> = {
  pending: { label: "Not started", icon: "schedule", type: "neutral" },
  active: { label: "Awaiting organizer", icon: "schedule", type: "neutral" },
  submitted: { label: "Needs review", icon: "error", type: "warning" },
  needs_info: { label: "Re-submission requested", icon: "refresh", type: "info" },
  accepted: { label: "Verified", icon: "check_circle", type: "success" },
};

export function stepStatusChrome(status: StepStatus) {
  const chrome = STEP_STATUS_CHROME[status] ?? STEP_STATUS_CHROME.pending;
  const colors = badgeColors(chrome.type);
  return { ...chrome, bg: colors.bg, fg: colors.fg };
}
