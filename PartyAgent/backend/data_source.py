import os
import firebase_admin
from firebase_admin import credentials, firestore

# Initialise Firebase Admin SDK once
_cred_path = os.path.join(os.path.dirname(__file__), 'firebase_service_account.json')
if not firebase_admin._apps:
    cred = credentials.Certificate(_cred_path)
    firebase_admin.initialize_app(cred)

_db = firestore.client()


# ── Fallback data (used if Firestore is unreachable) ─────────────────────────
# Must be defined before _fetch_events so the except clause can reference it.

_FALLBACK_DATA = [
    {
        'id': 'sl_1',
        'title': 'Colombo Sunset Soul',
        'location': 'Galle Face Green, Colombo',
        'country': 'Sri Lanka',
        'time': 'Tonight • 06:00 PM',
        'category': 'LOUNGE',
        'description': 'Chill vibes and soul music as the sun sets over the Indian Ocean.',
        'images': [
            'https://images.unsplash.com/photo-1544911845-1f34a3eb46b1?q=80&w=1000&auto=format&fit=crop',
        ],
        'interested_count': 85,
    },
    {
        'id': 'trend_1',
        'title': 'Midnight Neon Party',
        'location': 'Sky Lounge, Downtown NYC',
        'country': 'USA',
        'time': 'Tonight • 11:30 PM',
        'category': 'RAVE',
        'description': 'A high-energy neon-themed rave featuring top DJs.',
        'images': [
            'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=1000&auto=format&fit=crop',
        ],
        'interested_count': 150,
    },
]


def _fmt_time(d: dict) -> str:
    date = d.get('date', '')
    start = d.get('start_time', '')
    if date and start:
        return f'{date} • {start}'
    return date or start or 'TBA'


def _fetch_events() -> list[dict]:
    """Fetch upcoming published events from Firestore and normalise to the agent's expected format."""
    from datetime import date
    today = date.today().isoformat()   # e.g. "2026-04-24"
    try:
        docs = (
            _db.collection('events')
            .where('date', '>=', today)
            .order_by('date')
            .stream()
        )
        events = []
        for doc in docs:
            d = doc.to_dict()
            city = d.get('city', '')
            country = d.get('country', '')
            location = ', '.join(filter(None, [d.get('venue_name', ''), city]))
            events.append({
                'id': doc.id,
                'title': d.get('name', ''),
                'location': location or city,
                'city': city,
                'country': country,
                'country_code': d.get('country_code', ''),
                'lat': float(d.get('lat', 0) or 0),
                'lng': float(d.get('lng', 0) or 0),
                'date': d.get('date', ''),
                'start_time': d.get('start_time', ''),
                'time': _fmt_time(d),
                'category': d.get('category', 'Event'),
                'description': d.get('description', ''),
                'images': [d['cover_image']] if d.get('cover_image') else [],
                'interested_count': d.get('interested_count', 0),
                'genre': d.get('genre', ''),
                'vibe': d.get('vibe', ''),
                'price_hint': d.get('price_hint', ''),
            })
        return events
    except Exception as e:
        print(f'[data_source] Firestore fetch failed: {e}')
        return _FALLBACK_DATA


# Lazy singleton — refreshed each agent boot, stable within a session
_cached_events: list[dict] | None = None


def get_party_data() -> list[dict]:
    global _cached_events
    if _cached_events is None:
        _cached_events = _fetch_events()
    return _cached_events


def refresh_party_data() -> list[dict]:
    """Force a fresh fetch from Firestore (call after admin adds an event)."""
    global _cached_events
    _cached_events = _fetch_events()
    return _cached_events


# Legacy constants kept for backward-compat with agent.py imports
PARTY_DATA: list[dict] = []   # populated at first agent call via get_party_data()
AMENITIES_DATA: list[dict] = []  # reserved for future venue amenities

# Bootstrap synchronously so existing `from data_source import PARTY_DATA` still works
PARTY_DATA = get_party_data()
