"""Load agent spec .md files from the project root into system prompts.

The .md files are the single source of truth for each agent's full knowledge
base (intent tables, city intelligence, badge catalogs, emergency directories,
cultural norms, etc.). This loader reads them at import time so edits to the
.md files automatically reflect in the running agent without any code change.

Usage in a prompts.py:
    from party_agent.agents._md_loader import spec_section
    MAP_NAVIGATOR_PROMPT = _TOOL_CAPABILITIES + spec_section("agent2_party_map_navigator.md")
"""

from __future__ import annotations
import logging
import pathlib

log = logging.getLogger(__name__)

# Project root is 3 levels up from this file:
# src/party_agent/agents/_md_loader.py → parents[3] = project root
_ROOT = pathlib.Path(__file__).parents[3]


def load_spec(filename: str) -> str:
    """Return full text of a spec file. Logs a warning and returns '' if missing."""
    path = _ROOT / filename
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        log.warning("Spec file not found: %s", path)
        return ""
    except Exception as exc:
        log.warning("Failed to load spec file %s: %s", path, exc)
        return ""


def spec_section(filename: str, header: str = "FULL AGENT SPEC") -> str:
    """Load spec and wrap it in a clearly labelled section for the system prompt."""
    content = load_spec(filename)
    if not content:
        return ""
    bar = "━" * 44
    return f"\n\n{bar}\n{header}\n{bar}\n\n{content}"
