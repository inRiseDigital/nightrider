"""
PredictHQ event sync → Firestore.
Free tier: 1,000 requests/month, covers global events including Sri Lanka.

Usage:
    set PREDICTHQ_TOKEN=your_token_here
    python predicthq_sync.py
"""

import asyncio
import os
import sys

sys.path.insert(0, r'C:\Users\USER\Downloads\PartyApp\PartyApp\PartyAgent\backend')
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = r'C:\Users\USER\Downloads\PartyApp\PartyApp\PartyAgent\backend\firebase_service_account.json'

import httpx
import firebase_admin
from firebase_admin import credentials, firestore

PREDICTHQ_TOKEN = os.getenv("PREDICTHQ_TOKEN", "vWp8VyUG2rMJptFT0LmLSmhm7LT3M1ILgM5b-mbn")

_TARGETS = [
    ("JP", None,             "Japanese"),   # Japan — refresh upcoming events
    ("LK", None,             "English"),    # Sri Lanka — refresh upcoming events
    ("GB", "London",         "English"),
    ("GB", "Manchester",     "English"),
    ("FR", "Paris",          "French"),
    ("DE", "Berlin",         "German"),
    ("SG", "Singapore",      "English"),
    ("AE", "Dubai",          "Arabic"),
    ("AU", "Sydney",         "English"),
    ("NL", "Amsterdam",      "Dutch"),
    ("ES", "Barcelona",      "Spanish"),
    ("IN", "Mumbai",         "Hindi"),
    ("US", "New York",       "English"),
    ("BR", "São Paulo",      "Portuguese"),
]

_CATEGORIES = "concerts,festivals,performing-arts"
_NIGHTLIFE_LABELS = "electronic,edm,techno,house,rave,dj,nightclub,dance,dubstep,trance,drum-and-bass,hip-hop,music"
_LIMIT = 100  # max per request on free tier

_firebase_initialized = False

def _init_firebase():
    global _firebase_initialized
    if not _firebase_initialized and not firebase_admin._apps:
        cred = credentials.Certificate(
            r'C:\Users\USER\Downloads\PartyApp\PartyApp\PartyAgent\backend\firebase_service_account.json'
        )
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True


def _parse(raw: dict, country_code: str, language: str) -> dict | None:
    try:
        name = raw.get("title", "").strip()
        if not name:
            return None

        start = raw.get("start", "")
        date_str = start[:10] if start else ""

        entities  = raw.get("entities", [])
        venue_ent = next((e for e in entities if e.get("type") == "venue"), {})
        venue_name = venue_ent.get("name", "")

        geo       = raw.get("geo", {}) or {}
        geometry  = geo.get("geometry", {}) or {}
        coords    = geometry.get("coordinates", [0, 0])
        lng, lat  = (coords[0], coords[1]) if len(coords) >= 2 else (0, 0)

        location  = raw.get("location", [0, 0])
        if not lat and len(location) >= 2:
            lng, lat = location[0], location[1]

        labels    = raw.get("labels", [])
        genre     = labels[0].replace("-", " ").title() if labels else raw.get("category", "Music").title()

        addresses = raw.get("entities", [])
        addr_ent  = next((e for e in addresses if e.get("type") == "address"), {})
        city      = addr_ent.get("formatted_address", "").split(",")[0].strip()
        if not city:
            city = raw.get("place_hierarchies", [[]])[0][-1] if raw.get("place_hierarchies") else ""

        return {
            "name":         name,
            "date":         date_str,
            "start_time":   start,
            "cover_image":  "",
            "genre":        genre,
            "language":     language,
            "country_code": country_code,
            "country":      raw.get("country", country_code),
            "city":         city,
            "venue_name":   venue_name,
            "lat":          float(lat),
            "lng":          float(lng),
            "price_hint":   "Tickets",
            "ticket_url":   "",
            "description":  raw.get("description", ""),
            "status":       "published",
            "source":       "predicthq",
        }
    except Exception as e:
        print(f"  [parse error] {e}")
        return None


async def fetch_country(client: httpx.AsyncClient, db, country_code: str, city: str | None, language: str, start_gte: str = "") -> int:
    synced = 0
    url    = "https://api.predicthq.com/v1/events/"
    offset = 0

    while True:
        params: dict = {
            "country":    country_code,
            "category":   _CATEGORIES,
            "limit":      _LIMIT,
            "offset":     offset,
            "sort":       "start",
            "state":      "active",
        }
        if city:
            params["place.name"] = city
        if start_gte:
            params["start.gte"] = start_gte

        try:
            resp = await client.get(
                url,
                params=params,
                headers={"Authorization": f"Bearer {PREDICTHQ_TOKEN}",
                         "Accept": "application/json"},
            )
            if resp.status_code == 401:
                print("  ERROR: Invalid PredictHQ token.")
                return synced
            if resp.status_code == 429:
                print("  Rate limit hit — stopping.")
                return synced
            if resp.status_code != 200:
                print(f"  [{country_code}] HTTP {resp.status_code}: {resp.text[:120]}")
                break

            data   = resp.json()
            events = data.get("results", [])
            if not events:
                break

            batch       = db.batch()
            batch_count = 0
            for raw in events:
                parsed = _parse(raw, country_code, language)
                if not parsed:
                    continue
                doc_id = f"phq_{raw['id']}"
                ref    = db.collection("events").document(doc_id)
                batch.set(ref, parsed, merge=True)
                batch_count += 1

            if batch_count:
                batch.commit()
                synced     += batch_count
                label       = f"{city or country_code}"
                print(f"  [{label} offset={offset}] +{batch_count}")

            await asyncio.sleep(2)  # avoid rate limit
            offset += _LIMIT
            total   = data.get("count", 0)
            if offset >= min(total, 500):   # cap at 500 per target
                break

        except Exception as e:
            print(f"  [{country_code}] error: {e}")
            break

    return synced


async def main():
    if PREDICTHQ_TOKEN == "YOUR_TOKEN_HERE":
        print("ERROR: Set PREDICTHQ_TOKEN env var first.")
        return

    from datetime import date
    today = date.today().isoformat()

    _init_firebase()
    db    = firestore.client()
    total = 0

    print(f"Starting PredictHQ sync for {len(_TARGETS)} targets (from {today} onwards)...\n")
    async with httpx.AsyncClient(timeout=20) as client:
        for cc, city, lang in _TARGETS:
            label = f"{city or cc} ({cc})"
            print(f"Fetching: {label}")
            n      = await fetch_country(client, db, cc, city, lang, start_gte=today)
            total += n

    print(f"\nDone. Total synced: {total} events.")


asyncio.run(main())
