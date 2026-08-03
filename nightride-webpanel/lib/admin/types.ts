// Shared types for the frontend-only Admin Panel prototype.
// Field names loosely follow the real `users` / `events` Firestore shapes documented in
// nightride-webpanel/README.md and the live Flutter admin panel, extended with the
// club/permission concepts this prototype introduces (none of which exist in the DB yet).

export type Role = "user" | "verified" | "organizer" | "admin";

export type VerificationStatus = "verified" | "unverified";

export type AccountStatus = "active" | "deactivated" | "banned";

export type ApprovalStatus = "pending" | "approved" | "rejected";

export type ClubStatus = "active" | "deactivated";

export type EventStatus =
  | "draft"
  | "scheduled"
  | "starting_soon"
  | "ongoing"
  | "completed"
  | "cancelled"
  | "emergency_closure";

export type AdminAccessLevel = "super_admin" | "admin" | "moderator";

export const PERMISSION_KEYS = [
  "view_club_info",
  "submit_club_info",
  "edit_club_info",
  "create_events",
  "edit_events",
  "cancel_events",
  "publish_emergency_closures",
  "manage_users",
  "manage_roles",
  "manage_admins",
  "delete_records",
  "view_activity_logs",
] as const;

export type PermissionKey = (typeof PERMISSION_KEYS)[number];

export type RolePermissionMap = Record<Role, Record<PermissionKey, boolean>>;

export interface AdminNote {
  id: string;
  author: string;
  note: string;
  createdAt: string;
}

export interface OrganizerDetails {
  approvalStatus: ApprovalStatus;
  clubId: string | null;
  eventsCreated: number;
  recentActivity: string[];
}

export interface AdminDetails {
  accessLevel: AdminAccessLevel;
  grantedAt: string;
  grantedBy: string;
  permissionOverrides?: Partial<Record<PermissionKey, boolean>>;
}

export interface PlatformUser {
  id: string;
  fullName: string;
  email: string;
  avatarUrl?: string;
  phone?: string;
  instagram?: string;
  bio?: string;
  city?: string;
  role: Role;
  verificationStatus: VerificationStatus;
  accountStatus: AccountStatus;
  isOrganizer: boolean;
  isAdmin: boolean;
  registeredAt: string;
  lastActiveAt: string;
  organizerDetails?: OrganizerDetails;
  adminDetails?: AdminDetails;
  adminNotes: AdminNote[];
}

export interface Club {
  id: string;
  name: string;
  logoUrl?: string;
  organizerId: string | null;
  organizerName: string | null;
  status: ClubStatus;
  approvalStatus: ApprovalStatus;
  location: string;
  contactEmail: string;
  contactPhone: string;
  description: string;
  upcomingEventsCount: number;
  createdAt: string;
  lastUpdatedAt: string;
}

export interface EventStatusChange {
  status: EventStatus;
  changedAt: string;
  changedBy: string;
  reason?: string;
}

export interface EventRecord {
  id: string;
  title: string;
  clubId: string;
  clubName: string;
  organizerId: string;
  organizerName: string;
  dateTime: string;
  location: string;
  status: EventStatus;
  attendeesCount: number;
  createdAt: string;
  description: string;
  cancellationReason?: string;
  statusHistory: EventStatusChange[];
}

export type ActivityActionType =
  | "user_verified"
  | "user_unverified"
  | "user_activated"
  | "user_deactivated"
  | "user_banned"
  | "user_unbanned"
  | "role_changed"
  | "permission_changed"
  | "organizer_promoted"
  | "organizer_approved"
  | "organizer_rejected"
  | "organizer_access_removed"
  | "organizer_club_assigned"
  | "admin_access_granted"
  | "admin_access_removed"
  | "club_approved"
  | "club_rejected"
  | "club_edited"
  | "club_deactivated"
  | "club_deleted"
  | "event_edited"
  | "event_status_changed"
  | "event_cancelled"
  | "event_deleted";

export type ActivityTargetType = "user" | "organizer" | "admin" | "club" | "event" | "role";

export interface ActivityLogEntry {
  id: string;
  adminId: string;
  adminName: string;
  actionType: ActivityActionType;
  targetType: ActivityTargetType;
  targetId: string;
  targetLabel: string;
  previousValue?: string;
  newValue?: string;
  reason?: string;
  timestamp: string;
}
