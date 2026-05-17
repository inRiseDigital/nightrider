import logging
from collections import defaultdict
from contextlib import asynccontextmanager
from time import time

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.events import EVENT_JOB_ERROR
from agent import get_agent_response
from langchain_core.messages import HumanMessage, AIMessage
from ticketmaster_sync import fetch_and_sync_events as tm_sync
from mytickets_sync import fetch_and_sync_events as mt_sync
from data_source import refresh_party_data

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

scheduler = AsyncIOScheduler()

# ── Simple in-memory rate limiter ────────────────────────────────────────────
_rate_limits: dict[str, list[float]] = defaultdict(list)
_RATE_WINDOW = 60       # seconds
_RATE_MAX_CHAT = 20     # requests per window per IP
_RATE_MAX_ADMIN = 2     # sync/refresh requests per window per IP

def _is_rate_limited(ip: str, limit: int) -> bool:
    now = time()
    window_start = now - _RATE_WINDOW
    calls = [t for t in _rate_limits[ip] if t > window_start]
    calls.append(now)
    _rate_limits[ip] = calls
    if len(_rate_limits) > 5000:
        oldest = next(iter(_rate_limits))
        del _rate_limits[oldest]
    return len(calls) > limit

def _client_ip(request: Request) -> str:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"

# ── APScheduler error listener ───────────────────────────────────────────────
def _on_job_error(event):
    logger.error(f"[scheduler] Job {event.job_id} failed: {event.exception}", exc_info=True)

async def _scheduled_mt_sync():
    logger.info("[scheduler] Running mytickets.lk sync...")
    try:
        result = await mt_sync()
        logger.info(f"[scheduler] mytickets.lk sync done: {result}")
    except Exception as exc:
        logger.error(f"[scheduler] mytickets.lk sync FAILED: {exc}", exc_info=True)

@asynccontextmanager
async def lifespan(app: FastAPI):
    scheduler.add_listener(_on_job_error, EVENT_JOB_ERROR)
    scheduler.add_job(_scheduled_mt_sync, "interval", hours=6, id="mt_sync", replace_existing=True)
    scheduler.start()
    await _scheduled_mt_sync()
    yield
    scheduler.shutdown()

app = FastAPI(title="Nightride Party Agent API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatMessage(BaseModel):
    role: str  # 'user' or 'assistant'
    content: str

class ChatRequest(BaseModel):
    message: str
    history: Optional[List[ChatMessage]] = []
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class ChatResponse(BaseModel):
    response: str
    suggestions: List[str] = []

class InteractionRequest(BaseModel):
    message_id: str
    type: str   # 'like' or 'heart'
    value: bool

_interactions: dict[str, bool] = {}

@app.get("/")
async def root():
    return {"message": "Nightride Party Agent API is running"}

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest, req: Request):
    if _is_rate_limited(_client_ip(req), _RATE_MAX_CHAT):
        raise HTTPException(status_code=429, detail="Rate limit exceeded. Please wait a moment.")
    try:
        history = []
        for msg in request.history:
            if msg.role == 'user':
                history.append(HumanMessage(content=msg.content))
            else:
                history.append(AIMessage(content=msg.content))

        user_message = request.message
        if request.latitude is not None and request.longitude is not None:
            user_message += f" [User Location: {request.latitude:.4f}, {request.longitude:.4f}]"

        import json
        response_json = get_agent_response(user_message, history)
        data = json.loads(response_json)
        markdown_response = data['response_text']

        if data['party_recommendations']:
            markdown_response += "\n\n"
            for party in data['party_recommendations']:
                markdown_response += f"- **{party['title']}**\n"
                if party['images']:
                    img_markdown = " ".join([f"![thumbnail]({img})" for img in party['images']])
                    markdown_response += f"  - {img_markdown}\n"
                markdown_response += f"  - **Location**: {party['location']}, **{party['country']}**\n"
                markdown_response += f"  - **Time**: {party['time']}\n"

        return ChatResponse(
            response=markdown_response,
            suggestions=data.get('suggested_questions', []),
        )
    except Exception as e:
        logger.error("Chat endpoint error", exc_info=True)
        raise HTTPException(status_code=500, detail="Something went wrong. Please try again.")

@app.post("/interaction")
async def interaction(request: InteractionRequest):
    key = f"{request.message_id}_{request.type}"
    if len(_interactions) > 10000:
        _interactions.clear()
    _interactions[key] = request.value
    return {"status": "success"}

@app.post("/sync")
async def sync_events(req: Request):
    """Pull events from Ticketmaster and save them to Firestore."""
    if _is_rate_limited(_client_ip(req), _RATE_MAX_ADMIN):
        raise HTTPException(status_code=429, detail="Rate limit exceeded.")
    try:
        result = await tm_sync()
        return result
    except Exception as e:
        logger.error("Ticketmaster sync error", exc_info=True)
        raise HTTPException(status_code=500, detail="Sync failed. Check server logs.")

@app.post("/sync/srilanka")
async def sync_srilanka(req: Request):
    """Pull live events from mytickets.lk and save them to Firestore."""
    if _is_rate_limited(_client_ip(req), _RATE_MAX_ADMIN):
        raise HTTPException(status_code=429, detail="Rate limit exceeded.")
    try:
        result = await mt_sync()
        return result
    except Exception as e:
        logger.error("mytickets.lk sync error", exc_info=True)
        raise HTTPException(status_code=500, detail="Sync failed. Check server logs.")

@app.post("/refresh")
async def refresh_events(req: Request):
    """Bust the in-memory cache so the agent picks up newly added events."""
    if _is_rate_limited(_client_ip(req), _RATE_MAX_ADMIN):
        raise HTTPException(status_code=429, detail="Rate limit exceeded.")
    try:
        events = refresh_party_data()
        return {"status": "ok", "event_count": len(events)}
    except Exception as e:
        logger.error("Refresh error", exc_info=True)
        raise HTTPException(status_code=500, detail="Refresh failed. Check server logs.")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
