"""Social tools — RSVPs and stealth mode are LIVE (real Postgres persistence).

Friend graph (who's where, friend RSVPs visible to me, mutual visibility) is
NOT live yet — that requires user authentication and consent flows we haven't
built. ``friends_out_tonight`` still returns the honest unavailable marker so
the agent never invents friend names.
"""

from __future__ import annotations

from datetime import date as _date
from datetime import datetime

from langchain_core.tools import tool

from party_agent.data import users_db
from party_agent.tools._unavailable import unavailable


def _parse_date(s: str) -> _date | None:
    s = (s or "").strip()
    if not s:
        return None
    try:
        return datetime.strptime(s[:10], "%Y-%m-%d").date()
    except ValueError:
        return None


@tool
def post_rsvp(user_id: str, event_name: str, event_city: str = "",
              event_date: str = "", venue: str = "") -> str:
    """Record the user's RSVP for an event. Persists to Postgres.

    Args:
        user_id: Stable identifier for the current user.
        event_name: Display name of the event being RSVPed for.
        event_city: City the event is in (optional).
        event_date: ISO date YYYY-MM-DD (optional — leave empty for undated/recurring events).
        venue: Venue name (optional).
    """
    if not event_name.strip():
        return "RSVP failed: event_name is required."
    created = users_db.post_rsvp(
        user_id=user_id,
        event_name=event_name.strip(),
        event_city=event_city.strip() or None,
        event_date=_parse_date(event_date),
        venue=venue.strip() or None,
    )
    if created:
        return f"RSVP saved for '{event_name}'. You can list your RSVPs anytime with list_my_rsvps."
    return f"You already RSVPed to '{event_name}' — no change."


@tool
def list_my_rsvps(user_id: str, upcoming_only: bool = True) -> str:
    """List the user's upcoming RSVPs (or all if upcoming_only=False).

    Args:
        user_id: Stable identifier for the current user.
        upcoming_only: When True, only RSVPs whose event_date is today or later
                       (or undated). When False, show every RSVP ever made.
    """
    rsvps = users_db.list_rsvps(user_id, upcoming_only=upcoming_only)
    if not rsvps:
        return "No RSVPs on record."
    lines: list[str] = []
    for r in rsvps:
        when = r["event_date"].isoformat() if r["event_date"] else "date TBC"
        where = ", ".join(filter(None, [r.get("venue") or "", r.get("event_city") or ""]))
        lines.append(f"{r['event_name']} | {when} | {where or 'venue TBC'}")
    return "\n".join(lines)


@tool
def cancel_rsvp(user_id: str, event_name: str, event_date: str = "") -> str:
    """Remove a previously posted RSVP.

    Args:
        user_id: Stable identifier for the current user.
        event_name: Exact event name to remove the RSVP for.
        event_date: ISO date YYYY-MM-DD if the RSVP had one (optional).
    """
    deleted = users_db.cancel_rsvp(user_id, event_name.strip(), _parse_date(event_date))
    return "RSVP cancelled." if deleted else "No matching RSVP found to cancel."


@tool
def set_stealth_mode(user_id: str, enabled: bool) -> str:
    """Turn the user's stealth mode on or off. Persists in user_state.

    When stealth is on, social-graph features that show location to others
    are suppressed (real friend graph is not yet live; this flag is honoured
    by features when they ship).

    Args:
        user_id: Stable identifier for the current user.
        enabled: True to enable stealth, False to disable.
    """
    new_value = users_db.set_stealth(user_id, bool(enabled))
    state = "ON" if new_value else "OFF"
    return (
        f"Stealth mode is now {state}. "
        f"{'No location data will be visible once social features ship.' if new_value else 'Standard visibility restored.'}"
    )


@tool
def stealth_status(user_id: str) -> str:
    """Report whether the user's stealth mode is currently on.

    Args:
        user_id: Stable identifier for the current user.
    """
    return "Stealth mode is ON." if users_db.is_stealth(user_id) else "Stealth mode is OFF."


@tool
def friends_out_tonight(user_id: str) -> str:
    """List friends of user_id who are RSVP'd to events tonight."""
    # Friend graph is NOT live — must not invent names.
    return unavailable(
        "the friends-out-tonight feed",
        suggestion=(
            "tell the user this requires the friend-graph feature which "
            "isn't live yet; offer to find an event they can invite friends to"
        ),
    )
