"use client";

import Link from "next/link";
import { useMemo } from "react";
import {
  Users,
  UserCheck,
  UserX,
  UserCog,
  Ban,
  PauseCircle,
  Building2,
  CalendarClock,
  CalendarX,
  ArrowRight,
} from "lucide-react";
import { useAdminData } from "@/lib/admin/store";
import { StatCard, Card, CardHeader } from "@/components/admin/ui/Card";
import { Badge } from "@/components/admin/ui/Badge";
import { TimeAgo } from "@/components/admin/ui/TimeAgo";
import { EmptyState } from "@/components/admin/ui/EmptyState";
import { ACTIVITY_ACTION_LABELS } from "@/lib/admin/constants";

export default function DashboardPage() {
  const { users, clubs, events, activityLog } = useAdminData();

  const stats = useMemo(() => {
    const verified = users.filter((u) => u.verificationStatus === "verified").length;
    const unverified = users.length - verified;
    const activeOrganizers = users.filter((u) => u.isOrganizer && u.accountStatus === "active").length;
    const deactivated = users.filter((u) => u.accountStatus === "deactivated").length;
    const banned = users.filter((u) => u.accountStatus === "banned").length;
    const upcoming = events.filter((e) => ["scheduled", "starting_soon", "ongoing"].includes(e.status)).length;
    const cancelled = events.filter((e) => e.status === "cancelled" || e.status === "emergency_closure").length;
    const pendingOrganizers = users.filter((u) => u.organizerDetails?.approvalStatus === "pending").length;
    const pendingClubs = clubs.filter((c) => c.approvalStatus === "pending").length;

    return {
      totalUsers: users.length,
      verified,
      unverified,
      activeOrganizers,
      deactivated,
      banned,
      totalClubs: clubs.length,
      upcoming,
      cancelled,
      pendingOrganizers,
      pendingClubs,
    };
  }, [users, clubs, events]);

  const recentActivity = activityLog.slice(0, 8);

  return (
    <div className="space-y-6">
      {(stats.pendingOrganizers > 0 || stats.pendingClubs > 0) && (
        <div className="flex flex-wrap items-center gap-3 rounded-2xl border border-amber-500/20 bg-amber-500/5 px-5 py-4">
          <p className="text-sm text-amber-200">
            <span className="font-medium">{stats.pendingOrganizers}</span> organizer request(s) and{" "}
            <span className="font-medium">{stats.pendingClubs}</span> club submission(s) need review.
          </p>
          <div className="ml-auto flex gap-3 text-sm">
            <Link href="/admin/organizers" className="flex items-center gap-1 text-amber-300 hover:underline">
              Review organizers <ArrowRight size={14} />
            </Link>
            <Link href="/admin/clubs" className="flex items-center gap-1 text-amber-300 hover:underline">
              Review clubs <ArrowRight size={14} />
            </Link>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Total Users" value={stats.totalUsers} icon={Users} tone="primary" />
        <StatCard label="Verified Users" value={stats.verified} icon={UserCheck} tone="accent" />
        <StatCard label="Unverified Users" value={stats.unverified} icon={UserX} />
        <StatCard label="Active Organizers" value={stats.activeOrganizers} icon={UserCog} tone="accent" />
        <StatCard label="Deactivated Users" value={stats.deactivated} icon={PauseCircle} />
        <StatCard label="Banned Users" value={stats.banned} icon={Ban} tone="danger" />
        <StatCard label="Total Clubs" value={stats.totalClubs} icon={Building2} tone="primary" />
        <StatCard label="Upcoming Events" value={stats.upcoming} icon={CalendarClock} tone="accent" />
        <StatCard label="Cancelled Events" value={stats.cancelled} icon={CalendarX} tone="danger" />
      </div>

      <Card>
        <CardHeader
          title="Recent admin activity"
          description="Latest actions performed across the platform"
          action={
            <Link href="/admin/activity" className="flex items-center gap-1 text-sm text-nr-primary-light hover:underline">
              View all <ArrowRight size={14} />
            </Link>
          }
        />
        {recentActivity.length === 0 ? (
          <EmptyState title="No activity yet" description="Admin actions will show up here as they happen." />
        ) : (
          <ul className="divide-y divide-nr-border">
            {recentActivity.map((entry) => (
              <li key={entry.id} className="flex items-center justify-between gap-4 px-5 py-3">
                <div className="min-w-0">
                  <p className="truncate text-sm text-nr-text-primary">
                    <span className="font-medium">{entry.adminName}</span>{" "}
                    <span className="text-nr-text-secondary">{ACTIVITY_ACTION_LABELS[entry.actionType].toLowerCase()}</span>
                    {" — "}
                    <span className="text-nr-text-secondary">{entry.targetLabel}</span>
                  </p>
                </div>
                <div className="flex shrink-0 items-center gap-3">
                  <Badge variant="neutral">{entry.targetType}</Badge>
                  <span className="text-xs text-nr-text-hint">
                    <TimeAgo iso={entry.timestamp} />
                  </span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </Card>
    </div>
  );
}
