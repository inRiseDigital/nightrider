"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { addDoc, deleteDoc, doc, getDoc, getDocs, serverTimestamp, updateDoc } from "firebase/firestore";
import { venueBoostsCol, venuePromoStateDocRef, venuePromotionsCol, venuePushCampaignsCol, venueRankPerksDocRef } from "../data/refs";
import {
  parseBoostSlot,
  parsePromoCode,
  parsePromoState,
  parseRankPerks,
  pickCurrentBoost,
  toBoostCreateFields,
  toPromoCodeFields,
  type PromoState,
} from "../data/promotion";
import { useAsyncAction } from "./useAsyncAction";
import { describeFirestoreError } from "../data/errors";
import type { BoostSlot, PromoCode, PushState, RankPerk } from "../types";

const BLANK_PROMO_STATE: PromoState = { used: 0, max: 0 };
const BLANK_BOOST: BoostSlot = { active: false, night: "", price: 40 };

/**
 * `venues/{venueId}/{promotions,pushCampaigns,promoState,boosts,rankPerks}`.
 *
 * Real writes: promo codes (create/update/delete) and a boost request
 * (create only — `firestore.rules` forbids `update`/`delete` on `boosts`
 * once bought). `rankPerks/current` reads `write: if false` in
 * `firestore.rules` unconditionally, despite what an earlier pass of this
 * task's brief assumed — there is no `updatePerk` here at all; perks are
 * read-only (`PromotionSection.tsx` renders them as disabled inputs, not a
 * write that would only ever fail with `permission-denied`).
 * `promoState/current` is display state the organizer cannot write at all;
 * its `{used, max}` is shown as information, not a client-verified
 * guarantee — the real weekly cap is enforced by the FCM fanout function.
 * `sendPush` writes only `pushCampaigns/{id}` with `status: 'queued'`.
 */
export function usePromotion(venueId: string | null, showSnack: (text: string, tone?: "info" | "error") => void) {
  const [pushMessage, setPushMessage] = useState("");
  const [promoState, setPromoState] = useState<PromoState>(BLANK_PROMO_STATE);
  const [promos, setPromos] = useState<(PromoCode & { id: string })[]>([]);
  const [perks, setPerks] = useState<RankPerk[]>([]);
  const [boost, setBoost] = useState<(BoostSlot & { id: string }) | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const fetchAll = useCallback(async () => {
    if (!venueId) {
      setPromoState(BLANK_PROMO_STATE);
      setPromos([]);
      setPerks([]);
      setBoost(null);
      setLoading(false);
      setError("");
      return;
    }
    setLoading(true);
    try {
      const [promoStateSnap, perksSnap, promosSnap, boostsSnap] = await Promise.all([
        getDoc(venuePromoStateDocRef(venueId)),
        getDoc(venueRankPerksDocRef(venueId)),
        getDocs(venuePromotionsCol(venueId)),
        getDocs(venueBoostsCol(venueId)),
      ]);
      setPromoState(parsePromoState(promoStateSnap.exists() ? (promoStateSnap.data() as Record<string, unknown>) : undefined));
      setPerks(parseRankPerks(perksSnap.exists() ? (perksSnap.data() as Record<string, unknown>).perks : undefined));
      setPromos(promosSnap.docs.map((d) => parsePromoCode(d.id, d.data() as Record<string, unknown>)));
      const boostDoc = pickCurrentBoost(
        boostsSnap.docs.map((d) => ({ id: d.id, data: d.data() as Record<string, unknown> }))
      );
      setBoost(boostDoc ? parseBoostSlot(boostDoc.id, boostDoc.data) : null);
      setError("");
    } catch (err) {
      setError(describeFirestoreError(err));
    } finally {
      setLoading(false);
    }
  }, [venueId]);

  useEffect(() => {
    fetchAll();
  }, [fetchAll]);

  const { busy, actionError, run } = useAsyncAction(fetchAll);

  const sendPush = useCallback(async () => {
    if (!venueId) return;
    if (!pushMessage.trim()) {
      showSnack("Write a message first.", "error");
      return;
    }
    const ok = await run(async () => {
      await addDoc(venuePushCampaignsCol(venueId), {
        message: pushMessage.trim(),
        status: "queued",
        createdAt: serverTimestamp(),
      });
    });
    if (ok) {
      setPushMessage("");
      showSnack("Push queued — the weekly limit is enforced when it sends, not here.", "info");
    } else {
      showSnack("Couldn't queue that push.", "error");
    }
  }, [venueId, pushMessage, run, showSnack]);

  const addPromo = useCallback(async () => {
    if (!venueId) return;
    const ok = await run(async () => {
      await addDoc(venuePromotionsCol(venueId), { code: "NEWCODE", desc: "", maxUses: 100, used: 0, createdAt: serverTimestamp() });
    });
    if (!ok) showSnack("Couldn't add that code.", "error");
  }, [venueId, run, showSnack]);

  const updatePromo = useCallback(
    async (idx: number, field: "code" | "desc", value: string) => {
      const target = promos[idx];
      if (!venueId || !target) return;
      const { id, ...ui } = target;
      const next = { ...ui, [field]: value };
      setPromos((p) => p.map((x, i) => (i === idx ? { ...x, [field]: value } : x)));
      // `updateDoc` merges, so there is no need to spread an existing raw doc
      // here — `used` is simply omitted from the patch and stays untouched.
      const ok = await run(async () => {
        await updateDoc(doc(venuePromotionsCol(venueId), id), toPromoCodeFields(next, { raw: {} }));
      });
      if (!ok) showSnack("Couldn't save that code.", "error");
    },
    [venueId, promos, run, showSnack]
  );

  const removePromo = useCallback(
    async (idx: number) => {
      const target = promos[idx];
      if (!venueId || !target) return;
      const ok = await run(async () => {
        await deleteDoc(doc(venuePromotionsCol(venueId), target.id));
      });
      if (!ok) showSnack("Couldn't remove that code.", "error");
    },
    [venueId, promos, run, showSnack]
  );

  const [boostNightDraft, setBoostNightDraft] = useState("2026-08-15");
  const setBoostNight = useCallback((v: string) => setBoostNightDraft(v), []);

  const toggleBoost = useCallback(async () => {
    if (!venueId) return;
    if (boost) {
      showSnack("Boosts can't be cancelled or edited from here once bought.", "error");
      return;
    }
    const ok = await run(async () => {
      await addDoc(venueBoostsCol(venueId), toBoostCreateFields(boostNightDraft, BLANK_BOOST.price, serverTimestamp()));
    });
    if (!ok) showSnack("Couldn't buy that boost.", "error");
  }, [venueId, boost, boostNightDraft, run, showSnack]);

  const push: PushState = useMemo(
    () => ({ message: pushMessage, rateUsed: promoState.used, rateMax: promoState.max }),
    [pushMessage, promoState]
  );
  const boostUi: BoostSlot = useMemo(
    () => (boost ? { active: boost.active, night: boost.night, price: boost.price } : { ...BLANK_BOOST, night: boostNightDraft }),
    [boost, boostNightDraft]
  );

  const promosUi: PromoCode[] = useMemo(
    () => promos.map((p) => ({ code: p.code, desc: p.desc, maxUses: p.maxUses, used: p.used })),
    [promos]
  );

  const data = useMemo(() => ({ push, promos: promosUi, perks, boost: boostUi }), [push, promosUi, perks, boostUi]);

  return useMemo(
    () => ({
      data,
      loading,
      error,
      busy,
      actionError,
      setPushMessage,
      sendPush,
      addPromo,
      updatePromo,
      removePromo,
      setBoostNight,
      toggleBoost,
    }),
    [data, loading, error, busy, actionError, sendPush, addPromo, updatePromo, removePromo, setBoostNight, toggleBoost]
  );
}

export type PromotionState = ReturnType<typeof usePromotion>;
