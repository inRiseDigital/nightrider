"""Shared helper for tool stubs that aren't wired to real systems yet.

Stub tools used to return hardcoded fake responses like
``"[stub] 3 taxi stands near 6.9,79.8"`` which the agent then presented to the
user as real data. That was a product-trust problem (users get wrong info)
rather than a security one.

Instead, stubs now return a clear ``[FEATURE_NOT_LIVE]`` prefix that the LLM
agent reads and surfaces honestly. The marker is intentionally distinctive so
it can be grep'd, tested, and audited — never invent fake data again.
"""

from __future__ import annotations


_MARKER = "[FEATURE_NOT_LIVE]"


def unavailable(feature: str, *, eta: str = "next sprint", suggestion: str | None = None) -> str:
    """Return a structured \"feature unavailable\" message for a stub tool.

    The format is deliberately rigid so:
      - the LLM agent passes it through to the user verbatim or paraphrases
        honestly ("This feature isn't live yet...")
      - tests can assert on the marker without coupling to copy
      - greps can audit every unwired surface in one search

    Args:
        feature: Plain-English description of what's not yet available
                 (e.g. "venue directions", "ride booking", "friend RSVPs").
        eta: When users can expect this. Defaults to "next sprint" to avoid
             over-promising specific dates.
        suggestion: Optional fallback to suggest to the user
                    (e.g. "open your maps app for directions instead").
    """
    parts = [
        f"{_MARKER} {feature} is not live yet — wired up for {eta}.",
        "Tell the user honestly that this feature is in development.",
    ]
    if suggestion:
        parts.append(f"Suggest instead: {suggestion}")
    return " ".join(parts)
