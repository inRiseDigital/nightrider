import os
from models import PartyResponse
from typing import Annotated, TypedDict, List
from dotenv import load_dotenv
from langchain_anthropic import ChatAnthropic
from langchain_core.messages import BaseMessage, HumanMessage, AIMessage, SystemMessage
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode
from langchain_core.tools import tool
from data_source import get_party_data, AMENITIES_DATA

from langgraph.graph.message import add_messages

load_dotenv()

# Define the state for the graph
class AgentState(TypedDict):
    messages: Annotated[List[BaseMessage], add_messages]

def _slim(event: dict) -> dict:
    """Return only the fields Claude needs — keeps token count small."""
    return {
        'id':         event.get('id', ''),
        'title':      event.get('title', ''),
        'location':   event.get('location', ''),
        'country':    event.get('country', ''),
        'time':       event.get('time', ''),
        'category':   event.get('category', ''),
        'genre':      event.get('genre', ''),
        'price_hint': event.get('price_hint', ''),
        'image':      (event.get('images') or [''])[0],
        'ticket_url': event.get('ticket_url', ''),
    }

# Define tools
@tool
def get_party_list():
    """Returns a list of upcoming parties and events (top 15)."""
    return [_slim(p) for p in get_party_data()[:15]]

@tool
def search_parties(query: str):
    """Searches for parties based on a query string (e.g., 'techno', 'rave', 'Dubai')."""
    query = query.lower()
    results = [
        p for p in get_party_data()
        if (query in p['title'].lower() or
            query in p.get('category', '').lower() or
            query in p.get('description', '').lower() or
            query in p.get('country', '').lower() or
            query in p.get('location', '').lower() or
            query in p.get('genre', '').lower() or
            any(query in a.lower() for a in p.get('artists', [])))
    ]
    return [_slim(p) for p in results[:12]]

@tool
def get_party_details(title: str):
    """Gets detailed information about a specific party by its title."""
    for p in get_party_data():
        if p['title'].lower() == title.lower():
            return _slim(p)
    return f"Party '{title}' not found."

@tool
def search_nearby_amenities(party_id: str):
    """Searches for restaurants or bars near a specific party. Use this to help users plan their night out."""
    results = [a for a in AMENITIES_DATA if a.get('near_party') == party_id]
    return results

@tool
def search_amenities(query: str):
    """Searches for bars and restaurants by location or name (e.g., 'Colombo bars', 'Italian food')."""
    query = query.lower()
    results = [
        a for a in AMENITIES_DATA 
        if (query in a['name'].lower() or 
            query in a.get('category', '').lower() or 
            query in a.get('location', '').lower() or
            query in a.get('description', '').lower() or
            query in a.get('type', '').lower())
    ]
    return results

@tool
def update_user_preferences(preference: str):
    """Saves a user's preference (e.g., 'I love deep house', 'I prefer early events'). This helps personalize future responses."""
    profile_path = "user_profile.json"
    import json
    import os
    profile = {}
    if os.path.exists(profile_path):
        with open(profile_path, "r") as f:
            profile = json.load(f)
    
    preferences = profile.get("preferences", [])
    if preference not in preferences:
        preferences.append(preference)
        profile["preferences"] = preferences
        with open(profile_path, "w") as f:
            json.dump(profile, f)
    return f"Saved preference: {preference}"

@tool
def get_user_profile():
    """Retrieves the current user's saved preferences and history."""
    profile_path = "user_profile.json"
    import json
    import os
    if os.path.exists(profile_path):
        with open(profile_path, "r") as f:
            return json.load(f)
    return {"preferences": []}

tools = [get_party_list, search_parties, get_party_details, search_nearby_amenities, search_amenities, update_user_preferences, get_user_profile]
tool_node = ToolNode(tools)

from models import PartyResponse

# Initialize the LLM with structured output
llm = ChatAnthropic(model="claude-sonnet-4-6", temperature=0)
llm_with_tools = llm.bind_tools(tools)
structured_llm = llm.with_structured_output(PartyResponse)

# Define the node that calls the model
def call_model(state: AgentState):
    messages = state['messages']
    
    # Check if we need to call tools or generate final response
    response = llm_with_tools.invoke(messages)
    
    # If the LLM wants to call tools, return that
    if response.tool_calls:
        return {"messages": [response]}
    
    # Otherwise, force structured output for the final response
    final_response = structured_llm.invoke(messages)
    
    import json
    content = json.dumps(final_response.model_dump())
    return {"messages": [AIMessage(content=content)]}

# Define the routing logic
def should_continue(state: AgentState):
    messages = state['messages']
    last_message = messages[-1]
    
    # If it's a tool call, go to tools
    if hasattr(last_message, 'tool_calls') and last_message.tool_calls:
        return "tools"
    
    # Otherwise, we have our final structured response
    return END

# Build the graph
workflow = StateGraph(AgentState)

workflow.add_node("agent", call_model)
workflow.add_node("tools", tool_node)

workflow.set_entry_point("agent")

workflow.add_conditional_edges(
    "agent",
    should_continue,
)

workflow.add_edge("tools", "agent")

# Compile once at startup — NOT inside get_agent_response()
_app = workflow.compile()

# Minimal System Prompt
SYSTEM_PROMPT = """You are Nightride AI — a sharp, friendly nightlife assistant. You help people find parties and events worldwide.

TONE & STYLE:
- Be conversational and direct. Match the user's energy. Short messages get short replies.
- Never give a formatted "feature list" unless the user specifically asks what you can do.
- When asked "what can you do?" or similar: answer in 1-2 casual sentences, then immediately ask what they're looking for tonight.
- Do NOT use bullet points or headers for simple conversational replies.

IDENTITY:
- You are built by RISE AI (codegen). Never mention OpenAI, ChatGPT, GPT, or any AI model names.

FINDING EVENTS (CRITICAL):
- ALWAYS call `search_parties` or `get_party_list` before answering any event-related question. Never guess or invent events.
- If tools return no results: say "I don't have any events listed for [place] right now."
- Populate `party_recommendations` ONLY when showing event results. Leave it empty for conversation.
- Do not repeat event cards for follow-up questions about the same event — just answer in text.

LOCATION:
- User location [User Location: lat, lon] is provided. Use it to find nearby events when relevant.
- You are global — always search when asked about any city or country.

PERSONALIZATION:
- Save preferences with `update_user_preferences` if a user mentions their taste.
- Check `get_user_profile` when making recommendations for a returning user.
- Offer nearby bars/restaurants via `search_nearby_amenities` after showing an event.
"""

def validate_identity(text: str):
    banned = ["openai", "chatgpt", "gpt-4", "gpt-3.5"]
    if any(b in text.lower() for b in banned):
        # Fallback response for safety
        return "I am an AI agent developed by RISE AI (codegen)."
    return None

def get_agent_response(user_input: str, history: List[BaseMessage] = []):
    messages = [SystemMessage(content=SYSTEM_PROMPT)] + history + [HumanMessage(content=user_input)]
    final_state = _app.invoke({"messages": messages})
    
    last_msg = final_state['messages'][-1].content
    
    # Identity Check
    violation_fix = validate_identity(last_msg)
    if violation_fix:
        # In a real app we might log this violation
        # For now, return a structured error response
        error_response = PartyResponse(
            response_text=violation_fix,
            party_recommendations=[]
        )
        import json
        return json.dumps(error_response.model_dump())
        
    return last_msg
