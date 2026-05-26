"""Checkpointer factory.

Returns an AsyncPostgresSaver if DATABASE_URL is set, otherwise an InMemorySaver
for local development. The checkpointer holds short-term conversation state,
keyed by thread_id.

Why async: the FastAPI chat route uses `await graph.ainvoke(...)`, which calls
the checkpointer's async methods (`aget_tuple` / `aput`). The sync PostgresSaver
does not implement those — it raises NotImplementedError on the first request.
AsyncPostgresSaver implements both sync and async APIs so the scheduler's sync
DB code keeps working too.

We swap the contextmanager for an async one (entered from FastAPI's lifespan)
because AsyncPostgresSaver's setup is async-only.
"""

from __future__ import annotations
from contextlib import asynccontextmanager, contextmanager
from typing import AsyncIterator, Iterator

from langgraph.checkpoint.base import BaseCheckpointSaver
from langgraph.checkpoint.memory import InMemorySaver

from party_agent.config import get_settings


@asynccontextmanager
async def get_checkpointer() -> AsyncIterator[BaseCheckpointSaver]:
    """Yield a checkpointer appropriate for the current environment.

    Async-context managed so the Postgres pool is set up on app start and
    torn down on shutdown. Falls back to InMemorySaver when DATABASE_URL is
    unset (useful for local dev / unit tests).
    """
    settings = get_settings()
    if not settings.database_url:
        yield InMemorySaver()
        return

    # Lazy import — only require psycopg if Postgres is actually configured.
    from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
    async with AsyncPostgresSaver.from_conn_string(settings.database_url) as cp:
        await cp.setup()
        yield cp


@contextmanager
def get_checkpointer_sync() -> Iterator[BaseCheckpointSaver]:
    """Synchronous variant for scripts/CLI tools that aren't running an event loop."""
    settings = get_settings()
    if not settings.database_url:
        yield InMemorySaver()
        return
    from langgraph.checkpoint.postgres import PostgresSaver
    with PostgresSaver.from_conn_string(settings.database_url) as cp:
        cp.setup()
        yield cp
