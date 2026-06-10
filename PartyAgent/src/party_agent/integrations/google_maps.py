"""Async Google Maps API client — Places, Directions, Geocoding.

Requires GOOGLE_MAPS_API_KEY in the environment (set in .env).
The key is read server-side only and never exposed to the client.
"""

from __future__ import annotations

import logging
from typing import Any
from urllib.parse import quote

import httpx

from party_agent.config import get_settings

log = logging.getLogger(__name__)

_BASE = "https://maps.googleapis.com/maps/api"
_TIMEOUT = 8.0


def _key() -> str:
    key = get_settings().google_maps_api_key
    if not key:
        raise RuntimeError(
            "GOOGLE_MAPS_API_KEY is not set. "
            "Add it to your .env file and restart the server."
        )
    return key


async def geocode_address(address: str) -> dict[str, Any] | None:
    """Convert a free-text address to lat/lng + place metadata.

    Returns dict with keys: lat, lng, place_id, formatted_address.
    Returns None if the address cannot be resolved.
    """
    async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
        r = await client.get(
            f"{_BASE}/geocode/json",
            params={"address": address, "key": _key()},
        )
        data = r.json()
    if data.get("status") != "OK" or not data.get("results"):
        log.warning("geocode_address: status=%s address=%r", data.get("status"), address)
        return None
    result = data["results"][0]
    loc = result["geometry"]["location"]
    return {
        "lat": loc["lat"],
        "lng": loc["lng"],
        "place_id": result.get("place_id"),
        "formatted_address": result.get("formatted_address"),
    }


async def search_places(
    query: str,
    lat: float,
    lng: float,
    radius: int = 5000,
) -> list[dict[str, Any]]:
    """Search Google Places Text Search near coordinates.

    Returns a list of dicts: name, address, lat, lng, place_id, rating, open_now.
    """
    async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
        r = await client.get(
            f"{_BASE}/place/textsearch/json",
            params={
                "query": query,
                "location": f"{lat},{lng}",
                "radius": radius,
                "key": _key(),
            },
        )
        data = r.json()
    if data.get("status") not in ("OK", "ZERO_RESULTS"):
        log.warning("search_places: status=%s query=%r", data.get("status"), query)
        return []
    results = []
    for p in data.get("results", []):
        loc = p.get("geometry", {}).get("location", {})
        opening = p.get("opening_hours", {})
        results.append({
            "name": p.get("name"),
            "address": p.get("formatted_address"),
            "lat": loc.get("lat"),
            "lng": loc.get("lng"),
            "place_id": p.get("place_id"),
            "rating": p.get("rating"),
            "open_now": opening.get("open_now"),
        })
    return results


async def get_place_details(place_id: str) -> dict[str, Any] | None:
    """Fetch detailed info for a specific Google place_id.

    Returns dict: name, address, phone, google_maps_url, lat, lng,
                  rating, open_now, website.
    """
    async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
        r = await client.get(
            f"{_BASE}/place/details/json",
            params={
                "place_id": place_id,
                "fields": (
                    "name,formatted_address,international_phone_number,"
                    "url,geometry,rating,opening_hours,website"
                ),
                "key": _key(),
            },
        )
        data = r.json()
    if data.get("status") != "OK" or not data.get("result"):
        log.warning("get_place_details: status=%s place_id=%r", data.get("status"), place_id)
        return None
    result = data["result"]
    loc = result.get("geometry", {}).get("location", {})
    opening = result.get("opening_hours", {})
    return {
        "name": result.get("name"),
        "address": result.get("formatted_address"),
        "phone": result.get("international_phone_number"),
        "google_maps_url": result.get("url"),
        "lat": loc.get("lat"),
        "lng": loc.get("lng"),
        "rating": result.get("rating"),
        "open_now": opening.get("open_now"),
        "website": result.get("website"),
    }


async def calculate_route(
    origin_lat: float,
    origin_lng: float,
    dest_lat: float,
    dest_lng: float,
    mode: str = "driving",
) -> dict[str, Any] | None:
    """Calculate a route between two GPS points using Google Directions.

    mode: driving | walking | bicycling | transit
    Returns dict: distance_text, distance_meters, duration_text, duration_seconds, mode.
    Returns None if no route is found.
    """
    async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
        r = await client.get(
            f"{_BASE}/directions/json",
            params={
                "origin": f"{origin_lat},{origin_lng}",
                "destination": f"{dest_lat},{dest_lng}",
                "mode": mode,
                "key": _key(),
            },
        )
        data = r.json()
    if data.get("status") != "OK" or not data.get("routes"):
        log.warning(
            "calculate_route: status=%s mode=%s origin=(%s,%s) dest=(%s,%s)",
            data.get("status"), mode,
            origin_lat, origin_lng, dest_lat, dest_lng,
        )
        return None
    leg = data["routes"][0]["legs"][0]
    return {
        "distance_text": leg["distance"]["text"],
        "distance_meters": leg["distance"]["value"],
        "duration_text": leg["duration"]["text"],
        "duration_seconds": leg["duration"]["value"],
        "mode": mode,
    }


def create_navigation_url(dest_lat: float, dest_lng: float, dest_name: str) -> str:
    """Build a universal Google Maps navigation URL.

    Opens the Google Maps app (or web fallback) with turn-by-turn navigation.
    Safe to return to the client — no API key is embedded.
    """
    encoded = quote(dest_name)
    return (
        f"https://www.google.com/maps/dir/?api=1"
        f"&destination={dest_lat},{dest_lng}"
        f"&destination_place_name={encoded}"
        f"&travelmode=driving"
    )
