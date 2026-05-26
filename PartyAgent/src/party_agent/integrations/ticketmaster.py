"""Ticketmaster Discovery API client — worldwide event search.

Free API key: https://developer.ticketmaster.com/
Set TICKETMASTER_API_KEY in .env.
"""

from __future__ import annotations

import httpx

from party_agent.config import get_settings

_BASE = "https://app.ticketmaster.com/discovery/v2/events.json"
_TIMEOUT = 10

# Map freeform vibe keywords → Ticketmaster classification names
_VIBE_CLASSIFICATION: dict[str, str] = {
    "edm": "Electronic",
    "electronic": "Electronic",
    "techno": "Electronic",
    "underground": "Electronic",
    "hip-hop": "Hip-Hop/Rap",
    "hiphop": "Hip-Hop/Rap",
    "rap": "Hip-Hop/Rap",
    "jazz": "Jazz",
    "chill": "Jazz",
    "acoustic": "Folk",
    "folk": "Folk",
    "rock": "Rock",
    "pop": "Pop",
    "classical": "Classical",
    "reggae": "Reggae",
    "latin": "Latin",
    "r&b": "R&B",
    "soul": "R&B",
}

# Vibes that are better expressed as a keyword search
_VIBE_KEYWORD: dict[str, str] = {
    "vip": "VIP",
    "luxury": "luxury VIP",
    "lgbtq": "pride LGBTQ",
    "pride": "pride LGBTQ",
    "free": "free",
    "outdoor": "outdoor festival",
    "rooftop": "rooftop",
}


def _params_for_vibe(vibe: str | None) -> dict[str, str]:
    if not vibe:
        return {}
    v = vibe.lower()
    if v in _VIBE_CLASSIFICATION:
        return {"classificationName": _VIBE_CLASSIFICATION[v]}
    if v in _VIBE_KEYWORD:
        return {"keyword": _VIBE_KEYWORD[v]}
    return {"keyword": vibe}


def _normalise(events: list[dict]) -> list[dict]:
    out = []
    for e in events:
        venues = e.get("_embedded", {}).get("venues") or [{}]
        venue = venues[0]
        loc = venue.get("location", {})

        classifications = e.get("classifications") or [{}]
        genre = classifications[0].get("genre", {}).get("name", "")
        segment = classifications[0].get("segment", {}).get("name", "")
        vibe = genre if genre and genre not in ("Undefined", "Other") else segment

        price_ranges = e.get("priceRanges") or []
        price = (
            f"from {price_ranges[0]['min']:.0f} {price_ranges[0].get('currency','')}"
            if price_ranges
            else "price unavailable"
        )

        out.append({
            "name": e.get("name", "Unknown"),
            "city": venue.get("city", {}).get("name", ""),
            "country": venue.get("country", {}).get("name", ""),
            "vibe": vibe.lower() if vibe else "music",
            "date": e.get("dates", {}).get("start", {}).get("dateTime", ""),
            "price": price,
            "url": e.get("url", ""),
            "lat": float(loc["latitude"]) if loc.get("latitude") else None,
            "lng": float(loc["longitude"]) if loc.get("longitude") else None,
        })
    return out


def search_by_city(
    city: str,
    vibe: str | None = None,
    country_code: str | None = None,
    size: int = 5,
) -> list[dict]:
    """Search events in any city worldwide."""
    api_key = get_settings().ticketmaster_api_key
    if not api_key:
        return []

    params: dict = {
        "apikey": api_key,
        "city": city,
        "size": size,
        "sort": "relevance,desc",
        "classificationName": "Music",  # default to music/nightlife
    }
    if country_code:
        params["countryCode"] = country_code.upper()
    params.update(_params_for_vibe(vibe))

    resp = httpx.get(_BASE, params=params, timeout=_TIMEOUT)
    resp.raise_for_status()
    events = resp.json().get("_embedded", {}).get("events") or []
    return _normalise(events)


def search_nearby(
    lat: float,
    lng: float,
    max_km: float,
    vibe: str | None = None,
    size: int = 10,
) -> list[dict]:
    """Search events near GPS coordinates anywhere in the world."""
    api_key = get_settings().ticketmaster_api_key
    if not api_key:
        return []

    params: dict = {
        "apikey": api_key,
        "latlong": f"{lat},{lng}",
        "radius": max(1, int(max_km)),
        "unit": "km",
        "size": size,
        "sort": "relevance,desc",
    }
    params.update(_params_for_vibe(vibe))

    resp = httpx.get(_BASE, params=params, timeout=_TIMEOUT)
    resp.raise_for_status()
    events = resp.json().get("_embedded", {}).get("events") or []
    return _normalise(events)


def trending_in_city(city: str, country_code: str | None = None, size: int = 1) -> dict | None:
    """Return the most relevant event in a city right now."""
    results = search_by_city(city, vibe=None, country_code=country_code, size=size)
    return results[0] if results else None
