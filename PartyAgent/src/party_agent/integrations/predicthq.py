"""Predicthq API client — truly worldwide event search.

Covers 200+ countries: Japan, Sri Lanka, Nigeria, UAE, India, Thailand, Brazil, etc.
Free tier: https://predicthq.com/signup  (no credit card)
Set PREDICTHQ_TOKEN in .env.

City search works by geocoding the city name to coordinates (via free OpenStreetMap),
then searching Predicthq within a radius — this gives precise city-level results
for any city in the world.
"""

from __future__ import annotations

from datetime import date

import httpx

from party_agent.config import get_settings
from party_agent.integrations.geocoding import city_to_coords

_BASE = "https://api.predicthq.com/v1"
_TIMEOUT = 10
_CITY_RADIUS_KM = 50

# concerts + festivals gives real nightlife/music results worldwide.
# community adds noise (book fairs, education fairs) — only include it for
# vibes like lgbtq/pride/free/carnival where community events ARE the target.
_DEFAULT_CATEGORIES = "concerts,festivals"
_COMMUNITY_VIBES = {"lgbtq", "pride", "free", "carnival", "outdoor", "bhangra", "salsa"}

_VIBE_KEYWORDS: dict[str, str] = {
    "edm": "EDM electronic dance rave",
    "electronic": "electronic dance party",
    "techno": "techno rave",
    "underground": "underground rave club night",
    "hip-hop": "hip hop rap party",
    "hiphop": "hip hop party",
    "rap": "rap hip hop concert",
    "jazz": "jazz live music",
    "chill": "chill lounge acoustic",
    "acoustic": "acoustic live music",
    "rock": "rock concert live band",
    "pop": "pop music concert",
    "reggae": "reggae dancehall",
    "latin": "latin salsa reggaeton",
    "afrobeats": "afrobeats afro music concert",
    "afro": "afrobeats afro concert",
    "bollywood": "bollywood desi night",
    "desi": "desi bollywood party",
    "kpop": "kpop k-pop korean concert",
    "r&b": "R&B soul concert",
    "soul": "soul R&B music",
    "vip": "exclusive gala event",
    "luxury": "luxury gala exclusive",
    "lgbtq": "LGBTQ pride festival",
    "pride": "pride LGBTQ festival",
    "free": "free festival concert",
    "outdoor": "outdoor festival open air",
    "rooftop": "rooftop music event",
    "beach": "beach festival music",
    "carnival": "carnival festival",
    "salsa": "salsa bachata dance",
    "bhangra": "bhangra punjabi concert",
    "arabic": "arabic music concert",
    "persian": "persian iranian music",
    "j-pop": "japanese music concert jpop",
    "anime": "anime cosplay festival",
    "party": "party nightlife music",
}


def _headers() -> dict[str, str]:
    token = get_settings().predicthq_token
    if not token:
        raise RuntimeError("PREDICTHQ_TOKEN is not configured")
    return {"Authorization": f"Bearer {token}", "Accept": "application/json"}


def _normalise(events: list[dict]) -> list[dict]:
    out = []
    for e in events:
        entities = e.get("entities") or []
        venue = next((en for en in entities if en.get("type") == "venue"), {})

        coords = e.get("geo", {}).get("geometry", {}).get("coordinates") or []
        lat = coords[1] if len(coords) >= 2 else None
        lng = coords[0] if len(coords) >= 2 else None

        attendance = e.get("phq_attendance", 0)
        price_str = f"{attendance:,} expected" if attendance else "attendance TBC"

        address = venue.get("formatted_address", "")
        parts = [p.strip() for p in address.split(",")]
        city = parts[-2] if len(parts) >= 2 else ""

        out.append({
            "name": e.get("title", "Unknown"),
            "city": city,
            "country": e.get("country", ""),
            "vibe": (e.get("labels") or [e.get("category", "music")])[0],
            "date": e.get("start", ""),
            "price": price_str,
            "url": f"https://predicthq.com/events/{e.get('id', '')}",
            "source": "predicthq",
            "lat": lat,
            "lng": lng,
        })
    return out


def _within_param(lat: float, lng: float, km: int) -> str:
    return f"{km}km@{lat},{lng}"


def _categories_for_vibe(vibe: str | None) -> str:
    if vibe and vibe.lower() in _COMMUNITY_VIBES:
        return "concerts,festivals,community"
    return _DEFAULT_CATEGORIES


def search_by_city(
    city: str,
    vibe: str | None = None,
    country_code: str | None = None,
    size: int = 5,
) -> list[dict]:
    """Search events in any city worldwide using geocoded coordinates."""
    token = get_settings().predicthq_token
    if not token:
        return []

    # Geocode city → coordinates for precise city-level search
    coords = city_to_coords(city, country_code)
    if coords:
        return search_nearby(lat=coords[0], lng=coords[1], max_km=_CITY_RADIUS_KM, vibe=vibe, size=size)

    # Fallback: country-level when geocoding fails
    base_params: dict = {
        "category": _categories_for_vibe(vibe),
        "sort": "rank",
        "limit": size,
        "start.gte": date.today().isoformat(),
    }
    if country_code:
        base_params["country"] = country_code.upper()

    if vibe:
        params = {**base_params, "q": _VIBE_KEYWORDS.get(vibe.lower(), vibe)}
        resp = httpx.get(f"{_BASE}/events/", headers=_headers(), params=params, timeout=_TIMEOUT)
        resp.raise_for_status()
        results = resp.json().get("results") or []
        if results:
            return _normalise(results)

    resp = httpx.get(f"{_BASE}/events/", headers=_headers(), params=base_params, timeout=_TIMEOUT)
    resp.raise_for_status()
    return _normalise(resp.json().get("results") or [])


def search_nearby(
    lat: float,
    lng: float,
    max_km: float,
    vibe: str | None = None,
    size: int = 10,
) -> list[dict]:
    """Search events within km radius of any GPS coordinate on earth."""
    token = get_settings().predicthq_token
    if not token:
        return []

    base_params: dict = {
        "within": _within_param(lat, lng, max(1, int(max_km))),
        "category": _categories_for_vibe(vibe),
        "sort": "rank",
        "limit": size,
        "start.gte": date.today().isoformat(),
    }

    # Try with vibe keyword first; fall back to category-only if no results
    if vibe:
        params = {**base_params, "q": _VIBE_KEYWORDS.get(vibe.lower(), vibe)}
        resp = httpx.get(f"{_BASE}/events/", headers=_headers(), params=params, timeout=_TIMEOUT)
        resp.raise_for_status()
        results = resp.json().get("results") or []
        if results:
            return _normalise(results)

    resp = httpx.get(f"{_BASE}/events/", headers=_headers(), params=base_params, timeout=_TIMEOUT)
    resp.raise_for_status()
    return _normalise(resp.json().get("results") or [])


def trending_in_city(city: str, country_code: str | None = None) -> dict | None:
    results = search_by_city(city, vibe=None, country_code=country_code, size=1)
    return results[0] if results else None
