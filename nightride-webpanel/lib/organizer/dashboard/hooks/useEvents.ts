"use client";

import { useCallback, useMemo, useState } from "react";
import { MOCK_EVENTS } from "../mock-data";
import type { OrganizerEvent, VenueProfile } from "../types";
import { useAsyncAction } from "./useAsyncAction";
import { useEventEditor } from "./useEventEditor";

/** Status filter above the events table — "all" plus the statuses worth filtering by. */
export type EventFilter = "all" | "in_review" | "scheduled" | "live" | "draft";
export type EventsTab = "list" | "calendar";

export function blankEventDraft(date: string | undefined, venueId: string): OrganizerEvent {
  return {
    id: "",
    name: "",
    venue: venueId,
    date: date ?? "",
    startTime: "22:00",
    endTime: "04:00",
    lineup: [],
    tiers: [],
    status: "draft",
    recurring: false,
    recurrenceLabel: "",
    scheduledPublish: "",
    notifyOnChange: true,
    moderationFlag: "",
    moderationEta: "",
    cancelReason: "",
    sold: 0,
    revenue: 0,
  };
}

/**
 * Events list, the day-editor dialog, the cancel-flow dialog, and the
 * calendar tab's own filters — one `events/{id}` collection, one hook, one
 * context. `venues`/`venueOrder` are read-only inputs (picking the first
 * verified venue for a new draft); `showSnack` is the `Ui` context's.
 */
export function useEvents(
  venues: Record<string, VenueProfile>,
  venueOrder: string[],
  showSnack: (text: string, tone?: "info" | "error") => void
) {
  const [events, setEvents] = useState<OrganizerEvent[]>(MOCK_EVENTS);
  const [eventFilter, setEventFilter] = useState<EventFilter>("all");
  const [eventsTab, setEventsTab] = useState<EventsTab>("list");
  const [cancelingEventId, setCancelingEventId] = useState<string | null>(null);
  const [cancelReasonInput, setCancelReasonInput] = useState("");
  const [calendarOffset, setCalendarOffset] = useState(0);
  const [calendarVenueFilter, setCalendarVenueFilter] = useState("all");
  const [dayDialog, setDayDialog] = useState<{ iso: string; label: string } | null>(null);

  const editor = useEventEditor();
  const { busy, actionError, run } = useAsyncAction();

  const openNewEvent = useCallback(
    (date?: string) => {
      const firstVerified = venueOrder.find((id) => venues[id]?.verified) ?? venueOrder[0];
      editor.open(null, blankEventDraft(date, firstVerified));
    },
    [venueOrder, venues, editor]
  );

  const openEditEvent = useCallback(
    (id: string) => {
      const ev = events.find((e) => e.id === id);
      if (!ev) return;
      editor.open(id, { ...ev, lineup: [...ev.lineup], tiers: ev.tiers.map((t) => ({ ...t })) });
    },
    [events, editor]
  );

  const addLineup = useCallback(() => {
    const v = editor.lineupInput.trim();
    if (!v || !editor.draft) return;
    editor.set({ ...editor.draft, lineup: [...editor.draft.lineup, v] });
    editor.setLineupInput("");
  }, [editor]);

  const removeLineup = useCallback(
    (idx: number) => editor.draft && editor.set({ ...editor.draft, lineup: editor.draft.lineup.filter((_, i) => i !== idx) }),
    [editor]
  );

  const addTier = useCallback(
    () => editor.draft && editor.set({ ...editor.draft, tiers: [...editor.draft.tiers, { name: "New Tier", price: 0, qty: 0 }] }),
    [editor]
  );
  const updateTier = useCallback(
    (idx: number, field: "name" | "price" | "qty", value: string) =>
      editor.draft &&
      editor.set({
        ...editor.draft,
        tiers: editor.draft.tiers.map((t, i) => (i === idx ? { ...t, [field]: field === "name" ? value : Number(value) || 0 } : t)),
      }),
    [editor]
  );
  const removeTier = useCallback(
    (idx: number) => editor.draft && editor.set({ ...editor.draft, tiers: editor.draft.tiers.filter((_, i) => i !== idx) }),
    [editor]
  );

  const commitEvent = useCallback(
    async (status: OrganizerEvent["status"], extra: Partial<OrganizerEvent> = {}) => {
      const draft = editor.draft;
      const editingId = editor.editingId;
      if (!draft) return false;
      return run(async () => {
        const finalDraft: OrganizerEvent = { ...draft, status, ...extra };
        setEvents((prev) =>
          editingId ? prev.map((e) => (e.id === editingId ? finalDraft : e)) : [...prev, { ...finalDraft, id: `e${Date.now()}` }]
        );
      });
    },
    [editor, run]
  );

  const saveDraftEvent = useCallback(async () => {
    if (await commitEvent("draft")) {
      editor.close();
      showSnack("Draft saved.");
    }
  }, [commitEvent, editor, showSnack]);

  const submitEvent = useCallback(async () => {
    const scheduled = !!editor.draft?.scheduledPublish;
    const ok = await commitEvent(
      scheduled ? "scheduled" : "in_review",
      scheduled ? {} : { moderationFlag: "pending", moderationEta: "~2h remaining" }
    );
    if (ok) {
      editor.close();
      showSnack(scheduled ? "Event scheduled to publish." : "Event submitted for review — usually under 2h.");
    }
  }, [editor, commitEvent, showSnack]);

  const duplicateEvent = useCallback((id: string) => {
    setEvents((prev) => {
      const src = prev.find((e) => e.id === id);
      if (!src) return prev;
      return [
        ...prev,
        { ...src, id: `e${Date.now()}`, name: `${src.name} (Copy)`, status: "draft", recurring: false, cancelReason: "", sold: 0, revenue: 0 },
      ];
    });
  }, []);

  const openDayDialog = useCallback((iso: string, label: string) => setDayDialog({ iso, label }), []);
  const closeDayDialog = useCallback(() => setDayDialog(null), []);
  const shiftCalendar = useCallback((delta: number) => setCalendarOffset((o) => o + delta), []);

  const startCancel = useCallback((id: string) => {
    setCancelingEventId(id);
    setCancelReasonInput("");
  }, []);
  const cancelCancelFlow = useCallback(() => {
    setCancelingEventId(null);
    setCancelReasonInput("");
  }, []);
  const confirmCancel = useCallback(() => {
    const target = events.find((e) => e.id === cancelingEventId);
    setEvents((prev) => prev.map((e) => (e.id === cancelingEventId ? { ...e, status: "cancelled" as const, cancelReason: cancelReasonInput } : e)));
    setCancelingEventId(null);
    setCancelReasonInput("");
    showSnack(`${target?.name ?? "Event"} cancelled — ticket holders notified.`);
  }, [events, cancelingEventId, cancelReasonInput, showSnack]);

  const data = useMemo(
    () => ({
      events,
      eventFilter,
      eventsTab,
      eventEditorOpen: editor.isOpen,
      editingEventId: editor.editingId,
      eventDraft: editor.draft,
      lineupInput: editor.lineupInput,
      cancelingEventId,
      cancelReasonInput,
      calendarOffset,
      calendarVenueFilter,
      dayDialog,
    }),
    [events, eventFilter, eventsTab, editor.isOpen, editor.editingId, editor.draft, editor.lineupInput, cancelingEventId, cancelReasonInput, calendarOffset, calendarVenueFilter, dayDialog]
  );

  return useMemo(
    () => ({
      data,
      loading: false,
      error: null,
      busy,
      actionError,
      setEventFilter,
      setEventsTab,
      openNewEvent,
      openEditEvent,
      closeEditor: editor.close,
      updateDraft: editor.update,
      setLineupInput: editor.setLineupInput,
      addLineup,
      removeLineup,
      addTier,
      updateTier,
      removeTier,
      saveDraftEvent,
      submitEvent,
      duplicateEvent,
      startCancel,
      cancelCancelFlow,
      setCancelReasonInput,
      confirmCancel,
      shiftCalendar,
      setCalendarVenueFilter,
      openDayDialog,
      closeDayDialog,
    }),
    [
      data, busy, actionError, setEventFilter, setEventsTab, openNewEvent, openEditEvent,
      editor.close, editor.update, editor.setLineupInput, addLineup, removeLineup, addTier,
      updateTier, removeTier, saveDraftEvent, submitEvent, duplicateEvent, startCancel,
      cancelCancelFlow, confirmCancel, shiftCalendar, openDayDialog, closeDayDialog,
    ]
  );
}

export type EventsState = ReturnType<typeof useEvents>;
