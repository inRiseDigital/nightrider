"""User state, RSVPs, badges, and gamification accessors.

This module is the single Postgres-facing entry point for everything
"about a user": their points, streak, stealth setting, badges they've
earned, and the events they've RSVP'd to. Tools call these functions
directly; the agents never touch SQL.

Concurrency note: each function opens its own short-lived connection via
events_db._conn. The connection pool will batch these efficiently. Do NOT
keep a connection around across an LLM call.
"""

from __future__ import annotations

from datetime import date, timedelta
from typing import Optional

from party_agent.data.events_db import _conn


# ---------- user_state ----------

def _ensure_user_state(user_id: str) -> None:
    """Idempotent insert so subsequent UPDATEs always have a row to touch."""
    with _conn() as conn:
        conn.execute(
            "INSERT INTO user_state (user_id) VALUES (%s) ON CONFLICT (user_id) DO NOTHING",
            (user_id,),
        )
        conn.commit()


def get_user_state(user_id: str) -> dict:
    """Return the user's full state, creating an empty row if missing."""
    _ensure_user_state(user_id)
    with _conn() as conn:
        row = conn.execute(
            """
            SELECT user_id, points, streak_days, last_checkin_date,
                   stealth_mode, cities_visited, countries_visited, updated_at
            FROM user_state WHERE user_id = %s
            """,
            (user_id,),
        ).fetchone()
    return dict(row) if row else {}


# ---------- stealth ----------

def set_stealth(user_id: str, enabled: bool) -> bool:
    """Persist stealth on/off. Returns the new value."""
    _ensure_user_state(user_id)
    with _conn() as conn:
        conn.execute(
            "UPDATE user_state SET stealth_mode = %s, updated_at = NOW() WHERE user_id = %s",
            (enabled, user_id),
        )
        conn.commit()
    return enabled


def is_stealth(user_id: str) -> bool:
    return bool(get_user_state(user_id).get("stealth_mode", False))


# ---------- badges ----------

def list_badges(user_id: str) -> list[str]:
    with _conn() as conn:
        rows = conn.execute(
            "SELECT badge FROM user_badges WHERE user_id = %s ORDER BY earned_at",
            (user_id,),
        ).fetchall()
    return [r["badge"] for r in rows]


def award_badge(user_id: str, badge: str) -> bool:
    """Award a badge if the user doesn't already have it. Returns True if newly awarded."""
    _ensure_user_state(user_id)
    with _conn() as conn:
        result = conn.execute(
            """
            INSERT INTO user_badges (user_id, badge)
            VALUES (%s, %s)
            ON CONFLICT (user_id, badge) DO NOTHING
            """,
            (user_id, badge),
        )
        conn.commit()
        return (result.rowcount or 0) > 0


# ---------- points + streak + check-in ----------

# Tier thresholds in lifetime points → user-facing level name.
_LEVELS = [
    (0,       "Rookie"),
    (1_000,   "Scene Starter"),
    (5_000,   "Party Regular"),
    (15_000,  "Nightlife Native"),
    (50_000,  "Scene Legend"),
    (100_000, "Global Party Icon"),
]


def level_for_points(points: int) -> str:
    name = _LEVELS[0][1]
    for threshold, label in _LEVELS:
        if points >= threshold:
            name = label
    return name


def record_checkin(user_id: str, city: str, country: str | None = None) -> dict:
    """Record a check-in for `user_id` at `city`. Updates points, streak, and
    cities/countries visited atomically. Returns a delta summary the tool
    can present to the user::

        {
          "awarded_points":  150,
          "new_streak":      3,
          "streak_continued": True,   # vs reset to 1
          "new_city":         True,
          "new_country":      False,
          "new_badges":       ["First Timer", "City Explorer: Colombo"],
          "total_points":     650,
          "level":            "Rookie",
        }
    """
    _ensure_user_state(user_id)
    city_l = (city or "").strip().lower()
    cc_u = (country or "").strip().upper() or None
    today = date.today()

    with _conn() as conn:
        row = conn.execute(
            """
            SELECT points, streak_days, last_checkin_date,
                   cities_visited, countries_visited
            FROM user_state WHERE user_id = %s FOR UPDATE
            """,
            (user_id,),
        ).fetchone()

        cur_points    = row["points"]
        cur_streak    = row["streak_days"]
        last_checkin  = row["last_checkin_date"]
        cities        = list(row["cities_visited"])
        countries     = list(row["countries_visited"])

        new_city    = bool(city_l) and city_l not in cities
        new_country = bool(cc_u) and cc_u not in countries

        if last_checkin == today:
            streak_continued = True
            new_streak = cur_streak
            # Same-day repeat check-in is +50, not +100, to discourage farming.
            points_award = 50
        elif last_checkin == today - timedelta(days=1):
            streak_continued = True
            new_streak = cur_streak + 1
            points_award = 100
        else:
            streak_continued = False
            new_streak = 1
            points_award = 100

        if new_city:
            cities.append(city_l)
            points_award += 300
        if new_country:
            countries.append(cc_u)
            points_award += 500

        new_total = cur_points + points_award

        conn.execute(
            """
            UPDATE user_state SET
                points            = %s,
                streak_days       = %s,
                last_checkin_date = %s,
                cities_visited    = %s,
                countries_visited = %s,
                updated_at        = NOW()
            WHERE user_id = %s
            """,
            (new_total, new_streak, today, cities, countries, user_id),
        )
        conn.commit()

    # Award any badges this check-in unlocks.
    badges_awarded: list[str] = []
    candidates: list[tuple[str, bool]] = [
        ("First Timer",                cur_points == 0),
        (f"City Explorer: {city.title()}", new_city),
        (f"Country Unlocked: {cc_u}",  new_country) if cc_u else ("", False),
        ("Three-Peat",                 new_streak == 3),
        ("Week Warrior",               new_streak == 7),
        ("Fortnight Fiend",            new_streak == 14),
        ("Month Monster",              new_streak == 30),
    ]
    for badge, qualifies in candidates:
        if badge and qualifies and award_badge(user_id, badge):
            badges_awarded.append(badge)

    return {
        "awarded_points":   points_award,
        "new_streak":       new_streak,
        "streak_continued": streak_continued,
        "new_city":         new_city,
        "new_country":      new_country,
        "new_badges":       badges_awarded,
        "total_points":     new_total,
        "level":            level_for_points(new_total),
    }


# ---------- rsvps ----------

def post_rsvp(
    user_id: str,
    event_name: str,
    event_city: str | None = None,
    event_date: Optional[date] = None,
    venue: str | None = None,
) -> bool:
    """Record an RSVP. Returns True if newly created, False if duplicate."""
    with _conn() as conn:
        result = conn.execute(
            """
            INSERT INTO rsvps (user_id, event_name, event_city, event_date, venue)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (user_id, event_name, COALESCE(event_date, DATE '9999-12-31'))
            DO NOTHING
            """,
            (user_id, event_name, event_city, event_date, venue),
        )
        conn.commit()
        return (result.rowcount or 0) > 0


def list_rsvps(user_id: str, upcoming_only: bool = True) -> list[dict]:
    """Return the user's RSVPs, most recent first."""
    with _conn() as conn:
        if upcoming_only:
            rows = conn.execute(
                """
                SELECT event_name, event_city, event_date, venue, created_at
                FROM rsvps
                WHERE user_id = %s AND (event_date IS NULL OR event_date >= CURRENT_DATE)
                ORDER BY event_date NULLS LAST, created_at DESC
                """,
                (user_id,),
            ).fetchall()
        else:
            rows = conn.execute(
                """
                SELECT event_name, event_city, event_date, venue, created_at
                FROM rsvps WHERE user_id = %s
                ORDER BY created_at DESC
                """,
                (user_id,),
            ).fetchall()
    return [dict(r) for r in rows]


def cancel_rsvp(user_id: str, event_name: str, event_date: Optional[date] = None) -> bool:
    with _conn() as conn:
        result = conn.execute(
            """
            DELETE FROM rsvps
            WHERE user_id = %s AND event_name = %s
              AND COALESCE(event_date, DATE '9999-12-31') = COALESCE(%s, DATE '9999-12-31')
            """,
            (user_id, event_name, event_date),
        )
        conn.commit()
        return (result.rowcount or 0) > 0
