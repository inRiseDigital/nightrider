/**
 * Google Maps JS API loader for the organizer surface.
 *
 * The webpanel is a static export (`output: "export"`), so there is no server
 * to proxy or inject anything — the API key ships to the browser the same way
 * the Firebase web config does. Restrict it by HTTP referrer in the Google
 * Cloud console; that restriction, not secrecy, is what stops other origins
 * from spending against it.
 *
 * The Flutter app reads the same key from `--dart-define=GOOGLE_MAPS_API_KEY`
 * (Nightride/lib/core/config/maps_config.dart) — either one key with both an
 * app and a referrer restriction, or two keys on the same project.
 */

export const GOOGLE_MAPS_API_KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY ?? "";

/** Where the picker opens with no pin and no geolocation fix yet: Dubai. */
export const DEFAULT_MAP_CENTER = { latitude: 25.2048, longitude: 55.2708 };
export const DEFAULT_MAP_ZOOM = 11;

/** Zoom used once there is a fix — close enough to pick a door, not a district. */
export const PINNED_MAP_ZOOM = 17;

export function isGoogleMapsConfigured(): boolean {
  return GOOGLE_MAPS_API_KEY.length > 0;
}

const CALLBACK_NAME = "__nightrideGoogleMapsReady";

type MapsWindow = Window & {
  google?: { maps?: unknown };
  [CALLBACK_NAME]?: () => void;
};

let loadPromise: Promise<void> | null = null;

/**
 * Injects the Maps JS script once per page and resolves when `google.maps` is
 * usable. Memoised, so two pickers mounted at once share one script tag; a
 * failed load clears the memo so a retry actually retries.
 */
export function loadGoogleMaps(): Promise<void> {
  if (loadPromise) return loadPromise;

  loadPromise = new Promise<void>((resolve, reject) => {
    if (typeof window === "undefined") {
      reject(new Error("The map can only load in the browser."));
      return;
    }
    if (!isGoogleMapsConfigured()) {
      reject(new Error("Map unavailable: NEXT_PUBLIC_GOOGLE_MAPS_API_KEY is not set."));
      return;
    }

    const w = window as MapsWindow;
    if (w.google?.maps) {
      resolve();
      return;
    }

    // `loading=async` wants the callback form — without it the API logs a
    // performance warning and we would have to poll for readiness.
    const script = document.createElement("script");
    script.src =
      "https://maps.googleapis.com/maps/api/js" +
      `?key=${encodeURIComponent(GOOGLE_MAPS_API_KEY)}` +
      "&v=weekly&loading=async" +
      `&callback=${CALLBACK_NAME}`;
    script.async = true;
    script.onerror = () => {
      script.remove();
      reject(new Error("Could not load Google Maps. Check the API key and your connection."));
    };
    w[CALLBACK_NAME] = () => resolve();
    document.head.appendChild(script);
  }).catch((error: unknown) => {
    loadPromise = null;
    throw error;
  });

  return loadPromise;
}
