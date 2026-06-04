"""POST /chat — main entrypoint for the conversational agent."""

from __future__ import annotations

import asyncio
import json
import logging
import traceback
from typing import AsyncGenerator

import httpx
from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse

from party_agent.api.schemas import ChatRequest, ChatResponse, StreamChatRequest
from party_agent.core.llm import TRACKER
from party_agent.core.suggestions import generate_suggestions

log = logging.getLogger(__name__)
router = APIRouter(prefix="/chat", tags=["chat"])


def _is_placeholder_gps(lat: float, lng: float) -> bool:
    """Return True for default/null GPS values sent by Swagger UI or uninitialised clients."""
    return (lat == 0.0 and lng == 0.0) or (lat == -90.0 and lng == -180.0)


async def _reverse_geocode(lat: float, lon: float) -> str:
    """Convert GPS coords to a human-readable address using OpenStreetMap Nominatim."""
    try:
        async with httpx.AsyncClient(timeout=4.0) as client:
            r = await client.get(
                "https://nominatim.openstreetmap.org/reverse",
                params={"lat": lat, "lon": lon, "format": "json"},
                headers={"User-Agent": "NightrideApp/1.0"},
            )
            data = r.json()
            addr = data.get("address", {})
            # Build a readable label: place name + suburb/district + city + country
            parts = [
                addr.get("amenity") or addr.get("building") or addr.get("tourism")
                or addr.get("leisure") or addr.get("shop") or addr.get("office"),
                addr.get("road"),
                addr.get("suburb") or addr.get("neighbourhood") or addr.get("village"),
                addr.get("city") or addr.get("town") or addr.get("county"),
                addr.get("state"),
                addr.get("country"),
            ]
            return ", ".join(p for p in parts if p)
    except Exception:
        return f"{lat:.5f}, {lon:.5f}"  # fallback to raw coords on network error


@router.post("", response_model=ChatResponse)
async def chat(req: ChatRequest, request: Request) -> ChatResponse:
    # Graph is built once during the app's lifespan and stashed on app.state
    # so the async Postgres checkpointer pool stays alive across requests.
    graph = request.app.state.graph
    # Build message with location context injected so agents can use it
    message_content = req.message
    if req.gps and not _is_placeholder_gps(req.gps.latitude, req.gps.longitude):
        address = await _reverse_geocode(req.gps.latitude, req.gps.longitude)
        gps_context = f"[User location: {address}] {req.message}"
        message_content = gps_context

    # Only pass keys that exist on AgentState — passing unknown keys (e.g. `gps`)
    # raises an unhelpful empty-string exception inside LangGraph. GPS context is
    # already prepended to message_content above, so the agents still see it.
    state_input: dict = {
        "messages": [("user", message_content)],
        "user_id": req.user_id,
    }
    if req.city is not None:
        state_input["city"] = req.city

    try:
        result = await graph.ainvoke(
            state_input,
            config={"configurable": {"thread_id": req.thread_id, "user_id": req.user_id}},
        )
    except Exception as exc:
        tb = traceback.format_exc()
        log.error("chat handler failed for thread=%s user=%s\n%s",
                  req.thread_id, req.user_id, tb)

        exc_name = type(exc).__name__
        if "AuthenticationError" in exc_name or "401" in str(exc):
            raise HTTPException(
                status_code=503,
                detail="AI service unavailable: invalid API key. Update ANTHROPIC_API_KEY in .env and restart.",
            ) from exc

        detail = f"{exc_name}: {exc}" if str(exc) else exc_name
        raise HTTPException(status_code=500, detail=detail) from exc

    last = result["messages"][-1]
    reply_text = last.content if hasattr(last, "content") else str(last)
    return ChatResponse(
        reply=reply_text,
        routed_to=result.get("next_agent"),
        cost_usd_so_far=TRACKER.total_cost(),
        suggestions=generate_suggestions(req.message, reply_text),
    )


@router.post("/stream")
async def chat_stream(req: StreamChatRequest, request: Request) -> StreamingResponse:
    """SSE endpoint consumed by the Flutter app. Wraps the same graph as /chat."""
    graph = request.app.state.graph

    async def _generate() -> AsyncGenerator[str, None]:
        message_content = req.message
        if (req.latitude is not None and req.longitude is not None
                and not _is_placeholder_gps(req.latitude, req.longitude)):
            address = await _reverse_geocode(req.latitude, req.longitude)
            message_content = f"[User location: {address}] {req.message}"

        thread_id = req.thread_id or req.user_id
        state_input: dict = {
            "messages": [("user", message_content)],
            "user_id": req.user_id,
        }

        try:
            result = await asyncio.wait_for(
                graph.ainvoke(
                    state_input,
                    config={"configurable": {"thread_id": thread_id, "user_id": req.user_id}},
                ),
                timeout=30.0,
            )
            last = result["messages"][-1]
            reply_text = last.content if hasattr(last, "content") else str(last)
            data = {
                "type": "text",
                "text": reply_text,
                "suggestions": generate_suggestions(req.message, reply_text),
                "routed_to": result.get("next_agent"),
            }
            yield f"data: {json.dumps(data)}\n\n"
        except asyncio.TimeoutError:
            log.error("chat_stream timed out for thread=%s", thread_id)
            yield f"data: {json.dumps({'type': 'error', 'text': 'The agent took too long to respond. Please try again.'})}\n\n"
        except Exception as exc:
            log.error("chat_stream failed: %s", exc)
            yield f"data: {json.dumps({'type': 'error', 'text': str(exc)})}\n\n"

        yield "data: [DONE]\n\n"

    return StreamingResponse(_generate(), media_type="text/event-stream")
