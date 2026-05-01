from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from agent import get_agent_response
from langchain_core.messages import HumanMessage, AIMessage
from ticketmaster_sync import fetch_and_sync_events
from data_source import refresh_party_data

app = FastAPI(title="Nightride Party Agent API")

# CORS — required so the Flutter web build (any origin) can call this API
# from a browser. Without this, browsers block the POST after preflight.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatMessage(BaseModel):
    role: str # 'user' or 'assistant'
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
    type: str  # 'like' or 'heart'
    value: bool

# Mock interaction storage for now
interactions = {}

@app.get("/")
async def root():
    return {"message": "Nightride Party Agent API is running"}

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        # Convert history to LangChain format
        history = []
        for msg in request.history:
            if msg.role == 'user':
                history.append(HumanMessage(content=msg.content))
            else:
                history.append(AIMessage(content=msg.content))
        
        # Append location context if provided
        user_message = request.message
        if request.latitude is not None and request.longitude is not None:
            user_message += f" [User Location: {request.latitude:.4f}, {request.longitude:.4f}]"
        
        response_json = get_agent_response(user_message, history)
        
        # Parse the structured response
        import json
        data = json.loads(response_json)
        
        # Convert structured data back to Markdown for the frontend
        markdown_response = data['response_text']
        
        if data['party_recommendations']:
            markdown_response += "\n\n"
            for party in data['party_recommendations']:
                markdown_response += f"- **{party['title']}**\n"
                
                # Handle images
                if party['images']:
                    img_markdown = " ".join([f"![thumbnail]({img})" for img in party['images']])
                    markdown_response += f"  - {img_markdown}\n"
                
                markdown_response += f"  - **Location**: {party['location']}, **{party['country']}**\n"
                markdown_response += f"  - **Time**: {party['time']}\n"
        
        # Extract suggested questions from AI response
        suggested_questions = data.get('suggested_questions', [])
        
        return ChatResponse(response=markdown_response, suggestions=suggested_questions)
    except Exception as e:
        print(f"Error processing request: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/interaction")
async def interaction(request: InteractionRequest):
    key = f"{request.message_id}_{request.type}"
    interactions[key] = request.value
    print(f"Interaction recorded: {key} = {request.value}")
    return {"status": "success"}

@app.post("/sync")
async def sync_events():
    """Pull events from Ticketmaster and save them to Firestore."""
    try:
        result = await fetch_and_sync_events()
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/refresh")
async def refresh_events():
    """Bust the in-memory cache so the agent picks up newly added events."""
    try:
        events = refresh_party_data()
        return {"status": "ok", "event_count": len(events)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
