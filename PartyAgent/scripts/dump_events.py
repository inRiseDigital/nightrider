"""Print every web-crawled row currently in the events table."""
from __future__ import annotations
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from party_agent.data.events_db import _conn

with _conn() as conn:
    rows = conn.execute(
        """
        SELECT id, name, city, country, vibe, price, event_date,
               source, source_url, last_crawled_at
        FROM events
        WHERE source = 'web_crawl'
        ORDER BY last_crawled_at DESC
        """
    ).fetchall()

print(f"{len(rows)} crawler-sourced rows in DB:\n")
for r in rows:
    print(f"  [{r['id']}] {r['name'][:50]}")
    print(f"      city={r['city']} country={r['country']} vibe={r['vibe']}")
    print(f"      price={r['price']!r}  event_date={r['event_date']}")
    print(f"      source_url={r['source_url']}")
    print(f"      last_crawled_at={r['last_crawled_at']}")
    print()
