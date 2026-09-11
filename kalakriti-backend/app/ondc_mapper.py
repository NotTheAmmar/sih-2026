"""
ondc_mapper.py — Maps ArtisanListingPayload → ONDC-compliant Beckn on_search catalog.

Produces a fully schema-valid ``on_search`` response body for the
ONDC:RET12 (Fashion & Textiles) domain, populating:

  ✓ All Mandatory Critical attributes (protocol routing, pricing, inventory)
  ✓ All Mandatory Informational / Legal Metrology attributes (statutory disclosures)
  ○ Key Optional attributes (short_desc, long_desc, origin tag)

Reference: artifacts/ondc-requirements.md
Beckn Core Spec: 1.2.0
"""
import datetime
from typing import Optional

from app.schemas import ArtisanListingPayload


def _now_iso() -> str:
    """Return current UTC time in ISO 8601 with millisecond precision."""
    return datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="milliseconds")


def build_on_search_catalog(
    *,
    transaction_id: Optional[str],
    message_id: Optional[str],
    bpp_id: str,
    bpp_uri: str,
    item: ArtisanListingPayload,
    bap_id: Optional[str] = None,
    bap_uri: Optional[str] = None,
) -> dict:
    """
    Build a Beckn-compliant ``on_search`` response dictionary.

    Args:
        transaction_id: Echoed from the inbound ``search`` request context.
        message_id:     Echoed from the inbound ``search`` request context.
        bpp_id:         This BPP's subscriber ID (from config).
        bpp_uri:        This BPP's public callback URI (from config).
        item:           The artisan listing to include in the catalog.
        bap_id:         Buyer App ID from the inbound request (optional).
        bap_uri:        Buyer App URI from the inbound request (optional).

    Returns:
        A dict ready to be JSON-serialised and POSTed to ``{bap_uri}/on_search``.
    """
    provider_id = f"artisan_{item.artisan_name.lower().replace(' ', '_')}"

    # Truncate description to 95 chars for short_desc (ONDC display cards)
    short_desc = (
        item.description_en[:92] + "..."
        if len(item.description_en) > 95
        else item.description_en
    )

    return {
        "context": {
            "domain": item.category_id,          # e.g. "ONDC:RET12"
            "action": "on_search",
            "core_version": "1.2.0",
            "bpp_id": bpp_id,
            "bpp_uri": bpp_uri,
            **({"bap_id": bap_id} if bap_id else {}),
            **({"bap_uri": bap_uri} if bap_uri else {}),
            "transaction_id": transaction_id or "txn_mock_001",
            "message_id": message_id or "msg_mock_001",
            "city": "*",
            "country": "IND",
            "timestamp": _now_iso(),
            "ttl": "PT30S",
        },
        "message": {
            "catalog": {
                # ── BPP (platform) descriptor ─────────────────────────────
                "bpp/descriptor": {
                    "name": "KalaKriti Artisan Collective",
                    "short_desc": "Empowering marginalized weavers under MoSJE (SIH26090)",
                    "long_desc": (
                        "KalaKriti AI is a voice-first platform that helps rural artisans "
                        "list their handcrafted products on ONDC without typing a single "
                        "character. Photo + 15-second voice → ONDC-ready listing in under 60s."
                    ),
                    "symbol": item.studio_image_url,
                },
                # ── Fulfillment methods ───────────────────────────────────
                "bpp/fulfillments": [
                    {
                        "id": "ful_standard_delivery",
                        "type": "Delivery",
                    }
                ],
                # ── Providers (one per artisan) ───────────────────────────
                "bpp/providers": [
                    {
                        "id": provider_id,
                        "descriptor": {
                            "name": f"{item.artisan_name} Weaves",
                            "short_desc": (
                                f"Direct producer from {item.cluster_name}"
                            ),
                            "long_desc": (
                                f"Artisan {item.artisan_name} is a registered craftsperson "
                                f"at the {item.cluster_name}, producing {item.craft_category} "
                                f"using traditional methods passed down through generations."
                            ),
                            "images": [item.studio_image_url],
                        },
                        # ── Pickup location (the artisan workshop) ────────
                        "locations": [
                            {
                                "id": "loc_cluster_01",
                                "gps": item.gps_coordinates,
                                "address": {
                                    "locality": item.cluster_name,
                                    "city": "Chanderi",
                                    "state": "Madhya Pradesh",
                                    "country": "IND",
                                    "area_code": item.area_code,
                                },
                            }
                        ],
                        # ── Items ─────────────────────────────────────────
                        "items": [
                            {
                                # ── Mandatory Critical ────────────────────
                                "id": item.catalog_id,
                                "descriptor": {
                                    "name": item.title_en,
                                    "code": f"{item.category_id}-{item.catalog_id[-6:]}",
                                    "symbol": item.studio_image_url,
                                    "short_desc": short_desc,
                                    "long_desc": item.description_en,
                                    "images": [item.studio_image_url],
                                },
                                "price": {
                                    "currency": "INR",
                                    # value = fair price (recommended D2C selling price)
                                    "value": f"{item.fair_price:.2f}",
                                    # maximum_value = MRP / premium price
                                    "maximum_value": f"{item.premium_price:.2f}",
                                    # minimum_value = floor price (breakeven)
                                    "minimum_value": f"{item.floor_price:.2f}",
                                },
                                "category_id": item.category_id,
                                "fulfillment_id": "ful_standard_delivery",
                                "location_id": "loc_cluster_01",
                                "quantity": {
                                    "available": {"count": item.available_qty},
                                    "maximum": {"count": min(item.available_qty, 3)},
                                },
                                # ── Mandatory Critical — Commerce flags ───
                                "@ondc/org/returnable": True,
                                "@ondc/org/cancellable": True,
                                "@ondc/org/return_window": "P7D",
                                "@ondc/org/time_to_ship": "PT48H",
                                "@ondc/org/available_on_cod": False,
                                "@ondc/org/contact_details_consumer_care": (
                                    f"GRO: {item.artisan_name}, "
                                    f"gro@kalakriti.ai, +91-9876543210"
                                ),
                                # ── Mandatory Informational — Statutory tags
                                "tags": [
                                    # Country of origin (Consumer Protection Rules)
                                    {
                                        "code": "origin",
                                        "list": [
                                            {"code": "country", "value": "IND"}
                                        ],
                                    },
                                    # Craft attributes
                                    {
                                        "code": "attribute",
                                        "list": [
                                            {
                                                "code": "material",
                                                "value": ", ".join(item.materials),
                                            },
                                            {
                                                "code": "dimensions",
                                                "value": item.dimensions,
                                            },
                                        ],
                                    },
                                    # Legal Metrology Packaged Commodities Rules
                                    {
                                        "code": "legal_metrology",
                                        "list": [
                                            {
                                                "code": "manufacturer_name",
                                                "value": item.artisan_name,
                                            },
                                            {
                                                "code": "manufacturer_address",
                                                "value": (
                                                    f"{item.cluster_name}, "
                                                    f"PIN: {item.area_code}"
                                                ),
                                            },
                                            {
                                                "code": "generic_name",
                                                "value": item.craft_category,
                                            },
                                            {
                                                "code": "net_quantity",
                                                "value": f"1 unit ({item.dimensions})",
                                            },
                                            {
                                                "code": "country_of_origin",
                                                "value": "India",
                                            },
                                        ],
                                    },
                                    # Price transparency (optional but good practice)
                                    {
                                        "code": "price_slab",
                                        "list": [
                                            {
                                                "code": "floor_price",
                                                "value": f"{item.floor_price:.2f}",
                                            },
                                            {
                                                "code": "fair_price",
                                                "value": f"{item.fair_price:.2f}",
                                            },
                                        ],
                                    },
                                ],
                            }
                        ],
                    }
                ],
            }
        },
    }
