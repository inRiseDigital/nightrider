"use client";

import { useCallback, useMemo, useState } from "react";
import { MOCK_BOOST, MOCK_PERKS, MOCK_PROMOS, MOCK_PUSH } from "../mock-data";
import type { BoostSlot, PromoCode, PushState, RankPerk } from "../types";

/** `venues/{venueId}/{promotions,pushCampaigns,promoState,boosts,rankPerks}`. */
export function usePromotion(showSnack: (text: string, tone?: "info" | "error") => void) {
  const [push, setPush] = useState<PushState>(MOCK_PUSH);
  const [promos, setPromos] = useState<PromoCode[]>(MOCK_PROMOS);
  const [perks, setPerks] = useState<RankPerk[]>(MOCK_PERKS);
  const [boost, setBoost] = useState<BoostSlot>(MOCK_BOOST);

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

  const addPromo = useCallback(() => setPromos((p) => [...p, { code: "NEWCODE", desc: "", maxUses: 100, used: 0 }]), []);
  const updatePromo = useCallback((idx: number, field: "code" | "desc", value: string) => {
    setPromos((p) => p.map((x, i) => (i === idx ? { ...x, [field]: value } : x)));
  }, []);
  const removePromo = useCallback((idx: number) => setPromos((p) => p.filter((_, i) => i !== idx)), []);

  const updatePerk = useCallback((idx: number, value: string) => {
    setPerks((p) => p.map((x, i) => (i === idx ? { ...x, perk: value } : x)));
  }, []);

  const setBoostNight = useCallback((v: string) => setBoost((b) => ({ ...b, night: v })), []);
  const toggleBoost = useCallback(() => setBoost((b) => ({ ...b, active: !b.active })), []);

  const data = useMemo(() => ({ push, promos, perks, boost }), [push, promos, perks, boost]);

  return useMemo(
    () => ({ data, loading: false, error: null, busy: false, actionError: "", setPushMessage, sendPush, addPromo, updatePromo, removePromo, updatePerk, setBoostNight, toggleBoost }),
    [data, setPushMessage, sendPush, addPromo, updatePromo, removePromo, updatePerk, setBoostNight, toggleBoost]
  );
}

export type PromotionState = ReturnType<typeof usePromotion>;
