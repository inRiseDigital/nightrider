# Deployment

Two paths.

## Self-host (FastAPI + Docker)
```bash
docker build -t party-agent .
docker run -p 8000:8000 --env-file .env party-agent
```
Front it with a load balancer. Use a managed Postgres + Redis.

## LangGraph Platform
The simplest path. `langgraph deploy` from the repo root after adding
`langgraph.json`. Platform handles checkpointer infra, threads, scaling.
See https://docs.langchain.com/langgraph-platform
