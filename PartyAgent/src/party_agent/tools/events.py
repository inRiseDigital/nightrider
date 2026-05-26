"""Events tool — worldwide party search.

Sources, in fallback order:
  Ticketmaster  → US, UK, EU, Australia (only where they operate)
  Predicthq     → 200+ countries — Japan, Sri Lanka, India, Africa, Middle East,
                  SE Asia, Latin America, everywhere Ticketmaster doesn't reach
  Web crawl     → off-platform last resort (Sri Lankan venues, small-city promoters,
                  anywhere events live on Facebook/Instagram/standalone sites and
                  never make it into Ticketmaster/PHQ databases). SerpAPI discovers
                  the venue sites; Crawl4AI + Claude extract events. Cached for
                  CRAWL_FRESHNESS_HOURS so we don't re-crawl on every query.

Worldwide auto-discovery is brittle by nature — some sites will block, some
selectors will return junk. The crawl runs in cache-first mode so a bad crawl
never blocks the user; the cache simply doesn't refresh that turn.
"""

from __future__ import annotations

import logging

from langchain_core.tools import tool

from party_agent.config import get_settings
from party_agent.integrations import predicthq, ticketmaster, web_events

log = logging.getLogger(__name__)


def _merge(tm: list[dict], phq: list[dict], limit: int = 8) -> list[dict]:
    seen: set[str] = set()
    merged: list[dict] = []
    for event in tm + phq:
        key = event["name"].lower().strip()
        if key not in seen:
            seen.add(key)
            merged.append(event)
        if len(merged) >= limit:
            break
    return merged


def _fmt(events: list[dict]) -> str:
    parts = []
    for e in events:
        date = e["date"][:10] if e.get("date") else "date TBC"
        location = ", ".join(filter(None, [e.get("city"), e.get("country")]))
        parts.append(
            f"{e['name']} | {location} | {e.get('vibe','music')} | {e.get('price','?')} | {date}"
        )
    return "\n".join(parts)


def _no_key_msg() -> str | None:
    s = get_settings()
    if not s.ticketmaster_api_key and not s.predicthq_token and not s.serpapi_api_key:
        return (
            "No event sources configured. Add at least one to .env:\n"
            "  TICKETMASTER_API_KEY — free at https://developer.ticketmaster.com/\n"
            "  PREDICTHQ_TOKEN     — free at https://predicthq.com/signup\n"
            "  SERPAPI_API_KEY     — 100 free searches/mo at https://serpapi.com/\n"
            "                        (enables off-platform crawl fallback for"
            " Sri Lanka, small cities, etc.)"
        )
    return None


def _vibe_match(event: dict, vibe: str | None) -> bool:
    if not vibe:
        return True
    needle = vibe.lower().strip()
    haystack = " ".join(str(event.get(k, "")) for k in ("vibe", "name", "description")).lower()
    return needle in haystack


def _from_web_crawl(city: str, country: str | None, vibe: str | None) -> list[dict]:
    """Cache-first read with live-crawl fallback. Empty list on any failure.

    Re-shapes events_db rows into the same dict shape ticketmaster/predicthq
    return so _merge() and _fmt() stay agnostic to the source.
    """
    try:
        rows = web_events.fetch_or_crawl(city=city, country=country, vibe=vibe)
    except Exception as exc:
        log.warning("Web fallback failed for %s: %s", city, exc)
        return []

    out: list[dict] = []
    for r in rows:
        e = {
            "name":    r.get("name", ""),
            "city":    r.get("city", "") or city,
            "country": r.get("country") or (country or ""),
            "vibe":    r.get("vibe", "music"),
            "price":   r.get("price") or "see venue",
            "date":    (r.get("event_date").isoformat() if r.get("event_date") else ""),
            "source":  "web_crawl",
        }
        if _vibe_match(e, vibe):
            out.append(e)
    return out


@tool
def search_events(city: str, vibe: str, country: str = "") -> str:
    """Search nightlife and party events in any city in any country worldwide.

    Args:
        city: Any city on earth — e.g. "Tokyo", "Colombo", "Lagos", "Mumbai",
              "Berlin", "São Paulo", "Cairo", "Bangkok", "Nairobi", "Seoul".
        vibe: Party vibe — e.g. edm, hip-hop, afrobeats, bollywood, latin, jazz,
              rock, pop, reggae, kpop, underground, vip, lgbtq, free, rooftop,
              beach, carnival, salsa, bhangra, arabic, persian, j-pop, anime.
        country: Optional 2-letter ISO code to sharpen results, e.g. "JP" for Japan,
                 "LK" for Sri Lanka, "NG" for Nigeria, "AE" for UAE.
    """
    msg = _no_key_msg()
    if msg:
        return msg
    try:
        cc = country.strip() or None
        tm = ticketmaster.search_by_city(city=city, vibe=vibe, country_code=cc, size=3)
        phq = predicthq.search_by_city(city=city, vibe=vibe, country_code=cc, size=5)
        results = _merge(tm, phq)
        if results:
            return _fmt(results)

        # Off-platform fallback — Kandy, Colombo, small cities where TM+PHQ
        # have nothing. Cache-first; only crawls if the city is stale.
        web = _from_web_crawl(city=city, country=cc, vibe=vibe)
        if web:
            return _fmt(web)

        return (
            f"No '{vibe}' events found in {city} right now. "
            "Try a broader vibe like 'music' or 'party', or check back closer to the weekend."
        )
    except Exception as exc:
        return f"Event search error: {exc}"


@tool
def trending_events(city: str, country: str = "") -> str:
    """Return the hottest party or event happening right now in any city worldwide.

    Args:
        city: Any city on earth — e.g. "Osaka", "Colombo", "Accra", "Jakarta".
        country: Optional 2-letter ISO code, e.g. "JP", "LK", "GH", "ID".
    """
    msg = _no_key_msg()
    if msg:
        return msg
    try:
        cc = country.strip() or None
        tm = ticketmaster.search_by_city(city=city, vibe=None, country_code=cc, size=1)
        phq = predicthq.search_by_city(city=city, vibe=None, country_code=cc, size=1)
        top = (tm or phq or _from_web_crawl(city=city, country=cc, vibe=None) or [None])[0]
        if not top:
            return f"No trending event found for {city} right now."
        date = top["date"][:10] if top.get("date") else "date TBC"
        location = ", ".join(filter(None, [top.get("city"), top.get("country")]))
        return f"{top['name']} | {location} | {top.get('vibe','music')} | {top.get('price','?')} | {date}"
    except Exception as exc:
        return f"Trending lookup error: {exc}"


@tool
def nearby_events(lat: float, lng: float, max_km: float = 2.0, vibe: str = "") -> str:
    """Find parties near any GPS coordinates anywhere on earth.

    Args:
        lat: Latitude — e.g. 35.6762 for Tokyo, 6.9271 for Colombo, 6.5244 for Lagos.
        lng: Longitude — e.g. 139.6503 for Tokyo, 79.8612 for Colombo, 3.3792 for Lagos.
        max_km: Search radius in km (default 2.0 — increase to 20-50 for smaller cities).
        vibe: Optional filter — e.g. edm, afrobeats, hip-hop, latin. Blank = all types.
    """
    msg = _no_key_msg()
    if msg:
        return msg
    try:
        v = vibe.strip() or None
        tm = ticketmaster.search_nearby(lat=lat, lng=lng, max_km=max_km, vibe=v, size=4)
        phq = predicthq.search_nearby(lat=lat, lng=lng, max_km=max_km, vibe=v, size=6)
        results = _merge(tm, phq)
        if not results:
            return (
                f"No events within {max_km} km of your location. "
                "Try increasing max_km to 20 or 50."
            )
        return _fmt(results)
    except Exception as exc:
        return f"Nearby search error: {exc}"
