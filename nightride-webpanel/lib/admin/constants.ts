import {
  ActivityActionType,
  AdminAccessLevel,
  PermissionKey,
  Role,
  RolePermissionMap,
} from "./types";

export const ROLES: Role[] = ["user", "verified", "organizer", "admin"];

export const ROLE_LABELS: Record<Role, string> = {
  user: "User",
  verified: "Verified User",
  organizer: "Organizer",
  admin: "Admin",
};

export const PERMISSION_LABELS: Record<PermissionKey, string> = {
  view_club_info: "View club information",
  submit_club_info: "Submit club information",
  edit_club_info: "Edit club information",
  create_events: "Create events",
  edit_events: "Edit events",
  cancel_events: "Cancel events",
  publish_emergency_closures: "Publish emergency closures",
  manage_users: "Manage users",
  manage_roles: "Manage roles",
  manage_admins: "Manage admins",
  delete_records: "Delete records",
  view_activity_logs: "View activity logs",
};

export const PERMISSION_GROUPS: { label: string; keys: PermissionKey[] }[] = [
  { label: "Club", keys: ["view_club_info", "submit_club_info", "edit_club_info"] },
  {
    label: "Events",
    keys: ["create_events", "edit_events", "cancel_events", "publish_emergency_closures"],
  },
  {
    label: "Administration",
    keys: ["manage_users", "manage_roles", "manage_admins", "delete_records", "view_activity_logs"],
  },
];

// Default role -> permission matrix. Deep-cloned by consumers before mutating.
export const DEFAULT_ROLE_PERMISSIONS: RolePermissionMap = {
  user: {
    view_club_info: true,
    submit_club_info: false,
    edit_club_info: false,
    create_events: false,
    edit_events: false,
    cancel_events: false,
    publish_emergency_closures: false,
    manage_users: false,
    manage_roles: false,
    manage_admins: false,
    delete_records: false,
    view_activity_logs: false,
  },
  verified: {
    view_club_info: true,
    submit_club_info: true,
    edit_club_info: false,
    create_events: false,
    edit_events: false,
    cancel_events: false,
    publish_emergency_closures: false,
    manage_users: false,
    manage_roles: false,
    manage_admins: false,
    delete_records: false,
    view_activity_logs: false,
  },
  organizer: {
    view_club_info: true,
    submit_club_info: true,
    edit_club_info: true,
    create_events: true,
    edit_events: true,
    cancel_events: true,
    publish_emergency_closures: true,
    manage_users: false,
    manage_roles: false,
    manage_admins: false,
    delete_records: false,
    view_activity_logs: false,
  },
  admin: {
    view_club_info: true,
    submit_club_info: true,
    edit_club_info: true,
    create_events: true,
    edit_events: true,
    cancel_events: true,
    publish_emergency_closures: true,
    manage_users: true,
    manage_roles: true,
    manage_admins: true,
    delete_records: true,
    view_activity_logs: true,
  },
};

export const ADMIN_ACCESS_LEVEL_LABELS: Record<AdminAccessLevel, string> = {
  super_admin: "Super Admin",
  admin: "Admin",
  moderator: "Moderator",
};

export const ACTIVITY_ACTION_LABELS: Record<ActivityActionType, string> = {
  user_verified: "User verification changed",
  user_unverified: "User verification changed",
  user_activated: "User activated",
  user_deactivated: "User deactivated",
  user_banned: "User banned",
  user_unbanned: "User unbanned",
  role_changed: "Role changed",
  permission_changed: "Permission changed",
  organizer_promoted: "User promoted to organizer",
  organizer_approved: "Organizer approved",
  organizer_rejected: "Organizer rejected",
  organizer_access_removed: "Organizer access removed",
  organizer_club_assigned: "Organizer club assigned",
  admin_access_granted: "Admin access granted",
  admin_access_removed: "Admin access removed",
  club_approved: "Club approved",
  club_rejected: "Club rejected",
  club_edited: "Club edited",
  club_deactivated: "Club deactivated",
  club_deleted: "Club deleted",
  event_edited: "Event edited",
  event_status_changed: "Event status changed",
  event_cancelled: "Event cancelled",
  event_deleted: "Event deleted",
};

export const MOCK_CURRENT_ADMIN_ID = "usr_admin_001";
