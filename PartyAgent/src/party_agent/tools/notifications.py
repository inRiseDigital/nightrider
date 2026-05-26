"""Notifications tool — NOT YET WIRED.

Will integrate APNs / FCM / SendGrid via per-channel integrations. Returns an
honest unavailable marker for now — must NEVER report "push sent" without an
actual delivery, since users will rely on that.
"""
from langchain_core.tools import tool

from party_agent.tools._unavailable import unavailable


@tool
def send_push(user_id: str, message: str) -> str:
    """Send a push notification to user_id."""
    return unavailable(
        "push notification delivery",
        suggestion=(
            "do NOT claim a notification was sent; tell the user push isn't "
            "live yet and offer to keep the reminder in the conversation"
        ),
    )
