"""
main.py — KalaKriti BPP FastAPI application entrypoint.

Startup:
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Docs (auto-generated):
    http://localhost:8000/docs   (Swagger UI)
    http://localhost:8000/redoc  (ReDoc)
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.catalog_store import listing_count
from app.config import get_settings
from app.routes.app_routes import router as app_router
from app.routes.beckn_routes import router as beckn_router

# ─────────────────────────────────────────────────────────────────────────────
# Logging
# ─────────────────────────────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("kalakriti_bpp")


# ─────────────────────────────────────────────────────────────────────────────
# Lifespan
# ─────────────────────────────────────────────────────────────────────────────


@asynccontextmanager
async def lifespan(app: FastAPI):  # noqa: ANN001
    """Log startup summary and verify settings on boot."""
    settings = get_settings()
    logger.info("=" * 60)
    logger.info("  KalaKriti BPP — ONDC Beckn Provider Platform")
    logger.info("  Subscriber ID : %s", settings.bpp_subscriber_id)
    logger.info("  Public URI    : %s", settings.bpp_public_uri)
    logger.info(
        "  Signing Key   : %s",
        "✓ configured" if settings.bpp_signing_private_key else "⚠ NOT SET (mock mode)",
    )
    logger.info("  Catalog store : %d listing(s) pre-loaded", listing_count())
    logger.info("=" * 60)
    yield
    logger.info("KalaKriti BPP shutting down.")


# ─────────────────────────────────────────────────────────────────────────────
# App
# ─────────────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="KalaKriti BPP",
    description=(
        "ONDC Beckn Provider Platform Adapter for KalaKriti AI — "
        "Smart India Hackathon 2026 (SIH26090). "
        "Receives finalized artisan catalog payloads from the Flutter mobile app "
        "and serves them to ONDC buyer apps via the Beckn protocol."
    ),
    version="1.0.0",
    contact={
        "name": "Team LetEmCook",
        "url": "https://github.com/NotTheAmmar/sih-2026",
    },
    lifespan=lifespan,
)

# ─────────────────────────────────────────────────────────────────────────────
# Middleware
# ─────────────────────────────────────────────────────────────────────────────

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Open for dev/demo; restrict to app domains in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────────────────────────────────────────
# Global exception handler
# ─────────────────────────────────────────────────────────────────────────────


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """
    Catch-all: return a Beckn-style NACK so protocol clients get a
    structured error instead of a raw 500 traceback.
    """
    logger.exception("Unhandled exception on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "message": {"ack": {"status": "NACK"}},
            "error": {
                "type": "CORE-001",
                "message": "Internal server error",
                "path": str(request.url.path),
            },
        },
    )


# ─────────────────────────────────────────────────────────────────────────────
# Routers
# ─────────────────────────────────────────────────────────────────────────────

app.include_router(app_router)    # /api/v1/bpp/* — Flutter mobile app endpoints
app.include_router(beckn_router)  # /beckn/*       — ONDC Gateway / BAP webhooks


# ─────────────────────────────────────────────────────────────────────────────
# Root
# ─────────────────────────────────────────────────────────────────────────────


@app.get("/", tags=["Health"], status_code=status.HTTP_200_OK)
async def root() -> dict:
    """Health check — confirms the BPP is alive and shows active listing count."""
    settings = get_settings()
    return {
        "status": "ok",
        "service": "KalaKriti BPP",
        "subscriber_id": settings.bpp_subscriber_id,
        "bpp_uri": settings.bpp_public_uri,
        "active_listings": listing_count(),
        "docs": "/docs",
    }
