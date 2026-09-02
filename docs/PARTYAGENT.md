# `PartyAgent/` — AI chat backend

Python / FastAPI service behind the app's chat screen. LangGraph supervisor routes each
user message to one of six specialist agents; agents call tools, tools call external
data sources or Firestore.

## Graph

`src/party_agent/graph.py` builds: `START → supervisor → <specialist> → END`.
`supervisor/router.py` uses a cheap Haiku model with structured output to pick a
specialist name into `state.next_agent`; a conditional edge dispatches. Prompt in
`supervisor/prompts.py`.

| Agent (`agents/`) | Purpose | Spec doc |
|---|---|---|
| `event_discovery` | Find events/parties matching intent | `agent1_event_discovery.md` |
| `map_navigator` | Places, routes, getting there | `agent2_party_map_navigator.md` |
| `social_companion` | Social/group suggestions | `agent3_social_companion.md` |
| `gamification` | Ranks, badges, challenges | `agent4_gamification.md` |
| `night_recap` | After-the-night summary | `agent5_night_recap.md` |
| `safety_support` | Safety, help, de-escalation | `agent6_safety_support.md` |

Each agent dir is `agent.py` + `prompts.py`; `agents/_md_loader.py` pulls the spec
markdown in, so the `agent*_*.md` files at the package root are live inputs, not docs.

## HTTP API (`api/`)

`main.py` (lifespan-managed DB connect, CORS, routers) mounts:

- `routes/health.py` — health check.
- `routes/chat.py` — `POST /chat` and `POST /chat/stream` (SSE). Handles placeholder-GPS
  detection and reverse geocoding of the caller's coordinates.
- `routes/maps.py` — `GET /maps/place/search`, `GET /maps/place/{place_id}`,
  `GET /maps/travel`, `POST /maps/events/rank-by-location`.

`api/auth.py` verifies the Firebase ID token; `api/schemas.py` holds request/response
models.

## Supporting packages (`src/party_agent/`)

| Package | Contents |
|---|---|
| `tools/` | Agent-callable tools: `events`, `maps`, `travel`, `rides`, `crowd`, `weather`, `media`, `social_graph`, `gamification`, `notifications`, `_unavailable` (graceful stub when a key is missing) |
| `integrations/` | External providers: `ticketmaster`, `eventbrite`, `predicthq`, `serpapi`, `web_events`, `crawler`, `google_maps`, `nominatim`, `geocoding`, `openweather`, `uber`, `instagram`, `tiktok`, `scheduler` |
| `core/` | `llm` (model selection), `prompts`, `state` (`AgentState`, `SpecialistName`), `suggestions`, `cost_tracker`, `observability` |
| `memory/` | `checkpointer` (conversation state), `store`, `retrieval`, `schemas` |
| `data/` | `events_db`, `users_db`, `models`, `vector_index` |
| `safety/` | `content_filter`, `privacy`, `stealth` |
| `config.py` | Settings / env |

## Ops

- `run_server.py`, `Dockerfile`, `docker-compose.yml`.
- `scripts/` — `run_local.py`, `seed_events.py`, `refresh_events.py`, `dump_events.py`,
  `migrate_db.py`, `check_crawler.py`.
- `tests/` (pytest), `evals/` (agent quality evals).
- `docs/architecture.md`, `docs/agents.md`, `docs/deployment.md` — deeper than this file
  for graph internals and deploy.

Never commit `firebase_service_account.json` or `.env`.

See also: `FLUTTER_APP.md` (the client), `../LOCAL_DEV.md`.
