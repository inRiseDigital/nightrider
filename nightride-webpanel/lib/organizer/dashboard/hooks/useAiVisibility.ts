"use client";

import { useMemo } from "react";
import { MOCK_AI_INTENTS, MOCK_AI_RECOMMEND_COUNT } from "../mock-data";
import { MOCK_AI_PROMPTS, MOCK_AI_SCORE, MOCK_AI_TIPS } from "../mock-analytics";

/** `venues/{venueId}/aiVisibility/current` — read-only. */
export function useAiVisibility() {
  const data = useMemo(
    () => ({
      score: MOCK_AI_SCORE,
      prompts: MOCK_AI_PROMPTS,
      tips: MOCK_AI_TIPS,
      intents: MOCK_AI_INTENTS,
      recommendCount: MOCK_AI_RECOMMEND_COUNT,
    }),
    []
  );

  return useMemo(() => ({ data, loading: false, error: null, busy: false, actionError: "" }), [data]);
}

export type AiVisibilityState = ReturnType<typeof useAiVisibility>;
