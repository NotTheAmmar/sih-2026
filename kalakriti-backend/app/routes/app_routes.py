"""
app_routes.py — Mobile app integration endpoints.

These routes are called by the Flutter mobile app (not the ONDC network).
They form the bridge between the artisan's device and the BPP catalog store.

Endpoints:
  POST /api/v1/bpp/publish   — Flutter publishes a completed listing
  GET  /api/v1/bpp/listings  — Fetch all active listings (admin / Workbench)
  GET  /api/v1/bpp/listings/{catalog_id} — Fetch a single listing by ID
  DELETE /api/v1/bpp/listings/{catalog_id} — Remove a listing
  GET  /api/v1/bpp/health    — Quick count for monitoring
"""
from fastapi import APIRouter, HTTPException, status

from app.catalog_store import (
    delete_listing,
    get_all_listings,
    get_listing_by_id,
    listing_count,
    save_active_listing,
)
from app.schemas import ArtisanListingPayload

router = APIRouter(prefix="/api/v1/bpp", tags=["Artisan App"])


# ─────────────────────────────────────────────────────────────────────────────
# Publish
# ─────────────────────────────────────────────────────────────────────────────


@router.post("/publish", status_code=status.HTTP_200_OK)
async def publish_listing(listing: ArtisanListingPayload) -> dict:
    """
    Receive a finalized artisan listing from the Flutter app and stage it
    in the catalog store so it is served on the next ONDC ``/search`` request.

    The Flutter app calls this after the AI pipeline (Groq + Gemini) has
    generated the bilingual catalog card and the artisan taps **Publish**.

    Returns the assigned catalog_id so the Flutter app can track status.
    """
    save_active_listing(listing)
    return {
        "status": "PUBLISHED",
        "message": (
            f"Listing '{listing.title_en}' is now active on ONDC rails. "
            f"It will appear in the next /on_search callback."
        ),
        "catalog_id": listing.catalog_id,
        "artisan": listing.artisan_name,
        "fair_price_inr": listing.fair_price,
    }


# ─────────────────────────────────────────────────────────────────────────────
# Listings
# ─────────────────────────────────────────────────────────────────────────────


@router.get("/listings", status_code=status.HTTP_200_OK)
async def fetch_all_listings() -> dict:
    """
    Return all currently active listings in the catalog store.

    Useful for:
      - ONDC Workbench manual fetch & schema validation
      - Admin dashboard inspection
      - Integration tests
    """
    listings = get_all_listings()
    return {
        "count": len(listings),
        "listings": [lst.model_dump() for lst in listings],
    }


@router.get("/listings/{catalog_id}", status_code=status.HTTP_200_OK)
async def fetch_listing(catalog_id: str) -> dict:
    """Fetch a single listing by its catalog_id."""
    listing = get_listing_by_id(catalog_id)
    if listing is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Listing '{catalog_id}' not found.",
        )
    return listing.model_dump()


@router.delete("/listings/{catalog_id}", status_code=status.HTTP_200_OK)
async def remove_listing(catalog_id: str) -> dict:
    """Remove a listing from the catalog store."""
    removed = delete_listing(catalog_id)
    if not removed:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Listing '{catalog_id}' not found.",
        )
    return {"status": "REMOVED", "catalog_id": catalog_id}


# ─────────────────────────────────────────────────────────────────────────────
# Health
# ─────────────────────────────────────────────────────────────────────────────


@router.get("/health", status_code=status.HTTP_200_OK)
async def app_health() -> dict:
    """Quick health check — returns active listing count."""
    return {"status": "ok", "active_listings": listing_count()}
