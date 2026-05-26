"""Seed the events table with a starter catalog.

Run after migrate_db.py:
    python scripts/migrate_db.py
    python scripts/seed_events.py
"""

from __future__ import annotations

import os
import sys

import psycopg


DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql://party:party@localhost:5432/party_agent")

# Real lat/lng coordinates for each event venue/neighbourhood
SEED_EVENTS: list[dict] = [
    # Dubai
    {"name": "White Club Dubai",          "city": "dubai",     "vibe": "vip",         "lat": 25.1972, "lng": 55.2744, "rsvps": 2500, "description": "Exclusive VIP rooftop night at White Club"},
    {"name": "Sky Lounge Burj VIP",       "city": "dubai",     "vibe": "luxury",      "lat": 25.1975, "lng": 55.2796, "rsvps": 800,  "description": "Ultra-luxury lounge with Burj views"},
    {"name": "Base Dubai",                "city": "dubai",     "vibe": "edm",         "lat": 25.1908, "lng": 55.2650, "rsvps": 1200, "description": "Dubai's top EDM club in DIFC"},
    {"name": "Zero Gravity Beach Club",   "city": "dubai",     "vibe": "chill",       "lat": 25.2532, "lng": 55.3657, "rsvps": 950,  "description": "Beach club with chill vibes by the sea"},
    # Tokyo
    {"name": "Shinjuku basement show",    "city": "tokyo",     "vibe": "hip-hop",     "lat": 35.6938, "lng": 139.7034, "rsvps": 320, "description": "Underground hip-hop showcase in Shinjuku"},
    {"name": "Ultra Tokyo",               "city": "tokyo",     "vibe": "edm",         "lat": 35.6485, "lng": 139.7514, "rsvps": 3000, "description": "Massive EDM festival in Odaiba"},
    {"name": "Roppongi rooftop acoustic", "city": "tokyo",     "vibe": "chill",       "lat": 35.6641, "lng": 139.7310, "rsvps": 80,  "description": "Intimate acoustic sessions on a Roppongi rooftop"},
    {"name": "Womb Club Tokyo",           "city": "tokyo",     "vibe": "underground", "lat": 35.6549, "lng": 139.6984, "rsvps": 600, "description": "Iconic underground techno club in Shibuya"},
    # London
    {"name": "Hackney warehouse rave",    "city": "london",    "vibe": "underground", "lat": 51.5450, "lng": -0.0553,  "rsvps": 450, "description": "Illegal-feel warehouse rave in Hackney"},
    {"name": "Fabric London",             "city": "london",    "vibe": "edm",         "lat": 51.5195, "lng": -0.1015,  "rsvps": 1800, "description": "World-famous superclub in Farringdon"},
    {"name": "Jazz Cafe Camden",          "city": "london",    "vibe": "chill",       "lat": 51.5391, "lng": -0.1452,  "rsvps": 200, "description": "Live jazz and soul at the Camden institution"},
    {"name": "Heaven Nightclub",          "city": "london",    "vibe": "lgbtq",       "lat": 51.5075, "lng": -0.1233,  "rsvps": 900, "description": "Legendary LGBTQ+ venue under Charing Cross"},
    # Melbourne
    {"name": "Multicultural Food & Beats","city": "melbourne", "vibe": "free",        "lat": -37.8136, "lng": 144.9631, "rsvps": 1200, "description": "Free outdoor festival in Federation Square"},
    {"name": "Pride street festival",     "city": "melbourne", "vibe": "lgbtq",       "lat": -37.8183, "lng": 144.9671, "rsvps": 1800, "description": "Melbourne Pride street festival in Fitzroy"},
    {"name": "Revolver Upstairs",         "city": "melbourne", "vibe": "underground", "lat": -37.8600, "lng": 144.9920, "rsvps": 550, "description": "Beloved underground club in Prahran"},
    {"name": "Stereosonic Melbourne",     "city": "melbourne", "vibe": "edm",         "lat": -37.8239, "lng": 144.9513, "rsvps": 4000, "description": "Massive outdoor EDM festival"},
]

INSERT_SQL = """
INSERT INTO events (name, city, vibe, lat, lng, rsvps, description)
VALUES (%(name)s, %(city)s, %(vibe)s, %(lat)s, %(lng)s, %(rsvps)s, %(description)s)
ON CONFLICT DO NOTHING
"""


def main() -> None:
    print(f"Connecting to {DATABASE_URL} ...")
    with psycopg.connect(DATABASE_URL) as conn:
        for event in SEED_EVENTS:
            conn.execute(INSERT_SQL, event)
        conn.commit()
    print(f"Seeded {len(SEED_EVENTS)} events.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"Seeding failed: {exc}", file=sys.stderr)
        sys.exit(1)
