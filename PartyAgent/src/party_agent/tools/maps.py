"""Maps tool — NOT YET WIRED.

Will wrap Google Maps Places + Directions via integrations/google_maps.py once
those endpoints land. Until then, every call returns an honest
"feature not live" marker so the agent doesn't pretend it can navigate.
"""
from langchain_core.tools import tool

from party_agent.tools._unavailable import unavailable


@tool
def open_party_map(city: str, vibe_filter: str | None = None) -> str:
    """Open the party map filtered by city and optional vibe."""
    return unavailable(
        "the in-app party map",
        suggestion="describe nearby events from the event search results instead",
    )


@tool
def directions_to(venue_name: str) -> str:
    """Get walking/driving directions to a named venue."""
    return unavailable(
        f"venue directions to {venue_name}",
        suggestion="tell the user to tap the venue address in their own maps app",
    )
