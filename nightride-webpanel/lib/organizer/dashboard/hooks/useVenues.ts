"use client";

import { useCallback, useMemo, useState } from "react";
import { MOCK_TONIGHT, MOCK_VENUES, MOCK_VENUE_ORDER } from "../mock-data";
import type { DoorStatus, MenuItem, TonightState, VenueProfile, VerifyStepId } from "../types";
import { useAsyncAction } from "./useAsyncAction";
import { useVenueEditor } from "./useVenueEditor";

export type VenueTab = "profile" | "menu" | "hours" | "links";

/**
 * Fields that bypass the venue draft. Verification state is set by an admin
 * rather than the organizer, so it writes to the published record directly:
 * it is excluded from the dirty check and preserved when a draft commits.
 */
const LIVE_VENUE_FIELDS = ["verified", "verificationSteps", "openVerifyStep"] as const;

function withLiveFields(draft: VenueProfile, saved: VenueProfile): VenueProfile {
  return {
    ...draft,
    verified: saved.verified,
    verificationSteps: saved.verificationSteps,
    openVerifyStep: saved.openVerifyStep,
  };
}

function listingFieldsOf(p: VenueProfile): Partial<VenueProfile> {
  const listing: Partial<VenueProfile> = { ...p };
  for (const field of LIVE_VENUE_FIELDS) delete listing[field];
  return listing;
}

export function blankVenueProfile(name: string, city: string, days: readonly string[]): VenueProfile {
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
    hours: days.map((day) => ({ day: day as VenueProfile["hours"][number]["day"], closed: false, open: "22:00", close: "04:00" })),
    exceptions: [],
    menu: [],
    tableLink: "",
  };
}

let menuIdSeq = 0;
function nextMenuId(prefix: string) {
  menuIdSeq += 1;
  return `${prefix}-${Date.now().toString(36)}-${menuIdSeq}`;
}

/**
 * Venue CRUD, the draft/published listing seam, menu, hours/exceptions, and
 * the "tonight" door-status document — one Firestore document (`venues/{id}`
 * plus its `live` map), one hook, one context.
 */
export function useVenues(showSnack: (text: string, tone?: "info" | "error") => void) {
  const [venueOrder, setVenueOrder] = useState<string[]>(MOCK_VENUE_ORDER);
  const [venues, setVenues] = useState<Record<string, VenueProfile>>(MOCK_VENUES);
  const [editingVenue, setEditingVenue] = useState(MOCK_VENUE_ORDER[0]);
  const [venueTab, setVenueTab] = useState<VenueTab>("profile");
  const [addingVenue, setAddingVenue] = useState(false);
  const [newVenueName, setNewVenueName] = useState("");
  const [newVenueCity, setNewVenueCity] = useState("");
  const [tonight, setTonight] = useState<TonightState>(MOCK_TONIGHT);

  const { drafts: venueDrafts, updateListing, discard } = useVenueEditor();
  const { busy, actionError, run } = useAsyncAction();

  const updateVenue = useCallback((id: string, fn: (p: VenueProfile) => VenueProfile) => {
    setVenues((prev) => ({ ...prev, [id]: fn(prev[id]) }));
  }, []);

  const updateVenueListing = useCallback(
    (id: string, fn: (p: VenueProfile) => VenueProfile) => updateListing(id, venues[id], fn),
    [updateListing, venues]
  );

  const setVenueField = useCallback(
    <K extends keyof VenueProfile>(id: string, field: K, value: VenueProfile[K]) =>
      updateVenueListing(id, (p) => ({ ...p, [field]: value })),
    [updateVenueListing]
  );

  const toggleVenueSetValue = useCallback(
    (id: string, field: "genres" | "amenities", value: string) =>
      updateVenueListing(id, (p) => ({
        ...p,
        [field]: p[field].includes(value) ? p[field].filter((x) => x !== value) : [...p[field], value],
      })),
    [updateVenueListing]
  );

  const addSocialLink = useCallback(
    (id: string) =>
      updateVenueListing(id, (p) => ({ ...p, socialLinks: [...p.socialLinks, { network: "instagram", value: "" }] })),
    [updateVenueListing]
  );
  const removeSocialLink = useCallback(
    (id: string, idx: number) =>
      updateVenueListing(id, (p) => ({ ...p, socialLinks: p.socialLinks.filter((_, i) => i !== idx) })),
    [updateVenueListing]
  );
  const setSocialLinkField = useCallback(
    (id: string, idx: number, field: "network" | "value", value: string) =>
      updateVenueListing(id, (p) => ({
        ...p,
        socialLinks: p.socialLinks.map((s, i) => (i === idx ? { ...s, [field]: value } : s)),
      })),
    [updateVenueListing]
  );

  const setHourField = useCallback(
    (id: string, dayIdx: number, field: "open" | "close", value: string) =>
      updateVenueListing(id, (p) => ({
        ...p,
        hours: p.hours.map((h, i) => (i === dayIdx ? { ...h, [field]: value } : h)),
      })),
    [updateVenueListing]
  );
  const toggleDayClosed = useCallback(
    (id: string, dayIdx: number) =>
      updateVenueListing(id, (p) => ({
        ...p,
        hours: p.hours.map((h, i) => (i === dayIdx ? { ...h, closed: !h.closed } : h)),
      })),
    [updateVenueListing]
  );

  const addException = useCallback(
    (id: string) =>
      updateVenueListing(id, (p) => ({
        ...p,
        exceptions: [...p.exceptions, { label: "New exception", date: "", closed: true }],
      })),
    [updateVenueListing]
  );
  const removeException = useCallback(
    (id: string, idx: number) =>
      updateVenueListing(id, (p) => ({ ...p, exceptions: p.exceptions.filter((_, i) => i !== idx) })),
    [updateVenueListing]
  );
  const setExceptionField = useCallback(
    (id: string, idx: number, field: "label" | "date", value: string) =>
      updateVenueListing(id, (p) => ({
        ...p,
        exceptions: p.exceptions.map((e, i) => (i === idx ? { ...e, [field]: value } : e)),
      })),
    [updateVenueListing]
  );
  const toggleExceptionClosed = useCallback(
    (id: string, idx: number) =>
      updateVenueListing(id, (p) => ({
        ...p,
        exceptions: p.exceptions.map((e, i) => (i === idx ? { ...e, closed: !e.closed } : e)),
      })),
    [updateVenueListing]
  );

  const patchMenuItem = useCallback(
    (id: string, sectionId: string, itemId: string, patch: Partial<MenuItem>) =>
      updateVenueListing(id, (p) => ({
        ...p,
        menu: p.menu.map((sec) =>
          sec.id !== sectionId
            ? sec
            : { ...sec, items: sec.items.map((it) => (it.id === itemId ? { ...it, ...patch } : it)) }
        ),
      })),
    [updateVenueListing]
  );

  const addMenuSection = useCallback(
    (id: string) =>
      updateVenueListing(id, (p) => ({ ...p, menu: [...p.menu, { id: nextMenuId("sec"), name: "New section", items: [] }] })),
    [updateVenueListing]
  );
  const removeMenuSection = useCallback(
    (id: string, sectionId: string) => updateVenueListing(id, (p) => ({ ...p, menu: p.menu.filter((s) => s.id !== sectionId) })),
    [updateVenueListing]
  );
  const setMenuSectionName = useCallback(
    (id: string, sectionId: string, name: string) =>
      updateVenueListing(id, (p) => ({ ...p, menu: p.menu.map((s) => (s.id === sectionId ? { ...s, name } : s)) })),
    [updateVenueListing]
  );
  const addMenuItem = useCallback(
    (id: string, sectionId: string) =>
      updateVenueListing(id, (p) => ({
        ...p,
        menu: p.menu.map((s) =>
          s.id !== sectionId
            ? s
            : {
                ...s,
                items: [
                  ...s.items,
                  { id: nextMenuId("item"), name: "", price: 0, desc: "", size: "", serves: "", tags: [], nights: [], soldOut: false },
                ],
              }
        ),
      })),
    [updateVenueListing]
  );
  const removeMenuItem = useCallback(
    (id: string, sectionId: string, itemId: string) =>
      updateVenueListing(id, (p) => ({
        ...p,
        menu: p.menu.map((s) => (s.id !== sectionId ? s : { ...s, items: s.items.filter((it) => it.id !== itemId) })),
      })),
    [updateVenueListing]
  );
  const setMenuItemField = useCallback(
    <K extends keyof MenuItem>(id: string, sectionId: string, itemId: string, field: K, value: MenuItem[K]) =>
      patchMenuItem(id, sectionId, itemId, { [field]: value } as Partial<MenuItem>),
    [patchMenuItem]
  );

  const toggleMenuItemSoldOut = useCallback(
    (id: string, sectionId: string, itemId: string) => {
      const item = (venueDrafts[id] ?? venues[id])?.menu.find((s) => s.id === sectionId)?.items.find((it) => it.id === itemId);
      patchMenuItem(id, sectionId, itemId, { soldOut: !item?.soldOut });
      const name = item?.name || "Item";
      showSnack(item?.soldOut ? `${name} is back on the menu.` : `${name} marked sold out.`);
    },
    [venueDrafts, venues, patchMenuItem, showSnack]
  );

  const toggleMenuItemTag = useCallback(
    (id: string, sectionId: string, itemId: string, tag: string) =>
      updateVenueListing(id, (p) => ({
        ...p,
        menu: p.menu.map((s) =>
          s.id !== sectionId
            ? s
            : {
                ...s,
                items: s.items.map((it) =>
                  it.id !== itemId ? it : { ...it, tags: it.tags.includes(tag) ? it.tags.filter((t) => t !== tag) : [...it.tags, tag] }
                ),
              }
        ),
      })),
    [updateVenueListing]
  );
  const toggleMenuItemNight = useCallback(
    (id: string, sectionId: string, itemId: string, night: number) =>
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
                    : { ...it, nights: it.nights.includes(night) ? it.nights.filter((n) => n !== night) : [...it.nights, night].sort((a, b) => a - b) }
                ),
              }
        ),
      })),
    [updateVenueListing]
  );

  const toggleVerifyStep = useCallback(
    (id: string, step: VerifyStepId) => updateVenue(id, (p) => ({ ...p, openVerifyStep: p.openVerifyStep === step ? null : step })),
    [updateVenue]
  );

  const saveVenue = useCallback(
    async (id: string) => {
      const draft = venueDrafts[id];
      if (!draft) {
        showSnack("No changes to save.");
        return;
      }
      const ok = await run(async () => {
        setVenues((prev) => ({ ...prev, [id]: { ...prev[id], ...listingFieldsOf(draft) } }));
        discard(id);
      });
      if (ok) showSnack("Changes saved and submitted for review.");
    },
    [venueDrafts, run, discard, showSnack]
  );

  const discardVenue = useCallback(
    (id: string) => {
      if (!venueDrafts[id]) return;
      discard(id);
      showSnack("Changes discarded.");
    },
    [venueDrafts, discard, showSnack]
  );

  const openAddVenue = useCallback(() => {
    setAddingVenue(true);
    setNewVenueName("");
    setNewVenueCity("");
  }, []);
  const cancelAddVenue = useCallback(() => setAddingVenue(false), []);

  const createVenue = useCallback(
    (days: readonly string[]) => {
      const name = newVenueName.trim();
      if (!name) return;
      const id = `venue-${Date.now()}`;
      setVenues((prev) => ({ ...prev, [id]: blankVenueProfile(name, newVenueCity.trim() || "City, Country", days) }));
      setVenueOrder((prev) => [...prev, id]);
      setEditingVenue(id);
      setAddingVenue(false);
      setNewVenueName("");
      setNewVenueCity("");
    },
    [newVenueName, newVenueCity]
  );

  const setDoorStatus = useCallback(
    (status: DoorStatus) => {
      setTonight((p) => ({ ...p, status }));
      showSnack(`Door status set to ${status}.`);
    },
    [showSnack]
  );
  const setQueueMinutes = useCallback((v: number) => setTonight((p) => ({ ...p, queueMinutes: v })), []);
  const setFlashText = useCallback((v: string) => setTonight((p) => ({ ...p, flashText: v })), []);
  const setFlashUntil = useCallback((v: string) => setTonight((p) => ({ ...p, flashUntil: v })), []);
  const toggleFlash = useCallback(() => {
    setTonight((p) => {
      showSnack(p.flashActive ? "Flash offer ended." : "Flash offer is live.");
      return { ...p, flashActive: !p.flashActive };
    });
  }, [showSnack]);
  const toggleEmergency = useCallback(() => {
    setTonight((p) => {
      showSnack(p.emergencyActive ? "Venue reopened — you're back on the map." : "Emergency close requested — platform admin notified.");
      return { ...p, emergencyActive: !p.emergencyActive };
    });
  }, [showSnack]);

  const savedProfile = venues[editingVenue];
  const draft = venueDrafts[editingVenue];
  const profile = draft ? withLiveFields(draft, savedProfile) : savedProfile;
  const venueDirty = !!draft && JSON.stringify(listingFieldsOf(draft)) !== JSON.stringify(listingFieldsOf(savedProfile));

  const data = useMemo(
    () => ({
      venueOrder,
      venues,
      editingVenue,
      profile,
      savedProfile,
      venueDirty,
      venueTab,
      addingVenue,
      newVenueName,
      newVenueCity,
      tonight,
    }),
    [venueOrder, venues, editingVenue, profile, savedProfile, venueDirty, venueTab, addingVenue, newVenueName, newVenueCity, tonight]
  );

  return useMemo(
    () => ({
      data,
      loading: false,
      error: null,
      busy,
      actionError,
      setEditingVenue,
      setVenueTab,
      openAddVenue,
      cancelAddVenue,
      setNewVenueName,
      setNewVenueCity,
      createVenue,
      saveVenue,
      discardVenue,
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
      setDoorStatus,
      setQueueMinutes,
      setFlashText,
      setFlashUntil,
      toggleFlash,
      toggleEmergency,
    }),
    [
      data, busy, actionError, setEditingVenue, setVenueTab, openAddVenue, cancelAddVenue,
      setNewVenueName, setNewVenueCity, createVenue, saveVenue, discardVenue, setVenueField,
      toggleVenueSetValue, addSocialLink, removeSocialLink, setSocialLinkField, setHourField,
      toggleDayClosed, addException, removeException, setExceptionField, toggleExceptionClosed,
      addMenuSection, removeMenuSection, setMenuSectionName, addMenuItem, removeMenuItem,
      setMenuItemField, toggleMenuItemSoldOut, toggleMenuItemTag, toggleMenuItemNight,
      toggleVerifyStep, setDoorStatus, setQueueMinutes, setFlashText, setFlashUntil, toggleFlash,
      toggleEmergency,
    ]
  );
}

export type VenuesState = ReturnType<typeof useVenues>;
