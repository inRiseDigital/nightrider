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

Requires Python 3.11+.

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
python run_server.py
```

**Use `python run_server.py`, not the bare `uvicorn` CLI.** On Windows, psycopg's async pool requires a `SelectorEventLoop`, which the script forces before anything else imports asyncio (see its module docstring) — bare `uvicorn party_agent.api.main:app` resets the loop to Proactor and breaks the async Postgres pool.

By default `/chat` and `/chat/stream` require a verified-email Firebase ID token (`AUTH_ENFORCED=true`, checked in `api/auth.py`). For local dev without a `firebase_service_account.json`, set `AUTH_ENFORCED=false` in `.env`, or point at a local Auth emulator via `FIREBASE_AUTH_EMULATOR_HOST`/`GOOGLE_CLOUD_PROJECT` (real shell env vars, not `.env` — see the root `LOCAL_DEV.md`).

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
| `src/party_agent/api/`            | FastAPI HTTP layer — chat streaming (`routes/chat.py`, Firebase-auth gated), maps proxy (`routes/maps.py`) |
| `scripts/`                        | `run_local.py` (CLI sanity check), `seed_events.py`, `refresh_events.py`, `migrate_db.py`, `dump_events.py`, `check_crawler.py` |
| `tests/`                          | Unit + integration tests                     |
| `evals/`                          | LangSmith eval datasets and runners          |

## Cost tracking

Every model call is tallied by `core.cost_tracker.CostTracker`, which is attached
as a callback to every `ChatAnthropic` instance. Run `python scripts/run_local.py`
and you'll see a per-model breakdown at the end.

## Status

The backend is fully built: all 6 specialists, supervisor routing, the Postgres checkpointer, the FastAPI HTTP layer (chat streaming + maps proxy), and Firebase auth gating are implemented and running. `docs/architecture.md` describes the original design and build plan — read it for the full design, but treat any of its still-open steps as historical rather than an active to-do list.
