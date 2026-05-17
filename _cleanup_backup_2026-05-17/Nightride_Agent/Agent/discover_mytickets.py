"""One-off discovery script.

Opens https://mytickets.lk/events in a headless browser, captures every
network request, then dumps a sample of the rendered DOM. Tells us:
  1. What API the page calls for events (so we can hit it directly)
  2. The DOM structure (so we can scrape it as a fallback)

Run: python discover_mytickets.py
"""

import asyncio
import json
from urllib.parse import urlparse

from playwright.async_api import async_playwright

URL = "https://mytickets.lk/events"


async def main() -> None:
    api_calls: list[dict] = []

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        )
        page = await context.new_page()

        async def on_response(response):
            url = response.url
            ctype = (response.headers.get("content-type") or "").lower()
            if "json" not in ctype:
                return
            host = urlparse(url).netloc
            if host.endswith("mytickets.lk"):
                try:
                    body = await response.text()
                except Exception:
                    body = ""
                api_calls.append(
                    {
                        "url": url,
                        "status": response.status,
                        "method": response.request.method,
                        "size": len(body),
                        "body_preview": body[:600],
                    }
                )

        page.on("response", on_response)

        print(f"Loading {URL} ...")
        await page.goto(URL, wait_until="networkidle", timeout=30000)

        # Give client-side fetches a moment to settle.
        await page.wait_for_timeout(3000)

        print("\n" + "=" * 70)
        print(f"Captured {len(api_calls)} JSON API calls to *.mytickets.lk")
        print("=" * 70)
        for i, call in enumerate(api_calls):
            print(f"\n[{i}] {call['method']} {call['url']}")
            print(f"    status={call['status']}  size={call['size']}b")
            print(f"    body[:600]: {call['body_preview']!r}")

        # Try a few common selectors for event cards.
        print("\n" + "=" * 70)
        print("DOM probe")
        print("=" * 70)
        for selector in [
            "[class*=event-card]",
            "[class*=EventCard]",
            "a[href*='/event/']",
            "article",
            "[data-event-id]",
        ]:
            count = await page.locator(selector).count()
            print(f"  {selector!r:35s} -> {count} matches")

        # Sample first event link
        first_link = page.locator("a[href*='/event/']").first
        if await first_link.count() > 0:
            href = await first_link.get_attribute("href")
            text = (await first_link.inner_text())[:200]
            print(f"\nFirst /event/ link href: {href}")
            print(f"First /event/ link text: {text!r}")

        # Save full page HTML for offline inspection
        html = await page.content()
        out_path = "mytickets_rendered.html"
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(html)
        print(f"\nSaved rendered HTML -> {out_path} ({len(html)} chars)")

        # Save all api calls for offline inspection
        with open("mytickets_api_calls.json", "w", encoding="utf-8") as f:
            json.dump(api_calls, f, indent=2)
        print("Saved API calls    -> mytickets_api_calls.json")

        await browser.close()


if __name__ == "__main__":
    asyncio.run(main())
