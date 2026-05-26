"""Cost tracker for Claude API calls.

LangChain callback that aggregates token usage and computes USD cost per model,
including prompt-cache reads and writes.

Pricing verified May 2026 from https://docs.claude.com/en/docs/about-claude/pricing
"""

from __future__ import annotations
from dataclasses import dataclass
from typing import Any

from langchain_core.callbacks import BaseCallbackHandler
from langchain_core.outputs import LLMResult


PRICING_PER_MTOK: dict[str, dict[str, float]] = {
    "claude-opus-4-7":   {"input": 5.00, "output": 25.00, "cache_write": 6.25, "cache_read": 0.50},
    "claude-opus-4-6":   {"input": 5.00, "output": 25.00, "cache_write": 6.25, "cache_read": 0.50},
    "claude-sonnet-4-6": {"input": 3.00, "output": 15.00, "cache_write": 3.75, "cache_read": 0.30},
    "claude-haiku-4-5-20251001":  {"input": 1.00, "output":  5.00, "cache_write": 1.25, "cache_read": 0.10},
}


@dataclass
class ModelUsage:
    input_tokens: int = 0
    output_tokens: int = 0
    cache_write_tokens: int = 0
    cache_read_tokens: int = 0
    calls: int = 0

    def cost(self, prices: dict[str, float]) -> float:
        return (
            self.input_tokens         * prices["input"]       / 1_000_000
            + self.output_tokens      * prices["output"]      / 1_000_000
            + self.cache_write_tokens * prices["cache_write"] / 1_000_000
            + self.cache_read_tokens  * prices["cache_read"]  / 1_000_000
        )


class CostTracker(BaseCallbackHandler):
    """Aggregates token usage across models. Pass via callbacks=[tracker]."""

    def __init__(self) -> None:
        self.usage: dict[str, ModelUsage] = {}

    def _resolve_model(self, raw: str | None) -> str:
        if not raw:
            return "unknown"
        for known in PRICING_PER_MTOK:
            if raw.startswith(known):
                return known
        return raw

    def on_llm_end(self, response: LLMResult, **kwargs: Any) -> None:
        model_name = "unknown"
        usage_dict: dict[str, int] = {}

        if response.llm_output:
            model_name = (
                response.llm_output.get("model_name")
                or response.llm_output.get("model")
                or "unknown"
            )
            usage_dict = response.llm_output.get("usage") or {}

        if not usage_dict:
            try:
                msg = response.generations[0][0].message
                meta = getattr(msg, "usage_metadata", None) or {}
                usage_dict = {
                    "input_tokens": meta.get("input_tokens", 0),
                    "output_tokens": meta.get("output_tokens", 0),
                }
                details = meta.get("input_token_details") or {}
                usage_dict["cache_creation_input_tokens"] = details.get("cache_creation", 0)
                usage_dict["cache_read_input_tokens"] = details.get("cache_read", 0)
                if model_name == "unknown":
                    rmeta = getattr(msg, "response_metadata", {}) or {}
                    model_name = rmeta.get("model_name") or rmeta.get("model") or "unknown"
            except (IndexError, AttributeError):
                pass

        if not usage_dict:
            return

        key = self._resolve_model(model_name)
        bucket = self.usage.setdefault(key, ModelUsage())
        bucket.input_tokens       += int(usage_dict.get("input_tokens", 0))
        bucket.output_tokens      += int(usage_dict.get("output_tokens", 0))
        bucket.cache_write_tokens += int(usage_dict.get("cache_creation_input_tokens", 0))
        bucket.cache_read_tokens  += int(usage_dict.get("cache_read_input_tokens", 0))
        bucket.calls              += 1

    def total_cost(self) -> float:
        total = 0.0
        for model, bucket in self.usage.items():
            prices = PRICING_PER_MTOK.get(model)
            if prices:
                total += bucket.cost(prices)
        return total

    def summary(self) -> str:
        lines = ["", "Cost summary", "============"]
        grand = 0.0
        for model, bucket in sorted(self.usage.items()):
            prices = PRICING_PER_MTOK.get(model)
            if not prices:
                lines.append(f"\n{model}: {bucket.calls} calls (no pricing data)")
                continue
            cost = bucket.cost(prices)
            grand += cost
            lines.append(
                f"\n{model}"
                f"\n  calls         : {bucket.calls}"
                f"\n  input tokens  : {bucket.input_tokens:,}"
                f"\n  output tokens : {bucket.output_tokens:,}"
                f"\n  cache writes  : {bucket.cache_write_tokens:,}"
                f"\n  cache reads   : {bucket.cache_read_tokens:,}"
                f"\n  cost          : ${cost:.6f}"
            )
        lines.append(f"\nTotal: ${grand:.6f}")
        return "\n".join(lines)

    def reset(self) -> None:
        self.usage.clear()


def estimate_cost(
    model: str,
    input_tokens: int,
    output_tokens: int,
    cache_write_tokens: int = 0,
    cache_read_tokens: int = 0,
) -> float:
    """Estimate USD cost without hitting the API. Use for budgeting."""
    prices = PRICING_PER_MTOK.get(model)
    if not prices:
        raise ValueError(f"Unknown model: {model}. Known: {list(PRICING_PER_MTOK)}")
    return (
        input_tokens         * prices["input"]       / 1_000_000
        + output_tokens      * prices["output"]      / 1_000_000
        + cache_write_tokens * prices["cache_write"] / 1_000_000
        + cache_read_tokens  * prices["cache_read"]  / 1_000_000
    )
