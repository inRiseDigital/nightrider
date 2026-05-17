import os
import firebase_admin
from firebase_admin import credentials, firestore

_cred_path = os.path.join(os.path.dirname(__file__), 'firebase_service_account.json')
if not firebase_admin._apps:
    cred = credentials.Certificate(_cred_path)
    firebase_admin.initialize_app(cred)

_db = firestore.client()

_FALLBACK_DATA = [
    {
        'id': 'sl_1',
        'title': 'Colombo Sunset Soul',
        'location': 'Galle Face Green, Colombo',
        'country': 'Sri Lanka',
        'time': 'Tonight • 06:00 PM',
        'category': 'LOUNGE',
        'description': 'Chill vibes and soul music as the sun sets over the Indian Ocean.',
        'images': ['https://images.unsplash.com/photo-1544911845-1f34a3eb46b1?q=80&w=1000&auto=format&fit=crop'],
        'interested_count': 85,
        'genre': '', 'vibe': '', 'price_hint': '', 'ticket_url': '', 'artists': [],
    },
    {
        'id': 'trend_1',
        'title': 'Midnight Neon Party',
        'location': 'Sky Lounge, Downtown NYC',
        'country': 'USA',
        'time': 'Tonight • 11:30 PM',
        'category': 'RAVE',
        'description': 'A high-energy neon-themed rave featuring top DJs.',
        'images': ['https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=1000&auto=format&fit=crop'],
        'interested_count': 150,
        'genre': '', 'vibe': '', 'price_hint': '', 'ticket_url': '', 'artists': [],
    },
]


def _fmt_time(d: dict) -> str:
    date = d.get('date', '')
    start = d.get('start_time', '')
    if date and start:
        return f'{date} • {start}'
    return date or start or 'TBA'


def _fetch_events() -> list:
    try:
        docs = (
            _db.collection('events')
            .where(filter=firestore.FieldFilter('status', 'in', ['published', 'Published']))
            .stream()
        )
        events = []
        for doc in docs:
            d = doc.to_dict()
            city = d.get('city', '')
            location = ', '.join(filter(None, [d.get('venue_name', ''), city]))
            events.append({
                'id': doc.id,
                'title': d.get('name', ''),
                'location': location or city,
                'country': d.get('country', ''),
                'time': _fmt_time(d),
                'category': d.get('category', 'Event'),
                'description': d.get('description', ''),
                'images': [d['cover_image']] if d.get('cover_image') else [],
                'interested_count': d.get('interested_count', 0),
                'genre': d.get('genre', ''),
                'vibe': d.get('vibe', ''),
                'price_hint': d.get('price_hint', ''),
                'ticket_url': d.get('ticket_url', ''),
                'artists': d.get('artists', []),
                'date': d.get('date', ''),
            })
        # Sort by date in Python — avoids needing a Firestore composite index
        events.sort(key=lambda e: e.get('date', ''))
        return events
    except Exception as e:
        print(f'[data_source] Firestore fetch failed: {e}')
        return _FALLBACK_DATA


_cached_events: list = []


def get_party_data() -> list:
    global _cached_events
    if not _cached_events:
        _cached_events = _fetch_events()
    return _cached_events


def refresh_party_data() -> list:
    global _cached_events
    _cached_events = _fetch_events()
    return _cached_events


PARTY_DATA: list = get_party_data()
AMENITIES_DATA: list = []
