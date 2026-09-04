"use client";

import { useCallback, useReducer, useState } from "react";
import type { OrganizerEvent } from "../types";

interface EditorState {
  isOpen: boolean;
  editingId: string | null;
  draft: OrganizerEvent | null;
}

type Action =
  | { type: "open"; id: string | null; draft: OrganizerEvent }
  | { type: "close" }
  | { type: "update"; field: keyof OrganizerEvent; value: unknown }
  | { type: "set"; draft: OrganizerEvent };

const INITIAL: EditorState = { isOpen: false, editingId: null, draft: null };

function reducer(state: EditorState, action: Action): EditorState {
  switch (action.type) {
    case "open":
      return { isOpen: true, editingId: action.id, draft: action.draft };
    case "close":
      return INITIAL;
    case "update":
      return state.draft ? { ...state, draft: { ...state.draft, [action.field]: action.value } } : state;
    case "set":
      return state.draft ? { ...state, draft: action.draft } : state;
  }
}

/** The event-editor dialog's draft — the one place besides `useVenueEditor` a reducer earns its keep. */
export function useEventEditor() {
  const [state, dispatch] = useReducer(reducer, INITIAL);
  const [lineupInput, setLineupInput] = useState("");

  const open = useCallback((id: string | null, draft: OrganizerEvent) => {
    dispatch({ type: "open", id, draft });
    setLineupInput("");
  }, []);
  const close = useCallback(() => {
    dispatch({ type: "close" });
    setLineupInput("");
  }, []);
  const update = useCallback(<K extends keyof OrganizerEvent>(field: K, value: OrganizerEvent[K]) => {
    dispatch({ type: "update", field, value });
  }, []);
  const set = useCallback((draft: OrganizerEvent) => dispatch({ type: "set", draft }), []);

  return { ...state, lineupInput, setLineupInput, open, close, update, set };
}

export type EventEditorState = ReturnType<typeof useEventEditor>;
