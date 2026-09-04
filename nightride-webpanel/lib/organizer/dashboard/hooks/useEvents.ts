"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { doc, getDocs, query, setDoc, updateDoc, where } from "firebase/firestore";
import { eventDocRef, eventsCol } from "../data/refs";
import { describeFirestoreError } from "../data/errors";
import { parseOrganizerEvent, toEventDocFields } from "../data/events";
import { resolveTimeZone } from "../data/time";
import type { OrganizerEvent, VenueMeta, VenueProfile } from "../types";
import { useAsyncAction } from "./useAsyncAction";
import { useEventEditor } from "./useEventEditor";
import { useLatest } from "./useLatest";

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
 * context. Real Firestore now: a one-shot `getDocs` over the organizer's own
 * events, refetched after every write, mirroring `lib/admin/useVenueDetail.ts`'s
 * `load()` + `runAction()` shape. Not a listener — the organizer is the writer
 * that matters here, and a listener over a growing list buys continuous reads
 * for no operational gain.
 *
 * `venues`/`venueOrder`/`venueMeta` are read-only inputs: `venueMeta[id].timeZone`
 * is what every `startAt`/`endAt` <-> `date`/`startTime`/`endTime` mapping runs
 * through (never the browser zone), and `venues[id].name` is what `venueName`
 * is re-derived from on every write.
 */
export function useEvents(
  uid: string,
  venues: Record<string, VenueProfile>,
  venueOrder: string[],
  venueMeta: Record<string, VenueMeta>,
  showSnack: (text: string, tone?: "info" | "error") => void
) {
  // ---- Reads: one-shot, refetched after every write ----
  const [rawDocs, setRawDocs] = useState<Record<string, Record<string, unknown>>>({});
  const [eventsLoading, setEventsLoading] = useState(true);
  const [eventsError, setEventsError] = useState("");

  const loadEvents = useCallback(async () => {
    try {
      const snap = await getDocs(query(eventsCol(), where("organizerUid", "==", uid)));
      const next: Record<string, Record<string, unknown>> = {};
      snap.forEach((d) => {
        next[d.id] = d.data() as Record<string, unknown>;
      });
      setRawDocs(next);
      setEventsError("");
    } catch (err) {
      setEventsError(describeFirestoreError(err));
    } finally {
      setEventsLoading(false);
    }
  }, [uid]);

  useEffect(() => {
    setEventsLoading(true);
    loadEvents();
  }, [loadEvents]);

  const rawDocsRef = useLatest(rawDocs);

  // `raw` alongside the parsed events — the raw-remainder merge in
  // `toEventDocFields` needs the stored document, not just what
  // `OrganizerEvent` models.
  const events = useMemo(
    () =>
      Object.entries(rawDocs).map(([id, raw]) => {
        const venueId = typeof raw.venueId === "string" ? raw.venueId : "";
        const timeZone = resolveTimeZone(venueMeta[venueId]?.timeZone);
        return parseOrganizerEvent(id, raw, timeZone);
      }),
    [rawDocs, venueMeta]
  );
  const eventsRef = useLatest(events);

  // Sibling to `OrganizerEvent` per Global Constraint 7 rather than fields on
  // it — `coverImage`/`posterImage` have no form control of their own (only
  // the image-slot widgets in `EventEditor`), so there is nothing to gain by
  // making every existing `OrganizerEvent` literal carry them. Keyed by raw
  // doc id, straight off `rawDocs`, so it reflects a `patchEventImage` write
  // the moment `loadEvents` refetches — no separate cache to fall out of sync.
  const eventMedia = useMemo(() => {
    const out: Record<string, { coverImage: string; posterImage: string }> = {};
    for (const [id, raw] of Object.entries(rawDocs)) {
      out[id] = {
        coverImage: typeof raw.coverImage === "string" ? raw.coverImage : "",
        posterImage: typeof raw.posterImage === "string" ? raw.posterImage : "",
      };
    }
    return out;
  }, [rawDocs]);

  const [eventFilter, setEventFilter] = useState<EventFilter>("all");
  const [eventsTab, setEventsTab] = useState<EventsTab>("list");
  const [cancelingEventId, setCancelingEventId] = useState<string | null>(null);
  const [cancelReasonInput, setCancelReasonInput] = useState("");
  const [calendarOffset, setCalendarOffset] = useState(0);
  const [calendarVenueFilter, setCalendarVenueFilter] = useState("all");
  const [dayDialog, setDayDialog] = useState<{ iso: string; label: string } | null>(null);

  const editor = useEventEditor();
  const { busy, actionError, run } = useAsyncAction(loadEvents);
  const router = useRouter();

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

  /**
   * The sole event write point. Create (no `editingId`) pre-generates a doc
   * ref via `doc(eventsCol())` and stamps `organizerUid`/`source` — fields
   * `toEventDocFields` doesn't model because they never change on update.
   * Update spreads the stored document first via `toEventDocFields`'s own
   * raw-remainder merge, so a re-save can never silently drop fields this
   * panel doesn't model (`description`, `policies`, `genre`, `ticketUrl`, …).
   *
   * Returns `false` (via `run`) rather than throwing on a rules rejection —
   * `saveDraftEvent`/`submitEvent` only close the dialog when this resolves
   * true, so the organizer's draft survives a permission error instead of
   * being discarded.
   *
   * The non-empty-`endTime` requirement applies only to a document that is
   * (or is about to become) `source: 'organizer'` — a brand-new draft
   * (always organizer-sourced), or an existing document whose stored
   * `source` already is `'organizer'`. An organizer can also load an
   * admin- or scraper-sourced document assigned to them via `organizerUid`
   * (rules permit that update; `source` stays unchanged) with `endTime`
   * correctly parsed as `""` — that document must remain saveable with no
   * end time, which is exactly what `eventWindowToTimestamps` now does
   * (`endAt: null`) once this guard doesn't stand in the way. Fixed in
   * `data/time.ts`, not with a second guard here — see the fix-round report.
   */
  const commitEvent = useCallback(
    async (status: OrganizerEvent["status"], extra: Partial<OrganizerEvent> = {}) => {
      const draft = editor.draft;
      const editingId = editor.editingId;
      if (!draft) return false;
      return run(async () => {
        const finalDraft: OrganizerEvent = { ...draft, status, ...extra };
        const meta = venueMeta[finalDraft.venue];
        if (!meta) throw new Error("Select a venue before saving.");
        if (!finalDraft.name.trim()) throw new Error("Give the event a name before saving.");
        if (!finalDraft.date || !finalDraft.startTime) throw new Error("Set a date and start time before saving.");
        const raw = editingId ? rawDocsRef.current[editingId] ?? {} : {};
        const isOrganizerSourced = editingId ? raw.source === "organizer" : true;
        if (isOrganizerSourced && !finalDraft.endTime) {
          throw new Error("Set a close time before saving.");
        }
        const venueNameValue = venues[finalDraft.venue]?.name ?? "";
        if (editingId) {
          const fields = toEventDocFields(finalDraft, { meta, venueName: venueNameValue, raw });
          await setDoc(eventDocRef(editingId), fields);
        } else {
          const fields = toEventDocFields(finalDraft, { meta, venueName: venueNameValue, raw: {} });
          await setDoc(doc(eventsCol()), { ...fields, organizerUid: uid, source: "organizer" });
        }
      });
    },
    [editor, run, venueMeta, venues, rawDocsRef, uid]
  );

  /**
   * T12: patches `coverImage`/`posterImage` after a Storage upload has
   * already landed the object at `eventMedia/{eventId}/{cover,poster}.jpg`.
   * Deliberately its own write point rather than routed through
   * `commitEvent` — the ordering constraint (T12 brief, and the storage rule
   * itself: `isEventOwner()` has nothing else to authorize against) is
   * "create the draft, upload, then patch", so this only ever runs against
   * an event that already exists.
   *
   * Fix round 1: this is a single-field `updateDoc`, NOT a whole-document
   * `setDoc({ ...raw, [field]: url })` — spreading `rawDocsRef.current`
   * looked like it followed the raw-remainder-merge pattern every other
   * event write uses, but `rawDocsRef` only refreshes after `run()`'s
   * reload completes, so a cover upload and a poster upload fired in quick
   * succession (both `ImageSlot`s are independently clickable, nothing
   * locks one while the other is in flight) would both read the SAME stale
   * `raw`, and whichever `setDoc` landed second would silently revert the
   * other's field to its pre-upload value — the Storage object would exist,
   * successfully uploaded, and simply not be referenced by the document.
   * `updateDoc` touches only `[field]`, so two concurrent patches to
   * different fields compose correctly regardless of ordering. Global
   * Constraint 2's raw-remainder-merge concern (a whole-document write
   * silently dropping a field this panel doesn't model) does not apply to a
   * single-field dot-path update — there is no second field it could drop.
   */
  const patchEventImage = useCallback(
    (eventId: string, field: "coverImage" | "posterImage", url: string) =>
      run(async () => {
        if (!rawDocsRef.current[eventId]) throw new Error("Save this event before adding images.");
        await updateDoc(eventDocRef(eventId), { [field]: url });
      }),
    [run, rawDocsRef]
  );

  /**
   * The "New event" FAB (`Sidebar.tsx`) opens this editor from any dashboard
   * route, not just `/organizer/events` — so on a brand-new event (no
   * `editingId`) both save paths route to the events list after the write
   * lands. Otherwise the organizer's new event sits in Firestore with no
   * visible confirmation unless they happen to already be on that tab.
   */
  const saveDraftEvent = useCallback(async () => {
    const isNew = !editor.editingId;
    if (await commitEvent("draft")) {
      editor.close();
      showSnack("Draft saved.");
      if (isNew) {
        setEventsTab("list");
        router.push("/organizer/events");
      }
    }
  }, [commitEvent, editor, showSnack, router]);

  const submitEvent = useCallback(async () => {
    const isNew = !editor.editingId;
    const scheduled = !!editor.draft?.scheduledPublish;
    const ok = await commitEvent(scheduled ? "scheduled" : "in_review");
    if (ok) {
      editor.close();
      showSnack(scheduled ? "Event scheduled to publish." : "Event submitted for review — usually under 2h.");
      if (isNew) {
        setEventsTab("list");
        router.push("/organizer/events");
      }
    }
  }, [editor, commitEvent, showSnack, router]);

  /**
   * A fresh `draft` with a new id — never carries `moderation`/`sales`
   * forward (the source event's producer-owned fields are never read here;
   * the new document's `raw` starts empty, so `toEventDocFields` writes
   * neither). Always writes `source: 'organizer'` on the new document (it's
   * the organizer's own copy now, regardless of what the original's
   * `source` was), so it needs a non-empty `endTime` even when duplicating
   * an admin/scraped event that had none — required by `shapeOk()`, and
   * checked here with a clear message rather than left to a `permission-denied`
   * from the rules.
   */
  const duplicateEvent = useCallback(
    async (id: string) => {
      const src = eventsRef.current.find((e) => e.id === id);
      if (!src) return;
      const ok = await run(async () => {
        const meta = venueMeta[src.venue];
        if (!meta) throw new Error("That event's venue no longer exists.");
        if (!src.endTime) {
          throw new Error("That event has no close time on record — set one before duplicating it.");
        }
        const venueNameValue = venues[src.venue]?.name ?? "";
        const draftUi: OrganizerEvent = {
          ...src,
          id: "",
          name: `${src.name} (Copy)`,
          status: "draft",
          recurring: false,
          cancelReason: "",
          sold: 0,
          revenue: 0,
          moderationFlag: "",
          moderationEta: "",
        };
        const fields = toEventDocFields(draftUi, { meta, venueName: venueNameValue, raw: {} });
        await setDoc(doc(eventsCol()), { ...fields, organizerUid: uid, source: "organizer" });
      });
      if (ok) showSnack(`${src.name} duplicated as a new draft.`);
    },
    [eventsRef, run, venueMeta, venues, uid, showSnack]
  );

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

  /**
   * `status: 'cancelled'` requires a non-empty `cancelReason` — `shapeOk()`
   * rejects the write otherwise, so this is checked client-side too rather
   * than relying on the rules round-trip to surface it.
   */
  const confirmCancel = useCallback(async () => {
    const id = cancelingEventId;
    const reason = cancelReasonInput.trim();
    if (!id || !reason) return;
    const target = eventsRef.current.find((e) => e.id === id);
    if (!target) return;
    const ok = await run(async () => {
      const meta = venueMeta[target.venue];
      if (!meta) throw new Error("That event's venue no longer exists.");
      const venueNameValue = venues[target.venue]?.name ?? "";
      const finalDraft: OrganizerEvent = { ...target, status: "cancelled", cancelReason: reason };
      const raw = rawDocsRef.current[id] ?? {};
      const fields = toEventDocFields(finalDraft, { meta, venueName: venueNameValue, raw });
      await setDoc(eventDocRef(id), fields);
    });
    if (ok) {
      setCancelingEventId(null);
      setCancelReasonInput("");
      showSnack(`${target.name || "Event"} cancelled — ticket holders notified.`);
    }
  }, [cancelingEventId, cancelReasonInput, eventsRef, run, venueMeta, venues, rawDocsRef, showSnack]);

  const data = useMemo(
    () => ({
      events,
      eventsLoading,
      eventsError,
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
      eventMedia,
    }),
    [
      events, eventsLoading, eventsError, eventFilter, eventsTab, editor.isOpen, editor.editingId,
      editor.draft, editor.lineupInput, cancelingEventId, cancelReasonInput, calendarOffset,
      calendarVenueFilter, dayDialog, eventMedia,
    ]
  );

  return useMemo(
    () => ({
      data,
      loading: eventsLoading,
      error: eventsError,
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
      patchEventImage,
    }),
    [
      data, eventsLoading, eventsError, busy, actionError, setEventFilter, setEventsTab, openNewEvent, openEditEvent,
      editor.close, editor.update, editor.setLineupInput, addLineup, removeLineup, addTier,
      updateTier, removeTier, saveDraftEvent, submitEvent, duplicateEvent, startCancel,
      cancelCancelFlow, confirmCancel, shiftCalendar, openDayDialog, closeDayDialog, patchEventImage,
    ]
  );
}

export type EventsState = ReturnType<typeof useEvents>;
