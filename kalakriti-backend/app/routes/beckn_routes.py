"""
beckn_routes.py — ONDC Beckn protocol webhook handlers.

These routes are called by the ONDC Gateway or Buyer App (BAP) — NOT by
the Flutter mobile app. They implement the provider (BPP) side of the
Beckn protocol flow for the ONDC:RET12 domain.

Protocol flow:
  Gateway/BAP → POST /beckn/search  → synchronous ACK (< 1s)
                                    → async on_search callback to bap_uri
  BAP         → POST /beckn/select  → ACK (quote generation: future)
  BAP         → POST /beckn/init    → ACK (order init: future)
  BAP         → POST /beckn/confirm → ACK (order confirm + waybill: future)
  BAP/IGM     → POST /beckn/issue   → ACK (< 2hr SLA: future)

References:
  Beckn Core Specification 1.2.0
  ONDC Network Policy v1.x
"""
import json
import logging

import httpx
from fastapi import APIRouter, BackgroundTasks, Request, status

from app.catalog_store import get_latest_listing
from app.config import get_settings
from app.crypto import create_ondc_auth_header
from app.ondc_mapper import build_on_search_catalog
from app.schemas import BecknRequest, ack_response, nack_response

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/beckn", tags=["ONDC Protocol"])

# Set to True to enforce Ed25519 verification on inbound requests.
# Keep False for ONDC Workbench / mock testing (Workbench doesn't sign requests).
ENFORCE_INBOUND_AUTH: bool = False


# ─────────────────────────────────────────────────────────────────────────────
# Background task — async on_search callback
# ─────────────────────────────────────────────────────────────────────────────


async def dispatch_on_search(bap_uri: str, payload: dict) -> None:
    """
    POST the ``on_search`` catalog to the BAP's callback endpoint.

    This runs as a FastAPI BackgroundTask — it fires AFTER the synchronous
    ACK has already been returned to the Gateway/BAP, ensuring the BPP
    always responds within the 1-second Beckn protocol SLA.

    Auth:
        If BPP_SIGNING_PRIVATE_KEY is set in .env, the request is signed
        with an ONDC-compliant Ed25519 Authorization header. If the key is
        empty (local dev / mock mode), the header is omitted.
    """
    settings = get_settings()
    payload_bytes = json.dumps(payload, ensure_ascii=False).encode("utf-8")

    headers = {"Content-Type": "application/json"}

    # Attach ONDC auth header if a signing key is configured
    if settings.bpp_signing_private_key:
        try:
            auth_header = create_ondc_auth_header(
                payload_bytes=payload_bytes,
                subscriber_id=settings.bpp_subscriber_id,
                unique_key_id=settings.bpp_uk_id,
                private_key_b64=settings.bpp_signing_private_key,
            )
            headers["Authorization"] = auth_header
        except Exception as exc:
            logger.warning("Failed to generate auth header: %s", exc)

    target_url = f"{bap_uri.rstrip('/')}/on_search"
    logger.info("Dispatching on_search callback → %s", target_url)

    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            response = await client.post(
                target_url,
                content=payload_bytes,
                headers=headers,
            )
            logger.info(
                "on_search callback delivered: %s → HTTP %s",
                target_url,
                response.status_code,
            )
        except Exception as exc:
            logger.error("on_search callback failed to %s: %s", target_url, exc)


# ─────────────────────────────────────────────────────────────────────────────
# /beckn/search — Discovery
# ─────────────────────────────────────────────────────────────────────────────


@router.post("/search", status_code=status.HTTP_200_OK)
async def handle_search(request: Request, bg_tasks: BackgroundTasks) -> dict:
    """
    Handle inbound ``search`` request from ONDC Gateway or BAP.

    Steps:
      1. Parse Beckn context.
      2. Return synchronous ACK immediately (< 1s, mandatory by Beckn spec).
      3. Queue ``dispatch_on_search`` as a background task — it builds the
         full ONDC-compliant catalog and POSTs it to ``{bap_uri}/on_search``.

    Note:
        Even if no listing is found, we ACK the request (protocol requirement).
        The on_search callback is simply not dispatched if no catalog is available.
    """
    settings = get_settings()

    try:
        body = await request.json()
    except Exception:
        return nack_response("Invalid JSON body")

    try:
        beckn_req = BecknRequest(**body)
    except Exception as exc:
        logger.warning("Failed to parse Beckn request: %s", exc)
        return nack_response(str(exc))

    context = beckn_req.context
    bap_uri = context.bap_uri
    listing = get_latest_listing()

    if listing and bap_uri:
        catalog_payload = build_on_search_catalog(
            transaction_id=context.transaction_id,
            message_id=context.message_id,
            bpp_id=settings.bpp_subscriber_id,
            bpp_uri=settings.bpp_public_uri,
            item=listing,
            bap_id=context.bap_id,
            bap_uri=bap_uri,
        )
        bg_tasks.add_task(dispatch_on_search, bap_uri, catalog_payload)
        logger.info(
            "ACK /beckn/search [txn=%s] — on_search queued for %s",
            context.transaction_id,
            bap_uri,
        )
    else:
        if not listing:
            logger.warning("ACK /beckn/search — no active listing in store")
        if not bap_uri:
            logger.warning("ACK /beckn/search — no bap_uri in context, cannot callback")

    # Synchronous ACK — always returned immediately
    return ack_response()


# ─────────────────────────────────────────────────────────────────────────────
# /beckn/select — Item selection + preliminary quote
# ─────────────────────────────────────────────────────────────────────────────


@router.post("/select", status_code=status.HTTP_200_OK)
async def handle_select(request: Request) -> dict:
    """
    Acknowledge item selection from BAP.

    Phase 3 TODO: Parse the selected item, compute a delivery quote,
    and dispatch an async ``on_select`` callback with the full quote
    (item price + estimated delivery charge).
    """
    logger.info("ACK /beckn/select")
    return ack_response()


# ─────────────────────────────────────────────────────────────────────────────
# /beckn/init — Order initialization
# ─────────────────────────────────────────────────────────────────────────────


@router.post("/init", status_code=status.HTTP_200_OK)
async def handle_init(request: Request) -> dict:
    """
    Acknowledge order initialization from BAP.

    Phase 3 TODO: Validate buyer billing/shipping address, reserve inventory,
    and dispatch ``on_init`` with the final itemized order object.
    """
    logger.info("ACK /beckn/init")
    return ack_response()


# ─────────────────────────────────────────────────────────────────────────────
# /beckn/confirm — Final order confirmation
# ─────────────────────────────────────────────────────────────────────────────


@router.post("/confirm", status_code=status.HTTP_200_OK)
async def handle_confirm(request: Request) -> dict:
    """
    Acknowledge final order confirmation from BAP.

    Phase 3 TODO:
      - Save order to persistent store
      - Trigger Beckn logistics /search to find nearest 3PL
        (Delhivery, Shadowfax, India Post via Beckn Logistics domain)
      - Generate waybill QR code and push to artisan's device
      - Dispatch ``on_confirm`` callback with order + fulfillment state
    """
    logger.info("ACK /beckn/confirm")
    return ack_response()


# ─────────────────────────────────────────────────────────────────────────────
# /beckn/issue — ONDC IGM (Issue & Grievance Management) Level 1
# ─────────────────────────────────────────────────────────────────────────────


@router.post("/issue", status_code=status.HTTP_200_OK)
async def handle_issue(request: Request) -> dict:
    """
    Acknowledge an ONDC IGM Level 1 issue raised by the BAP.

    ONDC mandates:
      - < 2 hour SLA for issue acknowledgment (this ACK satisfies it)
      - < 24 hour SLA for issue resolution response

    Phase 3 TODO: Log the issue, notify the artisan, dispatch ``on_issue``
    callback with a resolution ETA.
    """
    logger.info("ACK /beckn/issue")
    return ack_response()


# ─────────────────────────────────────────────────────────────────────────────
# /beckn/status — Order status (optional but common)
# ─────────────────────────────────────────────────────────────────────────────


@router.post("/status", status_code=status.HTTP_200_OK)
async def handle_status(request: Request) -> dict:
    """
    Acknowledge an order status query from BAP.

    Phase 3 TODO: Look up order from persistent store and dispatch
    ``on_status`` with current fulfillment state.
    """
    logger.info("ACK /beckn/status")
    return ack_response()
