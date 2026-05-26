"""FastAPI application.

Run locally: uvicorn party_agent.api.main:app --reload --port 8000
"""

from __future__ import annotations
import asyncio
import logging
from contextlib import asynccontextmanager, AsyncExitStack

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from party_agent.core.observability import setup_observability
from party_agent.api.routes import chat, health
from party_agent.graph import build_graph
from party_agent.integrations import scheduler
from party_agent.memory.checkpointer import get_checkpointer
from party_agent.memory.store import get_store

log = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_observability()

    # Start immediately with an in-memory graph so the first request is never
    # blocked waiting for Postgres. The graph is swapped in-place once the DB
    # pools and migrations finish (usually 5-30 s). Requests arriving before
    # the swap work fine — they just won't persist conversation history.
    app.state.graph = build_graph()
    scheduler_tasks = scheduler.start()

    shutdown = asyncio.Event()

    async def _connect_db() -> None:
        try:
            async with AsyncExitStack() as stack:
                checkpointer, store = await asyncio.gather(
                    stack.enter_async_context(get_checkpointer()),
                    stack.enter_async_context(get_store()),
                )
                app.state.graph = build_graph(checkpointer=checkpointer, store=store)
                log.info("party-agent: Postgres-backed graph active")
                await shutdown.wait()   # hold pools open until server exits
        except asyncio.CancelledError:
            pass
        except Exception:
            log.exception("party-agent: DB setup failed — running on InMemory only")

    db_task = asyncio.create_task(_connect_db(), name="db-setup")

    try:
        yield                           # server announces startup here — instant
    finally:
        shutdown.set()                  # unblocks _connect_db → clean pool teardown
        await db_task
        await scheduler.stop(scheduler_tasks)


app = FastAPI(
    title="Party Chat Agent",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(chat.router)
