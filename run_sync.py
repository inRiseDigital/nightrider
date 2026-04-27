import asyncio
import os
import sys

sys.path.insert(0, r'C:\Users\USER\Downloads\PartyApp\PartyApp\PartyAgent\backend')
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = r'C:\Users\USER\Downloads\PartyApp\PartyApp\PartyAgent\backend\firebase_service_account.json'
os.environ['TICKETMASTER_API_KEY'] = 'JJ7UtBmZfRRt7MrsBWykZae992BsS2U7'

from ticketmaster_sync import fetch_and_sync_events

async def main():
    print("Starting Ticketmaster sync (more pages, more data)...")
    # size=200: fetch 200 events per page
    # pages_per_country=5: 5 pages × 18 countries = up to 18,000 events
    result = await fetch_and_sync_events(size=200, pages_per_country=5)
    print(result)

asyncio.run(main())
