"""
catalog_store.py — In-memory catalog store for active artisan listings.

Design:
  - A simple dict keyed by catalog_id. No external database dependency.
  - Ships with one pre-loaded Chanderi Silk Dupatta entry so the server
    responds correctly to ONDC Workbench / Gateway searches immediately,
    without requiring the Flutter app to POST a listing first.
  - Thread-safe for asyncio (single event loop; no shared mutable state
    across threads since Uvicorn runs a single-threaded async loop by default).

To upgrade to SQLite persistence, replace the body of each function with
SQLite queries — the interface contract (function signatures) stays the same.
"""
from typing import Dict, List, Optional

from app.schemas import ArtisanListingPayload


# ─────────────────────────────────────────────────────────────────────────────
# Default demo listing — Chanderi Silk Dupatta
# Pre-loaded so Workbench / curl tests work out-of-the-box.
# ─────────────────────────────────────────────────────────────────────────────

_DEFAULT_LISTING = ArtisanListingPayload(
    catalog_id="cat_chanderi_001",
    artisan_name="Ramesh Kumar",
    cluster_name="Chanderi Handloom Cluster",
    gps_coordinates="24.7118,78.1098",
    area_code="473446",
    title_en="Handwoven Chanderi Silk Dupatta with Gold Zari Border",
    title_hi="हाथ से बुनी चंदेरी सिल्क दुपट्टा, सोने की ज़री बॉर्डर के साथ",
    description_en=(
        "Exquisite authentic Chanderi dupatta handwoven on traditional pit looms "
        "using pure mulberry silk and 24-carat gold Zari thread. Each piece "
        "takes 5 days of skilled artisan labour and represents a 500-year-old "
        "weaving heritage from Chanderi, Madhya Pradesh. The lightweight, "
        "semi-translucent fabric with characteristic Chanderi butti motifs makes "
        "it ideal for festive occasions and formal wear."
    ),
    description_hi=(
        "पारंपरिक गड्ढा करघे पर बुनी गई उत्कृष्ट चंदेरी सिल्क दुपट्टा। "
        "शुद्ध मलबेरी सिल्क और 24 कैरेट सोने की ज़री धागे से बनी इस दुपट्टा में "
        "500 साल पुरानी बुनाई की परंपरा झलकती है।"
    ),
    craft_category="Handloom Silk",
    category_id="ONDC:RET12",
    materials=["Pure Mulberry Silk", "Gold Zari"],
    dimensions="6.2 meters",
    floor_price=1760.0,
    fair_price=2640.0,
    premium_price=3168.0,
    studio_image_url="https://images.unsplash.com/photo-1610030469983-98e550d6193c",
    available_qty=4,
)

# ─────────────────────────────────────────────────────────────────────────────
# In-memory store — dict[catalog_id → ArtisanListingPayload]
# ─────────────────────────────────────────────────────────────────────────────

_ACTIVE_LISTINGS: Dict[str, ArtisanListingPayload] = {
    _DEFAULT_LISTING.catalog_id: _DEFAULT_LISTING,
}


# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────


def save_active_listing(payload: ArtisanListingPayload) -> None:
    """Upsert a listing by catalog_id. Newer payloads overwrite older ones."""
    _ACTIVE_LISTINGS[payload.catalog_id] = payload


def get_latest_listing() -> Optional[ArtisanListingPayload]:
    """
    Return the most recently added listing.

    Falls back to the pre-loaded Chanderi Silk entry if the store is
    somehow empty (should never happen since we pre-load the default).
    """
    if not _ACTIVE_LISTINGS:
        return _DEFAULT_LISTING
    # Dicts preserve insertion order in Python 3.7+; last key = most recent.
    return list(_ACTIVE_LISTINGS.values())[-1]


def get_all_listings() -> List[ArtisanListingPayload]:
    """Return all active listings (newest last)."""
    return list(_ACTIVE_LISTINGS.values())


def get_listing_by_id(catalog_id: str) -> Optional[ArtisanListingPayload]:
    """Look up a specific listing by its catalog_id."""
    return _ACTIVE_LISTINGS.get(catalog_id)


def delete_listing(catalog_id: str) -> bool:
    """Remove a listing. Returns True if it existed."""
    if catalog_id in _ACTIVE_LISTINGS:
        del _ACTIVE_LISTINGS[catalog_id]
        return True
    return False


def listing_count() -> int:
    """Return the number of active listings (useful for health checks)."""
    return len(_ACTIVE_LISTINGS)
