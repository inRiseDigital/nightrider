import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate(
    r'C:\Users\USER\Downloads\PartyApp\PartyApp\PartyAgent\backend\firebase_service_account.json'
)
firebase_admin.initialize_app(cred)
db = firestore.client()

TODAY = '2026-04-23'
col = db.collection('events')

# Delete all events with date < today in batches
deleted = 0
while True:
    docs = list(col.where('date', '<', TODAY).limit(400).stream())
    if not docs:
        break
    batch = db.batch()
    for doc in docs:
        batch.delete(doc.reference)
    batch.commit()
    deleted += len(docs)
    print(f"  Deleted {deleted} past events so far...")

print(f"\nDone. Removed {deleted} past-dated events.")

# Confirm remaining count
remaining = len(list(col.limit(500).stream()))
print(f"Remaining events in Firestore: {remaining}+")
