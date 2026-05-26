"""Diagnostic — verify the crawl workflow is set up and working.

Run anytime:
    .venv\\Scripts\\python.exe scripts\\check_crawler.py

Reports on each prerequisite and shows what's currently in the DB. No
PowerShell quoting headaches — just one command.
"""

from __future__ import annotations

import logging
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))

# Windows consoles default to cp1252 and crash on box-drawing chars in
# upstream tracebacks (Playwright likes them). Force stdout to UTF-8 with
# replacement so the diagnostic itself can never blow up on output encoding.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass


GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
RESET = "\033[0m"


def _safe_print(msg: str) -> None:
    try:
        print(msg)
    except UnicodeEncodeError:
        print(msg.encode("ascii", "replace").decode("ascii"))


def ok(msg: str) -> None:
    _safe_print(f"{GREEN}[OK]{RESET}  {msg}")


def bad(msg: str) -> None:
    _safe_print(f"{RED}[FAIL]{RESET} {msg}")


def warn(msg: str) -> None:
    _safe_print(f"{YELLOW}[WARN]{RESET} {msg}")


def section(title: str) -> None:
    _safe_print(f"\n=== {title} ===")


def check_env() -> tuple[bool, bool, bool]:
    section("1. Environment variables")
    from party_agent.config import get_settings
    s = get_settings()

    has_db = bool(s.database_url)
    has_serp = bool(s.serpapi_api_key)
    has_anthropic = bool(s.anthropic_api_key)

    (ok if has_anthropic else bad)(f"ANTHROPIC_API_KEY {'set' if has_anthropic else 'MISSING (required for LLM extraction)'}")
    (ok if has_db   else bad)(f"DATABASE_URL      {'set' if has_db   else 'MISSING (scheduler will not run, nothing can be written)'}")
    (ok if has_serp else bad)(f"SERPAPI_API_KEY   {'set' if has_serp else 'MISSING (no venue discovery, no crawl will happen)'}")

    if s.ticketmaster_api_key:
        ok("TICKETMASTER_API_KEY set (used as primary source before fallback)")
    else:
        warn("TICKETMASTER_API_KEY missing (optional)")
    if s.predicthq_token:
        ok("PREDICTHQ_TOKEN set (used as primary source before fallback)")
    else:
        warn("PREDICTHQ_TOKEN missing (optional)")

    return has_anthropic, has_db, has_serp


def check_crawl4ai() -> bool:
    section("2. Crawl4AI + browser")
    try:
        import crawl4ai  # noqa: F401
        # The package's __version__ attribute is a submodule in some builds;
        # try the most reliable readable form available.
        ver = getattr(crawl4ai, "VERSION", None) or getattr(crawl4ai, "__version__", "?")
        ok(f"crawl4ai installed (version {ver if isinstance(ver, str) else 'present'})")
    except ImportError:
        bad("crawl4ai NOT installed — run: pip install -r requirements.txt")
        return False

    # Playwright/Chromium check — the crawler can't actually load pages without it.
    try:
        from playwright.sync_api import sync_playwright
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            browser.close()
        ok("Playwright Chromium working")
        return True
    except Exception as exc:
        bad(f"Playwright Chromium failed: {exc}")
        bad("Run: .venv\\Scripts\\python.exe -m playwright install chromium")
        return False


def check_db_connection() -> bool:
    section("3. Database connectivity")
    try:
        from party_agent.data.events_db import _conn
        with _conn() as conn:
            row = conn.execute("SELECT 1").fetchone()
        ok(f"Postgres reachable ({row})")
        return True
    except Exception as exc:
        bad(f"Postgres unreachable: {exc}")
        bad("Make sure docker-compose is up: docker compose up -d postgres")
        bad("And the schema is migrated: python scripts/migrate_db.py")
        return False


def check_db_contents() -> None:
    section("4. What's currently in the events table")
    try:
        from party_agent.data.events_db import _conn
        with _conn() as conn:
            total = conn.execute("SELECT COUNT(*) AS n FROM events").fetchone()["n"]
            crawled = conn.execute(
                "SELECT COUNT(*) AS n FROM events WHERE source = 'web_crawl'"
            ).fetchone()["n"]
            by_city = conn.execute(
                """SELECT city, COUNT(*) AS n
                   FROM events WHERE source = 'web_crawl'
                   GROUP BY city ORDER BY n DESC LIMIT 10"""
            ).fetchall()
            recent = conn.execute(
                """SELECT name, city, vibe, source_url, last_crawled_at
                   FROM events WHERE source = 'web_crawl'
                   ORDER BY last_crawled_at DESC NULLS LAST LIMIT 10"""
            ).fetchall()
    except Exception as exc:
        bad(f"Could not read events table: {exc}")
        return

    print(f"  Total events: {total}")
    print(f"  Web-crawled events: {crawled}")

    if crawled == 0:
        warn("No crawler-sourced rows yet — the crawl has never run successfully.")
        return

    print("\n  Top cities by crawled events:")
    for r in by_city:
        print(f"    {r['city']:20s} {r['n']}")

    print("\n  Most recently crawled:")
    for r in recent:
        ts = r["last_crawled_at"].isoformat() if r["last_crawled_at"] else "?"
        url = (r["source_url"] or "")[:60]
        print(f"    [{ts}] {r['name'][:40]:40s} {r['city']:15s} {url}")


def try_live_crawl(has_db: bool, has_serp: bool, has_browser: bool) -> None:
    section("5. Live crawl test (kandy, LK)")
    if not (has_db and has_serp and has_browser):
        warn("Skipped — fix the missing prerequisites above first.")
        return

    logging.basicConfig(level=logging.INFO, format="    %(levelname)s %(name)s — %(message)s")
    from party_agent.integrations import web_events
    written = web_events.refresh_city("kandy", "LK")
    if written:
        ok(f"Crawl wrote {written} events for kandy")
    else:
        warn("Crawl returned 0 events. Possible reasons:")
        warn("  - SerpAPI quota exhausted (free tier = 100/mo)")
        warn("  - All discovered sites blocked the headless browser")
        warn("  - Sites have no events listed today")
        warn("  - Claude could not extract structured events from the pages")


def main() -> int:
    print("Crawl workflow status check")
    print("---------------------------")
    has_anthropic, has_db, has_serp = check_env()
    has_browser = check_crawl4ai()
    db_ok = check_db_connection() if has_db else False
    if db_ok:
        check_db_contents()
    try_live_crawl(has_db=db_ok, has_serp=has_serp, has_browser=has_browser)

    section("Verdict")
    if has_anthropic and has_db and has_serp and has_browser and db_ok:
        ok("All prerequisites met. The workflow can run.")
        ok("Start the API and the scheduler will keep the DB warm: "
           "uvicorn party_agent.api.main:app --port 8000")
    else:
        bad("Workflow is NOT yet operational. Fix the [FAIL] items above.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
