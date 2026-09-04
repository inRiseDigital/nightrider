"use client";

// View-model hook for the Audit log section — see lib/admin/view-models.ts's
// AuditViewModel/AuditRow (the contract) and lib/admin/filters/audit.ts (the
// pure filter/derivation helpers this hook composes; it does not reimplement
// any of that logic). Read-only: no mutations, no runAction.

import { useCallback, useEffect, useState } from "react";
import type { Timestamp } from "firebase/firestore";
import { dataSource } from "./data-source-instance";
import type { AuditFilter, AuditLogEntry } from "./data-source";
import { auditActionType, auditTypeTone, initialsFor } from "./filters/audit";
import { simulated, type AuditFilterState, type AuditRange, type AuditRow, type AuditTypeBadge } from "./view-models";

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/** `D Mon YYYY · HH:MM` — the mockup's audit timestamp style, 24h clock. */
function formatAuditTime(at: Timestamp | null): string {
  if (!at) return "—";
  const d = at.toDate();
  const hh = String(d.getHours()).padStart(2, "0");
  const mm = String(d.getMinutes()).padStart(2, "0");
  return `${d.getDate()} ${MONTHS[d.getMonth()]} ${d.getFullYear()} · ${hh}:${mm}`;
}

function toAuditRow(entry: AuditLogEntry): AuditRow {
  const type = auditActionType(entry.log.action);
  const isSystemActor = entry.actorLabel === "System";
  return {
    id: entry.log.id,
    // Fabricated log rows (see AuditLogEntry's union) carry a pre-formatted
    // atLabel since they have no real Timestamp; real LogEntry rows format
    // their `at` Timestamp here.
    timeLabel: "atLabel" in entry.log ? entry.log.atLabel : formatAuditTime(entry.log.at),
    actorLabel: entry.actorLabel,
    actorInitials: initialsFor(entry.actorLabel),
    isSystemActor,
    action: entry.log.action,
    actionLabel: entry.log.summary,
    target: entry.log.targetId,
    type,
    tone: auditTypeTone(type),
    cityLabel: simulated(entry.cityLabel),
  };
}

const EMPTY_FILTER: AuditFilter = { actor: "all", type: "all", range: "all", search: "" };

export function useAudit() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [rows, setRows] = useState<AuditRow[]>([]);
  const [total, setTotal] = useState(0);
  const [actors, setActors] = useState<string[]>([]);
  const [actor, setActor] = useState<string | "all">("all");
  const [type, setType] = useState<AuditTypeBadge | "all">("all");
  const [range, setRange] = useState<AuditRange>("7d");
  const [search, setSearch] = useState("");

  const load = useCallback(() => {
    const filter: AuditFilter = { actor, type, range, search };
    Promise.all([dataSource.listAudit(filter), dataSource.listAudit(EMPTY_FILTER)])
      .then(([filtered, all]) => {
        setRows(filtered.map(toAuditRow));
        setTotal(all.length);
        setActors(Array.from(new Set(all.map((e) => e.actorLabel))));
        setError(null);
      })
      .catch((err) => setError(err instanceof Error ? err.message : "Failed to load audit log."))
      .finally(() => setLoading(false));
  }, [actor, type, range, search]);

  // Initial mount only relies on the `useState(true)` default above — see
  // useApplicantsList.ts for the same reasoning.
  useEffect(() => {
    void load();
  }, [load]);

  const refresh = useCallback(() => {
    setLoading(true);
    void load();
  }, [load]);

  const filter: AuditFilterState = { actor, type, range, search };
  const countLabel = `${rows.length} of ${total} entries`;

  return { loading, error, rows, countLabel, actors, filter, setActor, setType, setRange, setSearch, refresh };
}

export type Audit = ReturnType<typeof useAudit>;
