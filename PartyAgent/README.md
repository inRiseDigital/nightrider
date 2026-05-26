# Party Chat Agent

A conversational AI nightlife companion for Dubai, Tokyo, London, and Melbourne.
Built on **LangGraph** (multi-agent orchestration) + **Claude** (reasoning).

## Architecture at a glance

```
User → Supervisor → one of 6 specialist agents → tools → external APIs
                          ↑                ↓
                  short-term + long-term memory
```

The six specialists, each in `src/party_agent/agents/`:

| Agent              | Owns                                              |
|--------------------|---------------------------------------------------|
| event_discovery    | Search events, mood-based suggestions, culture    |
| map_navigator      | Geo, filters, routing, hidden gems                |
| social_companion   | Friends, RSVPs, stealth mode, group invites       |
| gamification       | Badges, streaks, levels, hidden rewards           |
| night_recap        | Photo/video curation, themes, captions, sharing   |
| safety_support     | Crowd, queue, weather, rides, exits, safety tips  |

## Quick start

```bash
# 1. Set up the environment
cp .env.example .env
# edit .env and paste your ANTHROPIC_API_KEY

# 2. Install dependencies
pip install -r requirements.txt

# 3. Optional: bring up Postgres + Redis for memory
docker-compose up -d

# 4. Run the CLI for a quick sanity check
python scripts/run_local.py

# 5. Start the FastAPI server
uvicorn party_agent.api.main:app --reload --port 8000
```

## Folder map

| Path                              | What lives here                              |
|-----------------------------------|----------------------------------------------|
| `src/party_agent/config.py`       | Settings + env loading                       |
| `src/party_agent/graph.py`        | The compiled `StateGraph`                    |
| `src/party_agent/core/`           | Cross-cutting (LLM factory, state, prompts)  |
| `src/party_agent/supervisor/`     | Intent routing + handoff tools               |
| `src/party_agent/agents/<name>/`  | One folder per specialist                    |
| `src/party_agent/tools/`          | Tools the agents call                        |
| `src/party_agent/memory/`         | Checkpointer + long-term Store               |
| `src/party_agent/data/`           | DB models, vector index                      |
| `src/party_agent/integrations/`   | External API clients (raw)                   |
| `src/party_agent/safety/`         | Privacy, stealth mode, content filters       |
| `src/party_agent/api/`            | FastAPI HTTP layer                           |
| `scripts/`                        | One-off CLI tools (seed, migrate, run)       |
| `tests/`                          | Unit + integration tests                     |
| `evals/`                          | LangSmith eval datasets and runners          |

## Cost tracking

Every model call is tallied by `core.cost_tracker.CostTracker`, which is attached
as a callback to every `ChatAnthropic` instance. Run `python scripts/run_local.py`
and you'll see a per-model breakdown at the end.

## Build order

1. Verify your key works: `python scripts/run_local.py`
2. Implement one specialist end-to-end (start with `event_discovery`)
3. Hook up real Postgres checkpointer in `memory/checkpointer.py`
4. Add the supervisor with handoff tools
5. Add the remaining 5 specialists, one at a time
6. Wire human-in-the-loop interrupts for RSVP/stealth-mode confirmations
7. Add the FastAPI HTTP layer
8. Deploy

See `docs/architecture.md` for the full design.
