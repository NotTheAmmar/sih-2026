# Backend Quickstart — KalaKriti BPP

> **Purpose:** Get the ONDC Beckn Provider Platform server running locally and demo it on ONDC Workbench.  
> **Time to first ACK:** ~2 minutes  
> **Last updated:** 2026-09-11

---

## Prerequisites

- Python 3.11+ (`python3 --version`)
- `cloudflared` installed for public tunnel ([download](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/))

---

## Step 1 — First-time Setup

```bash
cd kalakriti-backend

# Create and activate virtualenv
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate

# Install dependencies (7 packages, no ML, no torch)
pip install -r requirements.txt
```

---

## Step 2 — Generate Ed25519 Signing Keys

```bash
python generate_keys.py
```

Output looks like:
```
──────────────────────────────────────────────────
  KalaKriti BPP — ONDC Ed25519 Keypair
──────────────────────────────────────────────────
BPP_SIGNING_PRIVATE_KEY=YOUR_BASE64_PRIVATE_KEY
BPP_SIGNING_PUBLIC_KEY=YOUR_BASE64_PUBLIC_KEY
──────────────────────────────────────────────────
```

Copy those two lines into a `.env` file:

```bash
cp .env.example .env
# Then paste the key lines into .env
```

> [!NOTE]
> For **Workbench mock testing**, you can skip the keys entirely — the server works without signing keys in "mock mode." The `BPP_PUBLIC_URI` and `BPP_SUBSCRIBER_ID` can stay as defaults.

---

## Step 3 — Start the Server

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Expected startup output:
```
22:58:00  INFO     kalakriti_bpp — ============================================================
22:58:00  INFO     kalakriti_bpp —   KalaKriti BPP — ONDC Beckn Provider Platform
22:58:00  INFO     kalakriti_bpp —   Subscriber ID : kalakriti.bpp.org
22:58:00  INFO     kalakriti_bpp —   Public URI    : http://localhost:8000/beckn
22:58:00  INFO     kalakriti_bpp —   Signing Key   : ⚠ NOT SET (mock mode)
22:58:00  INFO     kalakriti_bpp —   Catalog store : 1 listing(s) pre-loaded
22:58:00  INFO     kalakriti_bpp — ============================================================
INFO:     Uvicorn running on http://0.0.0.0:8000
```

Browse to **http://localhost:8000/docs** for interactive Swagger UI.

---

## Step 4 — Verify Endpoints

```bash
# Health check
curl http://localhost:8000/
# → {"status":"ok","service":"KalaKriti BPP","active_listings":1,...}

# Fetch the pre-loaded Chanderi Silk listing
curl http://localhost:8000/api/v1/bpp/listings
# → {"count":1,"listings":[{"catalog_id":"cat_chanderi_001",...}]}

# Simulate a Beckn /search from Gateway/BAP
curl -X POST http://localhost:8000/beckn/search \
  -H "Content-Type: application/json" \
  -d '{
    "context": {
      "domain": "ONDC:RET12",
      "action": "search",
      "bap_id": "buyer-app.example.org",
      "bap_uri": "https://buyer-app.example.org/beckn",
      "transaction_id": "txn_demo_001",
      "message_id": "msg_demo_001"
    },
    "message": {"intent": {"item": {"descriptor": {"name": "silk"}}}}
  }'
# → {"message":{"ack":{"status":"ACK"}}}
# The async on_search callback fires in the background (visible in server logs)
```

---

## Step 5 — Expose via Cloudflare Tunnel (for Workbench)

In a second terminal:
```bash
cloudflared tunnel --url http://localhost:8000
```

Copy the generated `https://*.trycloudflare.com` URL. Update `.env`:
```env
BPP_PUBLIC_URI=https://YOUR-TUNNEL.trycloudflare.com/beckn
```

Restart the server for the change to take effect.

---

## Step 6 — Validate on ONDC Workbench (Scenario Testing)

Navigate to **[dev-workbench.ondc.tech](https://dev-workbench.ondc.tech/)** and click **Scenario Testing** in the top nav.

> [!NOTE]
> The Workbench acts as a **Buyer App (BAP)** and calls your BPP. You enter your BPP's public URL, and Workbench simulates the full Beckn discovery flow — sending a `/search` and validating your `on_search` callback for schema compliance.

### Create a New Session

Fill the **"Create a new Session"** form on the right panel:

| # | Field | Value for KalaKriti BPP |
|---|-------|------------------------|
| 1 | **Enter Subscriber URL** | `https://YOUR-TUNNEL.trycloudflare.com` |
| 2 | **Select Domain** | `ONDC:RET12` |
| 3 | **Select Version** | `1.2.0` |
| 4 | **Select Usecase** | Select the search/discovery usecase |
| 5 | **Select Your Role** | `Buyer App (BAP)` ← Workbench plays the buyer; your server plays the BPP |
| 6 | **Select Environment** | `PRE-PRODUCTION` |

Then click **Submit**. The remaining steps are automated:

| # | Step | What happens |
|---|------|-------------|
| 7 | **Generate Report** | Workbench sends a Beckn `/search` to your `/beckn/search` endpoint and records the exchange |
| 8 | **View Report** | Inspect the full request/response pair and schema validation results |
| 9 | **Download / Share Report** | Export the validation report (useful for jury demo) |

### Expected terminal output

```
22:58:01  INFO  ACK /beckn/search [txn=txn_workbench_xxx] — on_search queued for https://workbench.ondc.tech/...
22:58:01  INFO  on_search callback delivered → HTTP 200
```

The synchronous ACK fires first (< 1s), then the signed `on_search` callback with the full ONDC:RET12 catalog dispatches in the background.

> [!TIP]
> If the Subscriber URL field shows **"Field required"** after clicking Submit, make sure the URL includes `https://` — the field validates the full URI format.



## Endpoint Reference

| Method | Path | Who calls it | Purpose |
|--------|------|-------------|---------|
| `GET` | `/` | Anyone | Health check |
| `GET` | `/docs` | Developer | Swagger UI |
| `POST` | `/api/v1/bpp/publish` | Flutter app | Publish a new artisan listing |
| `GET` | `/api/v1/bpp/listings` | Dev / Workbench | Fetch all active listings |
| `GET` | `/api/v1/bpp/listings/{id}` | Dev | Fetch one listing |
| `DELETE` | `/api/v1/bpp/listings/{id}` | Dev | Remove a listing |
| `GET` | `/api/v1/bpp/health` | Monitoring | Listing count |
| `POST` | `/beckn/search` | ONDC Gateway / BAP | Product discovery |
| `POST` | `/beckn/select` | BAP | Item selection (ACK stub) |
| `POST` | `/beckn/init` | BAP | Order init (ACK stub) |
| `POST` | `/beckn/confirm` | BAP | Order confirm (ACK stub) |
| `POST` | `/beckn/status` | BAP | Order status (ACK stub) |
| `POST` | `/beckn/issue` | BAP / IGM | Grievance (ACK stub) |

---

## Repository Structure

```
kalakriti-backend/
├── app/
│   ├── config.py          # Pydantic Settings — env vars
│   ├── crypto.py          # Ed25519 + BLAKE2b-512 ONDC auth
│   ├── schemas.py         # Pydantic models + ACK/NACK helpers
│   ├── catalog_store.py   # In-memory listing store
│   ├── ondc_mapper.py     # ArtisanListingPayload → on_search JSON
│   └── routes/
│       ├── app_routes.py  # Flutter app endpoints
│       └── beckn_routes.py # ONDC protocol webhooks
├── main.py                # FastAPI app entrypoint
├── generate_keys.py       # Ed25519 keypair generator
├── requirements.txt       # 7 deps, no ML
└── .env.example           # Environment template
```
