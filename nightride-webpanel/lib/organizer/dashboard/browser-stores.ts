/**
 * Two bits of state that genuinely live outside React and differ between the
 * server render and the browser: the dropped-image sidecar (localStorage) and
 * the wall clock. Both are exposed as `useSyncExternalStore` sources so the
 * server snapshot is explicit and hydration stays consistent.
 */

type Listener = () => void;

const IMAGE_STORAGE_KEY = "nr-organizer-image-slots";
const EMPTY_IMAGES: Record<string, string> = {};

function createImageSlotStore() {
  let snapshot: Record<string, string> = EMPTY_IMAGES;
  let hydrated = false;
  const listeners = new Set<Listener>();
  const emit = () => listeners.forEach((l) => l());

  function persist() {
    try {
      window.localStorage.setItem(IMAGE_STORAGE_KEY, JSON.stringify(snapshot));
    } catch {
      // Quota or private-mode errors are non-fatal — the image still shows
      // for this session, it just won't survive a reload.
    }
  }

  function read(): Record<string, string> {
    try {
      const raw = window.localStorage.getItem(IMAGE_STORAGE_KEY);
      return raw ? (JSON.parse(raw) as Record<string, string>) : EMPTY_IMAGES;
    } catch {
      return EMPTY_IMAGES;
    }
  }

  return {
    subscribe(listener: Listener) {
      listeners.add(listener);
      if (!hydrated) {
        hydrated = true;
        // Publish the stored images once React has finished subscribing, so
        // the first paint still matches the server-rendered (empty) markup.
        queueMicrotask(() => {
          snapshot = read();
          emit();
        });
      }
      return () => {
        listeners.delete(listener);
      };
    },
    getSnapshot: () => snapshot,
    getServerSnapshot: () => EMPTY_IMAGES,
    set(slotId: string, dataUrl: string) {
      snapshot = { ...snapshot, [slotId]: dataUrl };
      persist();
      emit();
    },
    remove(slotId: string) {
      const next = { ...snapshot };
      delete next[slotId];
      snapshot = next;
      persist();
      emit();
    },
  };
}

export const imageSlotStore = createImageSlotStore();

/** Ticks once a minute — enough for "is this event live right now". */
const CLOCK_INTERVAL_MS = 60_000;

function createClockStore() {
  let snapshot: Date | null = null;
  let timer: ReturnType<typeof setInterval> | null = null;
  const listeners = new Set<Listener>();
  const emit = () => listeners.forEach((l) => l());

  return {
    subscribe(listener: Listener) {
      listeners.add(listener);
      if (!timer) {
        timer = setInterval(() => {
          snapshot = new Date();
          emit();
        }, CLOCK_INTERVAL_MS);
        queueMicrotask(() => {
          snapshot = new Date();
          emit();
        });
      }
      return () => {
        listeners.delete(listener);
        if (listeners.size === 0 && timer) {
          clearInterval(timer);
          timer = null;
        }
      };
    },
    getSnapshot: () => snapshot,
    /** The server has no meaningful clock for the organizer's timezone. */
    getServerSnapshot: () => null,
  };
}

export const clockStore = createClockStore();
