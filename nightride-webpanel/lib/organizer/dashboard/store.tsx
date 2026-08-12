"use client";

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  useSyncExternalStore,
  type ReactNode,
} from "react";
import { clockStore, imageSlotStore } from "./browser-stores";
import { DAYS, GALLERY_SLOT_COUNT, OTP_MIN_LENGTH } from "./constants";
import {
  MOCK_ACTIVITY,
  MOCK_BOOST,
  MOCK_EVENTS,
  MOCK_INBOX,
  MOCK_ORGANIZER,
  MOCK_PERKS,
  MOCK_PROMOS,
  MOCK_PUSH,
  MOCK_REVIEWS,
  MOCK_TEAM,
  MOCK_TONIGHT,
  MOCK_VENUES,
  MOCK_VENUE_ORDER,
} from "./mock-data";
import type {
  BoostSlot,
  DoorStatus,
  InboxMessage,
  OrganizerEvent,
  PromoCode,
  PushState,
  RankPerk,
  TeamMember,
  TeamRole,
  TonightState,
  VenueProfile,
  VenueReview,
  VerifyStepId,
} from "./types";

export type VenueTab = "gallery" | "attributes" | "hours" | "links";
export type ChangeField = "email" | "phone";
export type ChangeStage = "edit" | "otp";

/** Slot ids are shared between the editor and the live app preview, so the
 *  same image renders in both places — same contract as the design's
 *  `<image-slot id>` sidecar. */
export function heroSlotId(venueId: string) {
  return `hero-${venueId}`;
}
export function gallerySlotId(venueId: string, index: number) {
  return `gallery-${venueId}-${index}`;
}
export function gallerySlotIds(venueId: string) {
  return Array.from({ length: GALLERY_SLOT_COUNT }, (_, i) => gallerySlotId(venueId, i));
}
export function eventSlotIds(eventKey: string) {
  return {
    cover: `event-img-${eventKey}-cover`,
    poster: `event-img-${eventKey}-poster`,
  };
}


export function blankVenueProfile(name: string, city: string): VenueProfile {
  return {
    verified: false,
    verificationSteps: { license: "active", gps: "active", video: "active" },
    openVerifyStep: "license",
    name,
    city,
    genres: [],
    dressCode: "Casual",
    agePolicy: "18+",
    coverMin: 0,
    coverMax: 0,
    currency: "$",
    capacity: 0,
    amenities: [],
    hours: DAYS.map((day) => ({ day, closed: false, open: "22:00", close: "04:00" })),
    exceptions: [],
    tableLink: "",
  };
}

export function blankEventDraft(date?: string, venue = MOCK_VENUE_ORDER[0]): OrganizerEvent {
  return {
    id: "",
    name: "",
    venue,
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
  };
}

interface OrganizerDashboardValue {
  organizer: typeof MOCK_ORGANIZER;

  // ---- Venues ----
  venueOrder: string[];
  venues: Record<string, VenueProfile>;
  editingVenue: string;
  profile: VenueProfile;
  venueTab: VenueTab;
  addingVenue: boolean;
  newVenueName: string;
  newVenueCity: string;
  setEditingVenue: (id: string) => void;
  setVenueTab: (tab: VenueTab) => void;
  openAddVenue: () => void;
  cancelAddVenue: () => void;
  setNewVenueName: (v: string) => void;
  setNewVenueCity: (v: string) => void;
  createVenue: () => void;
  setVenueField: <K extends keyof VenueProfile>(id: string, field: K, value: VenueProfile[K]) => void;
  toggleVenueSetValue: (id: string, field: "genres" | "amenities", value: string) => void;
  setHourField: (id: string, dayIdx: number, field: "open" | "close", value: string) => void;
  toggleDayClosed: (id: string, dayIdx: number) => void;
  addException: (id: string) => void;
  removeException: (id: string, idx: number) => void;
  setExceptionField: (id: string, idx: number, field: "label" | "date", value: string) => void;
  toggleExceptionClosed: (id: string, idx: number) => void;
  toggleVerifyStep: (id: string, step: VerifyStepId) => void;
  approveVenue: (id: string) => void;

  // ---- Events ----
  events: OrganizerEvent[];
  eventEditorOpen: boolean;
  editingEventId: string | null;
  eventDraft: OrganizerEvent | null;
  lineupInput: string;
  cancelingEventId: string | null;
  cancelReasonInput: string;
  openNewEvent: (date?: string) => void;
  openEditEvent: (id: string) => void;
  closeEditor: () => void;
  updateDraft: <K extends keyof OrganizerEvent>(field: K, value: OrganizerEvent[K]) => void;
  setLineupInput: (v: string) => void;
  addLineup: () => void;
  removeLineup: (idx: number) => void;
  addTier: () => void;
  updateTier: (idx: number, field: "name" | "price" | "qty", value: string) => void;
  removeTier: (idx: number) => void;
  saveDraftEvent: () => void;
  submitEvent: () => void;
  duplicateEvent: (id: string) => void;
  startCancel: (id: string) => void;
  cancelCancelFlow: () => void;
  setCancelReasonInput: (v: string) => void;
  confirmCancel: () => void;

  // ---- Calendar ----
  calendarOffset: number;
  calendarVenueFilter: string;
  shiftCalendar: (delta: number) => void;
  setCalendarVenueFilter: (id: string) => void;

  // ---- Tonight ----
  tonight: TonightState;
  setDoorStatus: (status: DoorStatus) => void;
  setQueueMinutes: (v: number) => void;
  setFlashText: (v: string) => void;
  setFlashUntil: (v: string) => void;
  toggleFlash: () => void;
  toggleEmergency: () => void;

  // ---- Performance ----
  perfVenueFilter: string;
  perfEventId: string | null;
  setPerfVenueFilter: (id: string) => void;
  setPerfEventId: (id: string) => void;

  // ---- Promotion ----
  push: PushState;
  setPushMessage: (v: string) => void;
  sendPush: () => void;
  promos: PromoCode[];
  addPromo: () => void;
  updatePromo: (idx: number, field: "code" | "desc", value: string) => void;
  removePromo: (idx: number) => void;
  perks: RankPerk[];
  updatePerk: (idx: number, value: string) => void;
  boost: BoostSlot;
  setBoostNight: (v: string) => void;
  toggleBoost: () => void;

  // ---- Team ----
  team: TeamMember[];
  activity: typeof MOCK_ACTIVITY;
  inviteName: string;
  inviteEmail: string;
  inviteRole: TeamRole;
  setInviteName: (v: string) => void;
  setInviteEmail: (v: string) => void;
  setInviteRole: (v: TeamRole) => void;
  addTeamMember: () => void;
  removeTeamMember: (idx: number) => void;

  // ---- Reviews & inbox ----
  reviews: VenueReview[];
  setReviewReply: (id: string, value: string) => void;
  toggleReviewFlag: (id: string) => void;
  inbox: InboxMessage[];
  toggleInboxItem: (id: string) => void;
  hasUnreadInbox: boolean;

  // ---- Settings / account ----
  accountEmail: string;
  accountPhone: string;
  changeField: ChangeField | null;
  changeStage: ChangeStage;
  changeValue: string;
  changeOtp: string;
  changeError: string;
  startChangeField: (field: ChangeField) => void;
  cancelChangeField: () => void;
  setChangeValue: (v: string) => void;
  setChangeOtp: (v: string) => void;
  submitNewValue: () => void;
  submitOtp: () => void;

  // ---- Image slots ----
  images: Record<string, string>;
  setImage: (slotId: string, dataUrl: string) => void;
  confirmRemoveSlotId: string | null;
  requestRemoveImage: (slotId: string) => void;
  cancelRemoveImage: () => void;
  confirmRemoveImage: () => void;
}

const OrganizerDashboardContext = createContext<OrganizerDashboardValue | null>(null);

export function OrganizerDashboardProvider({ children }: { children: ReactNode }) {
  // ---- Venues ----
  const [venueOrder, setVenueOrder] = useState<string[]>(MOCK_VENUE_ORDER);
  const [venues, setVenues] = useState<Record<string, VenueProfile>>(MOCK_VENUES);
  const [editingVenue, setEditingVenue] = useState(MOCK_VENUE_ORDER[0]);
  const [venueTab, setVenueTab] = useState<VenueTab>("gallery");
  const [addingVenue, setAddingVenue] = useState(false);
  const [newVenueName, setNewVenueName] = useState("");
  const [newVenueCity, setNewVenueCity] = useState("");

  // ---- Events ----
  const [events, setEvents] = useState<OrganizerEvent[]>(MOCK_EVENTS);
  const [eventEditorOpen, setEventEditorOpen] = useState(false);
  const [editingEventId, setEditingEventId] = useState<string | null>(null);
  const [eventDraft, setEventDraft] = useState<OrganizerEvent | null>(null);
  const [lineupInput, setLineupInput] = useState("");
  const [cancelingEventId, setCancelingEventId] = useState<string | null>(null);
  const [cancelReasonInput, setCancelReasonInput] = useState("");

  // ---- Calendar / performance filters ----
  const [calendarOffset, setCalendarOffset] = useState(0);
  const [calendarVenueFilter, setCalendarVenueFilter] = useState("all");
  const [perfVenueFilter, setPerfVenueFilterState] = useState("all");
  const [perfEventId, setPerfEventId] = useState<string | null>("e1");

  // ---- Tonight / promotion / team ----
  const [tonight, setTonight] = useState<TonightState>(MOCK_TONIGHT);
  const [push, setPush] = useState<PushState>(MOCK_PUSH);
  const [promos, setPromos] = useState<PromoCode[]>(MOCK_PROMOS);
  const [perks, setPerks] = useState<RankPerk[]>(MOCK_PERKS);
  const [boost, setBoost] = useState<BoostSlot>(MOCK_BOOST);
  const [team, setTeam] = useState<TeamMember[]>(MOCK_TEAM);
  const [inviteName, setInviteName] = useState("");
  const [inviteEmail, setInviteEmail] = useState("");
  const [inviteRole, setInviteRole] = useState<TeamRole>("Marketing");

  // ---- Reviews / inbox / account ----
  const [reviews, setReviews] = useState<VenueReview[]>(MOCK_REVIEWS);
  const [inbox, setInbox] = useState<InboxMessage[]>(MOCK_INBOX);
  const [accountEmail, setAccountEmail] = useState(MOCK_ORGANIZER.email);
  const [accountPhone, setAccountPhone] = useState(MOCK_ORGANIZER.phone);
  const [changeField, setChangeField] = useState<ChangeField | null>(null);
  const [changeStage, setChangeStage] = useState<ChangeStage>("edit");
  const [changeValue, setChangeValue] = useState("");
  const [changeOtp, setChangeOtp] = useState("");
  const [changeError, setChangeError] = useState("");

  // ---- Image slots ----
  const images = useSyncExternalStore(
    imageSlotStore.subscribe,
    imageSlotStore.getSnapshot,
    imageSlotStore.getServerSnapshot
  );
  const [confirmRemoveSlotId, setConfirmRemoveSlotId] = useState<string | null>(null);

  const setImage = useCallback((slotId: string, dataUrl: string) => {
    imageSlotStore.set(slotId, dataUrl);
  }, []);

  const requestRemoveImage = useCallback((slotId: string) => setConfirmRemoveSlotId(slotId), []);
  const cancelRemoveImage = useCallback(() => setConfirmRemoveSlotId(null), []);
  const confirmRemoveImage = useCallback(() => {
    if (confirmRemoveSlotId) imageSlotStore.remove(confirmRemoveSlotId);
    setConfirmRemoveSlotId(null);
  }, [confirmRemoveSlotId]);

  // ---- Venue mutators ----
  const updateVenue = useCallback((id: string, fn: (p: VenueProfile) => VenueProfile) => {
    setVenues((prev) => ({ ...prev, [id]: fn(prev[id]) }));
  }, []);

  const setVenueField = useCallback(
    <K extends keyof VenueProfile>(id: string, field: K, value: VenueProfile[K]) => {
      updateVenue(id, (p) => ({ ...p, [field]: value }));
    },
    [updateVenue]
  );

  const toggleVenueSetValue = useCallback(
    (id: string, field: "genres" | "amenities", value: string) => {
      updateVenue(id, (p) => ({
        ...p,
        [field]: p[field].includes(value)
          ? p[field].filter((x) => x !== value)
          : [...p[field], value],
      }));
    },
    [updateVenue]
  );

  const setHourField = useCallback(
    (id: string, dayIdx: number, field: "open" | "close", value: string) => {
      updateVenue(id, (p) => ({
        ...p,
        hours: p.hours.map((h, i) => (i === dayIdx ? { ...h, [field]: value } : h)),
      }));
    },
    [updateVenue]
  );

  const toggleDayClosed = useCallback(
    (id: string, dayIdx: number) => {
      updateVenue(id, (p) => ({
        ...p,
        hours: p.hours.map((h, i) => (i === dayIdx ? { ...h, closed: !h.closed } : h)),
      }));
    },
    [updateVenue]
  );

  const addException = useCallback(
    (id: string) => {
      updateVenue(id, (p) => ({
        ...p,
        exceptions: [...p.exceptions, { label: "New exception", date: "", closed: true }],
      }));
    },
    [updateVenue]
  );

  const removeException = useCallback(
    (id: string, idx: number) => {
      updateVenue(id, (p) => ({ ...p, exceptions: p.exceptions.filter((_, i) => i !== idx) }));
    },
    [updateVenue]
  );

  const setExceptionField = useCallback(
    (id: string, idx: number, field: "label" | "date", value: string) => {
      updateVenue(id, (p) => ({
        ...p,
        exceptions: p.exceptions.map((e, i) => (i === idx ? { ...e, [field]: value } : e)),
      }));
    },
    [updateVenue]
  );

  const toggleExceptionClosed = useCallback(
    (id: string, idx: number) => {
      updateVenue(id, (p) => ({
        ...p,
        exceptions: p.exceptions.map((e, i) => (i === idx ? { ...e, closed: !e.closed } : e)),
      }));
    },
    [updateVenue]
  );

  const toggleVerifyStep = useCallback(
    (id: string, step: VerifyStepId) => {
      updateVenue(id, (p) => ({ ...p, openVerifyStep: p.openVerifyStep === step ? null : step }));
    },
    [updateVenue]
  );

  const approveVenue = useCallback(
    (id: string) => updateVenue(id, (p) => ({ ...p, verified: true })),
    [updateVenue]
  );

  const openAddVenue = useCallback(() => {
    setAddingVenue(true);
    setNewVenueName("");
    setNewVenueCity("");
  }, []);

  const cancelAddVenue = useCallback(() => setAddingVenue(false), []);

  const createVenue = useCallback(() => {
    const name = newVenueName.trim();
    if (!name) return;
    const id = `venue-${Date.now()}`;
    setVenues((prev) => ({
      ...prev,
      [id]: blankVenueProfile(name, newVenueCity.trim() || "City, Country"),
    }));
    setVenueOrder((prev) => [...prev, id]);
    setEditingVenue(id);
    setAddingVenue(false);
    setNewVenueName("");
    setNewVenueCity("");
  }, [newVenueName, newVenueCity]);

  // ---- Event mutators ----
  const openNewEvent = useCallback(
    (date?: string) => {
      const firstVerified = venueOrder.find((id) => venues[id]?.verified) ?? venueOrder[0];
      setEventDraft(blankEventDraft(date, firstVerified));
      setEditingEventId(null);
      setEventEditorOpen(true);
      setLineupInput("");
    },
    [venueOrder, venues]
  );

  const openEditEvent = useCallback(
    (id: string) => {
      const ev = events.find((e) => e.id === id);
      if (!ev) return;
      setEventDraft({ ...ev, lineup: [...ev.lineup], tiers: ev.tiers.map((t) => ({ ...t })) });
      setEditingEventId(id);
      setEventEditorOpen(true);
      setLineupInput("");
    },
    [events]
  );

  const closeEditor = useCallback(() => {
    setEventEditorOpen(false);
    setEventDraft(null);
    setEditingEventId(null);
    setLineupInput("");
  }, []);

  const updateDraft = useCallback(
    <K extends keyof OrganizerEvent>(field: K, value: OrganizerEvent[K]) => {
      setEventDraft((prev) => (prev ? { ...prev, [field]: value } : prev));
    },
    []
  );

  const addLineup = useCallback(() => {
    const v = lineupInput.trim();
    if (!v) return;
    setEventDraft((prev) => (prev ? { ...prev, lineup: [...prev.lineup, v] } : prev));
    setLineupInput("");
  }, [lineupInput]);

  const removeLineup = useCallback((idx: number) => {
    setEventDraft((prev) =>
      prev ? { ...prev, lineup: prev.lineup.filter((_, i) => i !== idx) } : prev
    );
  }, []);

  const addTier = useCallback(() => {
    setEventDraft((prev) =>
      prev ? { ...prev, tiers: [...prev.tiers, { name: "New Tier", price: 0, qty: 0 }] } : prev
    );
  }, []);

  const updateTier = useCallback(
    (idx: number, field: "name" | "price" | "qty", value: string) => {
      setEventDraft((prev) =>
        prev
          ? {
              ...prev,
              tiers: prev.tiers.map((t, i) =>
                i === idx
                  ? { ...t, [field]: field === "name" ? value : Number(value) || 0 }
                  : t
              ),
            }
          : prev
      );
    },
    []
  );

  const removeTier = useCallback((idx: number) => {
    setEventDraft((prev) =>
      prev ? { ...prev, tiers: prev.tiers.filter((_, i) => i !== idx) } : prev
    );
  }, []);

  const commitEvent = useCallback(
    (status: OrganizerEvent["status"], extra: Partial<OrganizerEvent> = {}) => {
      setEvents((prev) => {
        if (!eventDraft) return prev;
        const draft: OrganizerEvent = { ...eventDraft, status, ...extra };
        if (editingEventId) return prev.map((e) => (e.id === editingEventId ? draft : e));
        return [...prev, { ...draft, id: `e${Date.now()}` }];
      });
      closeEditor();
    },
    [eventDraft, editingEventId, closeEditor]
  );

  const saveDraftEvent = useCallback(() => commitEvent("draft"), [commitEvent]);

  const submitEvent = useCallback(() => {
    // Scheduling publishes later without review; submitting now enters the queue.
    const scheduled = !!eventDraft?.scheduledPublish;
    commitEvent(
      scheduled ? "scheduled" : "in_review",
      scheduled ? {} : { moderationFlag: "pending", moderationEta: "~2h remaining" }
    );
  }, [eventDraft, commitEvent]);

  const duplicateEvent = useCallback((id: string) => {
    setEvents((prev) => {
      const src = prev.find((e) => e.id === id);
      if (!src) return prev;
      return [
        ...prev,
        {
          ...src,
          id: `e${Date.now()}`,
          name: `${src.name} (Copy)`,
          status: "draft",
          recurring: false,
          cancelReason: "",
        },
      ];
    });
  }, []);

  const startCancel = useCallback((id: string) => {
    setCancelingEventId(id);
    setCancelReasonInput("");
  }, []);

  const cancelCancelFlow = useCallback(() => {
    setCancelingEventId(null);
    setCancelReasonInput("");
  }, []);

  const confirmCancel = useCallback(() => {
    setEvents((prev) =>
      prev.map((e) =>
        e.id === cancelingEventId
          ? { ...e, status: "cancelled" as const, cancelReason: cancelReasonInput }
          : e
      )
    );
    setCancelingEventId(null);
    setCancelReasonInput("");
  }, [cancelingEventId, cancelReasonInput]);

  // ---- Performance ----
  const setPerfVenueFilter = useCallback(
    (id: string) => {
      setPerfVenueFilterState(id);
      // Keep the selected event valid for the new venue filter.
      const eligible = events.filter(
        (e) =>
          (e.status === "live" || e.status === "scheduled" || e.status === "in_review") &&
          (id === "all" || e.venue === id)
      );
      setPerfEventId((prev) =>
        eligible.some((e) => e.id === prev) ? prev : (eligible[0]?.id ?? null)
      );
    },
    [events]
  );

  // ---- Tonight ----
  const setDoorStatus = useCallback(
    (status: DoorStatus) => setTonight((p) => ({ ...p, status })),
    []
  );
  const setQueueMinutes = useCallback(
    (v: number) => setTonight((p) => ({ ...p, queueMinutes: v })),
    []
  );
  const setFlashText = useCallback((v: string) => setTonight((p) => ({ ...p, flashText: v })), []);
  const setFlashUntil = useCallback((v: string) => setTonight((p) => ({ ...p, flashUntil: v })), []);
  const toggleFlash = useCallback(
    () => setTonight((p) => ({ ...p, flashActive: !p.flashActive })),
    []
  );
  const toggleEmergency = useCallback(
    () => setTonight((p) => ({ ...p, emergencyActive: !p.emergencyActive })),
    []
  );

  // ---- Promotion ----
  const setPushMessage = useCallback((v: string) => setPush((p) => ({ ...p, message: v })), []);
  const sendPush = useCallback(() => {
    setPush((p) =>
      p.rateUsed >= p.rateMax || !p.message.trim()
        ? p
        : { ...p, rateUsed: p.rateUsed + 1, message: "" }
    );
  }, []);
  const addPromo = useCallback(
    () => setPromos((p) => [...p, { code: "NEWCODE", desc: "", maxUses: 100, used: 0 }]),
    []
  );
  const updatePromo = useCallback((idx: number, field: "code" | "desc", value: string) => {
    setPromos((p) => p.map((x, i) => (i === idx ? { ...x, [field]: value } : x)));
  }, []);
  const removePromo = useCallback(
    (idx: number) => setPromos((p) => p.filter((_, i) => i !== idx)),
    []
  );
  const updatePerk = useCallback((idx: number, value: string) => {
    setPerks((p) => p.map((x, i) => (i === idx ? { ...x, perk: value } : x)));
  }, []);
  const setBoostNight = useCallback((v: string) => setBoost((b) => ({ ...b, night: v })), []);
  const toggleBoost = useCallback(() => setBoost((b) => ({ ...b, active: !b.active })), []);

  // ---- Team ----
  const addTeamMember = useCallback(() => {
    if (!inviteName.trim()) return;
    setTeam((p) => [...p, { name: inviteName.trim(), email: inviteEmail.trim(), role: inviteRole }]);
    setInviteName("");
    setInviteEmail("");
  }, [inviteName, inviteEmail, inviteRole]);

  const removeTeamMember = useCallback(
    (idx: number) => setTeam((p) => p.filter((_, i) => i !== idx)),
    []
  );

  // ---- Reviews / inbox ----
  const setReviewReply = useCallback((id: string, value: string) => {
    setReviews((p) => p.map((r) => (r.id === id ? { ...r, reply: value } : r)));
  }, []);
  const toggleReviewFlag = useCallback((id: string) => {
    setReviews((p) => p.map((r) => (r.id === id ? { ...r, flagged: !r.flagged } : r)));
  }, []);
  const toggleInboxItem = useCallback((id: string) => {
    setInbox((p) => p.map((m) => (m.id === id ? { ...m, open: !m.open } : m)));
  }, []);

  // ---- Account ----
  const startChangeField = useCallback(
    (field: ChangeField) => {
      setChangeField(field);
      setChangeStage("edit");
      setChangeValue(field === "email" ? accountEmail : accountPhone);
      setChangeOtp("");
      setChangeError("");
    },
    [accountEmail, accountPhone]
  );

  const cancelChangeField = useCallback(() => {
    setChangeField(null);
    setChangeStage("edit");
    setChangeValue("");
    setChangeOtp("");
    setChangeError("");
  }, []);

  const submitNewValue = useCallback(() => {
    if (!changeValue.trim()) {
      setChangeError("Enter a value.");
      return;
    }
    setChangeStage("otp");
    setChangeOtp("");
    setChangeError("");
  }, [changeValue]);

  const submitOtp = useCallback(() => {
    // No SMS or email is actually sent — any code of OTP_MIN_LENGTH digits passes.
    if (changeOtp.trim().length < OTP_MIN_LENGTH) {
      setChangeError("Enter the code we sent you.");
      return;
    }
    if (changeField === "email") setAccountEmail(changeValue.trim());
    if (changeField === "phone") setAccountPhone(changeValue.trim());
    cancelChangeField();
  }, [changeOtp, changeField, changeValue, cancelChangeField]);

  const profile = venues[editingVenue];
  const hasUnreadInbox = inbox.some((m) => !m.open);

  const value = useMemo<OrganizerDashboardValue>(
    () => ({
      organizer: MOCK_ORGANIZER,

      venueOrder,
      venues,
      editingVenue,
      profile,
      venueTab,
      addingVenue,
      newVenueName,
      newVenueCity,
      setEditingVenue,
      setVenueTab,
      openAddVenue,
      cancelAddVenue,
      setNewVenueName,
      setNewVenueCity,
      createVenue,
      setVenueField,
      toggleVenueSetValue,
      setHourField,
      toggleDayClosed,
      addException,
      removeException,
      setExceptionField,
      toggleExceptionClosed,
      toggleVerifyStep,
      approveVenue,

      events,
      eventEditorOpen,
      editingEventId,
      eventDraft,
      lineupInput,
      cancelingEventId,
      cancelReasonInput,
      openNewEvent,
      openEditEvent,
      closeEditor,
      updateDraft,
      setLineupInput,
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

      calendarOffset,
      calendarVenueFilter,
      shiftCalendar: (delta: number) => setCalendarOffset((o) => o + delta),
      setCalendarVenueFilter,

      tonight,
      setDoorStatus,
      setQueueMinutes,
      setFlashText,
      setFlashUntil,
      toggleFlash,
      toggleEmergency,

      perfVenueFilter,
      perfEventId,
      setPerfVenueFilter,
      setPerfEventId,

      push,
      setPushMessage,
      sendPush,
      promos,
      addPromo,
      updatePromo,
      removePromo,
      perks,
      updatePerk,
      boost,
      setBoostNight,
      toggleBoost,

      team,
      activity: MOCK_ACTIVITY,
      inviteName,
      inviteEmail,
      inviteRole,
      setInviteName,
      setInviteEmail,
      setInviteRole,
      addTeamMember,
      removeTeamMember,

      reviews,
      setReviewReply,
      toggleReviewFlag,
      inbox,
      toggleInboxItem,
      hasUnreadInbox,

      accountEmail,
      accountPhone,
      changeField,
      changeStage,
      changeValue,
      changeOtp,
      changeError,
      startChangeField,
      cancelChangeField,
      setChangeValue,
      setChangeOtp,
      submitNewValue,
      submitOtp,

      images,
      setImage,
      confirmRemoveSlotId,
      requestRemoveImage,
      cancelRemoveImage,
      confirmRemoveImage,
    }),
    [
      venueOrder, venues, editingVenue, profile, venueTab, addingVenue, newVenueName, newVenueCity,
      openAddVenue, cancelAddVenue, createVenue, setVenueField, toggleVenueSetValue, setHourField,
      toggleDayClosed, addException, removeException, setExceptionField, toggleExceptionClosed,
      toggleVerifyStep, approveVenue,
      events, eventEditorOpen, editingEventId, eventDraft, lineupInput, cancelingEventId,
      cancelReasonInput, openNewEvent, openEditEvent, closeEditor, updateDraft, addLineup,
      removeLineup, addTier, updateTier, removeTier, saveDraftEvent, submitEvent, duplicateEvent,
      startCancel, cancelCancelFlow, confirmCancel,
      calendarOffset, calendarVenueFilter,
      tonight, setDoorStatus, setQueueMinutes, setFlashText, setFlashUntil, toggleFlash,
      toggleEmergency,
      perfVenueFilter, perfEventId, setPerfVenueFilter,
      push, setPushMessage, sendPush, promos, addPromo, updatePromo, removePromo, perks, updatePerk,
      boost, setBoostNight, toggleBoost,
      team, inviteName, inviteEmail, inviteRole, addTeamMember, removeTeamMember,
      reviews, setReviewReply, toggleReviewFlag, inbox, toggleInboxItem, hasUnreadInbox,
      accountEmail, accountPhone, changeField, changeStage, changeValue, changeOtp, changeError,
      startChangeField, cancelChangeField, submitNewValue, submitOtp,
      images, setImage, confirmRemoveSlotId, requestRemoveImage, cancelRemoveImage,
      confirmRemoveImage,
    ]
  );

  return (
    <OrganizerDashboardContext.Provider value={value}>
      {children}
    </OrganizerDashboardContext.Provider>
  );
}

export function useOrganizerDashboard() {
  const ctx = useContext(OrganizerDashboardContext);
  if (!ctx) {
    throw new Error("useOrganizerDashboard must be used inside <OrganizerDashboardProvider>");
  }
  return ctx;
}

/**
 * The client's clock, or null until mounted.
 *
 * Anything time-dependent (is this event live *right now*, which month is it,
 * are we open today) must not render differently on the server than on the
 * client, so callers render a stable fallback while this is null.
 */
export function useNow(): Date | null {
  return useSyncExternalStore(
    clockStore.subscribe,
    clockStore.getSnapshot,
    clockStore.getServerSnapshot
  );
}
