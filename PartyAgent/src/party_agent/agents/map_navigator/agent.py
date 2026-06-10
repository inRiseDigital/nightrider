"""Map Navigator specialist — LIVE for ride deeplinks + travel estimate, preview for turn-by-turn."""

from __future__ import annotations
from langgraph.prebuilt import create_react_agent

from party_agent.core.llm import simple_llm
from party_agent.core.state import AgentState
from party_agent.tools.rides import ride_to, nearby_rides
from party_agent.tools.travel import travel_estimate
from party_agent.tools.maps import (
    directions_to,
    open_party_map,
    maps_find_nearby_parties,
    maps_get_event_travel_info,
    maps_open_navigation,
    maps_rank_events_by_distance,
    maps_check_walkability,
)
from party_agent.agents.map_navigator.prompts import MAP_NAVIGATOR_PROMPT


_agent = create_react_agent(
    model=simple_llm(),
    tools=[
        ride_to,
        travel_estimate,
        nearby_rides,
        directions_to,
        open_party_map,
        maps_find_nearby_parties,
        maps_get_event_travel_info,
        maps_open_navigation,
        maps_rank_events_by_distance,
        maps_check_walkability,
    ],
    name="map_navigator",
    prompt=MAP_NAVIGATOR_PROMPT,
)


async def map_navigator_node(state: AgentState) -> dict:
    result = await _agent.ainvoke(
        {"messages": state["messages"]},
        config={"recursion_limit": 12},
    )
    return {"messages": result["messages"]}
