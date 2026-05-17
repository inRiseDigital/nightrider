import asyncio
import os

import httpx
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

load_dotenv()

_firebase_initialized = False

def _init_firebase():
    global _firebase_initialized
    if not _firebase_initialized and not firebase_admin._apps:
        cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "firebase_service_account.json")
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True

def _map_genre(classifications: list) -> str:
    if not classifications:
        return "Music"
    c = classifications[0]
    genre = c.get("genre", {}).get("name", "")
    subgenre = c.get("subGenre", {}).get("name", "")
    segment = c.get("segment", {}).get("name", "Music")
    return subgenre or genre or segment

def _normalize_event(raw: dict) -> dict:
    venue_info = {}
    embedded = raw.get("_embedded", {})
    venues = embedded.get("venues", [])
    if venues:
        v = venues[0]
        venue_info = {
            "venue_name": v.get("name", ""),
            "city": v.get("city", {}).get("name", ""),
            "state": v.get("state", {}).get("name", ""),
            "country": v.get("country", {}).get("name", ""),
            "country_code": v.get("country", {}).get("countryCode", ""),
            "address": v.get("address", {}).get("line1", ""),
            "postal_code": v.get("postalCode", ""),
            "lat": float(v.get("location", {}).get("latitude", 0) or 0),
            "lng": float(v.get("location", {}).get("longitude", 0) or 0),
        }

    images = raw.get("images", [])
    cover_image = ""
    for img in images:
        if img.get("ratio") == "16_9" and img.get("width", 0) >= 1024:
            cover_image = img.get("url", "")
            break
    if not cover_image and images:
        cover_image = images[0].get("url", "")

    dates = raw.get("dates", {}).get("start", {})
    date_str = dates.get("localDate", "")
    time_str = dates.get("localTime", "")

    price_ranges = raw.get("priceRanges", [])
    price_hint = ""
    if price_ranges:
        pr = price_ranges[0]
        mn = pr.get("min")
        mx = pr.get("max")
        currency = pr.get("currency", "USD")
        if mn is not None and mx is not None:
            price_hint = f"{currency} {mn:.0f} - {mx:.0f}"
        elif mn is not None:
            price_hint = f"From {currency} {mn:.0f}"

    attractions = embedded.get("attractions", [])
    artist_names = [a.get("name", "") for a in attractions if a.get("name")]

    genre = _map_genre(raw.get("classifications", []))
    country_code = venue_info.get("country_code", "")
    language = _COUNTRY_LANGUAGES.get(country_code, "English")

    return {
        "id": raw.get("id", ""),
        "name": raw.get("name", ""),
        "description": raw.get("info", raw.get("pleaseNote", "")),
        "date": date_str,
        "start_time": f"{date_str}T{time_str}" if time_str else date_str,
        "cover_image": cover_image,
        "genre": genre,
        "language": language,
        "price_hint": price_hint,
        "ticket_url": raw.get("url", ""),
        "artists": artist_names,
        "status": "published",
        "source": "ticketmaster",
        **venue_info,
    }

_COUNTRY_LANGUAGES = {
    "US": "English",  "GB": "English",  "AU": "English",
    "NZ": "English",  "CA": "English",  "SG": "English",
    "IE": "English",  "ZA": "English",
    "DE": "German",   "AT": "German",
    "FR": "French",   "BE": "French",   "ML": "French",
    "ES": "Spanish",  "MX": "Spanish",  "AR": "Spanish",
    "CO": "Spanish",  "CL": "Spanish",
    "BR": "Portuguese", "PT": "Portuguese",
    "IT": "Italian",
    "NL": "Dutch",
    "SE": "Swedish",  "NO": "Norwegian", "DK": "Danish",
    "FI": "Finnish",
    "JP": "Japanese",
    "KR": "Korean",
    "CN": "Mandarin", "TW": "Mandarin",
    "AE": "Arabic",   "SA": "Arabic",   "EG": "Arabic",
    "IN": "Hindi",
    "RU": "Russian",
    "PL": "Polish",   "CZ": "Czech",
    "HU": "Hungarian", "RO": "Romanian",
    "TR": "Turkish",
    "TH": "Thai",     "ID": "Indonesian", "MY": "Malay",
    "LK": "Sinhala",
}

_COUNTRY_CODES = [
    "US", "GB", "DE", "AU", "CA",
    "NL", "FR", "ES", "IT", "JP",
    "BR", "MX", "NZ", "BE", "SE",
    "AE", "SA", "SG", "LK",
]

_EDM_KEYWORDS = ["EDM", "DJ", "rave", "techno", "house music", "electronic"]
_EDM_COUNTRIES = ["US", "GB", "DE", "AU", "NL", "FR", "BE"]

async def fetch_and_sync_events(size: int = 200, pages_per_country: int = 2) -> dict:
    _init_firebase()
    api_key = os.getenv("TICKETMASTER_API_KEY", "")
    sri_lanka_key = os.getenv("SRILANKA_TICKET_CONSUMER_KEY", "")
    if not api_key or api_key == "your_ticketmaster_key_here":
        return {"error": "TICKETMASTER_API_KEY not set", "synced": 0}

    url = "https://app.ticketmaster.com/discovery/v2/events.json"
    db = firestore.client()
    batch = db.batch()
    batch_count = 0
    total_synced = 0
    errors = []

    async with httpx.AsyncClient(timeout=20) as client:
        for country in _COUNTRY_CODES:
            country_key = sri_lanka_key if country == "LK" and sri_lanka_key else api_key
            for page in range(pages_per_country):
                params = {
                    "apikey": country_key,
                    "classificationName": "music",
                    "countryCode": country,
                    "size": size,
                    "page": page,
                    "sort": "date,asc",
                }
                try:
                    resp = await client.get(url, params=params)
                    resp.raise_for_status()
                    data = resp.json()
                except Exception as exc:
                    errors.append(f"{country}[{page}]: {exc}")
                    continue

                raw_events = data.get("_embedded", {}).get("events", [])
                if not raw_events:
                    break

                for raw in raw_events:
                    normalized = _normalize_event(raw)
                    doc_id = normalized["id"]
                    if not doc_id:
                        continue
                    ref = db.collection("events").document(doc_id)
                    batch.set(ref, normalized, merge=True)
                    batch_count += 1
                    total_synced += 1

                    if batch_count >= 400:
                        batch.commit()
                        batch = db.batch()
                        batch_count = 0

                await asyncio.sleep(0.25)

        for keyword in _EDM_KEYWORDS:
            for country in _EDM_COUNTRIES:
                params = {
                    "apikey": api_key,
                    "classificationName": "music",
                    "keyword": keyword,
                    "countryCode": country,
                    "size": size,
                    "page": 0,
                    "sort": "date,asc",
                }
                try:
                    resp = await client.get(url, params=params)
                    resp.raise_for_status()
                    data = resp.json()
                except Exception as exc:
                    errors.append(f"kw={keyword} {country}: {exc}")
                    continue

                raw_events = data.get("_embedded", {}).get("events", [])
                for raw in raw_events:
                    normalized = _normalize_event(raw)
                    doc_id = normalized["id"]
                    if not doc_id:
                        continue
                    ref = db.collection("events").document(doc_id)
                    batch.set(ref, normalized, merge=True)
                    batch_count += 1
                    total_synced += 1
                    if batch_count >= 400:
                        batch.commit()
                        batch = db.batch()
                        batch_count = 0

                await asyncio.sleep(0.25)

    if batch_count > 0:
        batch.commit()

    result = {"synced": total_synced, "message": f"Synced {total_synced} events from {len(_COUNTRY_CODES)} countries + EDM keyword pass"}
    if errors:
        result["errors"] = errors
    return result
