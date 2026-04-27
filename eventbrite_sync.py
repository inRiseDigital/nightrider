"""
Eventbrite event sync → Firestore.
Targets: Sri Lanka, Japan, UK, France, Germany, India, Singapore, UAE, Australia, and more.

Usage:
    python eventbrite_sync.py

Requires EVENTBRITE_API_KEY in environment (see README below).
"""

import asyncio
import os
import sys

sys.path.insert(0, r'C:\Users\USER\Downloads\PartyApp\PartyApp\PartyAgent\backend')
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = r'C:\Users\USER\Downloads\PartyApp\PartyApp\PartyAgent\backend\firebase_service_account.json'

import httpx
import firebase_admin
from firebase_admin import credentials, firestore

# ── Config ────────────────────────────────────────────────────────────────────
# Paste your Eventbrite private token here OR set EVENTBRITE_API_KEY env var
EVENTBRITE_API_KEY = os.getenv("EVENTBRITE_API_KEY", "YOUR_TOKEN_HERE")

_SEARCH_TARGETS = [
    # (location string,  country_code, language)
    ("Sri Lanka",        "LK", "English"),
    ("Colombo",          "LK", "English"),
    ("Tokyo, Japan",     "JP", "Japanese"),
    ("Osaka, Japan",     "JP", "Japanese"),
    ("London, UK",       "GB", "English"),
    ("Manchester, UK",   "GB", "English"),
    ("Paris, France",    "FR", "French"),
    ("Lyon, France",     "FR", "French"),
    ("Berlin, Germany",  "DE", "German"),
    ("Mumbai, India",    "IN", "Hindi"),
    ("Bangalore, India", "IN", "Hindi"),
    ("Singapore",        "SG", "English"),
    ("Dubai, UAE",       "AE", "Arabic"),
    ("Sydney, Australia","AU", "English"),
    ("Amsterdam",        "NL", "Dutch"),
    ("Barcelona, Spain", "ES", "Spanish"),
]

_MUSIC_CATEGORY_ID = "103"   # Eventbrite category for Music
_PAGES_PER_LOCATION = 3       # 50 events per page → up to 150 per location

_firebase_initialized = False

def _init_firebase():
    global _firebase_initialized
    if not _firebase_initialized and not firebase_admin._apps:
        cred = credentials.Certificate(
            r'C:\Users\USER\Downloads\PartyApp\PartyApp\PartyAgent\backend\firebase_service_account.json'
        )
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True


def _parse_event(raw: dict, country_code: str, language: str) -> dict | None:
    """Convert Eventbrite event dict to our Firestore schema."""
    try:
        name = raw.get("name", {}).get("text", "").strip()
        if not name:
            return None

        start = raw.get("start", {}).get("local", "")
        date_str = start[:10] if start else ""

        # Cover image
        logo = raw.get("logo") or {}
        cover_image = (
            logo.get("original", {}).get("url")
            or logo.get("url")
            or ""
        )

        # Venue (expanded inline)
        venue = raw.get("venue") or {}
        address = venue.get("address") or {}
        venue_name = venue.get("name", "")
        city       = address.get("city", "")
        country    = address.get("country", "")
        lat = float(venue.get("latitude") or 0)
        lng = float(venue.get("longitude") or 0)

        # Genre from category / subcategory / format
        subcategory = (raw.get("subcategory") or {}).get("name", "")
        category    = (raw.get("category") or {}).get("name", "")
        fmt         = (raw.get("format") or {}).get("name", "")
        genre = subcategory or category or fmt or "Music"

        # Price
        is_free = raw.get("is_free", False)
        currency = raw.get("currency", "")
        price_hint = "Free" if is_free else (f"{currency} Tickets" if currency else "Tickets")

        return {
            "name":         name,
            "date":         date_str,
            "start_time":   start,
            "cover_image":  cover_image,
            "genre":        genre,
            "language":     language,
            "country_code": country_code,
            "country":      country or country_code,
            "city":         city,
            "venue_name":   venue_name,
            "lat":          lat,
            "lng":          lng,
            "price_hint":   price_hint,
            "ticket_url":   raw.get("url", ""),
            "description":  (raw.get("description") or {}).get("text", ""),
            "status":       "published",
            "source":       "eventbrite",
        }
    except Exception as e:
        print(f"  [parse error] {e}")
        return None


async def fetch_and_sync(client: httpx.AsyncClient, db, location: str, country_code: str, language: str) -> int:
    synced = 0
    base_url = "https://www.eventbriteapi.com/v3/events/search/"

    for page in range(1, _PAGES_PER_LOCATION + 1):
        params = {
            "token":            EVENTBRITE_API_KEY,
            "location.address": location,
            "location.within":  "100km",
            "categories":       _MUSIC_CATEGORY_ID,
            "expand":           "venue,category,subcategory,format",
            "page_size":        50,
            "page":             page,
            "sort_by":          "date",
        }
        try:
            resp = await client.get(base_url, params=params)
            if resp.status_code == 401:
                print("  ERROR: Invalid Eventbrite token. Check EVENTBRITE_API_KEY.")
                return synced
            if resp.status_code != 200:
                print(f"  [{location} p{page}] HTTP {resp.status_code}")
                break

            data = resp.json()
            events = data.get("events", [])
            if not events:
                break

            batch = db.batch()
            batch_count = 0
            for raw in events:
                parsed = _parse_event(raw, country_code, language)
                if not parsed:
                    continue
                doc_id = f"eb_{raw['id']}"
                ref = db.collection("events").document(doc_id)
                batch.set(ref, parsed, merge=True)
                batch_count += 1

            if batch_count:
                batch.commit()
                synced += batch_count
                print(f"  [{location} p{page}] +{batch_count} events")

            pagination = data.get("pagination", {})
            if page >= pagination.get("page_count", 1):
                break

        except Exception as e:
            print(f"  [{location} p{page}] error: {e}")
            break

    return synced


async def main():
    if EVENTBRITE_API_KEY == "YOUR_TOKEN_HERE":
        print("ERROR: Set your Eventbrite token in EVENTBRITE_API_KEY env var or edit this file.")
        return

    _init_firebase()
    db = firestore.client()
    total = 0

    print(f"Starting Eventbrite sync for {len(_SEARCH_TARGETS)} locations...\n")

    async with httpx.AsyncClient(timeout=20) as client:
        for location, cc, lang in _SEARCH_TARGETS:
            print(f"Fetching: {location} ({cc})")
            n = await fetch_and_sync(client, db, location, cc, lang)
            total += n

    print(f"\nDone. Total synced: {total} events.")


asyncio.run(main())
