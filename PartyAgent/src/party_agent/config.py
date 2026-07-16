"""Central application settings.

Loads environment variables and exposes a single Settings() singleton other
modules import. Uses pydantic-settings so missing required vars fail loudly.
"""

from __future__ import annotations
from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # --- Required ---
    anthropic_api_key: str = Field(..., alias="ANTHROPIC_API_KEY")

    # --- Memory backends (optional locally) ---
    database_url: str | None = Field(default=None, alias="DATABASE_URL")
    redis_url: str | None = Field(default=None, alias="REDIS_URL")

    # --- External APIs ---
    google_maps_api_key: str | None = Field(default=None, alias="GOOGLE_MAPS_API_KEY")
    openweather_api_key: str | None = Field(default=None, alias="OPENWEATHER_API_KEY")
    ticketmaster_api_key: str | None = Field(default=None, alias="TICKETMASTER_API_KEY")
    eventbrite_token: str | None = Field(default=None, alias="EVENTBRITE_TOKEN")
    predicthq_token: str | None = Field(default=None, alias="PREDICTHQ_TOKEN")
    serpapi_api_key: str | None = Field(default=None, alias="SERPAPI_API_KEY")

    # --- Web crawler fallback ---
    # Cached events older than this are considered stale and trigger a re-crawl.
    crawl_freshness_hours: int = Field(default=6, alias="CRAWL_FRESHNESS_HOURS")
    # Cap per-city sites we crawl per refresh — keeps cost + latency bounded.
    crawl_max_sites_per_city: int = Field(default=8, alias="CRAWL_MAX_SITES_PER_CITY")
    # Model used for LLM-structured event extraction from scraped pages.
    crawl_extractor_model: str = Field(default="claude-haiku-4-5-20251001", alias="CRAWL_EXTRACTOR_MODEL")

    # --- Always-on scheduler ---
    # Set to false to disable the in-process refresh + cleanup loop
    # (e.g. when running multiple API instances and only one should crawl).
    crawl_scheduler_enabled: bool = Field(default=True, alias="CRAWL_SCHEDULER_ENABLED")
    # How often the scheduler iterates over the city list and refreshes stale ones.
    crawl_refresh_interval_minutes: int = Field(default=60, alias="CRAWL_REFRESH_INTERVAL_MINUTES")
    # How often expired events are purged from the database.
    crawl_cleanup_interval_minutes: int = Field(default=60, alias="CRAWL_CLEANUP_INTERVAL_MINUTES")
    # Grace period after event_date before an event is considered expired and deleted.
    crawl_event_ttl_hours: int = Field(default=6, alias="CRAWL_EVENT_TTL_HOURS")

    # --- LangSmith ---
    langsmith_tracing: bool = Field(default=False, alias="LANGSMITH_TRACING")
    langsmith_api_key: str | None = Field(default=None, alias="LANGSMITH_API_KEY")
    langsmith_project: str = Field(default="party-chat-agent", alias="LANGSMITH_PROJECT")

    # --- App ---
    app_env: str = Field(default="development", alias="APP_ENV")
    log_level: str = Field(default="INFO", alias="LOG_LEVEL")

    # --- Auth (Firebase ID-token verification on the chat endpoints) ---
    # When True, /chat and /chat/stream require a valid Firebase ID token whose
    # `email_verified` claim is true. Set AUTH_ENFORCED=false for local dev
    # without a service account. Fails closed: if enforced but firebase-admin
    # can't initialise, requests get 503 rather than being let through.
    auth_enforced: bool = Field(default=True, alias="AUTH_ENFORCED")
    # Path to the Firebase service-account JSON. Falls back to Application
    # Default Credentials (GOOGLE_APPLICATION_CREDENTIALS / metadata) if unset.
    firebase_service_account: str = Field(
        default="firebase_service_account.json", alias="FIREBASE_SERVICE_ACCOUNT"
    )

    # --- Model picks (override per-environment if you want) ---
    router_model: str = "claude-haiku-4-5-20251001"
    specialist_model: str = "claude-sonnet-4-6"
    recap_model: str = "claude-opus-4-7"  # creative captions/themes


@lru_cache
def get_settings() -> Settings:
    return Settings()
