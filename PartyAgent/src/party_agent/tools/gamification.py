"""Gamification tools — LIVE.

Points, streaks, badges and check-ins are all backed by Postgres
(``user_state`` + ``user_badges`` tables). No more invented numbers.

Leaderboards across users + GPS-verified festival challenges remain future
work — those need either anonymized aggregation or partner-festival APIs.
"""

from __future__ import annotations

from langchain_core.tools import tool

from party_agent.data import users_db


@tool
def check_progress(user_id: str) -> str:
    """Return the user's current points, streak, level, badges, and places visited.

    Args:
        user_id: Stable identifier for the current user.
    """
    state = users_db.get_user_state(user_id)
    badges = users_db.list_badges(user_id)

    points = state.get("points", 0)
    streak = state.get("streak_days", 0)
    last   = state.get("last_checkin_date")
    cities = state.get("cities_visited") or []
    countries = state.get("countries_visited") or []
    level  = users_db.level_for_points(points)

    parts = [
        f"Level: {level} ({points} pts)",
        f"Streak: {streak} day(s)" + (f" — last check-in {last}" if last else ""),
        f"Cities visited: {len(cities)}" + (f" ({', '.join(c.title() for c in cities[:5])}{'...' if len(cities) > 5 else ''})" if cities else ""),
        f"Countries visited: {len(countries)}" + (f" ({', '.join(countries)})" if countries else ""),
        f"Badges: {len(badges)}" + (f" — {', '.join(badges)}" if badges else ""),
    ]
    return "\n".join(parts)


@tool
def check_in(user_id: str, city: str, country_code: str = "") -> str:
    """Record a real-world check-in for the user at `city`.

    Awards points, updates streak, unlocks first-visit / streak / country
    badges atomically. Use this when the user tells you they've arrived at
    a venue or city.

    Args:
        user_id: Stable identifier for the current user.
        city: City the user is currently in.
        country_code: Optional 2-letter ISO country code.
    """
    if not city.strip():
        return "Check-in failed: city is required."

    result = users_db.record_checkin(user_id, city.strip(), country_code.strip() or None)

    lines = [
        f"Checked in to {city.title()}!",
        f"+{result['awarded_points']} pts (total: {result['total_points']} — Level: {result['level']})",
    ]
    if result["streak_continued"]:
        lines.append(f"Streak: {result['new_streak']} day(s)")
    else:
        lines.append("Streak reset to 1 day — welcome back!")
    if result["new_city"]:
        lines.append(f"New city unlocked: {city.title()}")
    if result["new_country"]:
        lines.append(f"New country unlocked: {country_code.upper()}")
    if result["new_badges"]:
        lines.append("Badges unlocked: " + ", ".join(result["new_badges"]))
    return "\n".join(lines)


@tool
def unlock_badge(user_id: str, badge: str) -> str:
    """Manually award a named badge (e.g. for a curated event achievement).

    Args:
        user_id: Stable identifier for the current user.
        badge:   Short badge title — will appear verbatim in the user's list.
    """
    if not badge.strip():
        return "Badge name is required."
    newly = users_db.award_badge(user_id, badge.strip())
    return f"Badge unlocked: '{badge}'." if newly else f"Already had badge '{badge}'."
