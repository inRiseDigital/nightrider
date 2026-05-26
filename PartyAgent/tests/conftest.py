"""Pytest config — add src/ to sys.path so tests can import party_agent."""

import sys
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))
