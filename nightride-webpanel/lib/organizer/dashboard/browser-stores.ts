/**
 * State that genuinely lives outside React and differs between the server
 * render and the browser: the wall clock, exposed as a `useSyncExternalStore`
 * source so the server snapshot is explicit and hydration stays consistent.
 */

type Listener = () => void;

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
