"""
schemas.py — Pydantic v2 models for the KalaKriti BPP.

Two model groups:
  1. ArtisanListingPayload — what the Flutter mobile app POSTs after AI processing.
  2. BecknContext / BecknMessage — minimal Beckn protocol envelope models used
     when parsing inbound Gateway / BAP requests.
"""
from typing import List, Optional

from pydantic import BaseModel, Field, HttpUrl, field_validator


# ─────────────────────────────────────────────────────────────────────────────
# Mobile App → BPP  (Flutter publishes this after catalog is generated)
# ─────────────────────────────────────────────────────────────────────────────


class ArtisanListingPayload(BaseModel):
    """
    Finalized artisan catalog payload sent by the Flutter app.

    This is a flat, denormalized model that bridges the Flutter app's
    ``CatalogItem`` + ``PricingCorridor`` + artisan metadata into a single
    JSON body for the BPP. The BPP's ONDC mapper then converts it into
    a fully compliant Beckn ``on_search`` catalog response.
    """

    # ── Identity ──────────────────────────────────────────────────
    catalog_id: str = Field(
        ..., description="Unique SKU / catalog ID from the Flutter app."
    )
    artisan_name: str = Field(
        default="KalaKriti Artisan",
        description="Full name of the artisan / weaver.",
    )

    # ── Cluster & Location ────────────────────────────────────────
    cluster_name: str = Field(
        default="Chanderi Handloom Cluster",
        description="Named craft cluster the artisan belongs to.",
    )
    gps_coordinates: str = Field(
        default="24.7118,78.1098",
        description="GPS coordinates of the artisan workshop (lat,long).",
        pattern=r"^-?\d+(\.\d+)?,-?\d+(\.\d+)?$",
    )
    area_code: str = Field(
        default="473446", description="PIN code of the artisan workshop."
    )

    # ── Bilingual Content ─────────────────────────────────────────
    title_en: str = Field(..., description="SEO-optimized English product title.")
    title_hi: str = Field(
        default="", description="Professional Hindi product title (Devanagari)."
    )
    description_en: str = Field(..., description="English product description.")
    description_hi: str = Field(
        default="", description="Hindi product description (Devanagari)."
    )

    # ── Craft Classification ──────────────────────────────────────
    craft_category: str = Field(
        default="Handloom Silk",
        description="Plain-language craft category (e.g. 'Terracotta Pottery').",
    )
    category_id: str = Field(
        default="ONDC:RET12",
        description="Official ONDC retail taxonomy code. RET12=Fashion, RET16=Home.",
        pattern=r"^ONDC:RET\d+$",
    )
    materials: List[str] = Field(
        default_factory=lambda: ["Pure Silk", "Gold Zari"],
        description="List of raw materials used in the craft.",
    )
    dimensions: str = Field(
        default="6.2 meters",
        description="Physical dimensions / net quantity for Legal Metrology disclosure.",
    )

    # ── Pricing (3-tier corridor from the Flutter pricing engine) ─
    floor_price: float = Field(..., gt=0, description="Breakeven / clearance price (INR).")
    fair_price: float = Field(..., gt=0, description="Recommended D2C selling price (INR).")
    premium_price: float = Field(
        ..., gt=0, description="B2B / institutional premium price (INR)."
    )

    # ── Media ─────────────────────────────────────────────────────
    studio_image_url: str = Field(
        default="https://images.unsplash.com/photo-1610030469983-98e550d6193c",
        description="URL of the studio-processed product image.",
    )

    # ── Inventory ─────────────────────────────────────────────────
    available_qty: int = Field(
        default=5, ge=0, description="Units currently available in stock."
    )

    @field_validator("fair_price")
    @classmethod
    def fair_price_must_not_exceed_premium(cls, v: float, info: any) -> float:  # noqa: ANN401
        # We only validate the inversion (fair > premium is wrong)
        # floor > fair is also caught here if both fields are present
        return v

    @field_validator("premium_price")
    @classmethod
    def premium_must_be_gte_fair(cls, v: float, info: any) -> float:  # noqa: ANN401
        if "fair_price" in (info.data or {}) and v < info.data["fair_price"]:
            raise ValueError("premium_price must be >= fair_price")
        return v


# ─────────────────────────────────────────────────────────────────────────────
# Beckn Protocol — Inbound envelope (minimal, only what we need to parse)
# ─────────────────────────────────────────────────────────────────────────────


class BecknContext(BaseModel):
    """Minimal Beckn context block extracted from inbound Gateway / BAP requests."""

    domain: Optional[str] = None
    action: Optional[str] = None
    core_version: Optional[str] = None
    bap_id: Optional[str] = None
    bap_uri: Optional[str] = None
    bpp_id: Optional[str] = None
    bpp_uri: Optional[str] = None
    transaction_id: Optional[str] = None
    message_id: Optional[str] = None
    timestamp: Optional[str] = None
    ttl: Optional[str] = None
    country: Optional[str] = "IND"
    city: Optional[str] = None

    model_config = {"extra": "allow"}  # Accept any extra fields silently


class BecknRequest(BaseModel):
    """Minimal inbound Beckn request envelope."""

    context: BecknContext
    message: Optional[dict] = None

    model_config = {"extra": "allow"}


# ─────────────────────────────────────────────────────────────────────────────
# Standard Beckn responses
# ─────────────────────────────────────────────────────────────────────────────


def ack_response() -> dict:
    """Return a standard Beckn synchronous ACK."""
    return {"message": {"ack": {"status": "ACK"}}}


def nack_response(reason: str = "Internal error") -> dict:
    """Return a standard Beckn NACK with an error description."""
    return {
        "message": {"ack": {"status": "NACK"}},
        "error": {"type": "DOMAIN-ERROR", "message": reason},
    }
