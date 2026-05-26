"""Social Companion specialist — LIVE for RSVPs + stealth, preview for friend graph."""

from __future__ import annotations
from langgraph.prebuilt import create_react_agent

from party_agent.core.llm import simple_llm
from party_agent.core.state import AgentState
from party_agent.tools.social_graph import (
    cancel_rsvp,
    friends_out_tonight,
    list_my_rsvps,
    post_rsvp,
    set_stealth_mode,
    stealth_status,
)
from party_agent.agents.social_companion.prompts import SOCIAL_COMPANION_PROMPT


_agent = create_react_agent(
    model=simple_llm(),
    tools=[
        post_rsvp,
        list_my_rsvps,
        cancel_rsvp,
        set_stealth_mode,
        stealth_status,
        friends_out_tonight,  # honestly reports unavailable until the friend graph ships
    ],
    name="social_companion",
    prompt=SOCIAL_COMPANION_PROMPT,
)


async def social_companion_node(state: AgentState) -> dict:
    result = await _agent.ainvoke(
        {"messages": state["messages"], "user_id": state.get("user_id", "")},
        config={"recursion_limit": 12},
    )
    return {"messages": result["messages"]}
