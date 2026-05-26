"""Launcher for the FastAPI app — runs uvicorn on a SelectorEventLoop on Windows.

Why this script exists
----------------------
psycopg's AsyncConnection rejects Windows' default ``ProactorEventLoop`` and
requires a ``SelectorEventLoop``. Uvicorn's CLI creates a fresh event loop
during boot, so even if we set ``WindowsSelectorEventLoopPolicy`` early,
uvicorn's internal startup can override it back to Proactor.

Reliable fix: drive ``Server.serve()`` ourselves inside ``asyncio.run`` with
an explicit ``loop_factory`` (Python 3.12+). This guarantees the running loop
is a SelectorEventLoop, which is exactly what the psycopg error message
recommends ("Please use a compatible event loop, for instance by running
'asyncio.run(..., loop_factory=...)'").

Use it instead of the bare ``uvicorn`` CLI on Windows::

    .venv\\Scripts\\python.exe run_server.py

On Linux/macOS we just call ``uvicorn.run`` — Proactor is Windows-only.
"""

from __future__ import annotations

import asyncio
import os
import sys

import uvicorn


# Port 8000 is the FastAPI/uvicorn default but it collides with a lot of
# other local services (ChromaDB ships its API on 8000). Default to 8010 and
# allow override via env var so multiple services can coexist.
DEFAULT_PORT = int(os.environ.get("PARTY_AGENT_PORT", "8000"))


CONFIG_KWARGS: dict = {
    "app": "party_agent.api.main:app",
    "host": "0.0.0.0",
    "port": DEFAULT_PORT,
    "log_level": "info",
    # Reload off so the AsyncPostgres pool stays stable across requests.
    "reload": False,
    # Allow reuse so the port clears instantly after a restart (no 30s TIME_WAIT wait on Windows).
    "timeout_graceful_shutdown": 1,
}


def _windows_main() -> None:
    """Run uvicorn on an explicit SelectorEventLoop (Python 3.12+ required)."""
    import selectors

    config = uvicorn.Config(**CONFIG_KWARGS)
    server = uvicorn.Server(config)

    async def _serve() -> None:
        await server.serve()

    asyncio.run(
        _serve(),
        loop_factory=lambda: asyncio.SelectorEventLoop(selectors.SelectSelector()),
    )


def main() -> None:
    if sys.platform == "win32":
        _windows_main()
    else:
        uvicorn.run(**CONFIG_KWARGS)


if __name__ == "__main__":
    main()
