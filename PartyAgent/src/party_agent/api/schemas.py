"""HTTP request/response models for the chat API."""

from __future__ import annotations
from pydantic import BaseModel, Field


class GPSCoords(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    accuracy_meters: float | None = None
    heading_degrees: float | None = None
    speed_kmh: float | None = None


class ChatRequest(BaseModel):
    user_id: str = Field(..., description="Stable user identifier")
    thread_id: str = Field(..., description="Conversation thread id (one per chat session)")
    message: str
    gps: GPSCoords | None = None       # real-time GPS from mobile app (primary location source)
    city: str | None = None            # fallback if GPS not available


class ChatResponse(BaseModel):
    reply: str
    routed_to: str | None = None       # which specialist handled this turn
    cost_usd_so_far: float = 0.0
    suggestions: list[str] = Field(
        default_factory=list,
        description="Dynamic follow-up chips tailored to this turn — UI renders as tappable buttons.",
    )


class StreamChatRequest(BaseModel):
    """Matches the Flutter ChatService payload for the /chat/stream SSE endpoint."""
    message: str
    user_id: str = "anonymous"
    thread_id: str | None = None
    history: list = Field(default_factory=list)
    latitude: float | None = None
    longitude: float | None = None
