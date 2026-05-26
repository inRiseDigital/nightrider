"""Events table accessor — PostgreSQL via psycopg."""

from __future__ import annotations

from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from typing import Iterator

import psycopg
from psycopg.rows import dict_row

from party_agent.config import get_settings


@contextmanager
def _conn() -> Iterator[psycopg.Connection]:
    url = get_settings().database_url
    if not url:
        raise RuntimeError("DATABASE_URL is not configured")
    with psycopg.connect(url, row_factory=dict_row) as conn:
        yield conn


def search_by_city_vibe(city: str, vibe: str) -> list[dict]:
    with _conn() as conn:
        return conn.execute(
            """
            SELECT id, name, city, vibe, rsvps, lat, lng
            FROM events
            WHERE city = %s AND vibe = %s
            ORDER BY rsvps DESC
            """,
            (city.lower(), vibe.lower()),
        ).fetchall()


def fallback_by_city(city: str, limit: int = 3) -> list[dict]:
    with _conn() as conn:
        return conn.execute(
            """
            SELECT id, name, city, vibe, rsvps, lat, lng
            FROM events
            WHERE city = %s
            ORDER BY rsvps DESC
            LIMIT %s
            """,
            (city.lower(), limit),
        ).fetchall()


def trending_in_city(city: str) -> dict | None:
    with _conn() as conn:
        return conn.execute(
            """
            SELECT id, name, city, vibe, rsvps
            FROM events
            WHERE city = %s
            ORDER BY rsvps DESC
            LIMIT 1
            """,
            (city.lower(),),
        ).fetchone()


def delete_expired_events(grace_hours: int | None = None) -> int:
    """Remove crawler-sourced events whose event_date is older than now - grace.

    Only crawler rows are deleted; rows with `source = 'manual'` are kept since
    those represent curated/seeded data that may not have a real event_date.
    Returns the number of rows deleted.
    """
    if grace_hours is None:
        grace_hours = get_settings().crawl_event_ttl_hours
    cutoff = datetime.now(timezone.utc) - timedelta(hours=grace_hours)
    with _conn() as conn:
        result = conn.execute(
            """
            DELETE FROM events
            WHERE source <> 'manual'
              AND event_date IS NOT NULL
              AND event_date < %s
            """,
            (cutoff,),
        )
        conn.commit()
        return result.rowcount or 0


def is_city_fresh(city: str, max_age_hours: int | None = None) -> bool:
    """True if any crawler-sourced event for `city` is newer than max_age_hours.

    Used by the live-fallback path to decide whether to skip the crawl and
    just read cache. We only count crawler-sourced rows (manual/seeded rows
    have no `last_crawled_at` so they shouldn't reset the freshness clock).
    """
    if max_age_hours is None:
        max_age_hours = get_settings().crawl_freshness_hours
    cutoff = datetime.now(timezone.utc) - timedelta(hours=max_age_hours)
    with _conn() as conn:
        row = conn.execute(
            """
            SELECT 1 FROM events
            WHERE city = %s AND last_crawled_at IS NOT NULL AND last_crawled_at >= %s
            LIMIT 1
            """,
            (city.lower(), cutoff),
        ).fetchone()
    return row is not None


def upsert_events(events: list[dict]) -> int:
    """Insert/update crawler events keyed on (source_url, name).

    Each dict may contain: name, city, country, vibe, price, date,
    source, source_url, last_crawled_at. Missing fields are filled with safe
    defaults so the schema's NOT NULL columns don't blow up.

    Returns the number of rows touched.
    """
    if not events:
        return 0
    rows = [
        (
            e["name"],
            (e.get("city") or "").lower(),
            (e.get("vibe") or "music").lower(),
            e.get("country"),
            e.get("price"),
            e.get("date"),
            e.get("source") or "web_crawl",
            e.get("source_url"),
            e.get("last_crawled_at") or datetime.now(timezone.utc).isoformat(),
        )
        for e in events
        if e.get("name")
    ]
    if not rows:
        return 0
    with _conn() as conn:
        with conn.cursor() as cur:
            cur.executemany(
                """
                INSERT INTO events
                    (name, city, vibe, country, price, event_date,
                     source, source_url, last_crawled_at)
                VALUES (%s, %s, %s, %s, %s,
                        NULLIF(%s, '')::timestamptz,
                        %s, %s, %s)
                ON CONFLICT (COALESCE(source_url, ''), name) DO UPDATE SET
                    city            = EXCLUDED.city,
                    vibe            = EXCLUDED.vibe,
                    country         = EXCLUDED.country,
                    price           = EXCLUDED.price,
                    event_date      = COALESCE(EXCLUDED.event_date, events.event_date),
                    source          = EXCLUDED.source,
                    last_crawled_at = EXCLUDED.last_crawled_at
                """,
                rows,
            )
        conn.commit()
    return len(rows)


def nearby(lat: float, lng: float, max_km: float) -> list[dict]:
    """Return events within max_km of the given coordinates, sorted by distance."""
    with _conn() as conn:
        return conn.execute(
            """
            WITH dist AS (
                SELECT
                    id, name, city, vibe, rsvps,
                    (6371 * acos(
                        LEAST(1.0,
                            cos(radians(%s)) * cos(radians(lat))
                            * cos(radians(lng) - radians(%s))
                            + sin(radians(%s)) * sin(radians(lat))
                        )
                    )) AS distance_km
                FROM events
            )
            SELECT * FROM dist
            WHERE distance_km <= %s
            ORDER BY distance_km
            """,
            (lat, lng, lat, max_km),
        ).fetchall()
