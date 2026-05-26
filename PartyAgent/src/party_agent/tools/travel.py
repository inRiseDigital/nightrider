"""Travel estimate tool — heuristic distance, duration, and best-vehicle recommendation.

Pure-Python: no external API key required. Uses the haversine formula for great-circle
distance and mode-based average speeds to suggest the most sensible transport. Swap in
Google Maps Directions later by extending integrations/google_maps.py.
"""

from __future__ import annotations

from math import asin, cos, radians, sin, sqrt

from langchain_core.tools import tool


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance in km between two GPS points."""
    r = 6371.0
    p1, p2 = radians(lat1), radians(lat2)
    dlat = radians(lat2 - lat1)
    dlng = radians(lng2 - lng1)
    a = sin(dlat / 2) ** 2 + cos(p1) * cos(p2) * sin(dlng / 2) ** 2
    return 2 * r * asin(sqrt(a))


def _format_duration(minutes: float) -> str:
    if minutes < 1:
        return "<1 min"
    if minutes < 60:
        return f"~{int(round(minutes))} min"
    hours = minutes / 60
    if hours < 10:
        return f"~{hours:.1f} hr"
    return f"~{int(round(hours))} hr"


def _recommend_mode(distance_km: float) -> tuple[str, float, str]:
    """Return (mode, avg_speed_kmh, why) for a given distance.

    Speeds include realistic overhead (traffic, stops) — not raw cruise speeds.
    """
    if distance_km <= 1.5:
        return ("walk", 5.0, "short enough to walk")
    if distance_km <= 5.0:
        return ("tuk-tuk / short taxi", 22.0, "quick urban ride")
    if distance_km <= 30.0:
        return ("car / taxi / ride-share", 35.0, "fastest door-to-door for this range")
    if distance_km <= 200.0:
        return ("train or intercity bus", 55.0, "comfortable for medium trips")
    if distance_km <= 800.0:
        return ("intercity train or domestic flight", 250.0, "covers long distance fast")
    return ("flight", 650.0, "only sensible option at this distance")


@tool
def travel_estimate(from_lat: float, from_lng: float, to_lat: float, to_lng: float) -> str:
    """Estimate distance, travel time, and best vehicle between two GPS points.

    Use this when suggesting a party in a different area/city than the user's GPS:
    tells them how far it is, how long it takes, and which transport to use.

    Args:
        from_lat: Origin latitude (the user's GPS).
        from_lng: Origin longitude (the user's GPS).
        to_lat: Destination latitude (the venue/event).
        to_lng: Destination longitude (the venue/event).

    Returns:
        A line like: "12.4 km | car / taxi / ride-share | ~21 min"
    """
    distance_km = _haversine_km(from_lat, from_lng, to_lat, to_lng)
    mode, speed_kmh, _why = _recommend_mode(distance_km)

    duration_min = (distance_km / speed_kmh) * 60
    # Long-haul overhead: airport + boarding adds real time.
    if mode == "flight":
        duration_min += 90
    elif "train" in mode or "bus" in mode:
        duration_min += 15  # station + waiting

    if distance_km < 10:
        dist_str = f"{distance_km:.1f} km"
    else:
        dist_str = f"{int(round(distance_km))} km"

    return f"{dist_str} | {mode} | {_format_duration(duration_min)}"
