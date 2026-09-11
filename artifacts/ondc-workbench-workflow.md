# ONDC Workbench Integration & Workflow

> **Component:** ONDC Network Testing & Validation  
> **Role:** Simulates the ONDC Buyer App (BAP) and Network Gateway to test the KalaKriti Seller Platform (BPP).  

This document explains the role of the ONDC Workbench in the KalaKriti AI ecosystem, the parameters used for connection, and the end-to-end Beckn protocol workflow that enables our rural artisans to sell on the open network.

---

## 1. What is the ONDC Workbench?

The ONDC Workbench is an official testing sandbox provided by ONDC. Since the real ONDC network requires extensive legal and technical onboarding, the Workbench acts as a simulated **Gateway** and **Buyer App (BAP)**. 

**Its Role in KalaKriti:**
It allows us to prove that the KalaKriti FastAPI Backend successfully functions as a **Beckn Provider Platform (BPP) / Seller Node**. When an artisan hits "Publish" on the Flutter app, we use the Workbench to verify that the listing is correctly broadcasted across the network, fully compliant with ONDC protocols.

---

## 2. Connection Architecture

Because ONDC requires public URLs to send webhook callbacks, the connection flow relies on secure tunnels during development.

1. **Flutter App (Mobile):** The artisan finalizes pricing and taps *Publish*. The app sends the catalog data to the KalaKriti BPP.
2. **KalaKriti BPP (FastAPI):** Receives the listing and saves it in the active catalog store. It is running locally on port `8000`.
3. **Cloudflare Tunnel (`cloudflared`):** Exposes the local `localhost:8000` to a public URL (e.g., `https://my-tunnel.trycloudflare.com`).
4. **ONDC Workbench:** Sends Beckn protocol requests (like `/search`) to our tunnel URL, and our FastAPI server responds to the Workbench's callback URL.

---

## 3. Workbench Session Parameters

To initiate a testing session, the Workbench requires specific parameters to configure the simulated ONDC network. For KalaKriti (Handicrafts/Apparel), we use the following configuration:

| Parameter | Selected Value | Explanation |
| :--- | :--- | :--- |
| **Subscriber Type** | `BAP` | Workbench acts as a Buyer App (like Paytm or Magicpin) requesting data from us. |
| **Domain** | `ONDC:RET12` | The specific ONDC retail domain for **Fashion & Handlooms**. |
| **Version** | `1.2.0` | The current stable Beckn API version for retail. |
| **Use Case** | `FASHION` | Tailors the test scenarios to apparel and handicraft rules. |
| **Environment** | `PRE-PRODUCTION` | The staging environment. |
| **Base URL** | `https://<tunnel>.trycloudflare.com` | Our exposed FastAPI backend endpoint. |

---

## 4. The Beckn Protocol Workflow (The "6-Step Dance")

ONDC relies on the **Beckn Protocol**, which uses asynchronous, paired API calls. For every request from a Buyer (BAP), the Seller (BPP) must immediately return an `ACK` (Acknowledgement), and then asynchronously send the actual data via an `on_<action>` callback.

Here is the exact workflow tested via the Workbench:

### Phase 1: Discovery (Cataloging) - *Our Primary Focus*
1. **`/search`** *(Workbench → KalaKriti)*: The simulated buyer searches for "Sarees" or "Handicrafts".
2. **`/on_search`** *(KalaKriti → Workbench)*: Our backend maps the artisan's `CatalogItem` into the ONDC schema and pushes the full catalog back to the network.

### Phase 2: Order Fulfillment
3. **`/select` & `/on_select`**: The buyer adds the artisan's item (e.g., Chanderi Dupatta) to their cart. We confirm availability (`available_qty`) and final price.
4. **`/init` & `/on_init`**: The buyer provides their shipping address. We return the shipping cost and billing details.
5. **`/confirm` & `/on_confirm`**: The buyer completes payment. We confirm the order creation and return an Order ID.
6. **`/status` & `/on_status`**: Tracking the shipment progress (Packed, Dispatched, Delivered).

---

## 5. Catalog Field Mapping (`/on_search`)

When the Flutter app pushes data to the backend, the backend formats it to strictly pass the Workbench's `ONDC:RET12` validation schemas:

*   **`bpp/providers`**: Identifies the specific artisan cluster (e.g., Chanderi Handloom Cluster).
*   **`items`**: 
    *   `id`: Flutter's `catalog_id`.
    *   `descriptor.name`: The product title (`title_en`).
    *   `descriptor.images`: The `studio_image_url` output from the AI matting pipeline.
    *   `category_id`: Hardcoded to `ONDC:RET12` for fashion/crafts.
*   **`price`**: 
    *   `value`: The final selling price (strictly $\ge$ the Statutory Floor $C_{\text{floor}}$).
    *   `maximum_value`: The premium price ceiling.
*   **`quantity.available`**: Derived from Flutter's `availableQuantity` stepper.
*   **`tags` (Legal Metrology)**: Extracts dimensions, manufacturer details, and country of origin required by Indian e-commerce law.
