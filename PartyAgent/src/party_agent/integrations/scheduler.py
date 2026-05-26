"""Always-on background scheduler.

Two concurrent loops, started from the FastAPI lifespan:

  refresh_loop  — every CRAWL_REFRESH_INTERVAL_MINUTES, walks the city list
                  and re-crawls any city whose cache is stale. New events
                  found by the crawler are upserted into Postgres.

  cleanup_loop  — every CRAWL_CLEANUP_INTERVAL_MINUTES, deletes crawler-sourced
                  events whose event_date is older than now - CRAWL_EVENT_TTL_HOURS.

Both loops:
  - Run in-process (no APScheduler/cron dep) using asyncio.
  - Survive errors: a failure in one iteration logs and continues.
  - Are cancel-safe: stopping the API cleanly cancels them.
  - Run the synchronous DB/crawl work in a thread so they never block the
    event loop or the chat endpoint.
"""

from __future__ import annotations

import asyncio
import logging
from typing import Iterable

from party_agent.config import get_settings
from party_agent.data import events_db
from party_agent.integrations import web_events

log = logging.getLogger(__name__)

# City list the scheduler keeps warm. Mirrors scripts/refresh_events.py
# defaults — biased toward markets where Ticketmaster + PredictHQ are weak.
DEFAULT_CITIES: list[tuple[str, str | None]] = [
    ("colombo", "LK"), ("kandy", "LK"), ("galle", "LK"),
    ("mumbai", "IN"), ("delhi", "IN"), ("bangalore", "IN"),
    ("dhaka", "BD"), ("kathmandu", "NP"),
    ("lagos", "NG"), ("nairobi", "KE"), ("accra", "GH"),
    ("bangkok", "TH"), ("ho chi minh city", "VN"), ("jakarta", "ID"),
    ("manila", "PH"), ("dubai", "AE"), ("istanbul", "TR"),
    ("cairo", "EG"), ("cape town", "ZA"), ("são paulo", "BR"),
]


async def _refresh_one(city: str, country: str | None) -> None:
    """Refresh one city only if its cache is stale. Runs the sync work off-loop."""
    loop = asyncio.get_running_loop()
    try:
        fresh = await loop.run_in_executor(None, events_db.is_city_fresh, city)
        if fresh:
            return
        written = await loop.run_in_executor(None, web_events.refresh_city, city, country)
        if written:
            log.info("scheduler: refreshed %s — %d events", city, written)
    except Exception as exc:
        log.warning("scheduler: refresh of %s failed: %s", city, exc)


async def refresh_loop(cities: Iterable[tuple[str, str | None]] = DEFAULT_CITIES) -> None:
    settings = get_settings()
    interval = max(60, settings.crawl_refresh_interval_minutes * 60)
    city_list = list(cities)
    log.info("scheduler: refresh loop started — %d cities every %d min",
             len(city_list), settings.crawl_refresh_interval_minutes)
    while True:
        for city, country in city_list:
            await _refresh_one(city, country)
        await asyncio.sleep(interval)


async def cleanup_loop() -> None:
    settings = get_settings()
    interval = max(60, settings.crawl_cleanup_interval_minutes * 60)
    log.info("scheduler: cleanup loop started — every %d min, ttl %dh",
             settings.crawl_cleanup_interval_minutes, settings.crawl_event_ttl_hours)
    loop = asyncio.get_running_loop()
    while True:
        try:
            deleted = await loop.run_in_executor(None, events_db.delete_expired_events)
            if deleted:
                log.info("scheduler: deleted %d expired events", deleted)
        except Exception as exc:
            log.warning("scheduler: cleanup failed: %s", exc)
        await asyncio.sleep(interval)


def start(
    cities: Iterable[tuple[str, str | None]] = DEFAULT_CITIES,
) -> list[asyncio.Task]:
    """Spawn the refresh and cleanup loops. Returns the tasks so the caller
    (FastAPI lifespan) can cancel them on shutdown.

    No-ops with a log line if disabled via CRAWL_SCHEDULER_ENABLED=false or if
    no DATABASE_URL is configured (cleanup needs the DB).
    """
    settings = get_settings()
    if not settings.crawl_scheduler_enabled:
        log.info("scheduler: disabled via CRAWL_SCHEDULER_ENABLED=false")
        return []
    if not settings.database_url:
        log.warning("scheduler: DATABASE_URL missing — scheduler disabled")
        return []

    return [
        asyncio.create_task(refresh_loop(cities), name="crawl-refresh-loop"),
        asyncio.create_task(cleanup_loop(), name="crawl-cleanup-loop"),
    ]


async def stop(tasks: list[asyncio.Task]) -> None:
    """Cancel scheduler tasks and wait for them to exit cleanly."""
    for t in tasks:
        t.cancel()
    for t in tasks:
        try:
            await t
        except (asyncio.CancelledError, Exception):
            pass
