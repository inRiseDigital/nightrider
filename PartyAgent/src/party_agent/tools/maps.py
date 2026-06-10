"""Maps tools — live Google Maps integration via integrations/google_maps.py.

All tools that call the Maps API require GOOGLE_MAPS_API_KEY in .env.
Tools are registered in the map_navigator and event_discovery agents.
"""

from __future__ import annotations

import json
import logging
from math import asin, cos, radians, sin, sqrt

from langchain_core.tools import tool

from party_agent.integrations import google_maps

log = logging.getLogger(__name__)


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371.0
    p1, p2 = radians(lat1), radians(lat2)
    dlat, dlng = radians(lat2 - lat1), radians(lng2 - lng1)
    a = sin(dlat / 2) ** 2 + cos(p1) * cos(p2) * sin(dlng / 2) ** 2
    return 2 * r * asin(sqrt(a))


@tool
async def maps_find_nearby_parties(
    query: str,
    user_lat: float,
    user_lng: float,
    radius_meters: int = 5000,
) -> str:
    """Search Google Maps for party venues / events near the user's GPS.

    Use when the user asks what's happening nearby, wants venue recommendations,
    or asks to find clubs, bars, parties, or events near a location.

    Args:
        query: Search query, e.g. "nightclub", "rooftop party", "rave Colombo".
        user_lat: User's current latitude.
        user_lng: User's current longitude.
        radius_meters: Search radius in metres (default 5000 = 5 km).

    Returns:
        JSON list of up to 5 matching venues with name, address, rating, open_now.
    """
    try:
        places = await google_maps.search_places(query, user_lat, user_lng, radius_meters)
    except RuntimeError as exc:
        return f"Maps search unavailable: {exc}"
    except Exception as exc:
        log.exception("maps_find_nearby_parties failed")
        return f"Maps search failed: {exc}"

    if not places:
        return "No venues found near your location for that search."

    summary = [
        {
            "name": p["name"],
            "address": p["address"],
            "rating": p.get("rating"),
            "open_now": p.get("open_now"),
            "lat": p["lat"],
            "lng": p["lng"],
            "place_id": p["place_id"],
        }
        for p in places[:5]
    ]
    return json.dumps(summary, ensure_ascii=False)


@tool
async def maps_get_event_travel_info(
    event_name: str,
    dest_lat: float,
    dest_lng: float,
    user_lat: float,
    user_lng: float,
    mode: str = "driving",
) -> str:
    """Get real travel distance and ETA from user to a venue via Google Directions.

    Use when the user asks how long it takes to get somewhere, wants to compare
    travel times between events, or asks for distance to a specific venue.

    Args:
        event_name: Human-readable name of the venue/event.
        dest_lat: Destination latitude.
        dest_lng: Destination longitude.
        user_lat: User's current latitude.
        user_lng: User's current longitude.
        mode: Travel mode — driving (default), walking, bicycling, or transit.

    Returns:
        Structured line: "VenueName | 3.2 km | 12 mins | driving | <nav_url>"
    """
    try:
        route = await google_maps.calculate_route(user_lat, user_lng, dest_lat, dest_lng, mode)
    except RuntimeError as exc:
        return f"Directions unavailable: {exc}"
    except Exception as exc:
        log.exception("maps_get_event_travel_info failed")
        return f"Directions failed: {exc}"

    if not route:
        return f"Could not find a route to {event_name}."

    nav_url = google_maps.create_navigation_url(dest_lat, dest_lng, event_name)
    return (
        f"{event_name} | "
        f"{route['distance_text']} | "
        f"{route['duration_text']} | "
        f"{route['mode']} | "
        f"{nav_url}"
    )


@tool
async def maps_open_navigation(
    dest_lat: float,
    dest_lng: float,
    dest_name: str,
) -> str:
    """Generate a Google Maps navigation URL for a venue.

    Use when the user says "take me there", "navigate to X", "open directions",
    or "how do I get to X". Returns a URL the app renders as a tappable button.

    Args:
        dest_lat: Destination latitude.
        dest_lng: Destination longitude.
        dest_name: Display name for the destination.

    Returns:
        Google Maps universal navigation URL.
    """
    try:
        return google_maps.create_navigation_url(dest_lat, dest_lng, dest_name)
    except Exception as exc:
        log.exception("maps_open_navigation failed")
        return f"Could not create navigation URL: {exc}"


@tool
def maps_rank_events_by_distance(
    events_json: str,
    user_lat: float,
    user_lng: float,
) -> str:
    """Rank a list of events from nearest to farthest using straight-line distance.

    Use when suggesting multiple events and the user cares about distance,
    or when asked "which is closest?".

    Args:
        events_json: JSON array of events, each with at least {name, lat, lng}.
        user_lat: User's latitude.
        user_lng: User's longitude.

    Returns:
        JSON array sorted by ascending distance, each event with distance_km added.
    """
    try:
        events = json.loads(events_json)
        for ev in events:
            ev["distance_km"] = round(_haversine_km(user_lat, user_lng, ev["lat"], ev["lng"]), 2)
        events.sort(key=lambda e: e["distance_km"])
        return json.dumps(events, ensure_ascii=False)
    except Exception as exc:
        log.exception("maps_rank_events_by_distance failed")
        return f"Ranking failed: {exc}"


@tool
async def maps_check_walkability(
    user_lat: float,
    user_lng: float,
    dest_lat: float,
    dest_lng: float,
) -> str:
    """Check if a destination is walkable from the user's location.

    Use when the user asks "can I walk there?", "is it far to walk?",
    or wants a quick sanity check before calling a ride.

    Args:
        user_lat: User's current latitude.
        user_lng: User's current longitude.
        dest_lat: Destination latitude.
        dest_lng: Destination longitude.

    Returns:
        Walkability verdict with real walking distance and duration.
    """
    try:
        route = await google_maps.calculate_route(user_lat, user_lng, dest_lat, dest_lng, "walking")
    except RuntimeError as exc:
        return f"Walkability check unavailable: {exc}"
    except Exception as exc:
        log.exception("maps_check_walkability failed")
        return f"Walkability check failed: {exc}"

    if not route:
        return "No walking route found."

    meters = route["distance_meters"]
    if meters <= 800:
        verdict = "Very walkable"
    elif meters <= 1500:
        verdict = "Walkable"
    elif meters <= 3000:
        verdict = "Long walk but doable"
    else:
        verdict = "Too far to walk — recommend a ride"

    return f"{verdict} | {route['distance_text']} | {route['duration_text']} on foot"


# Legacy aliases kept so existing agent.py import of (directions_to, open_party_map) still resolves.

@tool
async def open_party_map(city: str, vibe_filter: str | None = None) -> str:
    """Open the party map for a city, optionally filtered by vibe."""
    filter_text = f" (vibe: {vibe_filter})" if vibe_filter else ""
    return (
        f"Open the Map tab in the Nightride app to see parties in {city}{filter_text}. "
        "You can tap any marker for details."
    )


@tool
async def directions_to(venue_name: str) -> str:
    """Get a navigation link to a venue by name."""
    return (
        f"Share your GPS location and I'll give you a real-time route to {venue_name}. "
        "Or use maps_open_navigation with the venue's coordinates for an instant link."
    )
