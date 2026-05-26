"""Tests for the web-crawl fallback pipeline.

Covers SerpAPI host filtering, the LLM-output normaliser, and the cache-first
orchestrator path. Network and DB are mocked — no real calls.
"""

from __future__ import annotations

from unittest.mock import patch

import pytest

from party_agent.integrations import crawler, serpapi, web_events


# ---------- SerpAPI discovery ----------

def test_discover_returns_empty_without_api_key():
    with patch("party_agent.integrations.serpapi.get_settings") as gs:
        gs.return_value.serpapi_api_key = None
        assert serpapi.discover_venue_sites("kandy", "LK") == []


def test_discover_filters_blocked_hosts_and_dedupes():
    # Discovery now runs 3 queries; each query returns its own organic_results.
    # The same _Resp() is returned for every httpx.get call, so the helper
    # deduplicates across queries.
    serp_response = {
        "organic_results": [
            {"link": "https://www.facebook.com/events/123"},      # blocked
            {"link": "https://thepub.lk/whats-on"},               # ok
            {"link": "https://thepub.lk/menu"},                   # dupe host
            {"link": "https://www.tripadvisor.com/foo"},          # blocked
            {"link": "https://slightlychilled.com/events"},       # ok
            {"link": "https://m.facebook.com/events/abc"},        # subdomain blocked
            {"link": "https://kandycitynightlife.lk/tonight"},    # ok
            {"link": "https://www.wanderlog.com/list/foo"},       # newly blocked travel guide
        ]
    }

    class _Resp:
        def raise_for_status(self): ...
        def json(self): return serp_response

    with patch("party_agent.integrations.serpapi.get_settings") as gs, \
         patch("party_agent.integrations.serpapi.httpx.get", return_value=_Resp()):
        gs.return_value.serpapi_api_key = "fake"
        urls = serpapi.discover_venue_sites("kandy", "LK", max_results=5)

    assert urls == [
        "https://thepub.lk/whats-on",
        "https://slightlychilled.com/events",
        "https://kandycitynightlife.lk/tonight",
    ]


def test_discover_runs_multiple_queries_per_call():
    """Multi-pass discovery: confirms we hit Google more than once per call."""
    class _Resp:
        def raise_for_status(self): ...
        def json(self): return {"organic_results": []}

    with patch("party_agent.integrations.serpapi.get_settings") as gs, \
         patch("party_agent.integrations.serpapi.httpx.get", return_value=_Resp()) as get:
        gs.return_value.serpapi_api_key = "fake"
        serpapi.discover_venue_sites("kandy", "LK")

    assert get.call_count >= 2, "Expected multi-query discovery to make >1 SerpAPI call"


def test_discover_swallows_network_errors():
    with patch("party_agent.integrations.serpapi.get_settings") as gs, \
         patch("party_agent.integrations.serpapi.httpx.get", side_effect=RuntimeError("boom")):
        gs.return_value.serpapi_api_key = "fake"
        assert serpapi.discover_venue_sites("kandy", "LK") == []


# ---------- LLM-output normalisation ----------

def test_normalise_drops_unnamed_and_fills_defaults():
    raw = [
        {"name": "Friday Bash", "date": "2026-05-15", "vibe": "EDM", "price": "LKR 2000"},
        {"name": "", "date": "2026-05-16"},                 # dropped — no name
        {"name": "Open Mic", "city": "Kandy"},              # default vibe
    ]
    out = crawler._normalise(
        raw,
        source_url="https://thepub.lk/whats-on",
        fallback_city="kandy",
        fallback_country="LK",
    )

    assert len(out) == 2
    bash, mic = out

    assert bash["name"] == "Friday Bash"
    assert bash["city"] == "kandy"
    assert bash["country"] == "LK"
    assert bash["vibe"] == "edm"
    assert bash["price"] == "LKR 2000"
    assert bash["source"] == "web_crawl"
    assert bash["source_url"] == "https://thepub.lk/whats-on"
    assert bash["last_crawled_at"]  # ISO timestamp set

    assert mic["vibe"] == "music"          # defaulted
    assert mic["price"] is None            # missing → None, not ""


def test_normalise_carries_recurrence_into_vibe():
    """Recurring entries should still upsert; the recurrence note rides on vibe."""
    raw = [
        {"name": "Slightly Chilled", "vibe": "live music", "recurrence": "Fridays"},
        {"name": "Empire Pub", "recurrence": "regular nights"},
    ]
    out = crawler._normalise(
        raw,
        source_url="https://srilankatraveldeals.com/nightlife-in-kandy/",
        fallback_city="kandy",
        fallback_country="LK",
    )

    assert len(out) == 2
    assert out[0]["vibe"] == "live music (Fridays)"
    assert out[1]["vibe"] == "music (regular nights)"
    # Recurring rows have no specific date — still queryable by city.
    assert out[0]["date"] is None and out[1]["date"] is None


# ---------- Orchestrator: cache-first ----------

def test_fetch_or_crawl_skips_crawl_when_cache_fresh():
    cached = [{"name": "Cached Party", "city": "kandy"}]
    with patch("party_agent.integrations.web_events.events_db.is_city_fresh", return_value=True), \
         patch("party_agent.integrations.web_events.refresh_city") as refresh, \
         patch("party_agent.integrations.web_events.events_db.fallback_by_city", return_value=cached):
        out = web_events.fetch_or_crawl("kandy", "LK")

    refresh.assert_not_called()
    assert out == cached


def test_fetch_or_crawl_triggers_crawl_when_stale():
    with patch("party_agent.integrations.web_events.events_db.is_city_fresh", return_value=False), \
         patch("party_agent.integrations.web_events.refresh_city", return_value=3) as refresh, \
         patch("party_agent.integrations.web_events.events_db.fallback_by_city", return_value=[]):
        web_events.fetch_or_crawl("kandy", "LK", vibe="edm")

    refresh.assert_called_once_with("kandy", country="LK", vibe="edm")


def test_fetch_or_crawl_returns_cache_even_if_crawl_fails():
    cached = [{"name": "Old Party", "city": "kandy"}]
    with patch("party_agent.integrations.web_events.events_db.is_city_fresh", return_value=False), \
         patch("party_agent.integrations.web_events.refresh_city", side_effect=RuntimeError("crawl down")), \
         patch("party_agent.integrations.web_events.events_db.fallback_by_city", return_value=cached):
        out = web_events.fetch_or_crawl("kandy", "LK")

    assert out == cached


def test_refresh_city_noop_without_serpapi_key():
    with patch("party_agent.integrations.web_events.get_settings") as gs, \
         patch("party_agent.integrations.web_events.crawler.crawl_urls") as crawl:
        gs.return_value.serpapi_api_key = None
        gs.return_value.crawl_max_sites_per_city = 8
        assert web_events.refresh_city("kandy", "LK") == 0
    crawl.assert_not_called()


# ---------- events tool: web fallback shaping ----------

def test_from_web_crawl_filters_by_vibe_and_reshapes():
    from party_agent.tools import events as events_tool

    rows = [
        {"name": "EDM Night", "city": "kandy", "country": "LK", "vibe": "edm",
         "price": "LKR 2000", "event_date": None},
        {"name": "Acoustic Set", "city": "kandy", "country": "LK", "vibe": "acoustic",
         "price": None, "event_date": None},
    ]
    with patch("party_agent.tools.events.web_events.fetch_or_crawl", return_value=rows):
        out = events_tool._from_web_crawl(city="kandy", country="LK", vibe="edm")

    assert len(out) == 1
    assert out[0]["name"] == "EDM Night"
    assert out[0]["price"] == "LKR 2000"
    assert out[0]["source"] == "web_crawl"


def test_from_web_crawl_returns_empty_on_failure():
    from party_agent.tools import events as events_tool
    with patch("party_agent.tools.events.web_events.fetch_or_crawl", side_effect=RuntimeError("db down")):
        assert events_tool._from_web_crawl(city="kandy", country="LK", vibe=None) == []


# ---------- search_events end-to-end with mocked sources ----------

def test_search_events_falls_back_to_web_when_apis_empty():
    from party_agent.tools import events as events_tool

    web_rows = [{
        "name": "Slightly Chilled — DJ Night",
        "city": "kandy", "country": "LK", "vibe": "edm",
        "price": "LKR 1500", "event_date": None,
    }]
    with patch("party_agent.tools.events._no_key_msg", return_value=None), \
         patch("party_agent.tools.events.ticketmaster.search_by_city", return_value=[]), \
         patch("party_agent.tools.events.predicthq.search_by_city", return_value=[]), \
         patch("party_agent.tools.events.web_events.fetch_or_crawl", return_value=web_rows):
        result = events_tool.search_events.invoke({"city": "Kandy", "vibe": "edm", "country": "LK"})

    assert "Slightly Chilled" in result
    assert "kandy" in result.lower()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
