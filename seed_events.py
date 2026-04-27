import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate(
    r'C:\Users\USER\Downloads\PartyApp\PartyApp\PartyAgent\backend\firebase_service_account.json'
)
firebase_admin.initialize_app(cred)
db = firestore.client()

EVENTS = [
    {
        "id": "sl_1",
        "name": "Colombo Sunset Soul",
        "venue_name": "Galle Face Green",
        "city": "Colombo",
        "country": "Sri Lanka",
        "country_code": "LK",
        "date": "2026-04-25",
        "genre": "Lounge",
        "cover_image": "https://images.unsplash.com/photo-1544911845-1f34a3eb46b1?q=80&w=1400&auto=format&fit=crop",
        "price_hint": "Free",
        "lat": 6.9271,
        "lng": 79.8612,
    },
    {
        "id": "sl_2",
        "name": "Hikkaduwa Beach Rave",
        "venue_name": "Main Beach",
        "city": "Hikkaduwa",
        "country": "Sri Lanka",
        "country_code": "LK",
        "date": "2026-04-26",
        "genre": "Rave",
        "cover_image": "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?q=80&w=1400&auto=format&fit=crop",
        "price_hint": "Tickets",
        "lat": 6.1395,
        "lng": 80.1052,
    },
    {
        "id": "sl_3",
        "name": "Kandy Heritage Beats",
        "venue_name": "Kandy Lake Club",
        "city": "Kandy",
        "country": "Sri Lanka",
        "country_code": "LK",
        "date": "2026-04-27",
        "genre": "Cultural",
        "cover_image": "https://images.unsplash.com/photo-1514525253361-bee8718a74a2?q=80&w=1400&auto=format&fit=crop",
        "price_hint": "Tickets",
        "lat": 7.2906,
        "lng": 80.6337,
    },
    {
        "id": "trend_2",
        "name": "Underground Techno Berlin",
        "venue_name": "The Vault",
        "city": "Berlin",
        "country": "Germany",
        "country_code": "DE",
        "date": "2026-05-01",
        "genre": "Techno",
        "cover_image": "https://images.unsplash.com/photo-1574391884720-bbc37bb15932?q=80&w=1400&auto=format&fit=crop",
        "price_hint": "€20",
        "lat": 52.5200,
        "lng": 13.4050,
    },
    {
        "id": "trend_3",
        "name": "Tokyo City Lights Festival",
        "venue_name": "Shibuya Crossing Area",
        "city": "Tokyo",
        "country": "Japan",
        "country_code": "JP",
        "date": "2026-05-03",
        "genre": "Festival",
        "cover_image": "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?q=80&w=1400&auto=format&fit=crop",
        "price_hint": "¥3500",
        "lat": 35.6595,
        "lng": 139.7004,
    },
    {
        "id": "trend_4",
        "name": "Ibiza Foam Odyssey",
        "venue_name": "Amnesia",
        "city": "Ibiza",
        "country": "Spain",
        "country_code": "ES",
        "date": "2026-05-10",
        "genre": "Rave",
        "cover_image": "https://images.unsplash.com/photo-1545128485-c400e7702796?q=80&w=1400&auto=format&fit=crop",
        "price_hint": "€35",
        "lat": 38.9218,
        "lng": 1.4200,
    },
    {
        "id": "trend_5",
        "name": "London Underground Bass",
        "venue_name": "Fabric",
        "city": "London",
        "country": "United Kingdom",
        "country_code": "GB",
        "date": "2026-05-08",
        "genre": "Bass",
        "cover_image": "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=1400&auto=format&fit=crop",
        "price_hint": "£15",
        "lat": 51.5214,
        "lng": -0.1022,
    },
    {
        "id": "trend_6",
        "name": "Paris Rooftop Jazz & House",
        "venue_name": "Le Perchoir",
        "city": "Paris",
        "country": "France",
        "country_code": "FR",
        "date": "2026-04-30",
        "genre": "House",
        "cover_image": "https://images.unsplash.com/photo-1517457373958-b7bdd248c825?q=80&w=1400&auto=format&fit=crop",
        "price_hint": "€10",
        "lat": 48.8566,
        "lng": 2.3522,
    },
    {
        "id": "trend_7",
        "name": "Dubai Marina Yacht Party",
        "venue_name": "Marina Yacht Club",
        "city": "Dubai",
        "country": "UAE",
        "country_code": "AE",
        "date": "2026-05-02",
        "genre": "House",
        "cover_image": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1400&auto=format&fit=crop",
        "price_hint": "VIP",
        "lat": 25.0819,
        "lng": 55.1367,
    },
]

col = db.collection('events')

for event in EVENTS:
    eid = event.pop('id')
    col.document(eid).set(event)
    print(f"  Seeded: {event['name']} ({eid})")

print("\nDone — all events written to Firestore.")
