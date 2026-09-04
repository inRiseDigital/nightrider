"use client";

// Hook backing the "Users & organizers" directory — party-goers, approved
// organizers and admins in one list. Follows the load()/runAction()
// convention used by useApplicantDetail.ts / useVenueDetail.ts / useRoles.ts,
// built against the UsersViewModel contract in ./view-models.ts and composed
// from the pure helpers in ./filters/users.ts (never reimplemented here).
//
// Status note: docs/FIRESTORE_SCHEMA.md and view-models.ts agree the mockup's
// four states (Active/Suspended/Banned/Deactivated) collapse to Firebase
// Auth's single `disabled` boolean in the real model. The data source carries
// which of the four an admin actually chose (UserModerationState), so this
// hook reads that value rather than guessing intent from reason prose — and a
// suspend/ban here is plain write-then-refetch like every other mutation.

import { useCallback, useEffect, useMemo, useState } from "react";
import { addDoc, serverTimestamp } from "firebase/firestore";
import { dataSource } from "./data-source-instance";
import { userInboxCol } from "../organizer/dashboard/data/refs";
import { deriveUserIdentity, deriveUserRole, matchesUserRole, matchesUserSearch } from "./filters/users";
import {
  simulated,
  type ActionResult,
  type UserDetail,
  type UserModerationState,
  type UserRoleLabel,
  type UserRow,
  type UserTimelineEntry,
} from "./view-models";
import type { UserDirectoryEntry } from "./data-source";

/** The mockup's capitalized status label for a UserModerationState value. */
export type UserDisplayStatus = "Active" | "Suspended" | "Banned" | "Deactivated";
export type UserStatusFilterValue = "all" | UserDisplayStatus;

/** A directory row plus this section's own Active/Suspended/Banned/Deactivated read. */
export type UsersRow = UserRow & { displayStatus: UserDisplayStatus };
export type UsersDetail = UserDetail & { displayStatus: UserDisplayStatus };

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/** `02 Aug 2026` — the mockup's Joined date style. */
function dateLabel(ts: { toDate: () => Date } | null): string {
  if (!ts) return "—";
  const d = ts.toDate();
  return `${String(d.getDate()).padStart(2, "0")} ${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
}

const STATUS_LABEL: Record<UserModerationState, UserDisplayStatus> = {
  active: "Active",
  suspended: "Suspended",
  banned: "Banned",
  deactivated: "Deactivated",
};

const IDENTITY_ICON: Record<string, string> = {
  none: "remove",
  pending: "hourglass_top",
  approved: "verified_user",
  rejected: "report",
  revoked: "block",
};

function buildTimeline(row: UserRow, displayStatus: UserDisplayStatus): UserTimelineEntry[] {
  const entries: UserTimelineEntry[] = [
    { icon: "login", tone: "neutral", text: `Signed in — ${row.device.value}`, timeLabel: row.lastActiveLabel.value },
    { icon: "event_available", tone: "info", text: `RSVP'd to "Full Moon Rooftop" · ${row.city}`, timeLabel: "2 d ago" },
  ];
  if (row.role === "Organizer") {
    entries.push({
      icon: IDENTITY_ICON[row.identity] ?? "verified_user",
      tone: row.identity === "approved" ? "success" : row.identity === "rejected" ? "danger" : "warning",
      text:
        row.identity === "approved"
          ? "Identity verified"
          : row.identity === "pending"
            ? "Identity check started"
            : "No identity document on file",
      timeLabel: "3 w ago",
    });
  }
  entries.push({ icon: "person_add", tone: "neutral", text: `Account created in ${row.city}`, timeLabel: row.joinedLabel });
  if (row.role === "Organizer") {
    entries.splice(1, 0, { icon: "how_to_reg", tone: "success", text: "Approved as organizer", timeLabel: row.joinedLabel });
  }
  if (displayStatus === "Banned") entries.unshift({ icon: "block", tone: "danger", text: "Account banned", timeLabel: "5 h ago" });
  if (displayStatus === "Suspended") entries.unshift({ icon: "pause_circle", tone: "warning", text: "Suspended for 7 days", timeLabel: "1 d ago" });
  return entries;
}

function toUserRow(entry: UserDirectoryEntry): UsersRow {
  const { user } = entry;
  const role = deriveUserRole(user.isAdmin, user.organizerStatus);
  const identity = deriveUserIdentity(role, user.organizerStatus);
  const displayStatus = STATUS_LABEL[entry.moderationState];
  return {
    uid: user.uid,
    name: user.displayName || user.email,
    email: user.email,
    phone: user.phone,
    city: user.city,
    role,
    identity,
    accountState: entry.accountState,
    moderationState: simulated(entry.moderationState),
    displayStatus,
    disabledReasonLabel: entry.disabledReason ? simulated(entry.disabledReason) : null,
    joinedLabel: dateLabel(user.createdAt),
    lastActiveLabel: simulated(entry.lastActiveLabel),
    nightsOut: simulated(entry.nightsOut),
    savedCount: simulated(entry.savedCount),
    device: simulated(entry.device),
    adminScopeLabel: entry.adminScopeLabel ? simulated(entry.adminScopeLabel) : null,
  };
}

function toUserDetail(row: UsersRow, entry: UserDirectoryEntry): UsersDetail {
  return {
    ...row,
    timeline: simulated(buildTimeline(row, row.displayStatus)),
    note: entry.note,
    organizerVenueName: entry.organizerVenueName,
  };
}

export function useUsers(openOrganizerRecord?: (uid: string) => void) {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [entries, setEntries] = useState<UserDirectoryEntry[]>([]);

  const [search, setSearch] = useState("");
  const [role, setRole] = useState<UserRoleLabel | "all">("all");
  const [statusFilter, setStatusFilter] = useState<UserStatusFilterValue>("all");

  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [tab, setTab] = useState<"profile" | "activity">("profile");
  const [noticeOpen, setNoticeOpen] = useState(false);
  const [noticeDraft, setNoticeDraft] = useState("");
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const [actionBusy, setActionBusy] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const all = await dataSource.listUserDirectory({ search: "", role: "all", moderationState: "all" });
      setEntries(all);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load the user directory.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const runAction = useCallback(async (fn: () => Promise<void>): Promise<ActionResult> => {
    setActionBusy(true);
    setActionError(null);
    try {
      await fn();
      await load();
      return { ok: true };
    } catch (err) {
      const message = err instanceof Error ? err.message : "That action failed.";
      setActionError(message);
      return { ok: false, error: message };
    } finally {
      setActionBusy(false);
    }
  }, [load]);

  const allRows: UsersRow[] = useMemo(() => entries.map(toUserRow), [entries]);

  const rows: UsersRow[] = useMemo(() => {
    return allRows.filter((row) => {
      if (!matchesUserSearch({ name: row.name, email: row.email, phone: row.phone }, search)) return false;
      if (!matchesUserRole(row.role, role)) return false;
      if (statusFilter === "all") return true;
      return row.displayStatus === statusFilter;
    });
  }, [allRows, search, role, statusFilter]);

  const stats = useMemo(() => {
    const count = (label: UserDisplayStatus) => allRows.filter((r) => r.displayStatus === label).length;
    const countRole = (r: UserRoleLabel) => allRows.filter((row) => row.role === r).length;
    return [
      { label: "People", value: String(allRows.length), tone: "neutral" as const },
      { label: "Party-goers", value: String(countRole("Party-goer")), tone: "neutral" as const },
      { label: "Organizers", value: String(countRole("Organizer")), tone: "info" as const },
      { label: "Suspended", value: String(count("Suspended")), tone: "warning" as const },
      { label: "Banned", value: String(count("Banned")), tone: "danger" as const },
    ];
  }, [allRows]);

  const select = useCallback((id: string | null) => {
    setSelectedId(id);
    setTab("profile");
    setNoticeOpen(false);
    setNoticeDraft("");
    setConfirmDelete(false);
    setToast(null);
    setActionError(null);
  }, []);

  const selectedEntry = selectedId ? entries.find((e) => e.user.uid === selectedId) ?? null : null;
  const selectedRow = selectedId ? allRows.find((r) => r.uid === selectedId) ?? null : null;
  const detail: UsersDetail | null = selectedEntry && selectedRow ? toUserDetail(selectedRow, selectedEntry) : null;

  const setModerationState = useCallback(
    async (uid: string, state: UserModerationState): Promise<ActionResult> => {
      return runAction(() => dataSource.setUserModerationState(uid, state, ""));
    },
    [runAction],
  );

  const moveTo = useCallback(
    async (state: UserModerationState) => {
      if (!detail) return;
      const result = await setModerationState(detail.uid, state);
      if (result.ok) setToast(`Status set to ${STATUS_LABEL[state]}`);
    },
    [detail, setModerationState],
  );

  const toggleSuspend = useCallback(async () => {
    if (!detail) return;
    await moveTo(detail.displayStatus === "Suspended" ? "active" : "suspended");
  }, [detail, moveTo]);

  const toggleBan = useCallback(async () => {
    if (!detail) return;
    await moveTo(detail.displayStatus === "Banned" ? "active" : "banned");
  }, [detail, moveTo]);

  const resetPassword = useCallback(() => {
    setToast("Password reset link sent");
    setNoticeOpen(false);
    setConfirmDelete(false);
  }, []);

  const exportData = useCallback(() => {
    setToast("Data export queued — emailed when ready");
    setNoticeOpen(false);
    setConfirmDelete(false);
  }, []);

  const openNotice = useCallback(() => {
    setNoticeOpen((open) => !open);
    setToast(null);
  }, []);

  const sendNotice = useCallback(async () => {
    if (!detail || !noticeDraft.trim()) return;
    const result = await runAction(async () => {
      await addDoc(userInboxCol(detail.uid), {
        subject: "A message from Night Ride",
        from: "Night Ride admin team",
        type: "policy",
        body: noticeDraft.trim(),
        at: serverTimestamp(),
      });
    });
    if (result.ok) {
      setNoticeOpen(false);
      setNoticeDraft("");
      setToast("Notice sent to their app");
    }
  }, [detail, noticeDraft, runAction]);

  const askDelete = useCallback(() => {
    setConfirmDelete((open) => !open);
  }, []);

  const confirmDeleteAccount = useCallback(async () => {
    if (!detail) return;
    const result = await runAction(async () => {
      const res = await fetch("/api/admin/account", {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ uid: detail.uid }),
      });
      if (!res.ok) throw new Error("Couldn't schedule this account for deletion.");
    });
    if (result.ok) {
      setConfirmDelete(false);
      setToast("Account scheduled for deletion in 30 days");
    }
  }, [detail, runAction]);

  const openOrganizer = useCallback(() => {
    if (detail && openOrganizerRecord) openOrganizerRecord(detail.uid);
  }, [detail, openOrganizerRecord]);

  return {
    loading,
    error,
    rows,
    stats,
    filter: { search, role, statusFilter },
    setSearch,
    setRole,
    setStatusFilter,
    selectedId,
    select,
    detail,
    tab,
    setTab,
    setModerationState,
    toggleSuspend,
    toggleBan,
    resetPassword,
    exportData,
    noticeOpen,
    noticeDraft,
    setNoticeDraft,
    openNotice,
    sendNotice,
    confirmDelete,
    askDelete,
    confirmDeleteAccount,
    openOrganizer,
    toast,
    actionBusy,
    actionError,
    refresh: () => void load(),
  };
}

export type Users = ReturnType<typeof useUsers>;
