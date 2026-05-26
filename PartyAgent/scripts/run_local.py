"""CLI runner — drive the Party Chat Agent from the terminal.

Usage:
    python scripts/run_local.py

Intended for verifying your API key works and that the supervisor + agents
are wired up correctly. Use the FastAPI server (uvicorn) for real workloads.
"""

from __future__ import annotations
import os
import sys
import pathlib

# Make `party_agent` importable when running from the repo root.
ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))

from dotenv import load_dotenv  # noqa: E402

load_dotenv(ROOT / ".env")

if not os.getenv("ANTHROPIC_API_KEY"):
    print("ERROR: ANTHROPIC_API_KEY is missing.")
    print("Copy .env.example to .env and paste your key.")
    sys.exit(1)


from party_agent.core.llm import TRACKER  # noqa: E402
from party_agent.core.observability import setup_observability  # noqa: E402
from party_agent.graph import build_graph  # noqa: E402
from party_agent.memory.checkpointer import get_checkpointer  # noqa: E402
from party_agent.memory.store import get_store  # noqa: E402


SAMPLE_TURNS = [
    "What's happening in Dubai tonight? I want VIP vibes.",
    "Cool, anything in Tokyo for hip-hop?",
    "Open the map.",
    "Who's going out tonight?",
]


def main() -> None:
    setup_observability()

    with get_checkpointer() as cp, get_store() as st:
        graph = build_graph(checkpointer=cp, store=st)
        config = {"configurable": {"thread_id": "demo-thread", "user_id": "demo-user"}}

        for msg in SAMPLE_TURNS:
            print(f"\nUser : {msg}")
            result = graph.invoke(
                {"messages": [("user", msg)], "user_id": "demo-user"},
                config=config,
            )
            last = result["messages"][-1]
            content = last.content if hasattr(last, "content") else str(last)
            print(f"Agent: {content}")
            print(f"  (routed to: {result.get('next_agent')})")

        print(TRACKER.summary())
        print(f"\nRunning total: ${TRACKER.total_cost():.6f}")


if __name__ == "__main__":
    main()
