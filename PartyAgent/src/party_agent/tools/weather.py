"""Weather tool — LIVE.

Wraps the OpenWeather integration and returns a single-line summary the
agent can read out. Falls back to the honest "feature unavailable" marker
only when the API key is missing or the upstream call fails — never
invents weather.
"""

from __future__ import annotations

from langchain_core.tools import tool

from party_agent.integrations.openweather import current_weather
from party_agent.tools._unavailable import unavailable


def _format(w: dict) -> str:
    temp = f"{w['temp_c']:.0f}°C" if w.get("temp_c") is not None else "?°C"
    feels = f" (feels {w['feels_c']:.0f}°C)" if w.get("feels_c") is not None else ""
    summary = w.get("summary", "unknown").capitalize()
    wind = f", wind {w['wind_kmh']:.0f} km/h" if w.get("wind_kmh") else ""
    advice = w.get("advice") or ""
    location = ", ".join(filter(None, [w.get("city", ""), w.get("country", "")]))
    return f"{location}: {summary}, {temp}{feels}{wind}. {advice}"


@tool
def get_weather(city: str, country_code: str = "") -> str:
    """Get current weather for any city in the world.

    Args:
        city: City name, e.g. "Colombo", "Tokyo", "Lagos".
        country_code: Optional 2-letter ISO code to disambiguate
                      (e.g. "LK" for Sri Lanka, "JP" for Japan).

    Returns a one-line summary suitable to read aloud, including temperature,
    humidity, wind, rain advisory, and a "what to wear / where to go" hint.
    """
    cc = country_code.strip() or None
    data = current_weather(city, cc)
    if not data:
        return unavailable(
            f"live weather for {city}",
            suggestion="tell the user the lookup failed; check their own weather app",
        )
    return _format(data)
