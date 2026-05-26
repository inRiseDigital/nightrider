"""Crowd tool — NOT YET WIRED.

Requires a venue-partner API feed. Returns an honest unavailable marker for
now — making up occupancy / queue numbers is the single highest-risk
hallucination this app could ship.
"""
from langchain_core.tools import tool

from party_agent.tools._unavailable import unavailable


@tool
def venue_status(venue_name: str) -> str:
    """Return occupancy %, queue time, and current vibe of a venue."""
    return unavailable(
        f"live venue conditions for {venue_name}",
        suggestion=(
            "NEVER invent crowd percentages or wait times — tell the user "
            "live venue data isn't available yet and suggest they DM the "
            "venue directly or check social media for tonight's vibe"
        ),
    )
