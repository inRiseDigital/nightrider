"""SerpAPI client — venue/promoter site auto-discovery for any city worldwide.

Used by the live-crawl fallback path: when Ticketmaster + PredictHQ return
nothing for a given city (e.g. Kandy, Sri Lanka), we ask Google (via SerpAPI)
to find the actual venue and promoter websites for that city. The crawler then
extracts events from those pages.

Free tier: 100 searches/mo at https://serpapi.com/. Set SERPAPI_API_KEY in .env.

Why SerpAPI instead of scraping Google directly:
  - Google CAPTCHAs unauthenticated traffic after a handful of requests.
  - SerpAPI is paid-but-cheap, returns clean JSON, and is ToS-safe.

Multi-query discovery
---------------------
A single Google query for "kandy nightlife venues" surfaces mostly travel
guides (wanderlog, lonelyplanet) that have no real event data. To bias toward
pages with actual upcoming events we run several focused queries per call and
merge unique hosts. We also exclude obvious travel-guide noise via Google's
``-`` operator. Each call costs N SerpAPI credits where N = number of queries.
"""

from __future__ import annotations

import logging
from datetime import date
from urllib.parse import urlparse

import httpx

from party_agent.config import get_settings

log = logging.getLogger(__name__)

_BASE = "https://serpapi.com/search.json"
_TIMEOUT = 10

# Hosts that are noisy (review aggregators, social, big DBs). We skip these
# when discovering venue sites so the crawler spends its budget on small
# promoter/venue pages where off-platform events actually live.
_BLOCKED_HOSTS = {
    "tripadvisor.com", "yelp.com", "wikipedia.org", "reddit.com",
    "youtube.com", "facebook.com", "instagram.com", "tiktok.com",
    "twitter.com", "x.com", "ticketmaster.com", "eventbrite.com",
    "predicthq.com", "google.com", "maps.google.com", "booking.com",
    "agoda.com", "expedia.com",
    # Travel guides that pollute small-city searches with non-event content.
    "wanderlog.com", "lonelyplanet.com", "thrillophilia.com",
    "srilankatraveldeals.com", "viator.com", "getyourguide.com",
}

# Negative keywords passed to Google to push down generic travel-guide content.
_NEG_TERMS = "-tripadvisor -wanderlog -lonelyplanet -viator -getyourguide -travelguide"


def _host(url: str) -> str:
    try:
        # str.removeprefix("www.") — NOT lstrip. lstrip("www.") treats "www." as
        # a char set and over-strips hosts starting with 'w' (wanderlog.com →
        # anderlog.com), which silently breaks blocked-host matching.
        return (urlparse(url).hostname or "").lower().removeprefix("www.")
    except Exception:
        return ""


def _allowed(url: str) -> bool:
    host = _host(url)
    if not host:
        return False
    # Block exact match or any subdomain of a blocked host.
    return not any(host == b or host.endswith("." + b) for b in _BLOCKED_HOSTS)


def _build_queries(city: str, country: str | None, vibe: str | None) -> list[str]:
    """Three focused queries that bias Google toward real event pages.

    Empirically: a single broad "{city} nightlife" query brings up travel
    guides; layering on date hints, venue intent, and event-listing keywords
    surfaces a more useful mix.
    """
    location = f"{city}, {country}" if country else city
    year = date.today().year
    vibe_part = f" {vibe}" if vibe else ""

    return [
        # Pass 1 — recency-biased event listings.
        f'"{location}" event{vibe_part} party tonight {year} {_NEG_TERMS}',
        # Pass 2 — calendar/lineup pages from venues themselves.
        f'"{location}"{vibe_part} (inurl:event OR inurl:calendar OR inurl:lineup OR inurl:tonight)',
        # Pass 3 — generic venue intent so we still pick up promoter blogs.
        f"{location} nightclub{vibe_part} live music DJ this weekend {_NEG_TERMS}",
    ]


class _RateLimited(Exception):
    """Raised when SerpAPI returns 429 — signals caller to stop sending more queries."""


def _run_query(query: str, key: str) -> list[dict]:
    params = {"engine": "google", "q": query, "num": 20, "api_key": key, "hl": "en"}
    try:
        resp = httpx.get(_BASE, params=params, timeout=_TIMEOUT)
        if resp.status_code == 429:
            log.warning("SerpAPI rate limit hit — stopping queries for this cycle")
            raise _RateLimited
        resp.raise_for_status()
        return resp.json().get("organic_results") or []
    except _RateLimited:
        raise
    except Exception:
        return []


def discover_venue_sites(
    city: str,
    country: str | None = None,
    vibe: str | None = None,
    max_results: int = 8,
) -> list[str]:
    """Return up to max_results venue/promoter URLs for a city.

    Runs several focused Google queries via SerpAPI, merges the organic
    results, filters out travel-guide noise, and dedupes by host. Returns []
    if SerpAPI is not configured — caller is expected to degrade gracefully.
    """
    key = get_settings().serpapi_api_key
    if not key:
        return []

    seen_hosts: set[str] = set()
    urls: list[str] = []

    try:
        for query in _build_queries(city, country, vibe):
            for item in _run_query(query, key):
                url = item.get("link") or ""
                if not url or not _allowed(url):
                    continue
                host = _host(url)
                if host in seen_hosts:
                    continue
                seen_hosts.add(host)
                urls.append(url)
                if len(urls) >= max_results:
                    return urls
    except _RateLimited:
        pass  # stop early — return whatever we collected before the limit

    return urls
