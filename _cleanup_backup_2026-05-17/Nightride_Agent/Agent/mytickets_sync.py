"""Sync upcoming events from mytickets.lk into Firestore.

The mytickets.lk public API:
    GET https://api.mytickets.lk/event-svc/v1/events
        ?page=N&limit=50
        &sort[repeatable.start_time]=1
        &filter[repeatable.end_time]=gte(YYYY-MM-DD)
        &include=repeatable.location,repeatable.deals

Returns paginated MongoDB-style documents. We normalize each event to the
same shape as `ticketmaster_sync._normalize_event` so the Flutter app and
agent treat them identically.
"""

from __future__ import annotations

import asyncio
import os
from datetime import datetime, timezone
from typing import Any, Optional

import httpx
import firebase_admin
from firebase_admin import credentials, firestore

_API_BASE = "https://api.mytickets.lk/event-svc/v1/events"
_SOURCE = "mytickets.lk"

# Map mytickets subcategory/category → genre strings the Flutter app recognises.
# matchesGenre() in home_providers.dart checks: DJ, EDM, TECHNO, RAVE, HOUSE, CLUB, LIVE.
_SUBCATEGORY_GENRE: dict[str, str] = {
    "dj":           "DJ",
    "edm":          "EDM",
    "techno":       "Techno",
    "house":        "House",
    "rave":         "Rave",
    "club":         "Club",
    "live music":   "Live",
    "live":         "Live",
    "concert":      "Live",
    "theatre":      "Live",
    "theater":      "Live",
    "comedy":       "Live",
    "drama":        "Live",
    "musical":      "Live",
    "dance":        "EDM",
    "electronic":   "EDM",
    "hip hop":      "Hip-Hop",
    "hip-hop":      "Hip-Hop",
    "rap":          "Hip-Hop",
    "r&b":          "R&B",
    "soul":         "R&B",
    "pop":          "Club",
    "rock":         "Live",
    "jazz":         "Live",
    "reggae":       "Live",
    "adventure":    "Live",
    "leisure":      "Live",
    "sports":       "Live",
    "festival":     "Live",
    "party":        "Club",
}

_firebase_initialized = False


def _init_firebase() -> None:
    global _firebase_initialized
    if not _firebase_initialized and not firebase_admin._apps:
        cred_path = os.getenv(
            "GOOGLE_APPLICATION_CREDENTIALS", "firebase_service_account.json"
        )
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True


def _today_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def _first_photo(photo_urls: Any) -> str:
    if isinstance(photo_urls, dict):
        return photo_urls.get("default") or next(iter(photo_urls.values()), "")
    if isinstance(photo_urls, list) and photo_urls:
        return photo_urls[0]
    return ""


def _price_hint(deals: list[dict]) -> str:
    if not deals:
        return ""
    prices = [d.get("price") for d in deals if isinstance(d.get("price"), (int, float))]
    if not prices:
        return ""
    currency = deals[0].get("currency", "LKR")
    lo, hi = min(prices), max(prices)
    return f"{currency} {lo:.0f}" if lo == hi else f"{currency} {lo:.0f} - {hi:.0f}"


def _artist_names(artists: Any) -> list[str]:
    if not isinstance(artists, list):
        return []
    out: list[str] = []
    for a in artists:
        if isinstance(a, dict):
            n = a.get("name") or a.get("display_name")
            if n:
                out.append(n)
        elif isinstance(a, str):
            out.append(a)
    return out


def _normalize_event(raw: dict) -> Optional[dict]:
    rep = raw.get("repeatable") or {}
    start = rep.get("start_time", "")
    end = rep.get("end_time", "")
    if not start:
        return None

    date_str = start[:10] if len(start) >= 10 else start
    location = rep.get("location") or {}
    address = ", ".join(
        filter(None, [location.get("address_line_1"), location.get("address_line_2")])
    )

    alias = rep.get("alias") or raw.get("_id", "")
    ticket_url = f"https://mytickets.lk/event/{alias}" if alias else ""

    category = raw.get("category") or ""
    subcategory = raw.get("subcategory") or ""
    # Map to genre the Flutter matchesGenre() function understands
    genre_key = subcategory.lower().strip() or category.lower().strip()
    genre = _SUBCATEGORY_GENRE.get(genre_key) or subcategory or category or "Music"

    # Use address_line_1 as city when MongoDB ObjectID is stored in city field
    raw_city = location.get("city") or ""
    city = "" if len(raw_city) == 24 and raw_city.isalnum() else raw_city
    city = city or location.get("address_line_1") or ""

    return {
        "id": f"mt_{raw['_id']}",
        "name": raw.get("name", "").strip(),
        "description": raw.get("description") or raw.get("tagline", ""),
        "date": date_str,
        "start_time": start,
        "end_time": end,
        "cover_image": _first_photo(raw.get("photo_urls")),
        "genre": genre,
        "category": category,
        "subcategory": subcategory,
        "language": raw.get("language") or "Sinhala",
        "price_hint": _price_hint(rep.get("deals") or []),
        "ticket_url": ticket_url,
        "artists": _artist_names(rep.get("artists")),
        "status": "published",
        "source": _SOURCE,
        "venue_name": location.get("name", "").strip(),
        "city": city,
        "state": "",
        "country": "Sri Lanka",
        "country_code": "LK",
        "address": address,
        "postal_code": "",
        "lat": 0.0,
        "lng": 0.0,
    }


async def _fetch_page(client: httpx.AsyncClient, page: int, limit: int) -> dict:
    params = {
        "page": page,
        "limit": limit,
        "sort[repeatable.start_time]": 1,
        "filter[repeatable.end_time]": f"gte({_today_iso()})",
        "include": "repeatable.location,repeatable.deals",
    }
    resp = await client.get(_API_BASE, params=params)
    resp.raise_for_status()
    return resp.json()


async def fetch_and_sync_events(limit_per_page: int = 50) -> dict:
    """Pull all upcoming events from mytickets.lk and upsert into Firestore.

    Returns a summary dict with `synced`, `total`, and any `errors`.
    """
    _init_firebase()
    db = firestore.client()
    batch = db.batch()
    batch_count = 0
    total_synced = 0
    errors: list[str] = []

    async with httpx.AsyncClient(
        timeout=20,
        headers={"User-Agent": "Nightride/1.0 (sync)"},
    ) as client:
        try:
            first = await _fetch_page(client, 1, limit_per_page)
        except Exception as exc:
            return {"error": f"first page failed: {exc}", "synced": 0}

        meta = first.get("data", {})
        total_pages = int(meta.get("totalPages", 1))
        total_docs = int(meta.get("totalDocs", 0))

        async def process(payload: dict) -> int:
            nonlocal batch, batch_count, total_synced
            count = 0
            docs = payload.get("data", {}).get("docs", []) or []
            for raw in docs:
                norm = _normalize_event(raw)
                if not norm:
                    continue
                ref = db.collection("events").document(norm["id"])
                batch.set(ref, norm, merge=True)
                batch_count += 1
                total_synced += 1
                count += 1
                if batch_count >= 400:
                    batch.commit()
                    batch = db.batch()
                    batch_count = 0
            return count

        await process(first)

        for page in range(2, total_pages + 1):
            try:
                payload = await _fetch_page(client, page, limit_per_page)
                await process(payload)
                await asyncio.sleep(0.2)
            except Exception as exc:
                errors.append(f"page {page}: {exc}")

    if batch_count > 0:
        batch.commit()

    # Refresh the agent's in-memory cache so it sees the new events immediately
    try:
        from data_source import refresh_party_data
        refresh_party_data()
    except Exception as exc:
        pass  # non-fatal — cache will refresh on next agent call

    result: dict = {
        "synced": total_synced,
        "total": total_docs,
        "source": _SOURCE,
        "message": f"Synced {total_synced}/{total_docs} Sri Lanka events from mytickets.lk",
    }
    if errors:
        result["errors"] = errors
    return result


if __name__ == "__main__":
    summary = asyncio.run(fetch_and_sync_events())
    print(summary)
