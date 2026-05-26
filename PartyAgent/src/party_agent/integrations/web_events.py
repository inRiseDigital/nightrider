"""Worldwide web-event pipeline: discover → crawl → cache.

Glue between three pieces:
  serpapi.discover_venue_sites() — finds venue/promoter URLs for a city
  crawler.crawl_urls()           — extracts events with Claude
  events_db.upsert_events()      — caches to Postgres

Two entry points:

  refresh_city(city, country)
      Always crawls. Used by the scheduled refresh job (cron).

  fetch_or_crawl(city, country, vibe)
      Cache-first. Returns cached rows if fresh; otherwise crawls,
      upserts, and reads back. Used by the live-fallback path inside the
      events tool.

The pipeline is deliberately failure-tolerant: if SerpAPI is down we get []
URLs; if Crawl4AI is missing we get [] events; if the DB is unreachable we
re-raise (that's a real config problem, not a crawl problem).
"""

from __future__ import annotations

import logging

from party_agent.config import get_settings
from party_agent.data import events_db
from party_agent.integrations import crawler, serpapi

log = logging.getLogger(__name__)


def refresh_city(city: str, country: str | None = None, vibe: str | None = None) -> int:
    """Crawl the city now and upsert results. Returns rows written."""
    settings = get_settings()
    if not settings.serpapi_api_key:
        log.info("SERPAPI_API_KEY missing — cannot discover sites for %s", city)
        return 0

    urls = serpapi.discover_venue_sites(
        city=city,
        country=country,
        vibe=vibe,
        max_results=settings.crawl_max_sites_per_city,
    )
    if not urls:
        log.info("No venue URLs discovered for %s", city)
        return 0

    log.info("Crawling %d sites for %s", len(urls), city)
    events = crawler.crawl_urls(urls, city=city, country=country)
    if not events:
        log.info("Crawl returned 0 events for %s", city)
        return 0

    written = events_db.upsert_events(events)
    log.info("Wrote %d events for %s", written, city)
    return written


def fetch_or_crawl(
    city: str,
    country: str | None = None,
    vibe: str | None = None,
) -> list[dict]:
    """Read cache first; crawl on miss/stale. Returns events for `city`.

    Vibe is used only to bias the SerpAPI discovery query — the rows we
    return are filtered by city. The events tool layer does the final
    vibe-aware ranking/formatting because the cache holds events with
    different vibes from the same city.
    """
    if not events_db.is_city_fresh(city):
        try:
            refresh_city(city, country=country, vibe=vibe)
        except Exception as exc:
            # Don't fail the user query just because the crawl had a bad day.
            log.warning("Live crawl for %s failed: %s", city, exc)

    return events_db.fallback_by_city(city, limit=8)
