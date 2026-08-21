"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { Crosshair, LocateFixed, MapPin, X } from "lucide-react";
import { AccentButton } from "@/components/organizer/ui/AccentButton";
import { ErrorNote } from "@/components/organizer/ui/AuthCard";
import {
  DEFAULT_MAP_CENTER,
  DEFAULT_MAP_ZOOM,
  PINNED_MAP_ZOOM,
  isGoogleMapsConfigured,
  loadGoogleMaps,
} from "@/lib/organizer/google-maps";
import type { VenueAddressDraft } from "@/lib/organizer/types";

type Geo = NonNullable<VenueAddressDraft["geo"]>;

function formatGeo(geo: Geo): string {
  return `${geo.latitude.toFixed(5)}, ${geo.longitude.toFixed(5)}`;
}

/**
 * The venue-address step's "pin the location" control — the webpanel counterpart
 * of the Flutter step's location button (Nightride/lib/pages/organizer/
 * organizer_verify_page.dart), which captures a device GPS fix. A browser can't
 * do geolocator's mocked-location check, so this pin is a claim, not a proof:
 * the `gps` step on the mobile app is still what an admin measures against.
 * What it buys is a usable address for review instead of three typed fields.
 */
export function VenueLocationPicker({
  geo,
  onChange,
  disabled,
}: {
  geo: Geo | null;
  onChange: (geo: Geo | null) => void;
  disabled?: boolean;
}) {
  const [open, setOpen] = useState(false);

  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap items-center gap-2">
        <button
          type="button"
          disabled={disabled}
          onClick={() => setOpen(true)}
          className="inline-flex items-center gap-2 rounded-lg border border-nr-border bg-nr-surface-raised px-3 py-2 text-xs text-nr-text-primary transition-colors hover:border-[var(--org-accent)] disabled:cursor-not-allowed disabled:opacity-50"
        >
          <MapPin size={14} aria-hidden />
          {geo ? "Move pin on map" : "Pick location on map"}
        </button>
        {geo && (
          <button
            type="button"
            disabled={disabled}
            onClick={() => onChange(null)}
            className="text-xs text-nr-text-hint underline-offset-2 hover:underline disabled:opacity-50"
          >
            Clear pin
          </button>
        )}
      </div>

      <p className="text-xs text-nr-text-hint">
        {geo ? `Pinned: ${formatGeo(geo)}` : "No location pinned yet — optional, but it speeds up review."}
      </p>

      {open && (
        <LocationPickerModal
          initial={geo}
          onCancel={() => setOpen(false)}
          onConfirm={(picked) => {
            onChange(picked);
            setOpen(false);
          }}
        />
      )}
    </div>
  );
}

function LocationPickerModal({
  initial,
  onCancel,
  onConfirm,
}: {
  initial: Geo | null;
  onCancel: () => void;
  onConfirm: (geo: Geo) => void;
}) {
  const mapConfigured = isGoogleMapsConfigured();
  const mapHostRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<google.maps.Map | null>(null);

  const [center, setCenter] = useState<Geo>(initial ?? DEFAULT_MAP_CENTER);
  const [mapReady, setMapReady] = useState(false);
  const [error, setError] = useState("");
  const [locating, setLocating] = useState(false);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onCancel();
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [onCancel]);

  useEffect(() => {
    if (!mapConfigured) return;
    let cancelled = false;

    loadGoogleMaps()
      .then(() => {
        if (cancelled || !mapHostRef.current) return;
        const map = new google.maps.Map(mapHostRef.current, {
          center: { lat: center.latitude, lng: center.longitude },
          zoom: initial ? PINNED_MAP_ZOOM : DEFAULT_MAP_ZOOM,
          // The applicant picks a point, not a route or a street view.
          mapTypeControl: false,
          streetViewControl: false,
          fullscreenControl: false,
          clickableIcons: false,
          // One-finger pan inside a scrollable modal, not ctrl+scroll.
          gestureHandling: "greedy",
          // Follows the panel's dark surface. Ignored by API versions that
          // predate the option rather than erroring.
          colorScheme: "DARK",
        } as google.maps.MapOptions);

        // The pin is a fixed crosshair over the map's centre, so "where is the
        // pin" is always "where is the centre" — no marker to keep in sync.
        map.addListener("idle", () => {
          const c = map.getCenter();
          if (c) setCenter({ latitude: c.lat(), longitude: c.lng() });
        });
        // Tapping somewhere is the obvious way to move the pin there.
        map.addListener("click", (e: google.maps.MapMouseEvent) => {
          if (e.latLng) map.panTo(e.latLng);
        });

        mapRef.current = map;
        setMapReady(true);
      })
      .catch((e: unknown) => {
        if (!cancelled) setError(e instanceof Error ? e.message : "Could not load the map.");
      });

    return () => {
      cancelled = true;
      mapRef.current = null;
    };
    // Deliberately mount-only: re-running would rebuild the map under the user
    // on every pan (`center` changes on each idle).
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mapConfigured]);

  const useMyLocation = useCallback(() => {
    if (!navigator.geolocation) {
      setError("This browser cannot share a location.");
      return;
    }
    setError("");
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLocating(false);
        const next = { latitude: position.coords.latitude, longitude: position.coords.longitude };
        setCenter(next);
        const map = mapRef.current;
        if (map) {
          map.panTo({ lat: next.latitude, lng: next.longitude });
          map.setZoom(PINNED_MAP_ZOOM);
        }
      },
      (positionError) => {
        setLocating(false);
        setError(
          positionError.code === positionError.PERMISSION_DENIED
            ? "Location permission was denied — pin the venue on the map instead."
            : "Could not get a location fix. Pin the venue on the map instead."
        );
      },
      { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 }
    );
  }, []);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={onCancel} />
      <div
        role="dialog"
        aria-modal="true"
        aria-label="Pick the venue location"
        className="relative flex w-full max-w-2xl flex-col rounded-2xl border border-nr-border bg-nr-surface-raised shadow-2xl"
      >
        <div className="flex items-start justify-between gap-4 border-b border-nr-border p-5">
          <div>
            <h2 className="font-display text-lg tracking-wide text-nr-text-primary">Pin the venue</h2>
            <p className="mt-1 text-[13px] text-nr-text-secondary">
              Drag the map so the pin sits on the venue entrance, or use your current location.
            </p>
          </div>
          <button
            type="button"
            onClick={onCancel}
            aria-label="Close"
            className="shrink-0 text-nr-text-hint hover:text-nr-text-primary"
          >
            <X size={18} />
          </button>
        </div>

        <div className="flex flex-col gap-3 p-5">
          {mapConfigured ? (
            <div className="relative h-[320px] w-full overflow-hidden rounded-xl border border-nr-border bg-nr-surface">
              <div ref={mapHostRef} className="h-full w-full" />
              {mapReady && (
                <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
                  <Crosshair size={34} className="text-[var(--org-accent)] drop-shadow-[0_0_6px_rgba(0,0,0,0.9)]" aria-hidden />
                </div>
              )}
              {!mapReady && !error && (
                <p className="absolute inset-0 flex items-center justify-center text-xs text-nr-text-hint">
                  Loading map…
                </p>
              )}
            </div>
          ) : (
            <p className="rounded-lg border border-nr-border bg-nr-surface px-3 py-2.5 text-xs text-nr-text-secondary">
              The map is off because <span className="font-mono">NEXT_PUBLIC_GOOGLE_MAPS_API_KEY</span> is not set.
              &ldquo;Use my current location&rdquo; still works.
            </p>
          )}

          <div className="flex flex-wrap items-center justify-between gap-2">
            <button
              type="button"
              onClick={useMyLocation}
              disabled={locating}
              className="inline-flex items-center gap-2 rounded-lg border border-nr-border bg-nr-surface px-3 py-2 text-xs text-nr-text-primary transition-colors hover:border-[var(--org-accent)] disabled:cursor-not-allowed disabled:opacity-50"
            >
              <LocateFixed size={14} aria-hidden />
              {locating ? "Getting location…" : "Use my current location"}
            </button>
            <p className="font-mono text-xs text-nr-text-hint">{formatGeo(center)}</p>
          </div>

          {error && <ErrorNote>{error}</ErrorNote>}
        </div>

        <div className="flex justify-end gap-2 border-t border-nr-border p-4">
          <button
            type="button"
            onClick={onCancel}
            className="rounded-lg border border-nr-border px-4 py-2.5 text-xs text-nr-text-secondary transition-colors hover:text-nr-text-primary"
          >
            Cancel
          </button>
          <AccentButton size="sm" onClick={() => onConfirm(center)}>
            Use this location
          </AccentButton>
        </div>
      </div>
    </div>
  );
}
