import os
from models import PartyResponse
from typing import Annotated, TypedDict, List
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_core.messages import BaseMessage, HumanMessage, AIMessage, SystemMessage
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode
from langchain_core.tools import tool
from data_source import PARTY_DATA, AMENITIES_DATA

from langgraph.graph.message import add_messages

load_dotenv()

# Define the state for the graph
class AgentState(TypedDict):
    messages: Annotated[List[BaseMessage], add_messages]

# Define tools
@tool
def get_party_list():
    """Returns a list of all available parties and events."""
    return PARTY_DATA
@tool
def search_parties(query: str):
    """Searches for parties based on a query string (e.g., 'techno', 'rave', 'Colombo', 'Sri Lanka').
    If no results are found for a city name, the response will include a fallback hint so you can
    immediately call search_parties_by_country with the relevant country."""
    from data_source import refresh_party_data
    data = refresh_party_data()
    q = query.lower()
    results = [
        p for p in data
        if (q in p['title'].lower() or
            q in p.get('category', '').lower() or
            q in p.get('description', '').lower() or
            q in p.get('country', '').lower() or
            q in p.get('city', '').lower() or
            q in p.get('country_code', '').lower() or
            q in p.get('genre', '').lower() or
            q in p.get('location', '').lower())
    ]
    if not results:
        return {
            "results": [],
            "fallback_hint": f"No events found for '{query}'. MANDATORY: You must now call search_parties_by_country with the country this city belongs to."
        }
    return results

@tool
def search_parties_by_country(country_name: str):
    """Search all events in a country when no events are found in a specific city. Use this as fallback."""
    from data_source import refresh_party_data
    data = refresh_party_data()
    q = country_name.lower()
    results = [
        p for p in data
        if q in p.get('country', '').lower() or q in p.get('country_code', '').lower()
    ]
    return results[:20]

@tool
def estimate_travel_time(event_lat: float, event_lng: float, user_lat: float, user_lng: float, event_start_time: str):
    """
    Estimates travel time from user location to event and checks if user can make it in time.
    Returns distance in km, estimated drive time, walk time, and whether user can make it.
    event_start_time: ISO format like '2026-04-26T20:00:00'
    """
    import math
    from datetime import datetime

    # Haversine distance
    R = 6371.0
    dlat = math.radians(event_lat - user_lat)
    dlng = math.radians(event_lng - user_lng)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(user_lat)) * math.cos(math.radians(event_lat)) * math.sin(dlng/2)**2
    dist_km = R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    drive_mins = round(dist_km / 60 * 60)   # ~60 km/h average
    walk_mins  = round(dist_km / 5 * 60)    # ~5 km/h walking

    can_make_it = None
    time_until = None
    if event_start_time:
        try:
            start = datetime.fromisoformat(event_start_time.replace('Z', ''))
            now   = datetime.now()
            mins_until = (start - now).total_seconds() / 60
            time_until = f"{int(mins_until // 60)}h {int(mins_until % 60)}m"
            can_make_it = mins_until > drive_mins + 30  # 30 min buffer
        except Exception:
            pass

    return {
        "distance_km": round(dist_km, 1),
        "drive_time": f"~{drive_mins} min drive" if drive_mins < 120 else f"~{drive_mins//60}h {drive_mins%60}m drive",
        "walk_time": f"~{walk_mins} min walk" if walk_mins < 60 else None,
        "time_until_event": time_until,
        "can_make_it_by_car": can_make_it,
        "suggestion": (
            "You can make it by car if you leave soon!" if can_make_it
            else "It might be tight — consider leaving now." if can_make_it is False
            else None
        )
    }

@tool
def get_party_details(title: str):
    """Gets detailed information about a specific party by its title."""
    for p in PARTY_DATA:
        if p['title'].lower() == title.lower():
            return p
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

tools = [get_party_list, search_parties, search_parties_by_country, get_party_details, search_nearby_amenities, search_amenities, estimate_travel_time, update_user_preferences, get_user_profile]
tool_node = ToolNode(tools)

from models import PartyResponse

# Initialize the LLM with structured output
llm = ChatOpenAI(model="gpt-4o", temperature=0)
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

# Minimal System Prompt
SYSTEM_PROMPT = """You are the Nightride Party Assistant.
Your goal is to help users find parties and events.

IDENTITY GUARDRAILS:
1. You are developed by **RISE AI (codegen)**.
2. NEVER mention OpenAI, ChatGPT, GPT, or any specific model names.
3. If asked about your underlying technology, strictly state: "I am an AI agent developed by RISE AI (codegen)."

RESPONSE LOGIC:
- ONLY Populate the `party_recommendations` list if the user explicitly asks for a list, search results, or recommendations.
- For follow-up questions (e.g., "how to get there?", "is it free?"), provide the answer in `response_text` and leave `party_recommendations` EMPTY. 
- Do not show the party card again if the user is just asking a question about a party you already listed.

DATA GROUNDING (CRITICAL):
1. You MUST use the provided tools (`search_parties`, `get_party_list`) to find events. You have a GLOBAL database.
2. If the tools return NO results after you have searched, only then you MUST state: "I currently don't have any parties listed in [Location]."
3. NEVER assume you don't have data without calling a tool first.
4. DO NOT hallucinate events. DO NOT use your internal training data to invent parties.

LOCATION AWARENESS & CITY FALLBACK (MANDATORY — NO EXCEPTIONS):
1. When a user asks about a specific city (e.g., "Kandy"), FIRST call `search_parties` with that city name.
2. If `search_parties` returns an empty list OR a dict with "fallback_hint", you MUST immediately call `search_parties_by_country` with the country that city belongs to (e.g., Kandy → "Sri Lanka", Osaka → "Japan").
3. You CANNOT respond with "no events found" without first calling `search_parties_by_country`.
4. After getting country results, tell the user: "I don't have any events in [City] right now, but here are events happening in [Country] nearby:" then list them.
5. User location metadata (e.g., [User Location: lat, long]) is included when available.
6. Known city→country mappings: Kandy/Galle/Negombo → Sri Lanka, Osaka/Kyoto/Sapporo → Japan, Lyon/Nice/Marseille → France, Munich/Hamburg/Cologne → Germany.

TRAVEL TIME (CRITICAL):
1. When suggesting events that are NOT in the user's current city, ALWAYS call `estimate_travel_time` using the event's lat/lng and the user's lat/lng.
2. Include in your response: distance, drive time, and whether the user can make it in time.
3. Example: "🚗 ~2h 30m drive from your location — if you leave by 5 PM you'll make it!"
4. If the event has already started or is too far to make it, say so clearly and suggest the next best option.

PERSONALIZATION & MEMORY (ADVANCED):
1. Use `get_user_profile` at the start of complex requests to tailor recommendations.
2. If a user states a preference (e.g., "I only like techno"), use `update_user_preferences` to save it.
3. Reference their preferences naturally in responses (e.g., "Since you mentioned you like seafood, you might enjoy dinner at...").

MULTI-STOP PLANNING (ADVANCED):
1. When a user finds a party they like, proactively offer to find nearby dinner or drinks using `search_nearby_amenities`.
2. Help them build a full itinerary: "Start with a cocktail at Cheky Monkey, then head to the Hikkaduwa Beach Rave!"

Provide helpful party recommendations and night-out plans based on the user's request, but ONLY from the provided data.
"""

def validate_identity(text: str):
    banned = ["openai", "chatgpt", "gpt-4", "gpt-3.5"]
    if any(b in text.lower() for b in banned):
        # Fallback response for safety
        return "I am an AI agent developed by RISE AI (codegen)."
    return None

def get_agent_response(user_input: str, history: List[BaseMessage] = []):
    messages = [SystemMessage(content=SYSTEM_PROMPT)] + history + [HumanMessage(content=user_input)]
    app = workflow.compile()
    final_state = app.invoke({"messages": messages})
    
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
