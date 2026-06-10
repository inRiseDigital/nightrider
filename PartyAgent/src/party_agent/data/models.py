"""Data models for the party agent."""

from __future__ import annotations
from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class Event:
    id: int
    name: str
    city: str
    vibe: str
    lat: float
    lng: float
    rsvps: int
    description: str = ""
    event_date: datetime | None = None
    # Google Maps enrichment (populated on demand via integrations/google_maps.py)
    venue_place_id: str | None = None
    venue_address: str | None = None
    venue_google_maps_url: str | None = None
    distance_from_user_meters: int | None = None
    estimated_travel_time_minutes: int | None = None
    recommended_travel_mode: str | None = None


@dataclass
class User:
    id: int
    username: str
    city: str
    lat: float | None = None
    lng: float | None = None
    preferences: dict = field(default_factory=dict)
