"""Create the events table (and any other schema) in PostgreSQL."""

from __future__ import annotations

import os
import sys

import psycopg


DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql://party:party@localhost:5432/party_agent")

CREATE_EVENTS = """
CREATE TABLE IF NOT EXISTS events (
    id          SERIAL PRIMARY KEY,
    name        TEXT        NOT NULL,
    city        TEXT        NOT NULL,
    vibe        TEXT        NOT NULL,
    lat         DOUBLE PRECISION NOT NULL DEFAULT 0,
    lng         DOUBLE PRECISION NOT NULL DEFAULT 0,
    rsvps       INTEGER     NOT NULL DEFAULT 0,
    description TEXT        NOT NULL DEFAULT '',
    event_date  TIMESTAMPTZ,
    country         TEXT,
    price           TEXT,
    source          TEXT        NOT NULL DEFAULT 'manual',
    source_url      TEXT,
    last_crawled_at TIMESTAMPTZ
);

-- Idempotent column adds for environments that ran an earlier migration.
ALTER TABLE events ADD COLUMN IF NOT EXISTS country         TEXT;
ALTER TABLE events ADD COLUMN IF NOT EXISTS price           TEXT;
ALTER TABLE events ADD COLUMN IF NOT EXISTS source          TEXT NOT NULL DEFAULT 'manual';
ALTER TABLE events ADD COLUMN IF NOT EXISTS source_url      TEXT;
ALTER TABLE events ADD COLUMN IF NOT EXISTS last_crawled_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_events_city  ON events (city);
CREATE INDEX IF NOT EXISTS idx_events_vibe  ON events (vibe);
CREATE INDEX IF NOT EXISTS idx_events_rsvps ON events (rsvps DESC);
CREATE INDEX IF NOT EXISTS idx_events_freshness ON events (city, last_crawled_at DESC);

-- Dedup key for upserts from the crawler — same source URL + name should
-- update in place rather than create duplicates each refresh.
CREATE UNIQUE INDEX IF NOT EXISTS uq_events_source_name
    ON events (COALESCE(source_url, ''), name);

-- Per-user state: points, streak, stealth, places visited.
CREATE TABLE IF NOT EXISTS user_state (
    user_id            TEXT PRIMARY KEY,
    points             INTEGER NOT NULL DEFAULT 0,
    streak_days        INTEGER NOT NULL DEFAULT 0,
    last_checkin_date  DATE,
    stealth_mode       BOOLEAN NOT NULL DEFAULT FALSE,
    cities_visited     TEXT[] NOT NULL DEFAULT '{}',
    countries_visited  TEXT[] NOT NULL DEFAULT '{}',
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Earned badges. Idempotent inserts via PRIMARY KEY.
CREATE TABLE IF NOT EXISTS user_badges (
    user_id    TEXT NOT NULL,
    badge      TEXT NOT NULL,
    earned_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, badge)
);

-- RSVPs the user has marked. event_name + date is the dedupe key so the same
-- person can't RSVP twice to the same party.
CREATE TABLE IF NOT EXISTS rsvps (
    id          SERIAL PRIMARY KEY,
    user_id     TEXT NOT NULL,
    event_name  TEXT NOT NULL,
    event_city  TEXT,
    event_date  DATE,
    venue       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_rsvps_user_event
    ON rsvps (user_id, event_name, COALESCE(event_date, DATE '9999-12-31'));
CREATE INDEX IF NOT EXISTS idx_rsvps_user ON rsvps (user_id, created_at DESC);
"""


def main() -> None:
    print(f"Connecting to {DATABASE_URL} ...")
    with psycopg.connect(DATABASE_URL) as conn:
        conn.execute(CREATE_EVENTS)
        conn.commit()
    print("Migration complete.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"Migration failed: {exc}", file=sys.stderr)
        sys.exit(1)
