"""OpenWeather API client — real current-conditions lookup.

Free key from https://openweathermap.org/api — set OPENWEATHER_API_KEY in .env.
"""

from __future__ import annotations

import httpx

from party_agent.config import get_settings

_BASE = "https://api.openweathermap.org/data/2.5/weather"
_TIMEOUT = 6


def _is_rain_or_storm(main: str) -> bool:
    return main.lower() in {"rain", "drizzle", "thunderstorm", "squall"}


def current_weather(city: str, country_code: str | None = None) -> dict | None:
    """Return current weather for any city worldwide.

    Returns a dict like::

        {
          "city":        "Colombo",
          "country":     "LK",
          "summary":     "scattered clouds",
          "temp_c":      29.8,
          "feels_c":     33.4,
          "humidity":    72,
          "wind_kmh":    14.4,
          "rain":        False,
          "advice":      "Hot and humid — light clothing, hydrate.",
        }

    Returns ``None`` if the API key is missing, the city wasn't found, or the
    call errored. The weather tool degrades to "feature unavailable" in that
    case rather than inventing data.
    """
    key = get_settings().openweather_api_key
    if not key:
        return None

    q = f"{city},{country_code}" if country_code else city
    params = {"q": q, "appid": key, "units": "metric"}

    try:
        resp = httpx.get(_BASE, params=params, timeout=_TIMEOUT)
        if resp.status_code == 404:
            return None
        resp.raise_for_status()
        data = resp.json()
    except Exception:
        return None

    weather = (data.get("weather") or [{}])[0]
    main = weather.get("main", "")
    summary = weather.get("description", main or "unknown")

    temp_c = data.get("main", {}).get("temp")
    feels_c = data.get("main", {}).get("feels_like")
    humidity = data.get("main", {}).get("humidity")
    wind_mps = data.get("wind", {}).get("speed", 0) or 0
    wind_kmh = round(wind_mps * 3.6, 1)
    rain = _is_rain_or_storm(main)

    advice_parts: list[str] = []
    if rain:
        advice_parts.append("rain likely — avoid rooftops, bring a jacket")
    if temp_c is not None and temp_c >= 32:
        advice_parts.append("very hot — hydrate often, light clothing")
    elif temp_c is not None and temp_c <= 10:
        advice_parts.append("cold night — bring layers")
    if wind_kmh >= 30:
        advice_parts.append("windy — rooftop venues may close terraces")
    advice = "; ".join(advice_parts) or "comfortable conditions"

    return {
        "city":     data.get("name", city),
        "country":  data.get("sys", {}).get("country", country_code or ""),
        "summary":  summary,
        "temp_c":   temp_c,
        "feels_c":  feels_c,
        "humidity": humidity,
        "wind_kmh": wind_kmh,
        "rain":     rain,
        "advice":   advice,
    }
