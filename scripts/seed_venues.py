#!/usr/bin/env python3
"""
seed_venues.py
Fetches clubs, bars, and pubs from OpenStreetMap (free, no key needed)
for 100+ nightlife cities worldwide and uploads them to Firestore 'venues'.

Requirements:
    pip install firebase-admin requests

Usage:
    python seed_venues.py --credentials /path/to/serviceAccountKey.json

Options:
    --credentials   Path to Firebase service account JSON key (required)
    --radius        Search radius in metres per city  (default: 5000)
    --delay         Seconds between Overpass calls    (default: 2)
    --dry-run       Print counts only, do not upload
    --output        Also save all venues to a local JSON file
    --cities        Comma-separated city names to process (default: all)
"""

import argparse
import json
import sys
import time
from typing import Optional
import requests

# ── City list ─────────────────────────────────────────────────────────────────
# 100 top global nightlife cities with generous per-city radii.
NIGHTLIFE_CITIES = [
    # ── Europe ────────────────────────────────────────────────────────────────
    {"name": "Berlin",         "country": "Germany",        "cc": "DE", "lat":  52.5200, "lng":  13.4050, "r": 10000},
    {"name": "Amsterdam",      "country": "Netherlands",    "cc": "NL", "lat":  52.3700, "lng":   4.8950, "r":  6000},
    {"name": "Barcelona",      "country": "Spain",          "cc": "ES", "lat":  41.3850, "lng":   2.1730, "r":  7000},
    {"name": "Ibiza",          "country": "Spain",          "cc": "ES", "lat":  38.9086, "lng":   1.4330, "r":  8000},
    {"name": "London",         "country": "United Kingdom", "cc": "GB", "lat":  51.5074, "lng":  -0.1278, "r": 15000},
    {"name": "Paris",          "country": "France",         "cc": "FR", "lat":  48.8566, "lng":   2.3522, "r": 10000},
    {"name": "Madrid",         "country": "Spain",          "cc": "ES", "lat":  40.4168, "lng":  -3.7038, "r":  8000},
    {"name": "Prague",         "country": "Czech Republic", "cc": "CZ", "lat":  50.0755, "lng":  14.4378, "r":  6000},
    {"name": "Budapest",       "country": "Hungary",        "cc": "HU", "lat":  47.4979, "lng":  19.0402, "r":  6000},
    {"name": "Vienna",         "country": "Austria",        "cc": "AT", "lat":  48.2082, "lng":  16.3738, "r":  7000},
    {"name": "Lisbon",         "country": "Portugal",       "cc": "PT", "lat":  38.7169, "lng":  -9.1395, "r":  6000},
    {"name": "Porto",          "country": "Portugal",       "cc": "PT", "lat":  41.1579, "lng":  -8.6291, "r":  5000},
    {"name": "Dublin",         "country": "Ireland",        "cc": "IE", "lat":  53.3498, "lng":  -6.2603, "r":  5000},
    {"name": "Edinburgh",      "country": "United Kingdom", "cc": "GB", "lat":  55.9533, "lng":  -3.1883, "r":  4000},
    {"name": "Manchester",     "country": "United Kingdom", "cc": "GB", "lat":  53.4808, "lng":  -2.2426, "r":  5000},
    {"name": "Stockholm",      "country": "Sweden",         "cc": "SE", "lat":  59.3293, "lng":  18.0686, "r":  6000},
    {"name": "Copenhagen",     "country": "Denmark",        "cc": "DK", "lat":  55.6761, "lng":  12.5683, "r":  5000},
    {"name": "Oslo",           "country": "Norway",         "cc": "NO", "lat":  59.9139, "lng":  10.7522, "r":  5000},
    {"name": "Helsinki",       "country": "Finland",        "cc": "FI", "lat":  60.1699, "lng":  24.9384, "r":  5000},
    {"name": "Warsaw",         "country": "Poland",         "cc": "PL", "lat":  52.2297, "lng":  21.0122, "r":  7000},
    {"name": "Krakow",         "country": "Poland",         "cc": "PL", "lat":  50.0647, "lng":  19.9450, "r":  4000},
    {"name": "Kyiv",           "country": "Ukraine",        "cc": "UA", "lat":  50.4501, "lng":  30.5234, "r":  8000},
    {"name": "Riga",           "country": "Latvia",         "cc": "LV", "lat":  56.9460, "lng":  24.1059, "r":  4000},
    {"name": "Tallinn",        "country": "Estonia",        "cc": "EE", "lat":  59.4370, "lng":  24.7536, "r":  3000},
    {"name": "Hamburg",        "country": "Germany",        "cc": "DE", "lat":  53.5511, "lng":   9.9937, "r":  7000},
    {"name": "Munich",         "country": "Germany",        "cc": "DE", "lat":  48.1351, "lng":  11.5820, "r":  7000},
    {"name": "Frankfurt",      "country": "Germany",        "cc": "DE", "lat":  50.1109, "lng":   8.6821, "r":  6000},
    {"name": "Cologne",        "country": "Germany",        "cc": "DE", "lat":  50.9333, "lng":   6.9500, "r":  5000},
    {"name": "Brussels",       "country": "Belgium",        "cc": "BE", "lat":  50.8503, "lng":   4.3517, "r":  5000},
    {"name": "Rome",           "country": "Italy",          "cc": "IT", "lat":  41.9028, "lng":  12.4964, "r":  8000},
    {"name": "Milan",          "country": "Italy",          "cc": "IT", "lat":  45.4642, "lng":   9.1900, "r":  7000},
    {"name": "Naples",         "country": "Italy",          "cc": "IT", "lat":  40.8518, "lng":  14.2681, "r":  5000},
    {"name": "Athens",         "country": "Greece",         "cc": "GR", "lat":  37.9838, "lng":  23.7275, "r":  7000},
    {"name": "Mykonos",        "country": "Greece",         "cc": "GR", "lat":  37.4444, "lng":  25.3289, "r":  3000},
    {"name": "Split",          "country": "Croatia",        "cc": "HR", "lat":  43.5081, "lng":  16.4402, "r":  4000},
    {"name": "Dubrovnik",      "country": "Croatia",        "cc": "HR", "lat":  42.6507, "lng":  18.0944, "r":  3000},
    {"name": "Valletta",       "country": "Malta",          "cc": "MT", "lat":  35.8997, "lng":  14.5147, "r":  3000},
    {"name": "Ayia Napa",      "country": "Cyprus",         "cc": "CY", "lat":  34.9857, "lng":  33.9971, "r":  4000},
    {"name": "Tbilisi",        "country": "Georgia",        "cc": "GE", "lat":  41.6938, "lng":  44.8015, "r":  5000},
    {"name": "Yerevan",        "country": "Armenia",        "cc": "AM", "lat":  40.1872, "lng":  44.5152, "r":  4000},

    # ── Americas ──────────────────────────────────────────────────────────────
    {"name": "New York",       "country": "United States",  "cc": "US", "lat":  40.7128, "lng": -74.0060, "r": 12000},
    {"name": "Miami",          "country": "United States",  "cc": "US", "lat":  25.7617, "lng": -80.1918, "r":  8000},
    {"name": "Las Vegas",      "country": "United States",  "cc": "US", "lat":  36.1699, "lng":-115.1398, "r":  8000},
    {"name": "Los Angeles",    "country": "United States",  "cc": "US", "lat":  34.0522, "lng":-118.2437, "r": 15000},
    {"name": "Chicago",        "country": "United States",  "cc": "US", "lat":  41.8781, "lng": -87.6298, "r":  8000},
    {"name": "San Francisco",  "country": "United States",  "cc": "US", "lat":  37.7749, "lng":-122.4194, "r":  6000},
    {"name": "New Orleans",    "country": "United States",  "cc": "US", "lat":  29.9511, "lng": -90.0715, "r":  5000},
    {"name": "Nashville",      "country": "United States",  "cc": "US", "lat":  36.1627, "lng": -86.7816, "r":  5000},
    {"name": "Austin",         "country": "United States",  "cc": "US", "lat":  30.2672, "lng": -97.7431, "r":  6000},
    {"name": "Toronto",        "country": "Canada",         "cc": "CA", "lat":  43.6532, "lng": -79.3832, "r":  7000},
    {"name": "Montreal",       "country": "Canada",         "cc": "CA", "lat":  45.5017, "lng": -73.5673, "r":  6000},
    {"name": "Vancouver",      "country": "Canada",         "cc": "CA", "lat":  49.2827, "lng":-123.1207, "r":  5000},
    {"name": "Mexico City",    "country": "Mexico",         "cc": "MX", "lat":  19.4326, "lng": -99.1332, "r": 10000},
    {"name": "Cancun",         "country": "Mexico",         "cc": "MX", "lat":  21.1619, "lng": -86.8515, "r":  6000},
    {"name": "Playa del Carmen","country": "Mexico",        "cc": "MX", "lat":  20.6296, "lng": -87.0739, "r":  4000},
    {"name": "Buenos Aires",   "country": "Argentina",      "cc": "AR", "lat": -34.6037, "lng": -58.3816, "r": 10000},
    {"name": "Sao Paulo",      "country": "Brazil",         "cc": "BR", "lat": -23.5505, "lng": -46.6333, "r": 12000},
    {"name": "Rio de Janeiro", "country": "Brazil",         "cc": "BR", "lat": -22.9068, "lng": -43.1729, "r":  8000},
    {"name": "Medellin",       "country": "Colombia",       "cc": "CO", "lat":   6.2442, "lng": -75.5812, "r":  6000},
    {"name": "Bogota",         "country": "Colombia",       "cc": "CO", "lat":   4.7110, "lng": -74.0721, "r":  8000},
    {"name": "Cartagena",      "country": "Colombia",       "cc": "CO", "lat":  10.3910, "lng": -75.4794, "r":  4000},
    {"name": "Santiago",       "country": "Chile",          "cc": "CL", "lat": -33.4489, "lng": -70.6693, "r":  7000},
    {"name": "Lima",           "country": "Peru",           "cc": "PE", "lat": -12.0464, "lng": -77.0428, "r":  7000},
    {"name": "Havana",         "country": "Cuba",           "cc": "CU", "lat":  23.1136, "lng": -82.3666, "r":  5000},

    # ── Asia ──────────────────────────────────────────────────────────────────
    {"name": "Tokyo",          "country": "Japan",          "cc": "JP", "lat":  35.6762, "lng": 139.6503, "r": 15000},
    {"name": "Osaka",          "country": "Japan",          "cc": "JP", "lat":  34.6937, "lng": 135.5023, "r":  8000},
    {"name": "Seoul",          "country": "South Korea",    "cc": "KR", "lat":  37.5665, "lng": 126.9780, "r": 10000},
    {"name": "Hong Kong",      "country": "Hong Kong",      "cc": "HK", "lat":  22.3193, "lng": 114.1694, "r":  6000},
    {"name": "Singapore",      "country": "Singapore",      "cc": "SG", "lat":   1.3521, "lng": 103.8198, "r":  7000},
    {"name": "Bangkok",        "country": "Thailand",       "cc": "TH", "lat":  13.7563, "lng": 100.5018, "r": 10000},
    {"name": "Phuket",         "country": "Thailand",       "cc": "TH", "lat":   7.8804, "lng":  98.3923, "r":  8000},
    {"name": "Pattaya",        "country": "Thailand",       "cc": "TH", "lat":  12.9274, "lng": 100.8762, "r":  5000},
    {"name": "Bali",           "country": "Indonesia",      "cc": "ID", "lat":  -8.3405, "lng": 115.0920, "r":  8000},
    {"name": "Jakarta",        "country": "Indonesia",      "cc": "ID", "lat":  -6.2088, "lng": 106.8456, "r": 10000},
    {"name": "Taipei",         "country": "Taiwan",         "cc": "TW", "lat":  25.0330, "lng": 121.5654, "r":  8000},
    {"name": "Shanghai",       "country": "China",          "cc": "CN", "lat":  31.2304, "lng": 121.4737, "r": 12000},
    {"name": "Kuala Lumpur",   "country": "Malaysia",       "cc": "MY", "lat":   3.1390, "lng": 101.6869, "r":  7000},
    {"name": "Ho Chi Minh City","country": "Vietnam",       "cc": "VN", "lat":  10.8231, "lng": 106.6297, "r":  8000},
    {"name": "Manila",         "country": "Philippines",    "cc": "PH", "lat":  14.5995, "lng": 120.9842, "r":  8000},
    {"name": "Dubai",          "country": "UAE",            "cc": "AE", "lat":  25.2048, "lng":  55.2708, "r": 10000},
    {"name": "Abu Dhabi",      "country": "UAE",            "cc": "AE", "lat":  24.4539, "lng":  54.3773, "r":  7000},
    {"name": "Beirut",         "country": "Lebanon",        "cc": "LB", "lat":  33.8938, "lng":  35.5018, "r":  5000},
    {"name": "Tel Aviv",       "country": "Israel",         "cc": "IL", "lat":  32.0853, "lng":  34.7818, "r":  6000},
    {"name": "Mumbai",         "country": "India",          "cc": "IN", "lat":  19.0760, "lng":  72.8777, "r": 10000},
    {"name": "Goa",            "country": "India",          "cc": "IN", "lat":  15.2993, "lng":  74.1240, "r":  8000},
    {"name": "Delhi",          "country": "India",          "cc": "IN", "lat":  28.6139, "lng":  77.2090, "r": 10000},
    {"name": "Colombo",        "country": "Sri Lanka",      "cc": "LK", "lat":   6.9271, "lng":  79.8612, "r":  6000},
    {"name": "Phnom Penh",     "country": "Cambodia",       "cc": "KH", "lat":  11.5564, "lng": 104.9282, "r":  5000},

    # ── Africa & Middle East ──────────────────────────────────────────────────
    {"name": "Cape Town",      "country": "South Africa",   "cc": "ZA", "lat": -33.9249, "lng":  18.4241, "r":  8000},
    {"name": "Johannesburg",   "country": "South Africa",   "cc": "ZA", "lat": -26.2041, "lng":  28.0473, "r":  8000},
    {"name": "Nairobi",        "country": "Kenya",          "cc": "KE", "lat":  -1.2921, "lng":  36.8219, "r":  6000},
    {"name": "Lagos",          "country": "Nigeria",        "cc": "NG", "lat":   6.5244, "lng":   3.3792, "r":  8000},
    {"name": "Cairo",          "country": "Egypt",          "cc": "EG", "lat":  30.0444, "lng":  31.2357, "r":  8000},
    {"name": "Marrakech",      "country": "Morocco",        "cc": "MA", "lat":  31.6295, "lng":  -7.9811, "r":  4000},
    {"name": "Casablanca",     "country": "Morocco",        "cc": "MA", "lat":  33.5731, "lng":  -7.5898, "r":  6000},
    {"name": "Tunis",          "country": "Tunisia",        "cc": "TN", "lat":  36.8065, "lng":  10.1815, "r":  5000},

    # ── Oceania ───────────────────────────────────────────────────────────────
    {"name": "Sydney",         "country": "Australia",      "cc": "AU", "lat": -33.8688, "lng": 151.2093, "r": 10000},
    {"name": "Melbourne",      "country": "Australia",      "cc": "AU", "lat": -37.8136, "lng": 144.9631, "r":  9000},
    {"name": "Brisbane",       "country": "Australia",      "cc": "AU", "lat": -27.4698, "lng": 153.0251, "r":  6000},
    {"name": "Gold Coast",     "country": "Australia",      "cc": "AU", "lat": -28.0167, "lng": 153.4000, "r":  5000},
    {"name": "Auckland",       "country": "New Zealand",    "cc": "NZ", "lat": -36.8509, "lng": 174.7645, "r":  6000},
]

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
AMENITY_TYPES = "bar|nightclub|pub|biergarten|cocktail_bar|wine_bar|sports_bar|lounge"


# ── Overpass ──────────────────────────────────────────────────────────────────

def query_overpass(lat: float, lng: float, radius: int) -> list:
    query = f"""
[out:json][timeout:35];
(
  node["amenity"~"{AMENITY_TYPES}"](around:{radius},{lat},{lng});
  way["amenity"~"{AMENITY_TYPES}"](around:{radius},{lat},{lng});
);
out center;
"""
    resp = requests.post(OVERPASS_URL, data={"data": query}, timeout=50)
    resp.raise_for_status()
    return resp.json().get("elements", [])


def parse_element(el: dict, city: dict) -> Optional[dict]:
    tags = el.get("tags", {})
    name = tags.get("name", "").strip()
    if not name:
        return None

    lat, lng = None, None
    if el["type"] == "node":
        lat = el.get("lat")
        lng = el.get("lon")
    elif el["type"] == "way":
        center = el.get("center", {})
        lat = center.get("lat")
        lng = center.get("lon")

    if lat is None or lng is None:
        return None

    street   = tags.get("addr:street", "")
    house_no = tags.get("addr:housenumber", "")
    address  = f"{street} {house_no}".strip() if street else None

    amenity = tags.get("amenity", "bar")
    type_labels = {
        "nightclub":   "Night Club",
        "bar":         "Bar",
        "pub":         "Pub",
        "biergarten":  "Beer Garden",
        "cocktail_bar":"Cocktail Bar",
        "wine_bar":    "Wine Bar",
        "sports_bar":  "Sports Bar",
        "lounge":      "Lounge",
    }

    return {
        "name":          name,
        "lat":           round(lat, 6),
        "lng":           round(lng, 6),
        "type":          amenity,
        "type_label":    type_labels.get(amenity, amenity.replace("_", " ").title()),
        "city":          city["name"],
        "country":       city["country"],
        "country_code":  city["cc"],
        "address":       address,
        "opening_hours": tags.get("opening_hours"),
        "phone":         tags.get("phone") or tags.get("contact:phone"),
        "website":       tags.get("website") or tags.get("contact:website"),
        "source":        "osm",
        "osm_id":        str(el["id"]),
        "status":        "active",
    }


# ── Firestore ──────────────────────────────────────────────────────────────────

def upload_batch(db, venues: list) -> int:
    """Upload up to 499 venues in a single Firestore batch."""
    BATCH_SIZE = 499
    uploaded = 0
    batch = db.batch()
    count = 0

    for v in venues:
        doc_id = f"osm_{v['osm_id']}"
        ref = db.collection("venues").document(doc_id)
        batch.set(ref, v, merge=True)
        count   += 1
        uploaded += 1
        if count >= BATCH_SIZE:
            batch.commit()
            batch = db.batch()
            count = 0

    if count > 0:
        batch.commit()

    return uploaded


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Seed Firestore venues collection")
    parser.add_argument("--credentials", required=True,
                        help="Path to Firebase service account JSON key")
    parser.add_argument("--radius",  type=int, default=5000,
                        help="Default search radius in metres (default: 5000)")
    parser.add_argument("--delay",   type=float, default=2.0,
                        help="Seconds between Overpass calls (default: 2)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print counts only, do not upload to Firestore")
    parser.add_argument("--output",  default=None,
                        help="Also save all venues to this JSON file")
    parser.add_argument("--cities",  default=None,
                        help="Comma-separated city names to process (default: all)")
    args = parser.parse_args()

    # Filter cities if requested
    cities = NIGHTLIFE_CITIES
    if args.cities:
        requested = {c.strip().lower() for c in args.cities.split(",")}
        cities = [c for c in NIGHTLIFE_CITIES if c["name"].lower() in requested]
        if not cities:
            print("No matching cities found. Check spelling.")
            sys.exit(1)

    # Initialise Firebase (skip in dry-run)
    db = None
    if not args.dry_run:
        import firebase_admin
        from firebase_admin import credentials as fb_creds, firestore as fb_store
        cred = fb_creds.Certificate(args.credentials)
        firebase_admin.initialize_app(cred)
        db = fb_store.client()
        print(f"Connected to Firestore.")

    all_venues  = []
    seen_ids    = set()
    total_added = 0

    print(f"\nProcessing {len(cities)} cities  |  radius override: {args.radius}m\n")
    print(f"{'City':<22}  {'Found':>6}  {'New':>6}  {'Cumulative':>10}")
    print("-" * 52)

    for city in cities:
        radius = city.get("r", args.radius)
        try:
            elements = query_overpass(city["lat"], city["lng"], radius)
        except Exception as e:
            print(f"  {city['name']:<20}  ERROR: {e}")
            time.sleep(args.delay)
            continue

        city_venues = []
        for el in elements:
            v = parse_element(el, city)
            if v is None:
                continue
            osm_id = v["osm_id"]
            if osm_id in seen_ids:
                continue
            seen_ids.add(osm_id)
            city_venues.append(v)
            all_venues.append(v)

        if not args.dry_run and city_venues:
            total_added += upload_batch(db, city_venues)
        else:
            total_added += len(city_venues)

        print(f"  {city['name']:<20}  {len(elements):>6}  {len(city_venues):>6}  {total_added:>10}")
        time.sleep(args.delay)

    # Optional local JSON export
    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(all_venues, f, ensure_ascii=False, indent=2)
        print(f"\nSaved {len(all_venues)} venues → {args.output}")

    action = "Would upload" if args.dry_run else "Uploaded"
    print(f"\n✓  {action} {total_added:,} unique venues across {len(cities)} cities.")


if __name__ == "__main__":
    main()
