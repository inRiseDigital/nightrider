"""Safety & Support specialist — LIVE for weather, preview for GPS beacon / live crowd."""

from __future__ import annotations
from langgraph.prebuilt import create_react_agent

from party_agent.core.llm import specialist_llm
from party_agent.core.state import AgentState
from party_agent.tools.weather import get_weather
from party_agent.tools.rides import ride_to
from party_agent.tools.crowd import venue_status
from party_agent.agents.safety_support.prompts import SAFETY_SUPPORT_PROMPT


_agent = create_react_agent(
    model=specialist_llm(),
    tools=[get_weather, ride_to, venue_status],
    name="safety_support",
    prompt=SAFETY_SUPPORT_PROMPT,
)


async def safety_support_node(state: AgentState) -> dict:
    result = await _agent.ainvoke(
        {"messages": state["messages"]},
        config={"recursion_limit": 12},
    )
    return {"messages": result["messages"]}
