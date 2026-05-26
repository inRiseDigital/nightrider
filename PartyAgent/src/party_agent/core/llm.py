"""Single factory for ChatAnthropic instances.

All agents go through this so we get consistent settings (callbacks, temperature)
and so the cost tracker is attached everywhere automatically.
"""

from __future__ import annotations
from langchain_anthropic import ChatAnthropic
from langchain_core.callbacks import BaseCallbackHandler

from party_agent.config import get_settings
from party_agent.core.cost_tracker import CostTracker


# Module-level singleton — every model call in the process shares this tracker.
# Reset between requests if you want per-request cost reporting.
TRACKER = CostTracker()


def make_llm(
    model: str | None = None,
    *,
    temperature: float = 0.3,
    max_tokens: int = 1024,
    extra_callbacks: list[BaseCallbackHandler] | None = None,
) -> ChatAnthropic:
    """Build a ChatAnthropic with cost tracking attached.

    Args:
        model: Model id. Defaults to settings.specialist_model (Sonnet 4.6).
        temperature: Lower = more deterministic. 0.3 is a good agent default.
        max_tokens: Output token cap. Always set this in production.
        extra_callbacks: Additional handlers (e.g. for streaming UI).
    """
    settings = get_settings()
    callbacks: list[BaseCallbackHandler] = [TRACKER]
    if extra_callbacks:
        callbacks.extend(extra_callbacks)

    return ChatAnthropic(
        model=model or settings.specialist_model,
        api_key=settings.anthropic_api_key,
        temperature=temperature,
        max_tokens=max_tokens,
        callbacks=callbacks,
    )


def router_llm() -> ChatAnthropic:
    """Cheap, fast model for the supervisor."""
    return make_llm(get_settings().router_model, temperature=0.0, max_tokens=512)


def specialist_llm() -> ChatAnthropic:
    """Sonnet — for agents that need deep reasoning (event discovery, safety)."""
    return make_llm(get_settings().specialist_model)


def simple_llm() -> ChatAnthropic:
    """Haiku — for agents that do simple DB reads/writes (gamification, social, map, recap).
    ~10x cheaper than Sonnet for straightforward tool calls."""
    return make_llm(get_settings().router_model, max_tokens=1024)


def recap_llm() -> ChatAnthropic:
    """Higher-capability model for creative recap generation."""
    return make_llm(get_settings().recap_model, temperature=0.7, max_tokens=2048)
