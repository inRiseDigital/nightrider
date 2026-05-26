"""Cost tracker tests — pure unit tests, no API calls."""

from party_agent.core.cost_tracker import (
    CostTracker,
    ModelUsage,
    PRICING_PER_MTOK,
    estimate_cost,
)


def test_estimate_cost_sonnet() -> None:
    cost = estimate_cost("claude-sonnet-4-6", input_tokens=1_000_000, output_tokens=0)
    assert cost == 3.00


def test_estimate_cost_with_cache() -> None:
    # 1M cache reads at $0.30/MTok = $0.30 total
    cost = estimate_cost("claude-sonnet-4-6", input_tokens=0, output_tokens=0, cache_read_tokens=1_000_000)
    assert cost == 0.30


def test_haiku_cheaper_than_sonnet() -> None:
    h = estimate_cost("claude-haiku-4-5",  input_tokens=1_000_000, output_tokens=1_000_000)
    s = estimate_cost("claude-sonnet-4-6", input_tokens=1_000_000, output_tokens=1_000_000)
    assert h < s


def test_tracker_aggregates_per_model() -> None:
    tracker = CostTracker()
    tracker.usage["claude-sonnet-4-6"] = ModelUsage(
        input_tokens=10_000, output_tokens=2_000, calls=1,
    )
    tracker.usage["claude-haiku-4-5"] = ModelUsage(
        input_tokens=5_000, output_tokens=500, calls=3,
    )
    expected = (
        10_000 * 3.00 / 1_000_000 + 2_000 * 15.00 / 1_000_000
        + 5_000 * 1.00 / 1_000_000 + 500 * 5.00 / 1_000_000
    )
    assert abs(tracker.total_cost() - expected) < 1e-9


def test_pricing_table_has_current_models() -> None:
    for model in ("claude-opus-4-7", "claude-sonnet-4-6", "claude-haiku-4-5"):
        assert model in PRICING_PER_MTOK
        prices = PRICING_PER_MTOK[model]
        # output is always more expensive than input
        assert prices["output"] > prices["input"]
        # cache_read is the cheapest tier (~10% of input)
        assert prices["cache_read"] < prices["input"]
