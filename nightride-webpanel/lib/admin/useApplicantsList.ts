"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { listApplicantUsers } from "./firestore";
import type { UserRecord } from "./schema";
import { organizerStatusLabel } from "./present";

export function useApplicantsList() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [users, setUsers] = useState<UserRecord[]>([]);
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState("all");

  const load = useCallback(() => {
    listApplicantUsers()
      .then((u) => {
        setUsers(u);
        setError(null);
      })
      .catch((err) => setError(err instanceof Error ? err.message : "Failed to load applicants."))
      .finally(() => setLoading(false));
  }, []);

  // Initial mount only relies on the `useState(true)` default above — setting
  // it again synchronously in the effect body just to reset-then-refetch would
  // trigger an extra render for no visible change.
  useEffect(() => load(), [load]);

  const refresh = useCallback(() => {
    setLoading(true);
    load();
  }, [load]);

  const matches = useMemo(() => {
    const q = search.trim().toLowerCase();
    return (u: UserRecord) =>
      (!q || u.displayName.toLowerCase().includes(q) || u.email.toLowerCase().includes(q)) &&
      (filter === "all" || organizerStatusLabel(u.organizerStatus) === filter);
  }, [search, filter]);

  const filtered = users.filter(matches);
  const untriaged = filtered.filter((u) => u.organizerStatus === "none");
  const pending = filtered.filter((u) => u.organizerStatus === "pending");
  const approved = filtered.filter((u) => u.organizerStatus === "approved");
  const rejected = filtered.filter((u) => u.organizerStatus === "rejected");

  return { loading, error, search, setSearch, filter, setFilter, untriaged, pending, approved, rejected, refresh };
}

export type ApplicantsList = ReturnType<typeof useApplicantsList>;
