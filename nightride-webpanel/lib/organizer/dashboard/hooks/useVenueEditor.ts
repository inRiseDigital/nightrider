"use client";

import { useCallback, useReducer } from "react";
import type { VenueProfile } from "../types";

/**
 * Unsaved listing edits, keyed by venue id. A draft is created lazily on the
 * first edit (seeded from `base`, the published record) and cleared on
 * save/discard — `useVenues` always holds the published version separately.
 *
 * One reducer rather than the ~15 field-specific `useCallback`s the old
 * `store.tsx` had, one per editable shape (social links, hours, exceptions,
 * menu, ...): every one of them was the same "read the current draft (or
 * seed it), apply a pure function, write it back" shape, so the action payload
 * carries that function directly instead of the reducer re-deriving it from
 * a dozen action-type variants.
 */
type Drafts = Record<string, VenueProfile>;

type Action =
  | { type: "update"; id: string; base: VenueProfile; fn: (p: VenueProfile) => VenueProfile }
  | { type: "discard"; id: string };

function reducer(state: Drafts, action: Action): Drafts {
  switch (action.type) {
    case "update": {
      const current = state[action.id] ?? action.base;
      return { ...state, [action.id]: action.fn(current) };
    }
    case "discard": {
      if (!(action.id in state)) return state;
      const next = { ...state };
      delete next[action.id];
      return next;
    }
  }
}

export function useVenueEditor() {
  const [drafts, dispatch] = useReducer(reducer, {} as Drafts);

  const updateListing = useCallback(
    (id: string, base: VenueProfile, fn: (p: VenueProfile) => VenueProfile) => {
      dispatch({ type: "update", id, base, fn });
    },
    []
  );
  const discard = useCallback((id: string) => dispatch({ type: "discard", id }), []);

  return { drafts, updateListing, discard };
}

export type VenueEditorState = ReturnType<typeof useVenueEditor>;
