"use client";

import { createContext, useCallback, useContext, useMemo, useState, ReactNode } from "react";
import {
  AccountStatus,
  ActivityActionType,
  ActivityLogEntry,
  ActivityTargetType,
  AdminAccessLevel,
  ApprovalStatus,
  Club,
  ClubStatus,
  EventRecord,
  EventStatus,
  PermissionKey,
  PlatformUser,
  Role,
  RolePermissionMap,
} from "./types";
import {
  DEFAULT_ROLE_PERMISSIONS,
  MOCK_CURRENT_ADMIN_ID,
} from "./constants";
import { MOCK_ACTIVITY_LOG, MOCK_CLUBS, MOCK_EVENTS, MOCK_USERS } from "./mock-data";

export function cloneRolePermissions(matrix: RolePermissionMap): RolePermissionMap {
  return Object.fromEntries(
    Object.entries(matrix).map(([role, perms]) => [role, { ...perms }])
  ) as RolePermissionMap;
}

let logCounter = 0;
function makeLogId() {
  logCounter += 1;
  return `log_local_${logCounter}`;
}

interface LogInput {
  actionType: ActivityActionType;
  targetType: ActivityTargetType;
  targetId: string;
  targetLabel: string;
  previousValue?: string;
  newValue?: string;
  reason?: string;
}

interface AdminDataContextValue {
  users: PlatformUser[];
  clubs: Club[];
  events: EventRecord[];
  activityLog: ActivityLogEntry[];
  rolePermissions: RolePermissionMap;
  currentAdmin: PlatformUser;

  // Users / organizers / admins share the same underlying `users` collection.
  verifyUser: (id: string) => void;
  unverifyUser: (id: string) => void;
  activateUser: (id: string) => void;
  deactivateUser: (id: string, reason?: string) => void;
  banUser: (id: string, reason?: string) => void;
  unbanUser: (id: string) => void;
  changeUserRole: (id: string, role: Role, reason?: string) => void;
  addAdminNote: (id: string, note: string) => void;

  promoteToOrganizer: (id: string, clubId?: string | null) => void;
  removeOrganizerAccess: (id: string, reason?: string) => void;
  approveOrganizer: (id: string) => void;
  rejectOrganizer: (id: string, reason?: string) => void;
  assignOrganizerClub: (id: string, clubId: string | null) => void;

  grantAdminAccess: (
    id: string,
    accessLevel: AdminAccessLevel,
    permissionOverrides?: Partial<Record<PermissionKey, boolean>>
  ) => void;
  removeAdminAccess: (id: string, reason?: string) => void;

  approveClub: (id: string) => void;
  rejectClub: (id: string, reason?: string) => void;
  editClub: (id: string, patch: Partial<Club>) => void;
  setClubStatus: (id: string, status: ClubStatus, reason?: string) => void;
  deleteClub: (id: string, reason?: string) => void;

  editEvent: (id: string, patch: Partial<EventRecord>) => void;
  changeEventStatus: (id: string, status: EventStatus, reason?: string) => void;
  cancelEvent: (id: string, reason: string) => void;
  deleteEvent: (id: string, reason?: string) => void;

  saveRolePermissions: (matrix: RolePermissionMap) => void;
}

const AdminDataContext = createContext<AdminDataContextValue | null>(null);

export function AdminDataProvider({ children }: { children: ReactNode }) {
  const [users, setUsers] = useState<PlatformUser[]>(MOCK_USERS);
  const [clubs, setClubs] = useState<Club[]>(MOCK_CLUBS);
  const [events, setEvents] = useState<EventRecord[]>(MOCK_EVENTS);
  const [activityLog, setActivityLog] = useState<ActivityLogEntry[]>(MOCK_ACTIVITY_LOG);
  const [rolePermissions, setRolePermissions] = useState<RolePermissionMap>(() =>
    cloneRolePermissions(DEFAULT_ROLE_PERMISSIONS)
  );

  const currentAdmin = useMemo(
    () => users.find((u) => u.id === MOCK_CURRENT_ADMIN_ID) ?? users[0],
    [users]
  );

  const pushLog = useCallback(
    (input: LogInput) => {
      const entry: ActivityLogEntry = {
        id: makeLogId(),
        adminId: currentAdmin.id,
        adminName: currentAdmin.fullName,
        timestamp: new Date().toISOString(),
        ...input,
      };
      setActivityLog((prev) => [entry, ...prev]);
    },
    [currentAdmin.id, currentAdmin.fullName]
  );

  const patchUser = useCallback((id: string, patch: Partial<PlatformUser>) => {
    setUsers((prev) => prev.map((u) => (u.id === id ? { ...u, ...patch } : u)));
  }, []);

  const findUser = useCallback((id: string) => users.find((u) => u.id === id), [users]);

  const verifyUser = useCallback(
    (id: string) => {
      patchUser(id, { verificationStatus: "verified" });
      const u = findUser(id);
      pushLog({
        actionType: "user_verified",
        targetType: "user",
        targetId: id,
        targetLabel: u?.fullName ?? id,
        previousValue: "unverified",
        newValue: "verified",
      });
    },
    [patchUser, findUser, pushLog]
  );

  const unverifyUser = useCallback(
    (id: string) => {
      patchUser(id, { verificationStatus: "unverified" });
      const u = findUser(id);
      pushLog({
        actionType: "user_unverified",
        targetType: "user",
        targetId: id,
        targetLabel: u?.fullName ?? id,
        previousValue: "verified",
        newValue: "unverified",
      });
    },
    [patchUser, findUser, pushLog]
  );

  const setAccountStatus = useCallback(
    (id: string, status: AccountStatus, actionType: ActivityActionType, reason?: string) => {
      const u = findUser(id);
      const previousValue = u?.accountStatus;
      patchUser(id, { accountStatus: status });
      pushLog({
        actionType,
        targetType: "user",
        targetId: id,
        targetLabel: u?.fullName ?? id,
        previousValue,
        newValue: status,
        reason,
      });
    },
    [patchUser, findUser, pushLog]
  );

  const activateUser = useCallback((id: string) => setAccountStatus(id, "active", "user_activated"), [setAccountStatus]);
  const deactivateUser = useCallback(
    (id: string, reason?: string) => setAccountStatus(id, "deactivated", "user_deactivated", reason),
    [setAccountStatus]
  );
  const banUser = useCallback(
    (id: string, reason?: string) => setAccountStatus(id, "banned", "user_banned", reason),
    [setAccountStatus]
  );
  const unbanUser = useCallback((id: string) => setAccountStatus(id, "active", "user_unbanned"), [setAccountStatus]);

  const changeUserRole = useCallback(
    (id: string, role: Role, reason?: string) => {
      const u = findUser(id);
      patchUser(id, { role });
      pushLog({
        actionType: "role_changed",
        targetType: "user",
        targetId: id,
        targetLabel: u?.fullName ?? id,
        previousValue: u?.role,
        newValue: role,
        reason,
      });
    },
    [patchUser, findUser, pushLog]
  );

  const addAdminNote = useCallback(
    (id: string, note: string) => {
      setUsers((prev) =>
        prev.map((u) =>
          u.id === id
            ? {
                ...u,
                adminNotes: [
                  { id: `note_${id}_${u.adminNotes.length + 1}`, author: currentAdmin.fullName, note, createdAt: new Date().toISOString() },
                  ...u.adminNotes,
                ],
              }
            : u
        )
      );
    },
    [currentAdmin.fullName]
  );

  const promoteToOrganizer = useCallback(
    (id: string, clubId: string | null = null) => {
      const u = findUser(id);
      patchUser(id, {
        isOrganizer: true,
        role: "organizer",
        organizerDetails: {
          approvalStatus: "approved",
          clubId,
          eventsCreated: 0,
          recentActivity: [],
        },
      });
      if (clubId) {
        setClubs((prev) =>
          prev.map((c) => (c.id === clubId ? { ...c, organizerId: id, organizerName: u?.fullName ?? id } : c))
        );
      }
      pushLog({
        actionType: "organizer_promoted",
        targetType: "user",
        targetId: id,
        targetLabel: u?.fullName ?? id,
        newValue: "organizer",
      });
    },
    [findUser, patchUser, pushLog]
  );

  const removeOrganizerAccess = useCallback(
    (id: string, reason?: string) => {
      const u = findUser(id);
      patchUser(id, { isOrganizer: false, role: u?.isAdmin ? "admin" : "verified", organizerDetails: undefined });
      pushLog({
        actionType: "organizer_access_removed",
        targetType: "organizer",
        targetId: id,
        targetLabel: u?.fullName ?? id,
        reason,
      });
    },
    [findUser, patchUser, pushLog]
  );

  const approveOrganizer = useCallback(
    (id: string) => {
      const u = findUser(id);
      if (!u?.organizerDetails) return;
      patchUser(id, { organizerDetails: { ...u.organizerDetails, approvalStatus: "approved" } });
      pushLog({
        actionType: "organizer_approved",
        targetType: "organizer",
        targetId: id,
        targetLabel: u.fullName,
        newValue: "approved",
      });
    },
    [findUser, patchUser, pushLog]
  );

  const rejectOrganizer = useCallback(
    (id: string, reason?: string) => {
      const u = findUser(id);
      if (!u?.organizerDetails) return;
      patchUser(id, { organizerDetails: { ...u.organizerDetails, approvalStatus: "rejected" } });
      pushLog({
        actionType: "organizer_rejected",
        targetType: "organizer",
        targetId: id,
        targetLabel: u.fullName,
        newValue: "rejected",
        reason,
      });
    },
    [findUser, patchUser, pushLog]
  );

  const assignOrganizerClub = useCallback(
    (id: string, clubId: string | null) => {
      const u = findUser(id);
      if (!u?.organizerDetails) return;
      const previousClub = clubs.find((c) => c.id === u.organizerDetails?.clubId)?.name;
      patchUser(id, { organizerDetails: { ...u.organizerDetails, clubId } });
      setClubs((prev) =>
        prev.map((c) => {
          if (c.id === clubId) return { ...c, organizerId: id, organizerName: u.fullName };
          if (c.organizerId === id && c.id !== clubId) return { ...c, organizerId: null, organizerName: null };
          return c;
        })
      );
      const newClub = clubs.find((c) => c.id === clubId)?.name;
      pushLog({
        actionType: "organizer_club_assigned",
        targetType: "organizer",
        targetId: id,
        targetLabel: u.fullName,
        previousValue: previousClub,
        newValue: newClub,
      });
    },
    [findUser, patchUser, clubs, pushLog]
  );

  const grantAdminAccess = useCallback(
    (id: string, accessLevel: AdminAccessLevel, permissionOverrides?: Partial<Record<PermissionKey, boolean>>) => {
      const u = findUser(id);
      patchUser(id, {
        isAdmin: true,
        role: "admin",
        adminDetails: {
          accessLevel,
          grantedAt: new Date().toISOString(),
          grantedBy: currentAdmin.fullName,
          permissionOverrides,
        },
      });
      pushLog({
        actionType: "admin_access_granted",
        targetType: "admin",
        targetId: id,
        targetLabel: u?.fullName ?? id,
        newValue: accessLevel,
      });
    },
    [findUser, patchUser, currentAdmin.fullName, pushLog]
  );

  const removeAdminAccess = useCallback(
    (id: string, reason?: string) => {
      const u = findUser(id);
      patchUser(id, { isAdmin: false, role: u?.isOrganizer ? "organizer" : "verified", adminDetails: undefined });
      pushLog({
        actionType: "admin_access_removed",
        targetType: "admin",
        targetId: id,
        targetLabel: u?.fullName ?? id,
        reason,
      });
    },
    [findUser, patchUser, pushLog]
  );

  const findClub = useCallback((id: string) => clubs.find((c) => c.id === id), [clubs]);

  const approveClub = useCallback(
    (id: string) => {
      const c = findClub(id);
      setClubs((prev) => prev.map((x) => (x.id === id ? { ...x, approvalStatus: "approved" as ApprovalStatus } : x)));
      pushLog({ actionType: "club_approved", targetType: "club", targetId: id, targetLabel: c?.name ?? id, newValue: "approved" });
    },
    [findClub, pushLog]
  );

  const rejectClub = useCallback(
    (id: string, reason?: string) => {
      const c = findClub(id);
      setClubs((prev) => prev.map((x) => (x.id === id ? { ...x, approvalStatus: "rejected" as ApprovalStatus } : x)));
      pushLog({ actionType: "club_rejected", targetType: "club", targetId: id, targetLabel: c?.name ?? id, newValue: "rejected", reason });
    },
    [findClub, pushLog]
  );

  const editClub = useCallback(
    (id: string, patch: Partial<Club>) => {
      const c = findClub(id);
      setClubs((prev) =>
        prev.map((x) => (x.id === id ? { ...x, ...patch, lastUpdatedAt: new Date().toISOString() } : x))
      );
      pushLog({ actionType: "club_edited", targetType: "club", targetId: id, targetLabel: c?.name ?? id });
    },
    [findClub, pushLog]
  );

  const setClubStatus = useCallback(
    (id: string, status: ClubStatus, reason?: string) => {
      const c = findClub(id);
      setClubs((prev) => prev.map((x) => (x.id === id ? { ...x, status } : x)));
      pushLog({
        actionType: "club_deactivated",
        targetType: "club",
        targetId: id,
        targetLabel: c?.name ?? id,
        previousValue: c?.status,
        newValue: status,
        reason,
      });
    },
    [findClub, pushLog]
  );

  const deleteClub = useCallback(
    (id: string, reason?: string) => {
      const c = findClub(id);
      setClubs((prev) => prev.filter((x) => x.id !== id));
      pushLog({ actionType: "club_deleted", targetType: "club", targetId: id, targetLabel: c?.name ?? id, reason });
    },
    [findClub, pushLog]
  );

  const findEvent = useCallback((id: string) => events.find((e) => e.id === id), [events]);

  const editEvent = useCallback(
    (id: string, patch: Partial<EventRecord>) => {
      const e = findEvent(id);
      setEvents((prev) => prev.map((x) => (x.id === id ? { ...x, ...patch } : x)));
      pushLog({ actionType: "event_edited", targetType: "event", targetId: id, targetLabel: e?.title ?? id });
    },
    [findEvent, pushLog]
  );

  const changeEventStatus = useCallback(
    (id: string, status: EventStatus, reason?: string) => {
      const e = findEvent(id);
      setEvents((prev) =>
        prev.map((x) =>
          x.id === id
            ? {
                ...x,
                status,
                statusHistory: [
                  ...x.statusHistory,
                  { status, changedAt: new Date().toISOString(), changedBy: currentAdmin.fullName, reason },
                ],
              }
            : x
        )
      );
      pushLog({
        actionType: "event_status_changed",
        targetType: "event",
        targetId: id,
        targetLabel: e?.title ?? id,
        previousValue: e?.status,
        newValue: status,
        reason,
      });
    },
    [findEvent, currentAdmin.fullName, pushLog]
  );

  const cancelEvent = useCallback(
    (id: string, reason: string) => {
      const e = findEvent(id);
      setEvents((prev) =>
        prev.map((x) =>
          x.id === id
            ? {
                ...x,
                status: "cancelled" as EventStatus,
                cancellationReason: reason,
                statusHistory: [
                  ...x.statusHistory,
                  { status: "cancelled" as EventStatus, changedAt: new Date().toISOString(), changedBy: currentAdmin.fullName, reason },
                ],
              }
            : x
        )
      );
      pushLog({
        actionType: "event_cancelled",
        targetType: "event",
        targetId: id,
        targetLabel: e?.title ?? id,
        previousValue: e?.status,
        newValue: "cancelled",
        reason,
      });
    },
    [findEvent, currentAdmin.fullName, pushLog]
  );

  const deleteEvent = useCallback(
    (id: string, reason?: string) => {
      const e = findEvent(id);
      setEvents((prev) => prev.filter((x) => x.id !== id));
      pushLog({ actionType: "event_deleted", targetType: "event", targetId: id, targetLabel: e?.title ?? id, reason });
    },
    [findEvent, pushLog]
  );

  const saveRolePermissions = useCallback(
    (matrix: RolePermissionMap) => {
      setRolePermissions(matrix);
      pushLog({
        actionType: "permission_changed",
        targetType: "role",
        targetId: "multiple",
        targetLabel: "Role permission matrix",
        newValue: "Saved updated permission matrix",
      });
    },
    [pushLog]
  );

  const value: AdminDataContextValue = useMemo(
    () => ({
      users,
      clubs,
      events,
      activityLog,
      rolePermissions,
      currentAdmin,
      verifyUser,
      unverifyUser,
      activateUser,
      deactivateUser,
      banUser,
      unbanUser,
      changeUserRole,
      addAdminNote,
      promoteToOrganizer,
      removeOrganizerAccess,
      approveOrganizer,
      rejectOrganizer,
      assignOrganizerClub,
      grantAdminAccess,
      removeAdminAccess,
      approveClub,
      rejectClub,
      editClub,
      setClubStatus,
      deleteClub,
      editEvent,
      changeEventStatus,
      cancelEvent,
      deleteEvent,
      saveRolePermissions,
    }),
    [
      users,
      clubs,
      events,
      activityLog,
      rolePermissions,
      currentAdmin,
      verifyUser,
      unverifyUser,
      activateUser,
      deactivateUser,
      banUser,
      unbanUser,
      changeUserRole,
      addAdminNote,
      promoteToOrganizer,
      removeOrganizerAccess,
      approveOrganizer,
      rejectOrganizer,
      assignOrganizerClub,
      grantAdminAccess,
      removeAdminAccess,
      approveClub,
      rejectClub,
      editClub,
      setClubStatus,
      deleteClub,
      editEvent,
      changeEventStatus,
      cancelEvent,
      deleteEvent,
      saveRolePermissions,
    ]
  );

  return <AdminDataContext.Provider value={value}>{children}</AdminDataContext.Provider>;
}

export function useAdminData() {
  const ctx = useContext(AdminDataContext);
  if (!ctx) throw new Error("useAdminData must be used within an AdminDataProvider");
  return ctx;
}
