# Architecture

## Goals

- Six clear specialist agents matching the use case categories.
- One supervisor, cheap to run, that picks one specialist per turn.
- Two memory tiers: short-term per-thread state and long-term per-user state.
- Cost tracking baked in from day one.
- Pluggable tools so each capability can evolve independently.

## Topology

```
START → supervisor ─┬─► event_discovery   ─┐
                    ├─► map_navigator      │
                    ├─► social_companion   │
                    ├─► gamification       ├─► END (one per turn)
                    ├─► night_recap        │
                    └─► safety_support    ─┘
```

The supervisor sets `state.next_agent`, and a conditional edge in `graph.py`
dispatches to the matching node. Each specialist returns to END, so the next
user message re-enters at the supervisor — keeping each turn cheap and bounded.

## Models

| Layer       | Model              | Why                                      |
|-------------|--------------------|------------------------------------------|
| Supervisor  | Claude Haiku 4.5   | Routing is structured + small. ~$1/$5    |
| Specialists | Claude Sonnet 4.6  | Best balance of quality + price. $3/$15  |
| Night Recap | Claude Opus 4.7    | Creative captions/themes benefit. $5/$25 |

All instances are built via `core.llm.make_llm()` so the cost tracker is
attached uniformly.

## Memory

- **Short-term** (`memory/checkpointer.py`): `PostgresSaver` keyed by `thread_id`.
  Holds the message history and `AgentState` between turns.
- **Long-term** (`memory/store.py`): `PostgresStore` keyed by
  `("user", user_id, category)`. Holds preferences, badges, streaks, friend graph,
  event history. Vector-indexed where semantic search helps.

In local dev with no `DATABASE_URL`, both fall back to in-memory implementations.

## Tools

Each specialist gets a tightly scoped tool set — Map Navigator can't generate
recaps, Recap Assistant can't change RSVPs. This is enforced in
`agents/<name>/agent.py` by passing only the relevant tools to
`create_react_agent`.

## Privacy

Stealth mode is a flag on `AgentState`. `social_companion` and `map_navigator`
read it before every external write/post. Toggling is a human-in-the-loop
moment (use `interrupt()` so the user explicitly confirms).

## Cost tracking

`core.cost_tracker.CostTracker` is a `BaseCallbackHandler` attached to every
`ChatAnthropic`. After every model call its `on_llm_end` adds tokens to a
per-model bucket. Call `TRACKER.summary()` for a per-model breakdown or
`TRACKER.total_cost()` for the running USD total.

## Scaling notes

- Use `AsyncPostgresSaver` (not `PostgresSaver`) under FastAPI.
- Cache the supervisor's system prompt — it's identical every turn, and
  caching cuts that input cost by 90%.
- For Night Recap, prefer the Batch API (50% off) since users tolerate
  minutes of latency on async media generation.
- LangGraph Platform handles the checkpointer infra automatically when you
  deploy there.
