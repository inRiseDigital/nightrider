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


@dataclass
class User:
    id: int
    username: str
    city: str
    lat: float | None = None
    lng: float | None = None
    preferences: dict = field(default_factory=dict)
