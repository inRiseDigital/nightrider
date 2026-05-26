"""Event Discovery specialist.

Handles ED-01 through ED-10 from the use case spec — finding events by mood,
genre, culture, location, and trending status.
"""

from __future__ import annotations
from langgraph.prebuilt import create_react_agent

from party_agent.core.llm import specialist_llm
from party_agent.core.state import AgentState
from party_agent.tools.events import search_events, trending_events, nearby_events
from party_agent.tools.travel import travel_estimate
from party_agent.agents.event_discovery.prompts import EVENT_DISCOVERY_PROMPT


# Build once, invoke many times.
_agent = create_react_agent(
    model=specialist_llm(),
    tools=[search_events, trending_events, nearby_events, travel_estimate],
    name="event_discovery",
    prompt=EVENT_DISCOVERY_PROMPT,
)


async def event_discovery_node(state: AgentState) -> dict:
    """Graph node that delegates the conversation to the ReAct agent."""
    result = await _agent.ainvoke(
        {"messages": state["messages"]},
        config={"recursion_limit": 8},
    )
    return {"messages": result["messages"]}
