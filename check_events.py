import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate(
    r'C:\Users\USER\Downloads\PartyApp\PartyApp\PartyAgent\backend\firebase_service_account.json'
)
firebase_admin.initialize_app(cred)
db = firestore.client()

today = '2026-04-23'

# Check total events
all_docs = list(db.collection('events').limit(10).stream())
print(f"Total sample (first 10):")
for d in all_docs:
    data = d.to_dict()
    print(f"  [{d.id}] name={data.get('name','')} | date={data.get('date','')} | status={data.get('status','')}")

print()

# Check upcoming events (date >= today)
try:
    upcoming = list(db.collection('events').order_by('date').limit(10).stream())
    print(f"Upcoming events (orderBy date, limit 10):")
    for d in upcoming:
        data = d.to_dict()
        print(f"  [{d.id}] name={data.get('name','')} | date={data.get('date','')} | status={data.get('status','')}")
except Exception as e:
    print(f"orderBy query failed: {e}")
