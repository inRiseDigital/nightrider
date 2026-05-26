"""Dynamic follow-up suggestion generator.

Produces 2-3 short tappable chips relevant to the latest exchange. Replaces the
mobile app's hardcoded "What's happening tonight? / Find Techno parties" chips.

Uses the cheap router model (Haiku) — adds <1c per turn.
"""

from __future__ import annotations

import json
import re

from langchain_core.messages import SystemMessage, HumanMessage

from party_agent.core.llm import router_llm


_SYSTEM = """You generate 2-3 short follow-up tap suggestions ("chips") for a nightlife
chat app. Each chip becomes a button the user taps to send that exact text as their
next message.

Rules:
- Output ONLY a JSON array of strings. No prose, no keys, no markdown fences.
- 2 to 3 items. Each chip max 32 characters.
- Chips must be DIRECTLY related to what the assistant just said and progress the
  conversation. Do NOT repeat generic prompts like "What's happening tonight?".
- Phrase as something the user would tap — first person or imperative.
  Good: "Navigate to Empire Café", "Show me techno instead", "Book a tuk-tuk".
  Bad: "Empire Café", "Techno", "Click here".
- If the assistant suggested a venue, include a chip to navigate or get directions.
- If the assistant suggested a party in another area, include one chip about the
  ride/transport and one about more options nearby.
- Mirror the user's language style if they wrote in Sinhala, Hindi, Spanish, etc.
"""

_FALLBACK = ["More options", "Navigate there", "Book a ride"]


def _parse(raw: str) -> list[str]:
    """Best-effort JSON-array extraction with a regex fallback."""
    raw = raw.strip()
    # Strip accidental ```json fences.
    raw = re.sub(r"^```(?:json)?\s*|\s*```$", "", raw, flags=re.IGNORECASE).strip()
    try:
        data = json.loads(raw)
        if isinstance(data, list):
            return [str(x).strip() for x in data if str(x).strip()]
    except (json.JSONDecodeError, ValueError):
        pass
    # Fallback: pull quoted strings out.
    return re.findall(r'"([^"]{1,40})"', raw)


def generate_suggestions(user_message: str, assistant_reply: str) -> list[str]:
    """Produce 2-3 contextual chips for the next turn.

    Failures are non-fatal — return a small generic fallback so the UI still has chips.
    """
    if not assistant_reply.strip():
        return []
    try:
        llm = router_llm()
        resp = llm.invoke([
            SystemMessage(content=_SYSTEM),
            HumanMessage(
                content=(
                    f"User said: {user_message.strip()[:500]}\n\n"
                    f"Assistant replied: {assistant_reply.strip()[:1500]}\n\n"
                    "Output JSON array only."
                )
            ),
        ])
        chips = _parse(getattr(resp, "content", "") or "")
        chips = [c[:32] for c in chips if c][:3]
        return chips or _FALLBACK[:2]
    except Exception:
        return _FALLBACK[:2]
