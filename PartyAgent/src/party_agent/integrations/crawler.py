"""Crawl4AI wrapper — LLM-structured event extraction from arbitrary URLs.

This is the "off-platform" path: for cities where Ticketmaster and PredictHQ
return nothing (Kandy, Colombo, Lagos suburbs, Tier-2 Indian cities, etc.) we
let Claude read the actual venue/promoter site and pull out events.

Design notes:
  - Crawl4AI is imported lazily so the rest of the app keeps running even if
    the crawler isn't installed (Playwright/Chromium is a heavy dependency).
  - Extraction runs through Claude with a strict JSON schema — same shape the
    rest of the app already speaks (see _normalise() below).
  - Per-URL failures are isolated: one broken site does not poison the batch.
"""

from __future__ import annotations

import asyncio
import json
import logging
from datetime import datetime, timezone

from party_agent.config import get_settings

log = logging.getLogger(__name__)

_INSTRUCTION = (
    "Extract nightlife / party / concert / club / live-music entries from this page. "
    "Capture three kinds of items: "
    "(1) DATED events with a specific date in the future or today — resolve "
    "    relative phrases like 'this Friday' or 'tonight' to an ISO YYYY-MM-DD "
    "    date, (2) RECURRING events such as 'Live music every Friday' or "
    "    'Karaoke night Wednesdays' — leave date empty and put the recurrence "
    "    pattern (e.g. 'Fridays', 'every weekend') in the `recurrence` field, "
    "    (3) NIGHTLIFE VENUES that are clearly party / clubbing / DJ / live-music "
    "    spots even without a specific event listed — capture them with the "
    "    venue's name as `name` and use `recurrence`='regular nights'. "
    "Skip: past events, restaurant-only listings, hotels, generic city tourist info. "
    "Always include the city name from the page if available. Return [] only if the "
    "page truly has no nightlife content."
)

# JSON schema Claude must conform to. Kept flat so the LLM stays reliable.
_EVENT_SCHEMA = {
    "type": "array",
    "items": {
        "type": "object",
        "required": ["name"],
        "properties": {
            "name":       {"type": "string"},
            "date":       {"type": "string", "description": "YYYY-MM-DD; empty for recurring/venue entries"},
            "recurrence": {"type": "string", "description": "e.g. 'Fridays', 'every weekend', 'regular nights'"},
            "venue":      {"type": "string"},
            "city":       {"type": "string"},
            "country":    {"type": "string"},
            "vibe":       {"type": "string", "description": "music genre or scene (edm, jazz, hip-hop, live-music...)"},
            "price":      {"type": "string", "description": "e.g. 'free', '$20', 'LKR 2000'"},
        },
    },
}


def _normalise(raw: list[dict], source_url: str, fallback_city: str, fallback_country: str | None) -> list[dict]:
    """Coerce the LLM's output into the shape events_db.upsert_event expects.

    Recurring entries (e.g. "Karaoke every Friday") arrive with no `date` and a
    populated `recurrence`. We surface the recurrence into the price/vibe text
    so downstream formatting still has something useful to show the user.
    """
    out: list[dict] = []
    now = datetime.now(timezone.utc).isoformat()
    for r in raw:
        name = (r.get("name") or "").strip()
        if not name:
            continue
        recurrence = (r.get("recurrence") or "").strip()
        vibe = (r.get("vibe") or "music").strip().lower()
        # When a venue has no real event but is a clear party spot, we keep
        # the row but tag it so the agent can surface it as "regular nights".
        if recurrence and recurrence.lower() not in vibe:
            vibe = f"{vibe} ({recurrence})".strip()

        out.append({
            "name":            name,
            "city":            (r.get("city")    or fallback_city    or "").strip().lower(),
            "country":         (r.get("country") or fallback_country or "").strip().upper() or None,
            "vibe":            vibe,
            "price":           (r.get("price")   or "").strip() or None,
            "date":            (r.get("date")    or "").strip() or None,
            "source":          "web_crawl",
            "source_url":      source_url,
            "last_crawled_at": now,
        })
    return out


async def _extract_one(url: str, fallback_city: str, fallback_country: str | None) -> list[dict]:
    """Single-URL crawl + extract. Returns [] on any error so the batch survives."""
    try:
        from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig, LLMConfig
        from crawl4ai.extraction_strategy import LLMExtractionStrategy
    except ImportError:
        log.warning("crawl4ai not installed — skipping live crawl for %s", url)
        return []

    settings = get_settings()
    if not settings.anthropic_api_key:
        log.warning("ANTHROPIC_API_KEY missing — cannot run LLM extraction")
        return []

    llm = LLMExtractionStrategy(
        llm_config=LLMConfig(
            provider=f"anthropic/{settings.crawl_extractor_model}",
            api_token=settings.anthropic_api_key,
        ),
        schema=_EVENT_SCHEMA,
        extraction_type="schema",
        instruction=_INSTRUCTION,
        # Keep input bounded so token cost stays predictable per page.
        chunk_token_threshold=2000,
        apply_chunking=True,
    )

    try:
        async with AsyncWebCrawler(config=BrowserConfig(headless=True, verbose=False)) as crawler:
            result = await crawler.arun(
                url=url,
                config=CrawlerRunConfig(
                    extraction_strategy=llm,
                    page_timeout=20_000,
                    word_count_threshold=20,
                ),
            )
        if not result.success or not result.extracted_content:
            return []
        parsed = json.loads(result.extracted_content)
        # LLMExtractionStrategy can wrap items in a list of chunks; flatten if so.
        flat: list[dict] = []
        for item in parsed if isinstance(parsed, list) else [parsed]:
            if isinstance(item, list):
                flat.extend(x for x in item if isinstance(x, dict))
            elif isinstance(item, dict):
                flat.append(item)
        return _normalise(flat, source_url=url, fallback_city=fallback_city, fallback_country=fallback_country)
    except Exception as exc:
        log.warning("Crawl failed for %s: %s", url, exc)
        return []


async def _crawl_async(urls: list[str], city: str, country: str | None) -> list[dict]:
    # Run pages concurrently — Crawl4AI handles browser context isolation.
    # Cap concurrency so one busy node doesn't open 20 Chromium tabs.
    sem = asyncio.Semaphore(3)

    async def _one(u: str) -> list[dict]:
        async with sem:
            return await _extract_one(u, city, country)

    batches = await asyncio.gather(*(_one(u) for u in urls), return_exceptions=False)
    return [event for batch in batches for event in batch]


def crawl_urls(urls: list[str], city: str, country: str | None = None) -> list[dict]:
    """Sync entry point — crawl a list of URLs and return normalised events.

    Safe to call from sync code (the rest of the app is sync). Internally
    runs an asyncio loop. Returns [] if Crawl4AI is not installed or every
    URL failed.
    """
    if not urls:
        return []
    try:
        return asyncio.run(_crawl_async(urls, city, country))
    except RuntimeError:
        # Already inside a running loop (e.g. inside an async tool/test) — use a fresh loop.
        loop = asyncio.new_event_loop()
        try:
            return loop.run_until_complete(_crawl_async(urls, city, country))
        finally:
            loop.close()
