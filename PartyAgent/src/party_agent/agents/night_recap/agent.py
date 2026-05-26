"""night_recap specialist — STUB. Mirror the pattern from event_discovery/agent.py."""

from __future__ import annotations
from langgraph.prebuilt import create_react_agent

from party_agent.core.llm import simple_llm
from party_agent.core.state import AgentState
from party_agent.agents.night_recap.prompts import NIGHT_RECAP_PROMPT

# TODO: import the tools this specialist needs from party_agent.tools

_agent = create_react_agent(
    model=simple_llm(),
    tools=[],  # TODO
    name="night_recap",
    prompt=NIGHT_RECAP_PROMPT,
)


async def night_recap_node(state: AgentState) -> dict:
    result = await _agent.ainvoke(
        {"messages": state["messages"]},
        config={"recursion_limit": 12},
    )
    return {"messages": result["messages"]}
