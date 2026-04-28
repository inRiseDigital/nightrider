from agent import get_agent_response
import json

# Test AI-generated suggestions
response = get_agent_response("What's happening tonight?", [])
data = json.loads(response)

print("Response:", data['response_text'])
print("\nAI-Generated Suggestions:")
for i, suggestion in enumerate(data.get('suggested_questions', []), 1):
    print(f"{i}. {suggestion}")
