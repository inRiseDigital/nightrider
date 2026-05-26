import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate(r"PartyAgent\firebase_service_account.json")
firebase_admin.initialize_app(cred)

db = firestore.client()
uid = "5ujibJooAuh0bLBysMTS3crnwPI3"

db.collection("users").document(uid).update({
    "isAdmin": True,
    "isOrganizer": True,
    "role": "admin",
})

print(f"Done — user {uid} is now admin + organizer.")
