"""Honesty regression tests for tools that are STILL stubs.

As features move from stub → live, the test for that tool is removed from
this file. What remains here are the tools that genuinely aren't wired to
real systems yet — they MUST keep returning the FEATURE_NOT_LIVE marker so
the agent never invents data.

Currently still preview:
  - maps.open_party_map        (needs Google Maps + in-app map UI)
  - maps.directions_to         (needs Google Maps Directions API)
  - rides.nearby_rides         (needs Google Places for pickup discovery)
  - social_graph.friends_out_tonight (needs friend graph + auth)
  - crowd.venue_status         (needs venue-partner API)
  - media.build_recap          (needs storage + ffmpeg pipeline)
  - notifications.send_push    (needs APNs / FCM credentials)

If any of these stops returning the marker (because someone wired it up),
that's great news — delete its test here instead of "fixing" it.
"""

from __future__ import annotations

from party_agent.tools import crowd, maps, media, notifications, rides, social_graph
from party_agent.tools._unavailable import unavailable

MARKER = "[FEATURE_NOT_LIVE]"


def _call(tool, **kwargs) -> str:
    return tool.invoke(kwargs)


# ---------- helper itself ----------

def test_unavailable_helper_emits_marker():
    msg = unavailable("ride booking")
    assert msg.startswith(MARKER)
    assert "ride booking" in msg
    assert "in development" in msg


def test_unavailable_includes_suggestion_when_given():
    msg = unavailable("foo", suggestion="bar baz")
    assert "Suggest instead: bar baz" in msg


# ---------- still-preview tools ----------

def test_maps_open_party_map_is_unavailable():
    out = _call(maps.open_party_map, city="Kandy", vibe_filter=None)
    assert MARKER in out


def test_maps_directions_to_is_unavailable():
    out = _call(maps.directions_to, venue_name="King of the Mambo")
    assert MARKER in out
    assert "King of the Mambo" in out


def test_rides_nearby_is_unavailable():
    out = _call(rides.nearby_rides, lat=6.9, lng=79.9, radius_m=300)
    assert MARKER in out


def test_social_friends_out_tonight_is_unavailable_and_warns_against_fabrication():
    out = _call(social_graph.friends_out_tonight, user_id="u_42")
    assert MARKER in out
    # Critical: the tool must NEVER return a fake friend name.
    assert "Sara" not in out
    assert "@" not in out


def test_crowd_venue_status_is_unavailable_and_no_fake_numbers():
    out = _call(crowd.venue_status, venue_name="Fabric")
    assert MARKER in out
    # Old stub returned "70% capacity, 15 min queue". Must never re-emerge.
    assert "70%" not in out
    assert "15 min" not in out


def test_media_build_recap_is_unavailable():
    out = _call(media.build_recap, user_id="u_42", event_id=7, theme="wild_night")
    assert MARKER in out


def test_notifications_send_push_is_unavailable_and_does_not_claim_sent():
    out = _call(notifications.send_push, user_id="u_42", message="Doors open!")
    assert MARKER in out
    # Old stub said "Push sent to ...". Must never re-emerge.
    assert "Push sent" not in out
