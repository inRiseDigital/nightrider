"""Observability setup.

Enables LangSmith tracing if LANGSMITH_TRACING=true. Call setup_observability()
once at app startup before building the graph.
"""

from __future__ import annotations
import os
import logging

from party_agent.config import get_settings


def setup_observability() -> None:
    settings = get_settings()
    logging.basicConfig(level=settings.log_level)

    if settings.langsmith_tracing and settings.langsmith_api_key:
        os.environ["LANGSMITH_TRACING"] = "true"
        os.environ["LANGSMITH_API_KEY"] = settings.langsmith_api_key
        os.environ["LANGSMITH_PROJECT"] = settings.langsmith_project
        logging.info("LangSmith tracing enabled (project=%s)", settings.langsmith_project)
