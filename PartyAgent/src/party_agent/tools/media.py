"""Media tool — NOT YET WIRED.

Will assemble video recaps (ffmpeg) and generate captions/themes (recap_llm).
Returns an honest unavailable marker for now.
"""
from langchain_core.tools import tool

from party_agent.tools._unavailable import unavailable


@tool
def build_recap(user_id: str, event_id: int, theme: str = "wild_night") -> str:
    """Build a night recap from a user's photos/videos for a given event."""
    return unavailable(
        "night-recap video generation",
        suggestion="tell the user recap generation is coming and offer to remember the event for later",
    )
