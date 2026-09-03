"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  deleteDoc,
  doc,
  GeoPoint,
  getDocs,
  onSnapshot,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from "firebase/firestore";
import { getDb } from "@/lib/firebase";
import { encodeGeohash } from "@/lib/admin/geo";
import {
  computeVenueProfile,
  DEFAULT_TONIGHT_STATE,
  isVenueDirty,
  parseMenuSection,
  parseTonight,
  parseVenueProfile,
  toLiveFields,
  toMenuSectionFields,
  toVenueEditListing,
} from "../data/venues";
import {
  venueActivityCol,
  venueDocRef,
  venueEditsDocRef,
  venueMenuSectionDocRef,
  venueMenuSectionsCol,
  venuesCol,
} from "../data/refs";
import { describeFirestoreError } from "../data/errors";
import { crowdLevelForDoorStatus, liveStatusFor, offerFor, queueStatusForDoorStatus, ticketsAvailableFor } from "../data/enums";
import type { DoorStatus, MenuItem, TonightState, VenueProfile, VerifyStepId } from "../types";
import { useAsyncAction } from "./useAsyncAction";
import { useVenueEditor } from "./useVenueEditor";
import { useLatest } from "./useLatest";

export type VenueTab = "profile" | "menu" | "hours" | "links";

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
 * Best-effort device geolocation for a brand-new venue. The "Add venue" panel
 * only ever collected a name and a free-text city — no address step, no map
 * picker — but `venueShapeOk()` requires `geo is latlng` on every create.
 * `(0, 0)` is a loud, greppable placeholder rather than a plausible-looking
 * lie; every fallback path logs so this doesn't go unnoticed in the field.
 * See the task report for why this is flagged as a follow-up rather than
 * solved properly here (no geocoding service is wired in, and the brief is
 * silent on where one would come from).
 */
function bestEffortGeo(): Promise<{ latitude: number; longitude: number }> {
  const fallback = { latitude: 0, longitude: 0 };
  return new Promise((resolve) => {
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      console.warn(
        "[useVenues] createVenue: geolocation unavailable in this environment — falling back to (0, 0). This venue's real location must be corrected (e.g. by an admin) before it belongs on the map."
      );
      resolve(fallback);
      return;
    }
    let settled = false;
    const finish = (value: { latitude: number; longitude: number }, warning?: string) => {
      if (settled) return;
      settled = true;
      if (warning) console.warn(`[useVenues] createVenue: ${warning}`);
      resolve(value);
    };
    const timer = setTimeout(
      () => finish(fallback, "geolocation timed out — falling back to (0, 0)."),
      4000
    );
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        clearTimeout(timer);
        finish({ latitude: pos.coords.latitude, longitude: pos.coords.longitude });
      },
      () => {
        clearTimeout(timer);
        finish(fallback, "geolocation denied or failed — falling back to (0, 0).");
      },
      { timeout: 4000 }
    );
  });
}

function resolvedTimeZoneWithFallback(): string {
  try {
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
    if (tz) {
      console.warn(
        `[useVenues] createVenue: no address/geocoding step exists yet to derive a real time zone — falling back to this browser's local zone (${tz}). That is only correct if the organizer is creating the venue from a device physically in it.`
      );
    }
    return tz ?? "";
  } catch {
    return "";
  }
}

async function logActivity(batch: ReturnType<typeof writeBatch>, venueId: string, actorUid: string, what: string) {
  batch.set(doc(venueActivityCol(venueId)), { actorUid, at: serverTimestamp(), what });
}

/**
 * Venue CRUD, the draft/published listing seam, the menu subcollection, and
 * the "tonight" door-status surface — real Firestore now: one `onSnapshot`
 * listener over the caller's venues, one-shot menu reads refetched after
 * every write, and the venue document as the single source of truth for
 * everything else. `uid` is guaranteed non-null by `OrganizerGate` — this
 * hook only ever mounts once auth status is "approved".
 */
export function useVenues(uid: string, showSnack: (text: string, tone?: "info" | "error") => void) {
  // ---- Reads: the one listener ----
  const [rawDocs, setRawDocs] = useState<Record<string, Record<string, unknown>>>({});
  const [venuesLoading, setVenuesLoading] = useState(true);
  const [venuesError, setVenuesError] = useState("");

  useEffect(() => {
    setVenuesLoading(true);
    const q = query(venuesCol(), where("editorUids", "array-contains", uid));
    const unsub = onSnapshot(
      q,
      (snap) => {
        const next: Record<string, Record<string, unknown>> = {};
        snap.forEach((d) => {
          next[d.id] = d.data() as Record<string, unknown>;
        });
        setRawDocs(next);
        setVenuesError("");
        setVenuesLoading(false);
      },
      (err) => {
        setVenuesError(describeFirestoreError(err));
        setVenuesLoading(false);
      }
    );
    return unsub;
  }, [uid]);

  const rawDocsRef = useLatest(rawDocs);

  // ---- Menu: one-shot per venue, refetched after every write ----
  const [menuByVenue, setMenuByVenue] = useState<Record<string, ReturnType<typeof parseMenuSection>[]>>({});
  const [menuLoadingIds, setMenuLoadingIds] = useState<Set<string>>(new Set());

  const fetchMenu = useCallback(async (venueId: string) => {
    setMenuLoadingIds((prev) => new Set(prev).add(venueId));
    try {
      const snap = await getDocs(venueMenuSectionsCol(venueId));
      const sections = snap.docs.map((d) => parseMenuSection(d.id, d.data() as Record<string, unknown>));
      setMenuByVenue((prev) => ({ ...prev, [venueId]: sections }));
    } catch (err) {
      showSnack(describeFirestoreError(err), "error");
    } finally {
      setMenuLoadingIds((prev) => {
        const next = new Set(prev);
        next.delete(venueId);
        return next;
      });
    }
  }, [showSnack]);

  // ---- Selection ----
  const [editingVenue, setEditingVenueRaw] = useState("");
  const [venueTab, setVenueTab] = useState<VenueTab>("profile");
  const [addingVenue, setAddingVenue] = useState(false);
  const [newVenueName, setNewVenueName] = useState("");
  const [newVenueCity, setNewVenueCity] = useState("");

  const venueOrder = useMemo(
    () =>
      Object.keys(rawDocs).sort((a, b) => {
        const an = typeof rawDocs[a]?.name === "string" ? (rawDocs[a].name as string) : "";
        const bn = typeof rawDocs[b]?.name === "string" ? (rawDocs[b].name as string) : "";
        return an.localeCompare(bn) || a.localeCompare(b);
      }),
    [rawDocs]
  );

  // Once the listener resolves, land on the first venue if nothing (or a
  // since-removed venue) is selected. Never overrides a valid selection —
  // switching venues is the organizer's call, not the snapshot's.
  useEffect(() => {
    if (venuesLoading) return;
    setEditingVenueRaw((prev) => (venueOrder.includes(prev) ? prev : venueOrder[0] ?? ""));
  }, [venueOrder, venuesLoading]);

  useEffect(() => {
    if (editingVenue) fetchMenu(editingVenue);
  }, [editingVenue, fetchMenu]);

  const { drafts: venueDrafts, updateListing, discard } = useVenueEditor();
  const { busy, actionError, run } = useAsyncAction();

  // `openVerifyStep` is pure client accordion state — which verification row
  // is expanded — never written to Firestore, so it lives here rather than
  // in `parseVenueProfile`'s output.
  const [openVerifyStepByVenue, setOpenVerifyStepByVenue] = useState<Record<string, VerifyStepId | null>>({});

  const venues = useMemo(() => {
    const out: Record<string, VenueProfile> = {};
    for (const id of venueOrder) {
      const parsed = parseVenueProfile(id, rawDocs[id], menuByVenue[id] ?? []);
      out[id] = id in openVerifyStepByVenue ? { ...parsed, openVerifyStep: openVerifyStepByVenue[id] } : parsed;
    }
    return out;
  }, [venueOrder, rawDocs, menuByVenue, openVerifyStepByVenue]);
  const venuesRef = useLatest(venues);

  const toggleVerifyStep = useCallback(
    (id: string, step: VerifyStepId) => {
      setOpenVerifyStepByVenue((prev) => {
        const current = id in prev ? prev[id] : venuesRef.current[id]?.openVerifyStep ?? null;
        return { ...prev, [id]: current === step ? null : step };
      });
    },
    [venuesRef]
  );

  const setEditingVenue = useCallback((id: string) => {
    setEditingVenueRaw(id);
    setVenueTab("profile");
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

  // ---- Menu: writes straight to `menuSections/{id}`, debounced 800ms per
  // section so typing doesn't fire a write per keystroke, refetched after
  // every commit so the panel never drifts from what the app actually shows.
  // Structural edits (add/remove section or item, toggles) go through the
  // same path — the brief's optimistic/debounced/pessimistic split covers
  // `live` fields only; menu bypasses the draft entirely (rules: no review),
  // so this hook applies the same "coalesce writes, refetch after" treatment
  // uniformly rather than inventing a fourth category.
  const menuWrites = useRef<
    Record<string, { timer: ReturnType<typeof setTimeout>; venueId: string; sectionId: string }>
  >({});

  const commitMenuSection = useCallback(
    async (venueId: string, sectionId: string, section: ReturnType<typeof parseMenuSection>) => {
      try {
        await setDoc(venueMenuSectionDocRef(venueId, sectionId), toMenuSectionFields(section));
      } catch (err) {
        showSnack(describeFirestoreError(err), "error");
      } finally {
        fetchMenu(venueId);
      }
    },
    [showSnack, fetchMenu]
  );

  const scheduleMenuWrite = useCallback(
    (venueId: string, sectionId: string) => {
      const key = `${venueId}:${sectionId}`;
      const pending = menuWrites.current;
      if (pending[key]) clearTimeout(pending[key].timer);
      const timer = setTimeout(() => {
        delete pending[key];
        const section = menuByVenue[venueId]?.find((s) => s.id === sectionId);
        if (section) commitMenuSection(venueId, sectionId, section);
      }, 800);
      pending[key] = { timer, venueId, sectionId };
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [commitMenuSection]
  );

  const flushMenuWrite = useCallback(
    (venueId: string, sectionId: string) => {
      const key = `${venueId}:${sectionId}`;
      const pending = menuWrites.current[key];
      if (!pending) return;
      clearTimeout(pending.timer);
      delete menuWrites.current[key];
      const section = menuByVenue[venueId]?.find((s) => s.id === sectionId);
      if (section) commitMenuSection(venueId, sectionId, section);
    },
    [menuByVenue, commitMenuSection]
  );

  useEffect(
    () => () => {
      // Flush-on-unmount: fire every pending menu write; the promise races
      // the teardown, same best-effort semantics as `useDebouncedWrite`'s.
      for (const key of Object.keys(menuWrites.current)) {
        const pending = menuWrites.current[key];
        clearTimeout(pending.timer);
        const section = menuByVenue[pending.venueId]?.find((s) => s.id === pending.sectionId);
        if (section) commitMenuSection(pending.venueId, pending.sectionId, section);
      }
      menuWrites.current = {};
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  );

  const updateMenuLocal = useCallback(
    (id: string, fn: (sections: ReturnType<typeof parseMenuSection>[]) => ReturnType<typeof parseMenuSection>[]) => {
      setMenuByVenue((prev) => ({ ...prev, [id]: fn(prev[id] ?? []) }));
    },
    []
  );

  const addMenuSection = useCallback(
    (id: string) => {
      const section = { id: nextMenuId("sec"), name: "New section", items: [] };
      updateMenuLocal(id, (sections) => [...sections, section]);
      scheduleMenuWrite(id, section.id);
    },
    [updateMenuLocal, scheduleMenuWrite]
  );
  const removeMenuSection = useCallback(
    (id: string, sectionId: string) => {
      updateMenuLocal(id, (sections) => sections.filter((s) => s.id !== sectionId));
      const pending = menuWrites.current[`${id}:${sectionId}`];
      if (pending) {
        clearTimeout(pending.timer);
        delete menuWrites.current[`${id}:${sectionId}`];
      }
      deleteDoc(venueMenuSectionDocRef(id, sectionId))
        .catch((err) => showSnack(describeFirestoreError(err), "error"))
        .finally(() => fetchMenu(id));
    },
    [updateMenuLocal, showSnack, fetchMenu]
  );
  const setMenuSectionName = useCallback(
    (id: string, sectionId: string, name: string) => {
      updateMenuLocal(id, (sections) => sections.map((s) => (s.id === sectionId ? { ...s, name } : s)));
      scheduleMenuWrite(id, sectionId);
    },
    [updateMenuLocal, scheduleMenuWrite]
  );

  const patchMenuItem = useCallback(
    (id: string, sectionId: string, itemId: string, patch: Partial<MenuItem>) => {
      updateMenuLocal(id, (sections) =>
        sections.map((sec) =>
          sec.id !== sectionId
            ? sec
            : { ...sec, items: sec.items.map((it) => (it.id === itemId ? { ...it, ...patch } : it)) }
        )
      );
      scheduleMenuWrite(id, sectionId);
    },
    [updateMenuLocal, scheduleMenuWrite]
  );

  const addMenuItem = useCallback(
    (id: string, sectionId: string) => {
      updateMenuLocal(id, (sections) =>
        sections.map((s) =>
          s.id !== sectionId
            ? s
            : {
                ...s,
                items: [
                  ...s.items,
                  { id: nextMenuId("item"), name: "", price: 0, desc: "", size: "", serves: "", tags: [], nights: [], soldOut: false },
                ],
              }
        )
      );
      scheduleMenuWrite(id, sectionId);
    },
    [updateMenuLocal, scheduleMenuWrite]
  );
  const removeMenuItem = useCallback(
    (id: string, sectionId: string, itemId: string) => {
      updateMenuLocal(id, (sections) =>
        sections.map((s) => (s.id !== sectionId ? s : { ...s, items: s.items.filter((it) => it.id !== itemId) }))
      );
      scheduleMenuWrite(id, sectionId);
    },
    [updateMenuLocal, scheduleMenuWrite]
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
      flushMenuWrite(id, sectionId);
      const name = item?.name || "Item";
      showSnack(item?.soldOut ? `${name} is back on the menu.` : `${name} marked sold out.`);
    },
    [venueDrafts, venues, patchMenuItem, flushMenuWrite, showSnack]
  );

  const toggleMenuItemTag = useCallback(
    (id: string, sectionId: string, itemId: string, tag: string) => {
      updateMenuLocal(id, (sections) =>
        sections.map((s) =>
          s.id !== sectionId
            ? s
            : {
                ...s,
                items: s.items.map((it) =>
                  it.id !== itemId ? it : { ...it, tags: it.tags.includes(tag) ? it.tags.filter((t) => t !== tag) : [...it.tags, tag] }
                ),
              }
        )
      );
      scheduleMenuWrite(id, sectionId);
    },
    [updateMenuLocal, scheduleMenuWrite]
  );
  const toggleMenuItemNight = useCallback(
    (id: string, sectionId: string, itemId: string, night: number) => {
      updateMenuLocal(id, (sections) =>
        sections.map((s) =>
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
        )
      );
      scheduleMenuWrite(id, sectionId);
    },
    [updateMenuLocal, scheduleMenuWrite]
  );

  // ---- Save / discard: the listing draft -> `venueEdits/{id}` ----
  const saveVenue = useCallback(
    async (id: string) => {
      const draft = venueDrafts[id];
      if (!draft) {
        showSnack("No changes to save.");
        return;
      }
      const ok = await run(async () => {
        const batch = writeBatch(getDb());
        batch.set(venueEditsDocRef(id), {
          venueId: id,
          status: "pending",
          listing: toVenueEditListing(draft),
          submittedBy: uid,
          submittedAt: serverTimestamp(),
          reviewedBy: null,
          reviewedAt: null,
          note: "",
        });
        await logActivity(batch, id, uid, "Submitted listing changes for review");
        await batch.commit();
        discard(id);
      });
      if (ok) showSnack("Changes submitted for review.");
    },
    [venueDrafts, run, discard, showSnack, uid]
  );

  const discardVenue = useCallback(
    (id: string) => {
      if (!venueDrafts[id]) return;
      discard(id);
      showSnack("Changes discarded.");
    },
    [venueDrafts, discard, showSnack]
  );

  // ---- Add venue ----
  const openAddVenue = useCallback(() => {
    setAddingVenue(true);
    setNewVenueName("");
    setNewVenueCity("");
  }, []);
  const cancelAddVenue = useCallback(() => setAddingVenue(false), []);

  const createVenue = useCallback(
    async (days: readonly string[]) => {
      const name = newVenueName.trim();
      if (!name) return;
      const city = newVenueCity.trim() || "City, Country";
      const ok = await run(async () => {
        const { latitude, longitude } = await bestEffortGeo();
        const timeZone = resolvedTimeZoneWithFallback();
        const blank = blankVenueProfile(name, city, days);
        const ref = doc(venuesCol());
        await setDoc(ref, {
          name,
          city,
          countryCode: "",
          timeZone,
          geo: new GeoPoint(latitude, longitude),
          geohash: encodeGeohash(latitude, longitude),
          source: "organizer",
          status: "active",
          verified: false,
          ownerUid: uid,
          editors: { [uid]: "owner" },
          editorUids: [uid],
          ...toVenueEditListing(blank),
        });
        try {
          await setDoc(doc(venueActivityCol(ref.id)), {
            actorUid: uid,
            at: serverTimestamp(),
            what: `Created venue "${name}"`,
          });
        } catch {
          // Non-fatal: the venue itself was created successfully.
        }
        setEditingVenue(ref.id);
        setAddingVenue(false);
        setNewVenueName("");
        setNewVenueCity("");
      });
      if (ok) showSnack("Venue created — complete verification from the mobile app.");
    },
    [newVenueName, newVenueCity, run, uid, setEditingVenue, showSnack]
  );

  // ---- Live door status ----
  const capacityFor = useCallback((id: string) => venuesRef.current[id]?.capacity ?? 0, [venuesRef]);

  const ensuredLive = useRef<Set<string>>(new Set());
  const ensureLive = useCallback(
    async (id: string) => {
      if (ensuredLive.current.has(id)) return;
      const raw = rawDocsRef.current[id];
      if (raw && "live" in raw && raw.live && typeof raw.live === "object") {
        ensuredLive.current.add(id);
        return;
      }
      await updateDoc(venueDocRef(id), {
        live: toLiveFields(DEFAULT_TONIGHT_STATE, { capacity: capacityFor(id), raw: {} }),
      });
      ensuredLive.current.add(id);
    },
    [rawDocsRef, capacityFor]
  );

  // Local echo overlaid on the snapshot-derived tonight, for both the three
  // optimistic controls and the three debounced fields — cleared as soon as
  // a fresh snapshot for this venue's `live` map lands, which is what
  // confirms the write (or, on the debounced fields, just reflects the
  // organizer's own typing until the 800ms commit lands).
  const [localTonight, setLocalTonight] = useState<TonightState | null>(null);
  const liveDocRef = rawDocs[editingVenue]?.live;
  useEffect(() => {
    setLocalTonight(null);
  }, [editingVenue, liveDocRef]);

  const [liveBusy, setLiveBusy] = useState({ door: false, flash: false, emergency: false });

  const tonight = useMemo(
    () => localTonight ?? parseTonight(rawDocs[editingVenue]?.live as Record<string, unknown> | undefined, capacityFor(editingVenue)),
    [localTonight, rawDocs, editingVenue, capacityFor]
  );
  const tonightRef = useLatest(tonight);

  const writeLivePatch = useCallback(
    async (id: string, patch: Record<string, unknown>, activityWhat: string) => {
      await ensureLive(id);
      const batch = writeBatch(getDb());
      const dotted: Record<string, unknown> = { "live.updatedAt": serverTimestamp() };
      for (const [k, v] of Object.entries(patch)) dotted[`live.${k}`] = v;
      batch.update(venueDocRef(id), dotted);
      await logActivity(batch, id, uid, activityWhat);
      await batch.commit();
    },
    [ensureLive, uid]
  );

  const setDoorStatus = useCallback(
    (status: DoorStatus) => {
      const id = editingVenue;
      const capacity = capacityFor(id);
      const current = tonightRef.current;
      const next: TonightState = { ...current, status };
      setLocalTonight(next);
      setLiveBusy((b) => ({ ...b, door: true }));
      showSnack(`Door status set to ${status}.`);
      writeLivePatch(
        id,
        {
          status: liveStatusFor(status),
          crowdLevel: crowdLevelForDoorStatus(status, current.inVenue, capacity),
          queueStatus: queueStatusForDoorStatus(status, current.queueMinutes),
          doorStatus: status,
          ticketsAvailable: ticketsAvailableFor(status),
        },
        `Set door status to ${status}`
      )
        .catch((err) => {
          setLocalTonight(null);
          showSnack(describeFirestoreError(err), "error");
        })
        .finally(() => setLiveBusy((b) => ({ ...b, door: false })));
    },
    [editingVenue, capacityFor, tonightRef, showSnack, writeLivePatch]
  );

  const queueMinutesTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const flushQueueMinutes = useCallback(
    (id: string, value: number) => {
      if (queueMinutesTimer.current) {
        clearTimeout(queueMinutesTimer.current);
        queueMinutesTimer.current = null;
      }
      const status = tonightRef.current.status;
      writeLivePatch(
        id,
        { queueMinutes: value, queueStatus: queueStatusForDoorStatus(status, value) },
        "Set queue wait"
      ).catch((err) => showSnack(describeFirestoreError(err), "error"));
    },
    [tonightRef, writeLivePatch, showSnack]
  );
  const setQueueMinutes = useCallback(
    (v: number) => {
      const id = editingVenue;
      setLocalTonight({ ...tonightRef.current, queueMinutes: v });
      if (queueMinutesTimer.current) clearTimeout(queueMinutesTimer.current);
      queueMinutesTimer.current = setTimeout(() => flushQueueMinutes(id, v), 800);
    },
    [editingVenue, tonightRef, flushQueueMinutes]
  );
  const flushQueueMinutesNow = useCallback(() => {
    if (!queueMinutesTimer.current) return;
    flushQueueMinutes(editingVenue, tonightRef.current.queueMinutes);
  }, [editingVenue, tonightRef, flushQueueMinutes]);

  const flashTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const commitFlash = useCallback(
    (id: string, next: TonightState) => {
      if (flashTimer.current) {
        clearTimeout(flashTimer.current);
        flashTimer.current = null;
      }
      writeLivePatch(
        id,
        {
          flash: { active: next.flashActive, text: next.flashText.slice(0, 200), until: next.flashUntil },
          offer: offerFor(next.flashActive, next.flashText),
        },
        "Updated flash offer"
      ).catch((err) => showSnack(describeFirestoreError(err), "error"));
    },
    [writeLivePatch, showSnack]
  );
  const scheduleFlash = useCallback(
    (next: TonightState) => {
      const id = editingVenue;
      setLocalTonight(next);
      if (flashTimer.current) clearTimeout(flashTimer.current);
      flashTimer.current = setTimeout(() => commitFlash(id, next), 800);
    },
    [editingVenue, commitFlash]
  );
  const setFlashText = useCallback(
    (v: string) => scheduleFlash({ ...tonightRef.current, flashText: v }),
    [scheduleFlash, tonightRef]
  );
  const setFlashUntil = useCallback(
    (v: string) => scheduleFlash({ ...tonightRef.current, flashUntil: v }),
    [scheduleFlash, tonightRef]
  );
  const flushFlashNow = useCallback(() => {
    if (!flashTimer.current) return;
    commitFlash(editingVenue, tonightRef.current);
  }, [editingVenue, commitFlash, tonightRef]);

  useEffect(
    () => () => {
      if (queueMinutesTimer.current) flushQueueMinutesNow();
      if (flashTimer.current) flushFlashNow();
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  );

  const toggleFlash = useCallback(() => {
    const id = editingVenue;
    const current = tonightRef.current;
    const nextActive = !current.flashActive;
    const next: TonightState = { ...current, flashActive: nextActive };
    setLocalTonight(next);
    setLiveBusy((b) => ({ ...b, flash: true }));
    showSnack(current.flashActive ? "Flash offer ended." : "Flash offer is live.");
    writeLivePatch(
      id,
      {
        flash: { active: nextActive, text: next.flashText.slice(0, 200), until: next.flashUntil },
        offer: offerFor(nextActive, next.flashText),
      },
      nextActive ? "Turned on flash offer" : "Turned off flash offer"
    )
      .catch((err) => {
        setLocalTonight(null);
        showSnack(describeFirestoreError(err), "error");
      })
      .finally(() => setLiveBusy((b) => ({ ...b, flash: false })));
  }, [editingVenue, tonightRef, showSnack, writeLivePatch]);

  const toggleEmergency = useCallback(async () => {
    const id = editingVenue;
    const current = tonightRef.current;
    const nextActive = !current.emergencyActive;
    setLocalTonight({ ...current, emergencyActive: nextActive });
    setLiveBusy((b) => ({ ...b, emergency: true }));
    showSnack(nextActive ? "Venue closed on the map." : "Venue reopened — you're back on the map.");
    try {
      await ensureLive(id);
      const batch = writeBatch(getDb());
      batch.update(venueDocRef(id), {
        "live.emergencyActive": nextActive,
        "live.updatedAt": serverTimestamp(),
        status: nextActive ? "closed" : "active",
      });
      await logActivity(batch, id, uid, nextActive ? "Emergency-closed the venue" : "Reopened the venue");
      await batch.commit();
    } catch (err) {
      setLocalTonight(null);
      showSnack(describeFirestoreError(err), "error");
    } finally {
      setLiveBusy((b) => ({ ...b, emergency: false }));
    }
  }, [editingVenue, tonightRef, showSnack, ensureLive, uid]);

  // ---- Derived profile: draft/published seam ----
  const savedProfile = venues[editingVenue] ?? blankVenueProfile("", "", []);
  const draft = venueDrafts[editingVenue];
  const profile = computeVenueProfile(draft, savedProfile);
  const venueDirty = isVenueDirty(draft, savedProfile);
  const menuLoading = menuLoadingIds.has(editingVenue);

  const data = useMemo(
    () => ({
      venueOrder,
      venues,
      venuesLoading,
      venuesError,
      editingVenue,
      profile,
      savedProfile,
      venueDirty,
      venueTab,
      addingVenue,
      newVenueName,
      newVenueCity,
      tonight,
      liveBusy,
      menuLoading,
    }),
    [
      venueOrder, venues, venuesLoading, venuesError, editingVenue, profile, savedProfile, venueDirty,
      venueTab, addingVenue, newVenueName, newVenueCity, tonight, liveBusy, menuLoading,
    ]
  );

  return useMemo(
    () => ({
      data,
      loading: venuesLoading,
      error: venuesError,
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
      flushMenuWrite,
      toggleVerifyStep,
      setDoorStatus,
      setQueueMinutes,
      setFlashText,
      setFlashUntil,
      toggleFlash,
      toggleEmergency,
      flushQueueMinutesNow,
      flushFlashNow,
    }),
    [
      data, busy, actionError, setEditingVenue, setVenueTab, openAddVenue, cancelAddVenue,
      setNewVenueName, setNewVenueCity, createVenue, saveVenue, discardVenue, setVenueField,
      toggleVenueSetValue, addSocialLink, removeSocialLink, setSocialLinkField, setHourField,
      toggleDayClosed, addException, removeException, setExceptionField, toggleExceptionClosed,
      addMenuSection, removeMenuSection, setMenuSectionName, addMenuItem, removeMenuItem,
      setMenuItemField, toggleMenuItemSoldOut, toggleMenuItemTag, toggleMenuItemNight, flushMenuWrite,
      toggleVerifyStep, setDoorStatus, setQueueMinutes, setFlashText, setFlashUntil, toggleFlash,
      toggleEmergency, flushQueueMinutesNow, flushFlashNow, venuesLoading, venuesError,
    ]
  );
}

export type VenuesState = ReturnType<typeof useVenues>;
