"""Pydantic models for long-term memory.

Validates what gets written to the Store, so we never end up with mixed shapes
across users.
"""

from __future__ import annotations
from datetime import date
from pydantic import BaseModel, Field


class UserPreferences(BaseModel):
    """What the user likes — populated as the Event Discovery agent learns."""
    favorite_vibes: list[str] = Field(default_factory=list)
    favorite_cities: list[str] = Field(default_factory=list)
    avoid_genres: list[str] = Field(default_factory=list)
    likes_vip: bool = False
    privacy_default_stealth: bool = False


class UserGamification(BaseModel):
    badges: list[str] = Field(default_factory=list)
    streak_weeks: int = 0
    last_event_date: date | None = None
    level: int = 1


class FriendLink(BaseModel):
    friend_user_id: str
    nickname: str | None = None
    visible_to_me: bool = True
    visible_to_them: bool = True


class EventHistoryEntry(BaseModel):
    event_id: int
    city: str
    vibe: str
    attended_at: date
    rating: int | None = None  # 1–5, optional
