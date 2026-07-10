"""Free geocoding + venue search via OpenStreetMap Nominatim and OSRM.

No API key required. Nominatim usage policy requires a descriptive User-Agent.
"""

from __future__ import annotations

import logging
from math import asin, cos, radians, sin, sqrt
from typing import Any

import httpx

log = logging.getLogger(__name__)

_NOM_BASE = "https://nominatim.openstreetmap.org"
_OSRM_BASE = "https://router.project-osrm.org/route/v1"
_HEADERS = {"User-Agent": "NightrideApp/1.0 (contact@therisevillage.com)"}
_TIMEOUT = 10.0


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371.0
    p1, p2 = radians(lat1), radians(lat2)
    dlat, dlng = radians(lat2 - lat1), radians(lng2 - lng1)
    a = sin(dlat / 2) ** 2 + cos(p1) * cos(p2) * sin(dlng / 2) ** 2
    return 2 * r * asin(sqrt(a))


async def search_venue(
    query: str,
    user_lat: float | None = None,
    user_lng: float | None = None,
    limit: int = 5,
) -> list[dict[str, Any]]:
    """Search for a venue/place by name using Nominatim.

    If user_lat/user_lng are provided, results are sorted nearest-first.
    Returns list of dicts: name, address, lat, lng, type.
    """
    params: dict[str, Any] = {
        "q": query,
        "format": "json",
        "limit": limit,
        "addressdetails": 1,
    }

    # Bias results toward user location with a viewbox (±1 degree ~ 111 km)
    if user_lat is not None and user_lng is not None:
        params["viewbox"] = (
            f"{user_lng - 1},{user_lat + 1},{user_lng + 1},{user_lat - 1}"
        )
        params["bounded"] = 0  # prefer viewbox but don't exclude outside results

    try:
        async with httpx.AsyncClient(timeout=_TIMEOUT, headers=_HEADERS) as client:
            r = await client.get(f"{_NOM_BASE}/search", params=params)
            r.raise_for_status()
            data = r.json()
    except Exception as exc:
        log.warning("nominatim search_venue failed: %s", exc)
        return []

    results = []
    for item in data:
        try:
            lat = float(item["lat"])
            lng = float(item["lon"])
            display = item.get("display_name", "")
            name = display.split(",")[0].strip()
            results.append({
                "name": name,
                "address": display,
                "lat": lat,
                "lng": lng,
                "type": item.get("type", ""),
            })
        except (KeyError, ValueError):
            continue

    # Sort nearest-first if we have user location
    if user_lat is not None and user_lng is not None:
        results.sort(
            key=lambda r: _haversine_km(user_lat, user_lng, r["lat"], r["lng"])
        )

    return results


async def geocode(query: str) -> dict[str, Any] | None:
    """Resolve a free-text address/venue name to coordinates.

    Returns dict: lat, lng, address. Returns None if not found.
    """
    results = await search_venue(query, limit=1)
    return results[0] if results else None


async def calculate_route(
    origin_lat: float,
    origin_lng: float,
    dest_lat: float,
    dest_lng: float,
    mode: str = "driving",
) -> dict[str, Any] | None:
    """Calculate route distance and duration via OSRM (free, no API key).

    mode: driving | walking | bicycling (transit falls back to driving)
    Returns dict: distance_text, distance_meters, duration_text, duration_seconds, mode.
    """
    profile_map = {"walking": "foot", "bicycling": "bike"}
    profile = profile_map.get(mode, "driving")

    # OSRM expects lng,lat order
    url = (
        f"{_OSRM_BASE}/{profile}/"
        f"{origin_lng},{origin_lat};{dest_lng},{dest_lat}"
        f"?overview=false"
    )

    try:
        async with httpx.AsyncClient(timeout=_TIMEOUT, headers=_HEADERS) as client:
            r = await client.get(url)
            r.raise_for_status()
            data = r.json()
    except Exception as exc:
        log.warning("osrm calculate_route failed (%s): %s", mode, exc)
        return None

    if data.get("code") != "Ok":
        log.warning("osrm code=%s mode=%s", data.get("code"), mode)
        return None

    routes = data.get("routes")
    if not routes:
        return None

    route = routes[0]
    duration_s = route["duration"]
    distance_m = route["distance"]

    # Format duration
    mins = round(duration_s / 60)
    if mins < 60:
        duration_text = f"{mins} min"
    else:
        h, m = divmod(mins, 60)
        duration_text = f"{h}h {m}m" if m else f"{h}h"

    # Format distance
    if distance_m < 1000:
        distance_text = f"{round(distance_m)} m"
    else:
        distance_text = f"{distance_m / 1000:.1f} km"

    return {
        "distance_text": distance_text,
        "distance_meters": round(distance_m),
        "duration_text": duration_text,
        "duration_seconds": round(duration_s),
        "mode": mode,
    }
