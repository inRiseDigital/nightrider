import {
  AccountStatus,
  ApprovalStatus,
  ClubStatus,
  EventStatus,
  VerificationStatus,
} from "./types";

export type BadgeVariant = "success" | "warning" | "danger" | "neutral" | "info" | "accent";

export function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

export function formatDateTime(iso: string): string {
  return new Date(iso).toLocaleString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
}

export function relativeTime(iso: string): string {
  const diffMs = Date.now() - new Date(iso).getTime();
  const diffMin = Math.round(diffMs / 60000);
  if (diffMin < 1) return "just now";
  if (diffMin < 60) return `${diffMin}m ago`;
  const diffHr = Math.round(diffMin / 60);
  if (diffHr < 24) return `${diffHr}h ago`;
  const diffDay = Math.round(diffHr / 24);
  if (diffDay < 30) return `${diffDay}d ago`;
  return formatDate(iso);
}

export const verificationVariant = (s: VerificationStatus): BadgeVariant =>
  s === "verified" ? "success" : "neutral";

export const accountStatusVariant = (s: AccountStatus): BadgeVariant =>
  s === "active" ? "success" : s === "deactivated" ? "warning" : "danger";

export const approvalVariant = (s: ApprovalStatus): BadgeVariant =>
  s === "approved" ? "success" : s === "pending" ? "warning" : "danger";

export const clubStatusVariant = (s: ClubStatus): BadgeVariant =>
  s === "active" ? "success" : "warning";

export const EVENT_STATUS_LABELS: Record<EventStatus, string> = {
  draft: "Draft",
  scheduled: "Scheduled",
  starting_soon: "Starting Soon",
  ongoing: "Ongoing",
  completed: "Completed",
  cancelled: "Cancelled",
  emergency_closure: "Emergency Closure",
};

export const eventStatusVariant = (s: EventStatus): BadgeVariant => {
  switch (s) {
    case "draft":
      return "neutral";
    case "scheduled":
      return "info";
    case "starting_soon":
      return "accent";
    case "ongoing":
      return "success";
    case "completed":
      return "neutral";
    case "cancelled":
      return "danger";
    case "emergency_closure":
      return "danger";
  }
};

export function capitalize(s: string): string {
  return s.length ? s[0].toUpperCase() + s.slice(1) : s;
}

export function initials(name: string): string {
  const parts = name.trim().split(/\s+/);
  const first = parts[0]?.[0] ?? "";
  const last = parts.length > 1 ? parts[parts.length - 1][0] : "";
  return (first + last).toUpperCase();
}
