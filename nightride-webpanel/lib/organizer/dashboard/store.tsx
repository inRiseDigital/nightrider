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
  MenuItem,
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

export type VenueTab = "profile" | "menu" | "hours" | "links";
export type HomeTab = "tonight" | "activity";
export type EventsTab = "list" | "calendar";
export type AudienceTab = "performance" | "reviews" | "ai-visibility";
export type AccountTab = "team" | "inbox" | "promotion" | "settings";
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
export function menuItemSlotId(venueId: string, itemId: string) {
  return `menu-${venueId}-${itemId}`;
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
    address: "",
    about: "",
    socialLinks: [],
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
    menu: [],
    tableLink: "",
  };
}

/**
 * Fields that bypass the venue draft. Verification state is set by an admin
 * rather than the organizer, so it writes to the published record directly:
 * it is excluded from the dirty check and preserved when a draft commits.
 */
const LIVE_VENUE_FIELDS = ["verified", "verificationSteps", "openVerifyStep"] as const;

/** The draft with live fields overlaid — what the editor should render. */
function withLiveFields(draft: VenueProfile, saved: VenueProfile): VenueProfile {
  return {
    ...draft,
    verified: saved.verified,
    verificationSteps: saved.verificationSteps,
    openVerifyStep: saved.openVerifyStep,
  };
}

/** Just the reviewable listing fields, for comparing draft against published. */
function listingFieldsOf(p: VenueProfile): Partial<VenueProfile> {
  const listing: Partial<VenueProfile> = { ...p };
  for (const field of LIVE_VENUE_FIELDS) delete listing[field];
  return listing;
}

/** Menu sections and items are added client-side only, so a timestamp plus a
 *  counter is enough to keep React keys unique without a uuid dependency. */
let menuIdSeq = 0;
function nextMenuId(prefix: string) {
  menuIdSeq += 1;
  return `${prefix}-${Date.now().toString(36)}-${menuIdSeq}`;
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
  /** Listing fields as edited (draft when one exists); menu/verification always live. */
  profile: VenueProfile;
  /** The published record — what the app preview renders. */
  savedProfile: VenueProfile;
  /** True when the selected venue has uncommitted listing edits. */
  venueDirty: boolean;
  saveVenue: (id: string) => void;
  discardVenue: (id: string) => void;
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
  addSocialLink: (id: string) => void;
  removeSocialLink: (id: string, idx: number) => void;
  setSocialLinkField: (id: string, idx: number, field: "network" | "value", value: string) => void;
  setHourField: (id: string, dayIdx: number, field: "open" | "close", value: string) => void;
  toggleDayClosed: (id: string, dayIdx: number) => void;
  addException: (id: string) => void;
  removeException: (id: string, idx: number) => void;
  setExceptionField: (id: string, idx: number, field: "label" | "date", value: string) => void;
  toggleExceptionClosed: (id: string, idx: number) => void;
  addMenuSection: (id: string) => void;
  removeMenuSection: (id: string, sectionId: string) => void;
  setMenuSectionName: (id: string, sectionId: string, name: string) => void;
  addMenuItem: (id: string, sectionId: string) => void;
  removeMenuItem: (id: string, sectionId: string, itemId: string) => void;
  setMenuItemField: <K extends keyof MenuItem>(
    id: string,
    sectionId: string,
    itemId: string,
    field: K,
    value: MenuItem[K]
  ) => void;
  toggleMenuItemSoldOut: (id: string, sectionId: string, itemId: string) => void;
  toggleMenuItemTag: (id: string, sectionId: string, itemId: string, tag: string) => void;
  toggleMenuItemNight: (id: string, sectionId: string, itemId: string, night: number) => void;
  toggleVerifyStep: (id: string, step: VerifyStepId) => void;
  approveVenue: (id: string) => void;

  // ---- Destination tab strips ----
  homeTab: HomeTab;
  setHomeTab: (tab: HomeTab) => void;
  eventsTab: EventsTab;
  setEventsTab: (tab: EventsTab) => void;
  audienceTab: AudienceTab;
  setAudienceTab: (tab: AudienceTab) => void;
  accountTab: AccountTab;
  setAccountTab: (tab: AccountTab) => void;

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
  inviteEmail: string;
  setInviteEmail: (v: string) => void;
  sendInvite: () => void;
  setTeamRole: (id: string, role: TeamRole) => void;
  /** The member queued for removal — drives the confirm dialog. */
  removeTarget: TeamMember | null;
  removePassword: string;
  removeAck: boolean;
  removeError: string;
  startRemoveTeamMember: (id: string) => void;
  setRemovePassword: (v: string) => void;
  toggleRemoveAck: () => void;
  cancelRemoveTeamMember: () => void;
  confirmRemoveTeamMember: () => void;

  // ---- Snackbar ----
  /** Empty while nothing is showing. */
  snack: string;
  showSnack: (text: string) => void;
  dismissSnack: () => void;

  // ---- Reviews & inbox ----
  reviews: VenueReview[];
  setReviewReply: (id: string, value: string) => void;
  toggleReviewFlag: (id: string) => void;
  sendReviewReply: (id: string) => void;
  editPostedReply: (id: string) => void;
  deletePostedReply: (id: string) => void;
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
  /**
   * Unsaved listing edits, keyed by venue id. A draft is created lazily on the
   * first edit and cleared on save/discard, so `venues` always holds the
   * published version the app preview renders. Drafts survive switching venues.
   */
  const [venueDrafts, setVenueDrafts] = useState<Record<string, VenueProfile>>({});
  const [editingVenue, setEditingVenue] = useState(MOCK_VENUE_ORDER[0]);
  const [venueTab, setVenueTab] = useState<VenueTab>("profile");
  const [homeTab, setHomeTab] = useState<HomeTab>("tonight");
  const [eventsTab, setEventsTab] = useState<EventsTab>("list");
  const [audienceTab, setAudienceTab] = useState<AudienceTab>("performance");
  const [accountTab, setAccountTab] = useState<AccountTab>("team");
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
  const [inviteEmail, setInviteEmail] = useState("");
  const [removeTargetId, setRemoveTargetId] = useState<string | null>(null);
  const [removePassword, setRemovePassword] = useState("");
  const [removeAck, setRemoveAck] = useState(false);
  const [removeError, setRemoveError] = useState("");

  // ---- Snackbar ----
  const [snack, setSnack] = useState("");

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

  /**
   * Every mutation that changes something a guest or teammate would notice
   * confirms itself here, the way the design does. Declared before the
   * mutators so they can all reach it.
   */
  const showSnack = useCallback((text: string) => setSnack(text), []);
  const dismissSnack = useCallback(() => setSnack(""), []);

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
  /** Writes straight to the published record — for menu and verification only. */
  const updateVenue = useCallback((id: string, fn: (p: VenueProfile) => VenueProfile) => {
    setVenues((prev) => ({ ...prev, [id]: fn(prev[id]) }));
  }, []);

  /**
   * Writes into the venue's draft, seeding it from the published record on the
   * first edit. Every reviewable listing field goes through here, so nothing
   * reaches the app preview until the save bar commits it.
   */
  const updateVenueListing = useCallback(
    (id: string, fn: (p: VenueProfile) => VenueProfile) => {
      setVenueDrafts((prev) => {
        const base = prev[id] ?? venues[id];
        if (!base) return prev;
        return { ...prev, [id]: fn(base) };
      });
    },
    [venues]
  );

  const setVenueField = useCallback(
    <K extends keyof VenueProfile>(id: string, field: K, value: VenueProfile[K]) => {
      updateVenueListing(id, (p) => ({ ...p, [field]: value }));
    },
    [updateVenueListing]
  );

  const toggleVenueSetValue = useCallback(
    (id: string, field: "genres" | "amenities", value: string) => {
      updateVenueListing(id, (p) => ({
        ...p,
        [field]: p[field].includes(value)
          ? p[field].filter((x) => x !== value)
          : [...p[field], value],
      }));
    },
    [updateVenueListing]
  );

  const addSocialLink = useCallback(
    (id: string) => {
      updateVenueListing(id, (p) => ({
        ...p,
        socialLinks: [...p.socialLinks, { network: "instagram", value: "" }],
      }));
    },
    [updateVenueListing]
  );

  const removeSocialLink = useCallback(
    (id: string, idx: number) => {
      updateVenueListing(id, (p) => ({
        ...p,
        socialLinks: p.socialLinks.filter((_, i) => i !== idx),
      }));
    },
    [updateVenueListing]
  );

  const setSocialLinkField = useCallback(
    (id: string, idx: number, field: "network" | "value", value: string) => {
      updateVenueListing(id, (p) => ({
        ...p,
        socialLinks: p.socialLinks.map((s, i) => (i === idx ? { ...s, [field]: value } : s)),
      }));
    },
    [updateVenueListing]
  );

  const setHourField = useCallback(
    (id: string, dayIdx: number, field: "open" | "close", value: string) => {
      updateVenueListing(id, (p) => ({
        ...p,
        hours: p.hours.map((h, i) => (i === dayIdx ? { ...h, [field]: value } : h)),
      }));
    },
    [updateVenueListing]
  );

  const toggleDayClosed = useCallback(
    (id: string, dayIdx: number) => {
      updateVenueListing(id, (p) => ({
        ...p,
        hours: p.hours.map((h, i) => (i === dayIdx ? { ...h, closed: !h.closed } : h)),
      }));
    },
    [updateVenueListing]
  );

  const addException = useCallback(
    (id: string) => {
      updateVenueListing(id, (p) => ({
        ...p,
        exceptions: [...p.exceptions, { label: "New exception", date: "", closed: true }],
      }));
    },
    [updateVenueListing]
  );

  const removeException = useCallback(
    (id: string, idx: number) => {
      updateVenueListing(id, (p) => ({
        ...p,
        exceptions: p.exceptions.filter((_, i) => i !== idx),
      }));
    },
    [updateVenueListing]
  );

  const setExceptionField = useCallback(
    (id: string, idx: number, field: "label" | "date", value: string) => {
      updateVenueListing(id, (p) => ({
        ...p,
        exceptions: p.exceptions.map((e, i) => (i === idx ? { ...e, [field]: value } : e)),
      }));
    },
    [updateVenueListing]
  );

  const toggleExceptionClosed = useCallback(
    (id: string, idx: number) => {
      updateVenueListing(id, (p) => ({
        ...p,
        exceptions: p.exceptions.map((e, i) => (i === idx ? { ...e, closed: !e.closed } : e)),
      }));
    },
    [updateVenueListing]
  );

  /** Commits the draft's listing fields, leaving live fields (menu, verification) alone. */
  const saveVenue = useCallback(
    (id: string) => {
      if (!venueDrafts[id]) {
        showSnack("No changes to save.");
        return;
      }
      setVenueDrafts((prevDrafts) => {
        const draft = prevDrafts[id];
        if (!draft) return prevDrafts;
        setVenues((prev) => ({ ...prev, [id]: { ...prev[id], ...listingFieldsOf(draft) } }));
        const next = { ...prevDrafts };
        delete next[id];
        return next;
      });
      showSnack("Changes saved and submitted for review.");
    },
    [venueDrafts, showSnack]
  );

  const discardVenue = useCallback(
    (id: string) => {
      if (!venueDrafts[id]) return;
      setVenueDrafts((prev) => {
        const next = { ...prev };
        delete next[id];
        return next;
      });
      showSnack("Changes discarded.");
    },
    [venueDrafts, showSnack]
  );

  // ---- Menu mutators ----
  /** Rewrites one item in place; every per-item edit funnels through here. */
  const patchMenuItem = useCallback(
    (id: string, sectionId: string, itemId: string, patch: Partial<MenuItem>) => {
      updateVenueListing(id, (p) => ({
        ...p,
        menu: p.menu.map((sec) =>
          sec.id !== sectionId
            ? sec
            : {
                ...sec,
                items: sec.items.map((it) => (it.id === itemId ? { ...it, ...patch } : it)),
              }
        ),
      }));
    },
    [updateVenueListing]
  );

  const addMenuSection = useCallback(
    (id: string) => {
      updateVenueListing(id, (p) => ({
        ...p,
        menu: [...p.menu, { id: nextMenuId("sec"), name: "New section", items: [] }],
      }));
    },
    [updateVenueListing]
  );

  const removeMenuSection = useCallback(
    (id: string, sectionId: string) => {
      updateVenueListing(id, (p) => ({ ...p, menu: p.menu.filter((s) => s.id !== sectionId) }));
    },
    [updateVenueListing]
  );

  const setMenuSectionName = useCallback(
    (id: string, sectionId: string, name: string) => {
      updateVenueListing(id, (p) => ({
        ...p,
        menu: p.menu.map((s) => (s.id === sectionId ? { ...s, name } : s)),
      }));
    },
    [updateVenueListing]
  );

  const addMenuItem = useCallback(
    (id: string, sectionId: string) => {
      updateVenueListing(id, (p) => ({
        ...p,
        menu: p.menu.map((s) =>
          s.id !== sectionId
            ? s
            : {
                ...s,
                items: [
                  ...s.items,
                  {
                    id: nextMenuId("item"),
                    name: "",
                    price: 0,
                    desc: "",
                    size: "",
                    serves: "",
                    tags: [],
                    nights: [],
                    soldOut: false,
                  },
                ],
              }
        ),
      }));
    },
    [updateVenueListing]
  );

  const removeMenuItem = useCallback(
    (id: string, sectionId: string, itemId: string) => {
      updateVenueListing(id, (p) => ({
        ...p,
        menu: p.menu.map((s) =>
          s.id !== sectionId ? s : { ...s, items: s.items.filter((it) => it.id !== itemId) }
        ),
      }));
    },
    [updateVenueListing]
  );

  const setMenuItemField = useCallback(
    <K extends keyof MenuItem>(
      id: string,
      sectionId: string,
      itemId: string,
      field: K,
      value: MenuItem[K]
    ) => {
      patchMenuItem(id, sectionId, itemId, { [field]: value } as Partial<MenuItem>);
    },
    [patchMenuItem]
  );

  const toggleMenuItemSoldOut = useCallback(
    (id: string, sectionId: string, itemId: string) => {
      // Menu lives in the draft once edited, so read the draft first.
      const item = (venueDrafts[id] ?? venues[id])?.menu
        .find((s) => s.id === sectionId)
        ?.items.find((it) => it.id === itemId);
      updateVenueListing(id, (p) => ({
        ...p,
        menu: p.menu.map((s) =>
          s.id !== sectionId
            ? s
            : {
                ...s,
                items: s.items.map((it) =>
                  it.id === itemId ? { ...it, soldOut: !it.soldOut } : it
                ),
              }
        ),
      }));
      const name = item?.name || "Item";
      showSnack(item?.soldOut ? `${name} is back on the menu.` : `${name} marked sold out.`);
    },
    [venueDrafts, venues, updateVenueListing, showSnack]
  );

  const toggleMenuItemTag = useCallback(
    (id: string, sectionId: string, itemId: string, tag: string) => {
      updateVenueListing(id, (p) => ({
        ...p,
        menu: p.menu.map((s) =>
          s.id !== sectionId
            ? s
            : {
                ...s,
                items: s.items.map((it) =>
                  it.id !== itemId
                    ? it
                    : {
                        ...it,
                        tags: it.tags.includes(tag)
                          ? it.tags.filter((t) => t !== tag)
                          : [...it.tags, tag],
                      }
                ),
              }
        ),
      }));
    },
    [updateVenueListing]
  );

  const toggleMenuItemNight = useCallback(
    (id: string, sectionId: string, itemId: string, night: number) => {
      updateVenueListing(id, (p) => ({
        ...p,
        menu: p.menu.map((s) =>
          s.id !== sectionId
            ? s
            : {
                ...s,
                items: s.items.map((it) =>
                  it.id !== itemId
                    ? it
                    : {
                        ...it,
                        nights: it.nights.includes(night)
                          ? it.nights.filter((n) => n !== night)
                          : [...it.nights, night].sort((a, b) => a - b),
                      }
                ),
              }
        ),
      }));
    },
    [updateVenueListing]
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

  const saveDraftEvent = useCallback(() => {
    commitEvent("draft");
    showSnack("Draft saved.");
  }, [commitEvent, showSnack]);

  const submitEvent = useCallback(() => {
    // Scheduling publishes later without review; submitting now enters the queue.
    const scheduled = !!eventDraft?.scheduledPublish;
    commitEvent(
      scheduled ? "scheduled" : "in_review",
      scheduled ? {} : { moderationFlag: "pending", moderationEta: "~2h remaining" }
    );
    showSnack(
      scheduled ? "Event scheduled to publish." : "Event submitted for review — usually under 2h."
    );
  }, [eventDraft, commitEvent, showSnack]);

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
    const target = events.find((e) => e.id === cancelingEventId);
    setEvents((prev) =>
      prev.map((e) =>
        e.id === cancelingEventId
          ? { ...e, status: "cancelled" as const, cancelReason: cancelReasonInput }
          : e
      )
    );
    setCancelingEventId(null);
    setCancelReasonInput("");
    showSnack(`${target?.name ?? "Event"} cancelled — ticket holders notified.`);
  }, [events, cancelingEventId, cancelReasonInput, showSnack]);

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
    (status: DoorStatus) => {
      setTonight((p) => ({ ...p, status }));
      showSnack(`Door status set to ${status}.`);
    },
    [showSnack]
  );
  const setQueueMinutes = useCallback(
    (v: number) => setTonight((p) => ({ ...p, queueMinutes: v })),
    []
  );
  const setFlashText = useCallback((v: string) => setTonight((p) => ({ ...p, flashText: v })), []);
  const setFlashUntil = useCallback((v: string) => setTonight((p) => ({ ...p, flashUntil: v })), []);
  const toggleFlash = useCallback(() => {
    setTonight((p) => ({ ...p, flashActive: !p.flashActive }));
    showSnack(tonight.flashActive ? "Flash offer ended." : "Flash offer is live.");
  }, [tonight.flashActive, showSnack]);
  const toggleEmergency = useCallback(() => {
    setTonight((p) => ({ ...p, emergencyActive: !p.emergencyActive }));
    showSnack(
      tonight.emergencyActive
        ? "Venue reopened — you're back on the map."
        : "Emergency close requested — platform admin notified."
    );
  }, [tonight.emergencyActive, showSnack]);

  // ---- Promotion ----
  const setPushMessage = useCallback((v: string) => setPush((p) => ({ ...p, message: v })), []);
  const sendPush = useCallback(() => {
    if (push.rateUsed >= push.rateMax) {
      showSnack("No pushes left this week.");
      return;
    }
    if (!push.message.trim()) {
      showSnack("Write a message first.");
      return;
    }
    setPush((p) => ({ ...p, rateUsed: p.rateUsed + 1, message: "" }));
    showSnack("Push queued for 240 followers.");
  }, [push.rateUsed, push.rateMax, push.message, showSnack]);
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
  /** Invited staff start on the narrowest role; the owner widens it after. */
  const sendInvite = useCallback(() => {
    const email = inviteEmail.trim();
    if (!email) {
      showSnack("Enter an email address first.");
      return;
    }
    const name = email.split("@")[0].replace(/[._-]+/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
    setTeam((p) => [...p, { id: `tm${Date.now()}`, name, email, role: "Door staff" }]);
    setInviteEmail("");
    showSnack(`Invite sent to ${email}.`);
  }, [inviteEmail, showSnack]);

  const setTeamRole = useCallback(
    (id: string, role: TeamRole) => {
      setTeam((p) => p.map((m) => (m.id === id ? { ...m, role } : m)));
      const member = team.find((m) => m.id === id);
      if (member) showSnack(`${member.name} is now ${role}.`);
    },
    [team, showSnack]
  );

  const removeTarget = team.find((m) => m.id === removeTargetId) ?? null;

  const resetRemoveFlow = useCallback(() => {
    setRemoveTargetId(null);
    setRemovePassword("");
    setRemoveAck(false);
    setRemoveError("");
  }, []);

  const startRemoveTeamMember = useCallback((id: string) => {
    setRemoveTargetId(id);
    setRemovePassword("");
    setRemoveAck(false);
    setRemoveError("");
  }, []);

  const setRemovePasswordValue = useCallback((v: string) => {
    setRemovePassword(v);
    setRemoveError("");
  }, []);

  const toggleRemoveAck = useCallback(() => {
    setRemoveAck((v) => !v);
    setRemoveError("");
  }, []);

  const confirmRemoveTeamMember = useCallback(() => {
    if (!removeTarget) return;
    // Mock auth: any password of a plausible length passes, except one demo
    // value kept around so the error state is reachable without a backend.
    if (removePassword.length < 6) {
      setRemoveError("Enter your account password to continue.");
      return;
    }
    if (removePassword === "wrongpass") {
      setRemoveError("That password doesn't match our records.");
      return;
    }
    if (!removeAck) {
      setRemoveError("Tick the box to confirm you understand.");
      return;
    }
    setTeam((p) => p.filter((m) => m.id !== removeTarget.id));
    resetRemoveFlow();
    showSnack(`${removeTarget.name} removed — access revoked and the platform admin was notified.`);
  }, [removeTarget, removePassword, removeAck, resetRemoveFlow, showSnack]);

  // ---- Reviews / inbox ----
  const setReviewReply = useCallback((id: string, value: string) => {
    setReviews((p) => p.map((r) => (r.id === id ? { ...r, reply: value } : r)));
  }, []);
  const toggleReviewFlag = useCallback(
    (id: string) => {
      const wasFlagged = reviews.find((r) => r.id === id)?.flagged;
      setReviews((p) => p.map((r) => (r.id === id ? { ...r, flagged: !r.flagged } : r)));
      showSnack(wasFlagged ? "Report withdrawn." : "Review reported to Trust & Safety.");
    },
    [reviews, showSnack]
  );
  /** Publishes the composer draft as the public reply guests see. */
  const sendReviewReply = useCallback(
    (id: string) => {
      const target = reviews.find((r) => r.id === id);
      if (!target?.reply.trim()) {
        showSnack("Write a reply first.");
        return;
      }
      const today = new Date().toLocaleDateString("en-US", { month: "short", day: "numeric" });
      setReviews((p) =>
        p.map((r) =>
          r.id === id && r.reply.trim()
            ? { ...r, posted: r.reply.trim(), postedWhen: today, reply: "" }
            : r
        )
      );
      showSnack(target.posted ? "Reply updated." : "Reply posted publicly.");
    },
    [reviews, showSnack]
  );
  /** Moves the posted reply back into the composer for another pass. */
  const editPostedReply = useCallback((id: string) => {
    setReviews((p) =>
      p.map((r) => (r.id === id ? { ...r, reply: r.posted, posted: "", postedWhen: "" } : r))
    );
  }, []);
  const deletePostedReply = useCallback(
    (id: string) => {
      setReviews((p) => p.map((r) => (r.id === id ? { ...r, posted: "", postedWhen: "" } : r)));
      showSnack("Reply removed.");
    },
    [showSnack]
  );
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

  const savedProfile = venues[editingVenue];
  const draft = venueDrafts[editingVenue];
  // The editor sees drafted listing fields; the menu and verification state it
  // shows are always the live ones, since those never enter the draft.
  const profile = draft ? withLiveFields(draft, savedProfile) : savedProfile;
  const venueDirty =
    !!draft &&
    JSON.stringify(listingFieldsOf(draft)) !== JSON.stringify(listingFieldsOf(savedProfile));
  const hasUnreadInbox = inbox.some((m) => !m.open);

  const value = useMemo<OrganizerDashboardValue>(
    () => ({
      organizer: MOCK_ORGANIZER,

      venueOrder,
      venues,
      editingVenue,
      profile,
      savedProfile,
      venueDirty,
      saveVenue,
      discardVenue,
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
      addSocialLink,
      removeSocialLink,
      setSocialLinkField,
      setHourField,
      toggleDayClosed,
      addException,
      removeException,
      setExceptionField,
      toggleExceptionClosed,
      addMenuSection,
      removeMenuSection,
      setMenuSectionName,
      addMenuItem,
      removeMenuItem,
      setMenuItemField,
      toggleMenuItemSoldOut,
      toggleMenuItemTag,
      toggleMenuItemNight,
      toggleVerifyStep,
      approveVenue,

      homeTab,
      setHomeTab,
      eventsTab,
      setEventsTab,
      audienceTab,
      setAudienceTab,
      accountTab,
      setAccountTab,

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
      inviteEmail,
      setInviteEmail,
      sendInvite,
      setTeamRole,
      removeTarget,
      removePassword,
      removeAck,
      removeError,
      startRemoveTeamMember,
      setRemovePassword: setRemovePasswordValue,
      toggleRemoveAck,
      cancelRemoveTeamMember: resetRemoveFlow,
      confirmRemoveTeamMember,

      snack,
      showSnack,
      dismissSnack,

      reviews,
      setReviewReply,
      toggleReviewFlag,
      sendReviewReply,
      editPostedReply,
      deletePostedReply,
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
      venueOrder, venues, editingVenue, profile, savedProfile, venueDirty, saveVenue,
      discardVenue, venueTab, addingVenue, newVenueName, newVenueCity,
      openAddVenue, cancelAddVenue, createVenue, setVenueField, toggleVenueSetValue,
      addSocialLink, removeSocialLink, setSocialLinkField, setHourField,
      toggleDayClosed, addException, removeException, setExceptionField, toggleExceptionClosed,
      addMenuSection, removeMenuSection, setMenuSectionName, addMenuItem, removeMenuItem,
      setMenuItemField, toggleMenuItemSoldOut, toggleMenuItemTag, toggleMenuItemNight,
      toggleVerifyStep, approveVenue,
      homeTab, eventsTab, audienceTab, accountTab,
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
      team, inviteEmail, sendInvite, setTeamRole,
      removeTarget, removePassword, removeAck, removeError, startRemoveTeamMember,
      setRemovePasswordValue, toggleRemoveAck, resetRemoveFlow, confirmRemoveTeamMember,
      snack, showSnack, dismissSnack,
      reviews, setReviewReply, toggleReviewFlag, sendReviewReply, editPostedReply,
      deletePostedReply, inbox, toggleInboxItem, hasUnreadInbox,
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
