"""
config.py — Application settings loaded from .env via pydantic-settings.

Usage:
    from app.config import get_settings
    settings = get_settings()
    print(settings.bpp_subscriber_id)
"""
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """All configuration read from environment variables / .env file."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── ONDC Identity ─────────────────────────────────────────────
    bpp_subscriber_id: str = "kalakriti.bpp.org"
    """Subscriber ID registered on the ONDC network."""

    bpp_uk_id: str = "key-1"
    """Unique Key ID — identifies this signing key in the ONDC registry."""

    bpp_signing_private_key: str = ""
    """Base64-encoded Ed25519 private key seed. Generate with generate_keys.py."""

    bpp_signing_public_key: str = ""
    """Base64-encoded Ed25519 public key. Registered in ONDC subscriber registry."""

    # ── Network ───────────────────────────────────────────────────
    bpp_public_uri: str = "http://localhost:8000/beckn"
    """Publicly reachable URI of this BPP server (used in Beckn context.bpp_uri)."""

    gateway_url: str = ""
    """ONDC Gateway URL for proactive catalog pushes. Leave empty for Workbench testing."""

    # ── Server ────────────────────────────────────────────────────
    host: str = "0.0.0.0"
    port: int = 8000


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Cached settings singleton — reads .env once at startup."""
    return Settings()
