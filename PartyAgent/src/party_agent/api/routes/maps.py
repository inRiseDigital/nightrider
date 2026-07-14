"""GET /maps/* — Google Maps proxy endpoints.

The GOOGLE_MAPS_API_KEY stays server-side. The Flutter app calls these
endpoints; the backend signs outbound Maps API requests with the key.
"""

from __future__ import annotations

import logging
from math import asin, cos, radians, sin, sqrt
from typing import Any

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from party_agent.integrations import google_maps

log = logging.getLogger(__name__)
router = APIRouter(prefix="/maps", tags=["maps"])


# ── response schemas ─────────────────────────────────────────────────────────

class PlaceResult(BaseModel):
    name: str
    address: str | None = None
    lat: float | None = None
    lng: float | None = None
    place_id: str | None = None
    rating: float | None = None
    open_now: bool | None = None


class PlaceDetails(PlaceResult):
    phone: str | None = None
    google_maps_url: str | None = None
    website: str | None = None


class RouteResult(BaseModel):
    distance_text: str
    distance_meters: int
    duration_text: str
    duration_seconds: int
    mode: str
    navigation_url: str


class RankEventsRequest(BaseModel):
    user_lat: float
    user_lng: float
    events: list[dict[str, Any]]


# ── endpoints ─────────────────────────────────────────────────────────────────

@router.get("/place/search", response_model=list[PlaceResult])
async def search_places(
    query: str = Query(..., description="Free-text search, e.g. 'nightclub Colombo'"),
    lat: float = Query(..., description="Center latitude"),
    lng: float = Query(..., description="Center longitude"),
    radius: int = Query(5000, ge=100, le=50000, description="Radius in metres"),
) -> list[PlaceResult]:
    """Search Google Places near the given coordinates."""
    try:
        places = await google_maps.search_places(query, lat, lng, radius)
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return [PlaceResult(**p) for p in places]


@router.get("/place/{place_id}", response_model=PlaceDetails)
async def get_place_details(place_id: str) -> PlaceDetails:
    """Fetch detailed info for a single place by its Google place_id."""
    try:
        details = await google_maps.get_place_details(place_id)
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    if not details:
        raise HTTPException(status_code=404, detail="Place not found")
    return PlaceDetails(**details)


@router.get("/travel", response_model=RouteResult)
async def get_travel_info(
    dest_lat: float = Query(...),
    dest_lng: float = Query(...),
    dest_name: str = Query(...),
    user_lat: float = Query(...),
    user_lng: float = Query(...),
    mode: str = Query("driving", pattern="^(driving|walking|bicycling|transit)$"),
) -> RouteResult:
    """Get travel time and distance from user location to a destination."""
    try:
        route = await google_maps.calculate_route(user_lat, user_lng, dest_lat, dest_lng, mode)
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    if not route:
        raise HTTPException(status_code=404, detail="No route found")
    nav_url = google_maps.create_navigation_url(dest_lat, dest_lng, dest_name)
    return RouteResult(**route, navigation_url=nav_url)


@router.post("/events/rank-by-location", response_model=list[dict])
async def rank_events_by_location(body: RankEventsRequest) -> list[dict]:
    """Sort events from nearest to farthest from the user's location.

    Each event in the request must have lat and lng fields.
    Returns the same list with distance_meters added, sorted ascending.
    """
    def _haversine_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
        r = 6_371_000.0
        p1, p2 = radians(lat1), radians(lat2)
        dlat, dlng = radians(lat2 - lat1), radians(lng2 - lng1)
        a = sin(dlat / 2) ** 2 + cos(p1) * cos(p2) * sin(dlng / 2) ** 2
        return 2 * r * asin(sqrt(a))

    enriched = []
    for ev in body.events:
        dist = _haversine_m(body.user_lat, body.user_lng, ev["lat"], ev["lng"])
        enriched.append({**ev, "distance_meters": round(dist)})
    enriched.sort(key=lambda e: e["distance_meters"])
    return enriched
