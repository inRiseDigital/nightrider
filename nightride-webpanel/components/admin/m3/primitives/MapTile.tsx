import { osmTileUrl } from "@/lib/admin/geo";
import { ACCENT, SURFACE, TEXT } from "@/lib/admin/tokens";
import { Icon } from "../Icon";

// Per-city fallback OSM tiles, matching the mockup's `cityTile()` helper —
// used when a record has no precise geo point yet.
const CITY_TILE: Record<string, string> = {
  Dubai: "https://tile.openstreetmap.org/12/2676/1751.png",
  Tokyo: "https://tile.openstreetmap.org/12/3636/1612.png",
  London: "https://tile.openstreetmap.org/12/2046/1362.png",
  Melbourne: "https://tile.openstreetmap.org/12/3697/2513.png",
};

/**
 * Static OSM map preview used for venue/event location cards — a pin marker
 * over a background-image tile, with attribution. Falls back to a per-city
 * static tile when no precise `geo` is available, and to a placeholder icon
 * when neither is.
 */
export function MapTile({ city, geo, height = 200 }: { city?: string; geo?: { latitude: number; longitude: number } | null; height?: number }) {
  const url = geo ? osmTileUrl(geo.latitude, geo.longitude) : city ? CITY_TILE[city] : undefined;

  if (!url) {
    return (
      <div style={{ width: "100%", height, background: SURFACE.hover, display: "flex", alignItems: "center", justifyContent: "center", color: TEXT.muted }}>
        <Icon name="location_off" size={32} />
      </div>
    );
  }

  return (
    <div
      style={{
        position: "relative",
        width: "100%",
        height,
        background: `${SURFACE.hover} url('${url}') center / cover no-repeat`,
      }}
    >
      <div style={{ position: "absolute", left: "50%", top: "50%", transform: "translate(-50%, -100%)", color: ACCENT.pink }}>
        <Icon name="location_on" size={36} filled style={{ filter: "drop-shadow(0 2px 4px rgba(0,0,0,0.6))" }} />
      </div>
      <div
        style={{
          position: "absolute",
          right: 8,
          bottom: 6,
          fontSize: 9,
          color: TEXT.primary,
          background: "rgba(0,0,0,0.55)",
          padding: "2px 6px",
          borderRadius: 6,
        }}
      >
        © OpenStreetMap
      </div>
    </div>
  );
}
