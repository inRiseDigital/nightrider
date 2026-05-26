from __future__ import annotations
from langgraph.checkpoint.base import BaseCheckpointSaver
from langgraph.graph import StateGraph, START, END
from langgraph.store.base import BaseStore

from party_agent.core.state import AgentState
from party_agent.supervisor.router import supervisor_node, route_to_specialist

from party_agent.agents.event_discovery.agent  import event_discovery_node
from party_agent.agents.map_navigator.agent    import map_navigator_node
from party_agent.agents.social_companion.agent import social_companion_node
from party_agent.agents.gamification.agent     import gamification_node
from party_agent.agents.night_recap.agent      import night_recap_node
from party_agent.agents.safety_support.agent   import safety_support_node


def build_graph(
    checkpointer: BaseCheckpointSaver | None = None,
    store: BaseStore | None = None,
):
    """Compile the agent graph. Pass a checkpointer + store to enable memory."""
    builder = StateGraph(AgentState)

    builder.add_node("supervisor",        supervisor_node)
    builder.add_node("event_discovery",   event_discovery_node)
    builder.add_node("map_navigator",     map_navigator_node)
    builder.add_node("social_companion",  social_companion_node)
    builder.add_node("gamification",      gamification_node)
    builder.add_node("night_recap",       night_recap_node)
    builder.add_node("safety_support",    safety_support_node)

    builder.add_edge(START, "supervisor")
    builder.add_conditional_edges(
        "supervisor",
        route_to_specialist,
        {
            "event_discovery":  "event_discovery",
            "map_navigator":    "map_navigator",
            "social_companion": "social_companion",
            "gamification":     "gamification",
            "night_recap":      "night_recap",
            "safety_support":   "safety_support",
        },
    )

    # Each specialist ends the turn. The next user message will re-enter at supervisor.
    for specialist in (
        "event_discovery", "map_navigator", "social_companion",
        "gamification", "night_recap", "safety_support",
    ):
        builder.add_edge(specialist, END)

    return builder.compile(checkpointer=checkpointer, store=store)
