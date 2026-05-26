"""Ride tool — LIVE (deeplinks only).

We don't have business agreements with Uber/Bolt/etc., so we can't *book*
rides on the user's behalf. What we CAN do is generate a tap-to-open URL
for the right local ride-share app, pre-filled with the destination (and
pickup, when GPS is known). The mobile app opens that URL → user confirms
and books inside the ride app.

This is the same UX pattern Google Maps and most travel apps use. It needs
zero credentials on our side.
"""

from __future__ import annotations

from urllib.parse import quote_plus

from langchain_core.tools import tool


# Per-country primary ride-share app and its deeplink template.
# Templates support {pickup_lat}, {pickup_lng}, {drop_lat}, {drop_lng}, {drop_label}.
# Where an app has a stable web URL we use that — works on web AND opens the
# installed app on mobile when present.
_RIDE_APPS: dict[str, dict] = {
    # South Asia
    "LK": {"name": "PickMe",  "web": "https://pickme.lk/"},
    "IN": {"name": "Uber",
           "web": "https://m.uber.com/looking?drop[0]={drop_label}&drop[0]_latitude={drop_lat}&drop[0]_longitude={drop_lng}"},
    "PK": {"name": "Careem", "web": "https://www.careem.com/"},
    "BD": {"name": "Pathao", "web": "https://pathao.com/"},
    "NP": {"name": "Pathao", "web": "https://pathao.com/"},

    # SE Asia
    "TH": {"name": "Grab",   "web": "https://www.grab.com/sg/"},
    "VN": {"name": "Grab",   "web": "https://www.grab.com/vn/en/"},
    "ID": {"name": "Gojek",  "web": "https://www.gojek.com/"},
    "PH": {"name": "Grab",   "web": "https://www.grab.com/ph/"},
    "MY": {"name": "Grab",   "web": "https://www.grab.com/my/"},
    "SG": {"name": "Grab",   "web": "https://www.grab.com/sg/"},

    # East Asia
    "JP": {"name": "LINE Taxi", "web": "https://taxi.line.me/"},
    "KR": {"name": "Kakao T",   "web": "https://kakaot.kakao.com/"},
    "TW": {"name": "LINE Taxi", "web": "https://taxi.line.me/"},
    "CN": {"name": "DiDi",      "web": "https://www.didiglobal.com/"},
    "HK": {"name": "HKTaxi",    "web": "https://www.hktaxiapp.com/"},

    # Middle East
    "AE": {"name": "Careem", "web": "https://www.careem.com/en-AE/"},
    "SA": {"name": "Careem", "web": "https://www.careem.com/en-SA/"},
    "QA": {"name": "Careem", "web": "https://www.careem.com/en-QA/"},
    "KW": {"name": "Careem", "web": "https://www.careem.com/en-KW/"},
    "EG": {"name": "Uber",
           "web": "https://m.uber.com/looking?drop[0]={drop_label}&drop[0]_latitude={drop_lat}&drop[0]_longitude={drop_lng}"},
    "TR": {"name": "BiTaksi", "web": "https://bitaksi.com/"},

    # Europe
    "GB": {"name": "Bolt", "web": "https://bolt.eu/en-gb/"},
    "IE": {"name": "Free Now", "web": "https://www.free-now.com/ie/"},
    "FR": {"name": "Bolt", "web": "https://bolt.eu/en/"},
    "DE": {"name": "Bolt", "web": "https://bolt.eu/de/"},
    "ES": {"name": "Cabify", "web": "https://cabify.com/"},
    "PT": {"name": "Bolt", "web": "https://bolt.eu/pt-pt/"},
    "NL": {"name": "Bolt", "web": "https://bolt.eu/nl/"},
    "PL": {"name": "Bolt", "web": "https://bolt.eu/pl/"},
    "SE": {"name": "Bolt", "web": "https://bolt.eu/sv-se/"},

    # Africa
    "NG": {"name": "Bolt", "web": "https://bolt.eu/en-ng/"},
    "GH": {"name": "Bolt", "web": "https://bolt.eu/en-gh/"},
    "KE": {"name": "Bolt", "web": "https://bolt.eu/en-ke/"},
    "TZ": {"name": "Bolt", "web": "https://bolt.eu/en-tz/"},
    "ZA": {"name": "Bolt", "web": "https://bolt.eu/en-za/"},
    "MA": {"name": "Heetch", "web": "https://www.heetch.com/"},

    # Americas
    "US": {"name": "Uber",
           "web": "https://m.uber.com/looking?drop[0]={drop_label}&drop[0]_latitude={drop_lat}&drop[0]_longitude={drop_lng}"},
    "CA": {"name": "Uber",
           "web": "https://m.uber.com/looking?drop[0]={drop_label}&drop[0]_latitude={drop_lat}&drop[0]_longitude={drop_lng}"},
    "MX": {"name": "DiDi",   "web": "https://www.didiglobal.com/"},
    "BR": {"name": "Uber",
           "web": "https://m.uber.com/looking?drop[0]={drop_label}&drop[0]_latitude={drop_lat}&drop[0]_longitude={drop_lng}"},
    "AR": {"name": "Cabify", "web": "https://cabify.com/"},
    "CL": {"name": "DiDi",   "web": "https://www.didiglobal.com/"},
    "CO": {"name": "DiDi",   "web": "https://www.didiglobal.com/"},

    # Oceania
    "AU": {"name": "Uber",
           "web": "https://m.uber.com/looking?drop[0]={drop_label}&drop[0]_latitude={drop_lat}&drop[0]_longitude={drop_lng}"},
    "NZ": {"name": "Uber",
           "web": "https://m.uber.com/looking?drop[0]={drop_label}&drop[0]_latitude={drop_lat}&drop[0]_longitude={drop_lng}"},
}

# Fallback when country isn't in the table. Uber operates in 70+ countries and
# its web deeplink is the best generic option.
_FALLBACK = {
    "name": "Uber",
    "web": "https://m.uber.com/looking?drop[0]={drop_label}&drop[0]_latitude={drop_lat}&drop[0]_longitude={drop_lng}",
}


def _format_url(template: str, drop_lat: float, drop_lng: float, drop_label: str) -> str:
    return template.format(
        drop_lat=drop_lat,
        drop_lng=drop_lng,
        drop_label=quote_plus(drop_label or "Destination"),
    )


@tool
def ride_to(
    drop_lat: float,
    drop_lng: float,
    drop_label: str = "",
    country_code: str = "",
) -> str:
    """Return a tap-to-open ride-share URL pre-filled with the destination.

    Use this when the user wants to "get a ride", "book a taxi", "Uber there".
    The URL opens the user's installed ride app on mobile or its web page on
    desktop; they confirm and pay inside that app. We do not book on their
    behalf and never request payment.

    Args:
        drop_lat:     Destination latitude (e.g. the venue's lat).
        drop_lng:     Destination longitude.
        drop_label:   Human-readable destination name (e.g. "King of the Mambo").
        country_code: 2-letter ISO country code (e.g. "LK", "JP", "US"). When
                      empty, falls back to Uber's global web deeplink.
    """
    cc = (country_code or "").upper().strip()
    app = _RIDE_APPS.get(cc, _FALLBACK)
    url = _format_url(app["web"], drop_lat, drop_lng, drop_label)

    label = drop_label.strip() or "destination"
    return (
        f"Open in {app['name']}: {url}\n"
        f"(Tap the link to launch {app['name']} pre-filled with {label}. "
        "You confirm and pay inside the app — this assistant doesn't book on your behalf.)"
    )


@tool
def nearby_rides(lat: float, lng: float, radius_m: int = 300) -> str:
    """Find taxi stands and ride-share pickup points near a point.

    Args:
        lat: Latitude of the search center.
        lng: Longitude of the search center.
        radius_m: Search radius in metres.
    """
    # Pickup-point discovery needs Google Places (paid, key-gated). Falling
    # back honestly until that key is configured.
    from party_agent.tools._unavailable import unavailable
    return unavailable(
        "nearby-pickup-point discovery",
        suggestion=(
            "tell the user to use the ride_to tool to open the ride-share "
            "app, which uses live GPS to pick the closest pickup itself"
        ),
    )
