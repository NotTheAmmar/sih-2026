# Flutter → ONDC Integration Checklist

> **Status:** ✅ Implemented in Prototype  
> **Depends on:** `kalakriti-backend` BPP server running (see [backend-quickstart.md](./backend-quickstart.md))  
> **Last updated:** 2026-09-11

This document tracks everything needed to wire the Flutter mobile app's
**"Publish"** button directly to the ONDC BPP backend, so artisan listings
flow from the Flutter catalog card all the way onto the ONDC network.

---

## Overview: What Needs to Happen

```
Flutter App (CatalogScreen)
  │  Artisan taps "Publish to ONDC"
  │  POST /api/v1/bpp/publish  ──────────►  KalaKriti BPP (FastAPI)
  │  ← {"status": "PUBLISHED",              │  save_active_listing()
  │      "catalog_id": "cat_xxx"}           │
  │                                         │  Next /beckn/search arrives
  │  Show ✓ Published badge                 │  → on_search callback fires
  │  Update CatalogStatus.published         │  → ONDC Buyer Apps can discover it
```

---

## Task Checklist

### 1. Backend URL Configuration

- `[x]` Add `BPP_BACKEND_URL` to the Flutter app's `.env` file:
  ```env
  BPP_BACKEND_URL=http://localhost:8000
  # Or your Cloudflare tunnel URL for device testing:
  # BPP_BACKEND_URL=https://YOUR-TUNNEL.trycloudflare.com
  ```
- `[x]` Add `bppBackendUrl` getter to [`lib/config/constants.dart`](file:///home/ammar/Programs/Flutter/sih_26_kalakriti/lib/config/constants.dart):
  ```dart
  static String get bppBackendUrl =>
      dotenv.env['BPP_BACKEND_URL'] ?? 'http://localhost:8000';
  ```

---

### 2. Publish Service Method

- `[x]` Add `publishToOndc` method to [`lib/services/api_service.dart`](file:///home/ammar/Programs/Flutter/sih_26_kalakriti/lib/services/api_service.dart).

  **Request body** — map Flutter's `CatalogItem` + `PricingCorridor` to the BPP's `ArtisanListingPayload` schema:

  ```dart
  final body = {
    "catalog_id": item.id,
    "artisan_name": item.craftAttributes?.artisanName ?? "KalaKriti Artisan",
    "cluster_name": item.craftAttributes?.clusterLocation ?? "Chanderi Handloom Cluster",
    "title_en": item.titleEn ?? "",
    "title_hi": item.titleHi ?? "",
    "description_en": item.descriptionEn ?? "",
    "description_hi": item.descriptionHi ?? "",
    "craft_category": item.craftAttributes?.category ?? "Handloom Silk",
    "materials": item.craftAttributes?.materials ?? [],
    "floor_price": item.pricing?.floorPrice.toDouble() ?? 0.0,
    "fair_price": item.pricing?.fairPrice.toDouble() ?? 0.0,
    "premium_price": item.pricing?.premiumPrice.toDouble() ?? 0.0,
    "studio_image_url": item.studioImagePath ?? "",
    "dimensions": item.craftAttributes?.dimensions ?? "1 unit",
    "available_qty": availableQuantity,
  };
  ```

  **Response:** Check `status == "PUBLISHED"` and return the `catalog_id`.

- `[x]` Add the same method stub to `MockApiService` (returns `"PUBLISHED"` after a short delay for demo mode).

---

### 3. CatalogController — Publish Action

- `[x]` Add `publishToOndc()` method to [`lib/controllers/catalog_controller.dart`](file:///home/ammar/Programs/Flutter/sih_26_kalakriti/lib/controllers/catalog_controller.dart):
  - Sets a `isPublishing` loading flag
  - Calls `apiService.publishToOndc(currentItem)`
  - On success: updates `currentItem.status = CatalogStatus.published`
  - On failure: sets `publishError` string for UI display
  - Notifies listeners

---

### 4. CatalogScreen UI — Publish Button

- `[ ]` Update [`lib/views/screens/catalog_screen.dart`](file:///home/ammar/Programs/Flutter/sih_26_kalakriti/lib/views/screens/catalog_screen.dart):
  - Replace / augment the existing "Phir Se Karein" (Retake) CTA with a new primary **"ONDC par Prakashan Karein"** (Publish to ONDC) green button
  - Show `CircularProgressIndicator` while `isPublishing == true`
  - Show a **✓ Published** green badge with the catalog_id on success
  - Show a retry snackbar on failure

  > [!NOTE]
  > Per the zero-typing mandate, the publish confirmation can be a large
  > green button with a checkmark icon + TTS readback: _"Aapka utpad
  > ONDC par prakashan ho gaya hai"_ (Your product has been published on ONDC).

---

### 5. Status Persistence

- `[ ]` Update [`lib/services/storage_service.dart`](file:///home/ammar/Programs/Flutter/sih_26_kalakriti/lib/services/storage_service.dart) to persist `CatalogStatus.published` in SharedPreferences/SQLite so the badge survives app restarts.

---

### 6. End-to-End Test Flow

Once wired up, the full demo flow becomes:

1. Capture photo → voice narration → AI pipeline runs
2. Catalog card appears with pricing corridor
3. Artisan taps **"ONDC par Prakashan Karein"**
4. Flutter POSTs to `/api/v1/bpp/publish` → gets `"PUBLISHED"` response
5. Green badge appears; TTS reads confirmation
6. On ONDC Workbench, trigger a `/beckn/search` → see the listing appear in `on_search`

---

## API Contract (Flutter → BPP)

### `POST /api/v1/bpp/publish`

**Request:**
```json
{
  "catalog_id": "cat_a7f3b2",
  "artisan_name": "Ramesh Kumar",
  "cluster_name": "Chanderi Handloom Cluster",
  "gps_coordinates": "24.7118,78.1098",
  "area_code": "473446",
  "title_en": "Handwoven Chanderi Silk Dupatta",
  "title_hi": "हाथ से बुनी चंदेरी सिल्क दुपट्टा",
  "description_en": "...",
  "description_hi": "...",
  "craft_category": "Handloom Silk",
  "category_id": "ONDC:RET12",
  "materials": ["Pure Mulberry Silk", "Gold Zari"],
  "dimensions": "6.2 meters",
  "floor_price": 1760.0,
  "fair_price": 2640.0,
  "premium_price": 3168.0,
  "studio_image_url": "https://...",
  "available_qty": 5
}
```

**Success Response (200):**
```json
{
  "status": "PUBLISHED",
  "message": "Listing 'Handwoven Chanderi Silk Dupatta' is now active on ONDC rails.",
  "catalog_id": "cat_a7f3b2",
  "artisan": "Ramesh Kumar",
  "fair_price_inr": 2640.0
}
```

**Error Response (422 — validation failure):**
```json
{
  "detail": [{"loc": ["body", "floor_price"], "msg": "...", "type": "..."}]
}
```

---

## Notes

- `gps_coordinates` and `area_code` are not currently in the Flutter app's data model. These should ideally come from the artisan's device GPS or a cluster registry lookup. For the demo, hardcode the Chanderi cluster defaults (already the BPP default).
- `studio_image_url` needs to be a publicly accessible URL. If the studio image is only on-device, either upload it to a CDN first, or use the fallback Unsplash URL for the demo.
- The `available_qty` field has no equivalent in the current Flutter flow — hardcode to `5` for the demo.
