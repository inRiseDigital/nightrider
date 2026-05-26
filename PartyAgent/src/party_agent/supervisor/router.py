"""Supervisor — routes user messages to the right specialist.

Uses a cheap Haiku model with structured output to pick one of six specialists.
The chosen specialist is written into state.next_agent, and the graph's
conditional edge dispatches to that node.
"""

from __future__ import annotations
from typing import get_args

from langchain_core.messages import SystemMessage
from pydantic import BaseModel, Field

from party_agent.core.llm import router_llm
from party_agent.core.state import AgentState, SpecialistName
from party_agent.supervisor.prompts import SUPERVISOR_PROMPT


# Allowed names excluding the __end__ sentinel — used for the structured output.
_VALID_AGENTS = [n for n in get_args(SpecialistName) if n != "__end__"]


class RouteDecision(BaseModel):
    """Structured output the router returns."""
    agent: str = Field(description=f"One of: {', '.join(_VALID_AGENTS)}")


async def supervisor_node(state: AgentState) -> dict:
    """Route to a specialist based on the latest user message."""
    llm = router_llm().with_structured_output(RouteDecision)

    last_user_msg = next(
        (m for m in reversed(state["messages"]) if m.type == "human"),
        None,
    )
    if last_user_msg is None:
        return {"next_agent": "event_discovery"}

    decision: RouteDecision = await llm.ainvoke([
        SystemMessage(content=SUPERVISOR_PROMPT),
        last_user_msg,
    ])

    chosen = decision.agent if decision.agent in _VALID_AGENTS else "event_discovery"
    return {"next_agent": chosen}


def route_to_specialist(state: AgentState) -> str:
    """Conditional edge — reads next_agent and returns the node name to dispatch to."""
    return state.get("next_agent") or "event_discovery"
