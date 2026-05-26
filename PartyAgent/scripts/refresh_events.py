"""Background refresh job — crawl events for a list of cities and cache them.

Usage:
    python scripts/refresh_events.py                 # refresh built-in city list
    python scripts/refresh_events.py kandy colombo   # refresh just these
    python scripts/refresh_events.py --file cities.txt

Run it on a cron (every 6h matches CRAWL_FRESHNESS_HOURS):

    0 */6 * * * cd /app && python scripts/refresh_events.py >> /var/log/refresh.log 2>&1

Or in docker-compose:

    refresh:
      build: .
      command: ["sh", "-c", "while true; do python scripts/refresh_events.py; sleep 21600; done"]
      depends_on: [postgres]
"""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

# Make the package importable when this script is run directly.
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))

from party_agent.integrations import web_events  # noqa: E402

# Default city set — biased toward markets where Ticketmaster + PredictHQ
# have weak coverage. Override with --file or positional args in production.
DEFAULT_CITIES: list[tuple[str, str | None]] = [
    ("colombo", "LK"),
    ("kandy", "LK"),
    ("galle", "LK"),
    ("mumbai", "IN"),
    ("delhi", "IN"),
    ("bangalore", "IN"),
    ("dhaka", "BD"),
    ("kathmandu", "NP"),
    ("lagos", "NG"),
    ("nairobi", "KE"),
    ("accra", "GH"),
    ("bangkok", "TH"),
    ("ho chi minh city", "VN"),
    ("jakarta", "ID"),
    ("manila", "PH"),
    ("dubai", "AE"),
    ("istanbul", "TR"),
    ("cairo", "EG"),
    ("cape town", "ZA"),
    ("são paulo", "BR"),
]


def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Refresh cached events via web crawl.")
    p.add_argument("cities", nargs="*", help="Cities to refresh (overrides defaults).")
    p.add_argument("--file", help="Path to file with one 'city,country_code' pair per line.")
    p.add_argument("--country", default=None, help="Default country code for positional cities.")
    return p.parse_args()


def _load_from_file(path: str) -> list[tuple[str, str | None]]:
    out: list[tuple[str, str | None]] = []
    for raw in Path(path).read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "," in line:
            city, cc = (p.strip() for p in line.split(",", 1))
            out.append((city, cc or None))
        else:
            out.append((line, None))
    return out


def main() -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s — %(message)s",
    )
    log = logging.getLogger("refresh_events")
    args = _parse_args()

    if args.file:
        cities = _load_from_file(args.file)
    elif args.cities:
        cities = [(c, args.country) for c in args.cities]
    else:
        cities = DEFAULT_CITIES

    total_written = 0
    failures = 0
    for city, country in cities:
        try:
            written = web_events.refresh_city(city, country=country)
            total_written += written
        except Exception as exc:
            log.exception("Refresh failed for %s (%s): %s", city, country, exc)
            failures += 1

    log.info("Done — %d events written across %d cities (%d failures)",
             total_written, len(cities), failures)
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
