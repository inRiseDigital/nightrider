"""Long-term memory Store.

The Store is keyed by (namespace, key). For the Party Agent, the canonical
namespace pattern is ("user", user_id, category) — for example:

    ("user", "u_123", "preferences")  → {"vibe": "underground", "city": "london"}
    ("user", "u_123", "badges")       → ["night_owl", "city_explorer"]
    ("user", "u_123", "streak")       → {"weeks": 3, "last_event": "2026-05-04"}

PostgresStore in prod, InMemoryStore locally. Vector search is enabled for the
"preferences" and "history" namespaces so the Event Discovery agent can do
semantic retrieval across past behaviour.
"""

from __future__ import annotations
from contextlib import asynccontextmanager, contextmanager
from typing import AsyncIterator, Iterator

from langgraph.store.base import BaseStore
from langgraph.store.memory import InMemoryStore

from party_agent.config import get_settings


@asynccontextmanager
async def get_store() -> AsyncIterator[BaseStore]:
    """Async store for the FastAPI runtime — see checkpointer.py for the rationale."""
    settings = get_settings()
    if not settings.database_url:
        yield InMemoryStore()
        return

    from langgraph.store.postgres.aio import AsyncPostgresStore
    async with AsyncPostgresStore.from_conn_string(settings.database_url) as store:
        await store.setup()
        yield store


@contextmanager
def get_store_sync() -> Iterator[BaseStore]:
    """Sync store for scripts/CLI tools."""
    settings = get_settings()
    if not settings.database_url:
        yield InMemoryStore()
        return

    from langgraph.store.postgres import PostgresStore
    with PostgresStore.from_conn_string(settings.database_url) as store:
        store.setup()
        yield store


# --- Convenience helpers used by agents ---

def user_namespace(user_id: str, category: str) -> tuple[str, str, str]:
    """Build the canonical namespace tuple for a user's data."""
    return ("user", user_id, category)
