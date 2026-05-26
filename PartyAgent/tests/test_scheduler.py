"""Tests for the always-on scheduler.

Verify start() respects the kill-switches, refresh skips fresh cities, and
cleanup invokes the DB function. The two long-running loops are exercised by
swapping asyncio.sleep for a fast canceller so we don't actually wait.
"""

from __future__ import annotations

import asyncio
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from party_agent.integrations import scheduler


# ---------- start() kill-switches ----------

def test_start_disabled_returns_no_tasks():
    with patch("party_agent.integrations.scheduler.get_settings") as gs:
        gs.return_value.crawl_scheduler_enabled = False
        gs.return_value.database_url = "postgres://x"
        assert scheduler.start() == []


def test_start_without_database_url_returns_no_tasks():
    with patch("party_agent.integrations.scheduler.get_settings") as gs:
        gs.return_value.crawl_scheduler_enabled = True
        gs.return_value.database_url = None
        assert scheduler.start() == []


# ---------- _refresh_one ----------

@pytest.mark.asyncio
async def test_refresh_one_skips_when_fresh():
    with patch("party_agent.integrations.scheduler.events_db.is_city_fresh", return_value=True), \
         patch("party_agent.integrations.scheduler.web_events.refresh_city") as refresh:
        await scheduler._refresh_one("kandy", "LK")
    refresh.assert_not_called()


@pytest.mark.asyncio
async def test_refresh_one_crawls_when_stale():
    with patch("party_agent.integrations.scheduler.events_db.is_city_fresh", return_value=False), \
         patch("party_agent.integrations.scheduler.web_events.refresh_city", return_value=4) as refresh:
        await scheduler._refresh_one("kandy", "LK")
    refresh.assert_called_once_with("kandy", "LK")


@pytest.mark.asyncio
async def test_refresh_one_swallows_errors():
    """One bad city must not crash the whole loop."""
    with patch("party_agent.integrations.scheduler.events_db.is_city_fresh", side_effect=RuntimeError("db down")):
        await scheduler._refresh_one("kandy", "LK")  # should not raise


# ---------- refresh_loop ----------

@pytest.mark.asyncio
async def test_refresh_loop_iterates_and_then_sleeps():
    """One full pass over the city list, then we cancel during the sleep."""
    settings = MagicMock(crawl_refresh_interval_minutes=60)
    cities = [("kandy", "LK"), ("colombo", "LK")]

    visited: list[str] = []

    async def fake_refresh_one(city: str, country: str | None) -> None:
        visited.append(city)

    sleep_mock = AsyncMock(side_effect=asyncio.CancelledError)

    with patch("party_agent.integrations.scheduler.get_settings", return_value=settings), \
         patch("party_agent.integrations.scheduler._refresh_one", new=fake_refresh_one), \
         patch("party_agent.integrations.scheduler.asyncio.sleep", new=sleep_mock):
        with pytest.raises(asyncio.CancelledError):
            await scheduler.refresh_loop(cities)

    assert visited == ["kandy", "colombo"]
    sleep_mock.assert_awaited_once()


# ---------- cleanup_loop ----------

@pytest.mark.asyncio
async def test_cleanup_loop_calls_delete_then_sleeps():
    settings = MagicMock(
        crawl_cleanup_interval_minutes=60,
        crawl_event_ttl_hours=6,
    )
    delete_mock = MagicMock(return_value=3)
    sleep_mock = AsyncMock(side_effect=asyncio.CancelledError)

    with patch("party_agent.integrations.scheduler.get_settings", return_value=settings), \
         patch("party_agent.integrations.scheduler.events_db.delete_expired_events", new=delete_mock), \
         patch("party_agent.integrations.scheduler.asyncio.sleep", new=sleep_mock):
        with pytest.raises(asyncio.CancelledError):
            await scheduler.cleanup_loop()

    delete_mock.assert_called_once()
    sleep_mock.assert_awaited_once()


@pytest.mark.asyncio
async def test_cleanup_loop_survives_db_errors():
    settings = MagicMock(crawl_cleanup_interval_minutes=60, crawl_event_ttl_hours=6)
    delete_mock = MagicMock(side_effect=RuntimeError("db down"))
    sleep_mock = AsyncMock(side_effect=asyncio.CancelledError)

    with patch("party_agent.integrations.scheduler.get_settings", return_value=settings), \
         patch("party_agent.integrations.scheduler.events_db.delete_expired_events", new=delete_mock), \
         patch("party_agent.integrations.scheduler.asyncio.sleep", new=sleep_mock):
        with pytest.raises(asyncio.CancelledError):
            await scheduler.cleanup_loop()

    delete_mock.assert_called_once()


# ---------- stop() ----------

@pytest.mark.asyncio
async def test_stop_cancels_tasks_cleanly():
    async def forever():
        while True:
            await asyncio.sleep(60)

    tasks = [asyncio.create_task(forever()), asyncio.create_task(forever())]
    await scheduler.stop(tasks)
    assert all(t.cancelled() or t.done() for t in tasks)
