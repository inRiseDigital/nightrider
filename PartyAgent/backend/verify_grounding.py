from agent import get_agent_response
import json

def test_grounding():
    with open("verification_log.txt", "w", encoding="utf-8") as f:
        def log(msg):
            print(msg)
            f.write(msg + "\n")
            
        log("Testing 'Parties in Japan' (Should only return DB data)...")
        # Ensure imports worked
        log("Calling get_agent_response...")
        try:
            response_json = get_agent_response("Show me parties in Japan")
            log(f"Raw response: {response_json}")
            data = json.loads(response_json)
        except Exception as e:
            log(f"CRITICAL ERROR: {e}")
            return

        recommendations = data.get('party_recommendations', [])
        titles = [p['title'] for p in recommendations]
        log(f"Returned titles: {titles}")
        
        # Check for valid party
        if "Tokyo City Lights Festival" in titles:
            log("✅ Correctly found 'Tokyo City Lights Festival'.")
        else:
            log("❌ FAILED to find 'Tokyo City Lights Festival'.")
            
        # Check for hallucinations
        hallucinations = ["Ultra Japan", "EDC Japan", "Wired Music Festival"]
        found_hallucinations = [h for h in hallucinations if h in titles]
        
        if not found_hallucinations:
            log("✅ No hallucinations found.")
        else:
            log(f"❌ HALLUCINATION ALERT! Found: {found_hallucinations}")

        log("\nTesting 'Parties in Mars' (Should return nothing)...")
        response_json_mars = get_agent_response("Show me parties in Mars")
        data_mars = json.loads(response_json_mars)
        
        if not data_mars.get('party_recommendations'):
             log("✅ Correctly returned no parties for Mars.")
        else:
             log(f"❌ HALLUCINATION ALERT! Found parties in Mars: {data_mars['party_recommendations']}")
             
        if "don't have any parties" in data_mars['response_text'].lower() or "no parties" in data_mars['response_text'].lower():
            log("✅ Correctly stated no info.")
        else:
            log(f"⚠️ Response text might be ambiguous: {data_mars['response_text']}")

if __name__ == "__main__":
    test_grounding()
