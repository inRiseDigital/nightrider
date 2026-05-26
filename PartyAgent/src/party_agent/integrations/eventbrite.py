"""Eventbrite API client — worldwide party and nightlife search.

Strong coverage in: Africa, Middle East, South/SE Asia, Latin America, India.
Free key: https://www.eventbrite.com/platform/api/
Set EVENTBRITE_TOKEN in .env.
"""

from __future__ import annotations

import httpx

from party_agent.config import get_settings

_BASE = "https://www.eventbriteapi.com/v3"
_TIMEOUT = 10

# Eventbrite category IDs relevant to nightlife / parties
_CATEGORY_MUSIC = "103"
_CATEGORY_FOOD_DRINK = "110"  # includes bar/club nights in many regions

# Vibe → keyword mapping for Eventbrite keyword search
_VIBE_KEYWORDS: dict[str, str] = {
    "edm": "EDM electronic dance",
    "electronic": "electronic dance party",
    "techno": "techno rave",
    "underground": "underground rave party",
    "hip-hop": "hip hop rap party",
    "hiphop": "hip hop party",
    "rap": "rap hip hop",
    "jazz": "jazz live music",
    "chill": "chill lounge night",
    "acoustic": "acoustic live music",
    "rock": "rock live band",
    "pop": "pop music party",
    "reggae": "reggae dancehall",
    "latin": "latin salsa reggaeton",
    "afrobeats": "afrobeats afro dance",
    "afro": "afrobeats afro party",
    "bollywood": "bollywood night desi party",
    "desi": "desi bollywood night",
    "kpop": "kpop k-pop korean party",
    "r&b": "R&B soul night",
    "soul": "soul R&B night",
    "vip": "VIP exclusive party",
    "luxury": "luxury VIP gala",
    "lgbtq": "LGBTQ pride queer party",
    "pride": "pride LGBTQ queer",
    "free": "free party event",
    "outdoor": "outdoor festival open air",
    "rooftop": "rooftop party",
    "beach": "beach party",
    "carnival": "carnival masquerade",
    "salsa": "salsa bachata latin dance",
    "bhangra": "bhangra punjabi party",
    "arabic": "arabic oriental night",
    "persian": "persian iranian night",
}


def _headers() -> dict[str, str]:
    token = get_settings().eventbrite_token
    if not token:
        raise RuntimeError("EVENTBRITE_TOKEN is not configured")
    return {"Authorization": f"Bearer {token}"}


def _normalise(events: list[dict]) -> list[dict]:
    out = []
    for e in events:
        venue = e.get("venue") or {}
        address = venue.get("address") or {}
        ta = e.get("ticket_availability") or {}

        if ta.get("is_free"):
            price = "free"
        elif ta.get("minimum_ticket_price"):
            mp = ta["minimum_ticket_price"]
            price = f"from {mp.get('major_value', '?')} {mp.get('currency', '')}"
        else:
            price = "price unavailable"

        out.append({
            "name": (e.get("name") or {}).get("text", "Unknown"),
            "city": address.get("city", ""),
            "country": address.get("country", ""),
            "vibe": "party",
            "date": (e.get("start") or {}).get("utc", ""),
            "price": price,
            "url": e.get("url", ""),
            "source": "eventbrite",
            "lat": float(venue["latitude"]) if venue.get("latitude") else None,
            "lng": float(venue["longitude"]) if venue.get("longitude") else None,
        })
    return out


def search_by_city(
    city: str,
    vibe: str | None = None,
    country_code: str | None = None,
    size: int = 5,
) -> list[dict]:
    """Search party/nightlife events in any city worldwide."""
    token = get_settings().eventbrite_token
    if not token:
        return []

    location = f"{city}, {country_code}" if country_code else city
    keyword = _VIBE_KEYWORDS.get((vibe or "").lower(), vibe or "party nightlife")

    params: dict = {
        "q": keyword,
        "location.address": location,
        "location.within": "30km",
        "sort_by": "best",
        "expand": "venue,ticket_availability",
        "categories": _CATEGORY_MUSIC,
        "page_size": size,
    }

    resp = httpx.get(
        f"{_BASE}/events/search/",
        headers=_headers(),
        params=params,
        timeout=_TIMEOUT,
    )
    resp.raise_for_status()
    events = resp.json().get("events") or []
    return _normalise(events)


def search_nearby(
    lat: float,
    lng: float,
    max_km: float,
    vibe: str | None = None,
    size: int = 10,
) -> list[dict]:
    """Search party/nightlife events near GPS coordinates worldwide."""
    token = get_settings().eventbrite_token
    if not token:
        return []

    keyword = _VIBE_KEYWORDS.get((vibe or "").lower(), vibe or "party nightlife")

    params: dict = {
        "q": keyword,
        "location.latitude": lat,
        "location.longitude": lng,
        "location.within": f"{max(1, int(max_km))}km",
        "sort_by": "distance",
        "expand": "venue,ticket_availability",
        "categories": _CATEGORY_MUSIC,
        "page_size": size,
    }

    resp = httpx.get(
        f"{_BASE}/events/search/",
        headers=_headers(),
        params=params,
        timeout=_TIMEOUT,
    )
    resp.raise_for_status()
    events = resp.json().get("events") or []
    return _normalise(events)
