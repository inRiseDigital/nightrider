from agent import get_agent_response
import json

def test_response_logic():
    print("Testing 'Show me techno parties'...")
    response_json = get_agent_response("Show me techno parties")
    data = json.loads(response_json)
    
    if data['party_recommendations']:
        print("✅ Party recommendations present for search query.")
    else:
        print("❌ Party recommendations MISSING for search query.")
        
    print("\nTesting 'How do I get to the first one?'...")
    # mimic context
    history = [] 
    # In a real scenario, we'd pass the actual history, but for this test, 
    # we just want to see if the agent *generates* cards for a non-search query.
    # We can pass the previous response as history to give it context.
    from langchain_core.messages import AIMessage, HumanMessage
    history.append(HumanMessage(content="Show me techno parties"))
    history.append(AIMessage(content=data['response_text'])) # slightly simplified history
    
    response_json_followup = get_agent_response("How do I get there?", history)
    data_followup = json.loads(response_json_followup)
    
    if not data_followup['party_recommendations']:
        print("✅ Party recommendations CORRECTLY omitted for follow-up.")
    else:
         print("❌ Party recommendations INCORRECTLY included for follow-up.")

if __name__ == "__main__":
    test_response_logic()
