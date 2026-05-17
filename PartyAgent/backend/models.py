from pydantic import BaseModel, Field
from typing import List, Optional

class PartyDetails(BaseModel):
    title: str = Field(description="The name of the party or event")
    location: str = Field(description="The venue or location name")
    country: str = Field(description="The country where the event is taking place")
    time: str = Field(description="Date and time of the event")
    images: List[str] = Field(description="List of image URLs for the event")

class PartyResponse(BaseModel):
    response_text: str = Field(description="Conversational response to the user")
    party_recommendations: List[PartyDetails] = Field(description="List of recommended parties. ONLY include if the user explicitly asks for a list, search, or recommendations. Do NOT include for general follow-up questions like 'how to get there' or 'tell me more'.")
    suggested_questions: List[str] = Field(description="3-4 intelligent follow-up questions the user might ask next, based on the conversation context. Make them natural, relevant, and helpful.")
