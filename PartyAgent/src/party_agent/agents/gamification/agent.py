"""Gamification specialist — LIVE (real points, streaks, badges in Postgres)."""

from __future__ import annotations
from langgraph.prebuilt import create_react_agent

from party_agent.core.llm import simple_llm
from party_agent.core.state import AgentState
from party_agent.tools.gamification import check_in, check_progress, unlock_badge
from party_agent.agents.gamification.prompts import GAMIFICATION_PROMPT


_agent = create_react_agent(
    model=simple_llm(),
    tools=[check_progress, check_in, unlock_badge],
    name="gamification",
    prompt=GAMIFICATION_PROMPT,
)


async def gamification_node(state: AgentState) -> dict:
    result = await _agent.ainvoke(
        {"messages": state["messages"], "user_id": state.get("user_id", "")},
        config={"recursion_limit": 12},
    )
    return {"messages": result["messages"]}
