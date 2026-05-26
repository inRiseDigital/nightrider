"""Shared agent state.

Every node in the graph reads and writes this TypedDict. Keep it small —
expensive structures (event lists, friend graphs) belong in tools or memory,
not in state.
"""

from __future__ import annotations
from typing import Annotated, Literal, TypedDict

from langchain_core.messages import AnyMessage
from langgraph.graph.message import add_messages


# Names must match agent registration in graph.py
SpecialistName = Literal[
    "event_discovery",
    "map_navigator",
    "social_companion",
    "gamification",
    "night_recap",
    "safety_support",
    "__end__",  # supervisor returns this when conversation is complete
]


class AgentState(TypedDict, total=False):
    """The state object that flows through the graph."""

    # Conversation history. add_messages handles append + dedup correctly.
    messages: Annotated[list[AnyMessage], add_messages]

    # Who the user is. Set on entry, used by every agent for personalization
    # and used to namespace the long-term memory store.
    user_id: str

    # Which city we're operating in (Dubai / Tokyo / London / Melbourne).
    # Set from user profile or detected from message.
    city: str | None

    # Set by supervisor each turn — which specialist should handle this.
    next_agent: SpecialistName | None

    # Privacy flag — when True, social_companion + map_navigator hide the user.
    stealth_mode: bool
