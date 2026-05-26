"""Free city → GPS coordinates using OpenStreetMap Nominatim. No API key needed."""

from __future__ import annotations

import httpx

_BASE = "https://nominatim.openstreetmap.org/search"
_TIMEOUT = 5
_HEADERS = {"User-Agent": "party-chat-agent/1.0"}


def city_to_coords(city: str, country_code: str | None = None) -> tuple[float, float] | None:
    """Return (lat, lng) for any city in the world. Returns None if not found."""
    q = f"{city}, {country_code}" if country_code else city
    try:
        resp = httpx.get(
            _BASE,
            params={"q": q, "format": "json", "limit": 1},
            headers=_HEADERS,
            timeout=_TIMEOUT,
        )
        results = resp.json()
        if results:
            return float(results[0]["lat"]), float(results[0]["lon"])
    except Exception:
        pass
    return None
