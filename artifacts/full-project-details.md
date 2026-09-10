# Project Proposal: KalaKriti AI (कलाकृति AI)
## Autonomous Voice-First Studio & Decentralized Commerce Engine for Marginalized Artisans

**Smart India Hackathon 2026 | Problem Statement ID: SIH26090**  
**Ministry:** Ministry of Social Justice and Empowerment (MoSJE), Department of Social Justice and Empowerment  
**Category:** Software | **Theme:** Heritage & Culture  
**Team Name:** LetEmCook  

---

## Executive Summary
Traditional artisans and handloom weavers across India remain tethered to sporadic physical trade fairs (such as Shilp Samagam, Surajkund Mela, and Dilli Haat) and predatory intermediaries, leaving over 66% of artisan households earning below ₹5,000 monthly. While India's craft sector drives more than ₹35,000 Crore in export earnings, e-commerce channels contribute a negligible 0.2% of total weaver sales. Complex, text-heavy onboarding portals create an 80%+ drop-off rate among low-literacy craftspeople.  

KalaKriti AI is a sovereign, voice-first mobile platform that functions as an autonomous "Virtual Business Manager". Operating under a zero-typing and zero-dashboard design pattern, KalaKriti AI transforms an unedited smartphone photo taken on a workshop floor alongside a 15-second regional dialect voice note into an e-commerce-ready, bilingual listing (Hindi and English) equipped with an algorithmic fair-price corridor. The platform syndicates products directly to open commerce networks (ONDC) and government procurement portals (GeM) in under 60 seconds with an inference compute cost under ₹0.07 per catalog.  

## Problem Context & Field Evidence

- **Intermediary Squeeze:** A 2022 value-chain assessment by Sattva Knowledge Institute established that 90% of rural weavers remain tied to traders and master weavers, who extract 30% to 50% profit margins, keeping primary creators in chronic poverty.  
- **Digital Onboarding Drop-Off:** The Digital Empowerment Foundation (DEF) surveyed over 2,000 handicraft workers across India and found that while more than 90% of artisans desire to sell online, over 80% abandon the process when confronted with complex desktop web forms and English-only interfaces. Only ~20% of artisans have ever received any digital sales training.  
- **Severe Economic Disparity:** The Fourth All-India Handloom Census reported that despite high domestic and global demand, e-commerce generates merely 0.2% of weaver sales, with over two-thirds of weavers earning less than US $63 (~₹5,000) per month.  
- **Lack of Formal Credit:** Over 75% of rural weavers lack formal banking records or transaction histories, disqualifying them from central credit schemes such as MUDRA loans.  

## Proposed Solution Architecture

KalaKriti AI eliminates text-input barriers by replacing traditional admin screens with an automated, multimodal ingestion pipeline.  

```text
[Raw Smartphone Photo] ──> On-Device Matting (BiRefNet INT8) ──> Studio-Grade Image (1:1 Canvas)
                                                                       │
[15-Sec Dialect Voice] ──> Bhashini ASR ──> IndicTrans2/Gemini Flash ──┼──> Dynamic Fair-Pricing Engine
                                                                       │    (CLIP ViT-B/32 + XGBoost)
                                                                       ▼
[Bilingual Catalog Card] ──> 1-Tap ONDC / GeM Publish ──> Automated 3PL Dispatch (Beckn Protocol)
```

### Core System Modules

- **AI Image Enhancer & Studio Module:** Ingests raw camera frames, isolates complex craft textures, eliminates workshop clutter, corrects lighting via adaptive histogram equalization, and synthesizes realistic contact shadows without manual bounding-box adjustments.  
- **Voice-Driven Multilingual Auto-Cataloger:** Ingests 15-second dialect audio notes, transcribes them via regional acoustic models, extracts structured attributes (dimensions, raw materials, crafting days), and generates bilingual product listings.  
- **Dynamic Fair-Pricing Assistant:** Evaluates visual craft complexity alongside recorded input costs to predict a transparent 3-tier price corridor (Floor, Fair, and Premium).  
- **Decentralized Commerce & 3PL Integration:** Acts as an open Beckn Provider Platform (BPP / Seller Node) that broadcasts product catalogs to ONDC buyer apps and assigns nearest couriers automatically.  

## Technical Specification & Deep Learning Pipeline

### 1. Edge Vision & Automated Studio Compositing

Traditional background removal pipelines fail on intricate textile borders, loose threads, and porous brassware. KalaKriti AI executes a multi-stage vision pipeline optimized for budget hardware (4GB RAM) targeting sub-750 ms total turnaround:  

- **Real-Time Framing (CameraX & OpenCV C++):** Ingests the 1080p camera buffer stream at 30 FPS, checking framing coordinates and object boundaries (~45 ms).  
- **Illumination Normalization:** Applies Contrast Limited Adaptive Histogram Equalization (CLAHE) to balance harsh workshop sunlight or low ambient indoor lighting (~30 ms).  
- **High-Resolution Matting (BiRefNet / RMBG-1.4 INT8):** Bilateral Reference Network running via ONNX Runtime Mobile leverages NNAPI acceleration to predict fine alpha mattes for complex contours (~520 ms).  
- **Guided Filter Refinement:** OpenCV guided filtering refines semi-transparent hair-fine fringes and fringe tassels (~65 ms).  
- **Studio Blending:** Composites the product onto a clean 1:1 neutral studio canvas, synthesizing a directional contact drop-shadow to maintain ground contact (~40 ms).  

### 2. Multilingual Voice-to-Catalog Engine

Artisans provide context naturally in their spoken dialect (e.g., Bundelkhandi-influenced Hindi or rural Marathi). The UI operates with zero required keyboard input:  

- **Audio Ingestion & Noise Gate:** A Flutter native audio stream captures 16 kHz PCM audio while applying local DSP noise-reduction filters (~20 ms).  
- **Speech-to-Text (ASR):** Bhashini ASR and IndicWav2Vec models transcribe spoken speech into regional text representations (~800 ms).  
- **Entity Extraction & Translation:** Gemini 2.5 Flash processes the transcription into structured JSON entities while IndicTrans2 generates grammatically accurate, SEO-optimized descriptions in English and standard Hindi (~1,200 ms):  

```json
{
  "artisan_name": "Ramesh Kumar",
  "craft_category": "Handloom Silk Sarees",
  "cluster_location": "Chanderi, Madhya Pradesh",
  "base_material": "Pure Mulberry Silk & Gold Zari",
  "dimensions": "6.2 meters",
  "labor_duration_days": 5,
  "stated_raw_material_cost_inr": 1100
}
```

- **Audio Readback Verification (TTS):** Bhashini Text-to-Speech reads the extracted listing summary back to the artisan in their native dialect for audio verification (~400 ms).  

### 3. Dynamic Fair-Pricing Engine

To prevent distress selling to middlemen or excessive pricing that suppresses digital liquidity, the pricing engine fuses cost accounting, visual feature density, and live market benchmarks.  

**Step 1: Non-Negotiable Algorithmic Cost Floor ($C_{floor}$):**
Guarantees the artisan never operates at a capital loss:
$$C_{floor} = M_{raw} + (T_{days} \times W_{artisan}) + O_{overhead}$$

Where:
- $M_{raw}$: Extracted cost of yarn, dyes, clay, wood, or metals.  
- $T_{days}$: Labor days recorded via voice transcription.  
- $W_{artisan}$: Statutory skilled craft wage rate per day (benchmarked at ₹450–₹600/day against Ministry standards).  
- $O_{overhead}$: Fixed overhead allowance (packaging, local transport, utilities ~ 10%).  

**Step 2: Visual Complexity Embedding ($F_{visual}$):**
Intricate hand-detailing (e.g., weave count, border density) is extracted using a pretrained CLIP ViT-B/32 visual encoder:
$$E_{img} = \text{CLIP-Encoder}(I_{studio}) \in \mathbb{R}^{512}$$
A linear projection compresses $E_{img}$ into an 8-dimensional visual intricacy vector $V \in \mathbb{R}^8$.  

**Step 3: Tabular Feature Vector Construction ($X$):**
$$X = [C_{floor}, M_{raw}, T_{days}, V_1 \dots V_8, \text{OneHotCategory}, \text{GeoClusterPin}]$$
  
**Step 4: Gradient-Boosted Market Regression:**
Vector $X$ passes into an XGBoost/LightGBM regressor trained on 45,000+ scraped listings from GeM, Tribes India, ONDC, and Amazon Karigar to output the fair selling price $P_{fair}$.  

- **Floor Price ($P_{floor}$):** Base breakeven rate for fast inventory clearance.  
- **Fair Market Price ($P_{fair}$):** Recommended standard D2C price.  
- **Premium / B2B Price ($P_{prem}$):** Scaled for corporate bulk or GeM institutional procurement:
$$P_{prem} = P_{fair} \times 1.20$$
  
### 4. Decentralized Protocol Linkage & Fulfillment

- **Beckn Provider Platform (BPP):** KalaKriti AI translates saved inventory catalogs into standard Beckn schemas (`/on_search`, `/on_select`, `/on_init`, `/on_confirm`).  
- **Cross-Network Syndication:** Product catalogs sync across all ONDC-enabled buyer applications (e.g., Paytm, Mystore, Craftsvilla) and central government portals (GeM) via unified JSON-LD schema feeds.  
- **Automated 3PL Logistics:** Accepting an incoming order triggers automated Beckn logistics calls to 3PL partners (Delhivery, Shadowfax, India Post), generating a scannable waybill QR code directly on the artisan's mobile screen without requiring label printers.  

## Technical Architecture & Technology Stack

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   KalaKriti Client (Flutter Mobile)                    │
│   • CameraX Capture Viewfinder        • Audio Record / Playback        │
│   • Offline SQLite Local Storage      • Multilingual Pictorial UI      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTPS / REST (Multipart Payloads)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   High-Performance Backend (FastAPI)                   │
│   • Auth & Ingestion Gateways         • PostGIS Cluster Mapping        │
│   • Redis Streaming Task Queue        • PostgreSQL Transaction Stores  │
└───────┬───────────────────────────┬───────────────────────────┬────────┘
        │                           │                           │
        ▼                           ▼                           ▼
┌──────────────────┐        ┌──────────────────┐        ┌────────────────┐
│ Edge/Vision Host │        │ Speech / NLP     │        │ Commerce Rails │
│ • BiRefNet INT8  │        │ • Bhashini ASR   │        │ • Beckn Adapter│
│ • OpenCV Engine  │        │ • IndicTrans2    │        │ • ONDC Gateway │
│ • CLIP ViT-B/32  │        │ • Gemini Flash   │        │ • GeM / 3PL API│
└──────────────────┘        └──────────────────┘        └────────────────┘
```

### Technology Component Stack

| Subsystem | Technology Component | Exact Role in KalaKriti AI |
| :--- | :--- | :--- |
| **Mobile Client** | Flutter 3.x, Dart | Cross-platform, high-contrast, accessible UI for low-literacy users. |
| **Local Camera Engine** | CameraX / Native Bindings | Stream frame extraction and focus locking on budget devices. |
| **Local Cache** | SQLite, Hive | Store-and-forward offline synchronization for rural areas with spotty 2G/3G connectivity. |
| **Vision Matting** | BiRefNet / RMBG-1.4 (ONNX INT8) | Clutter removal and studio extraction under 550 ms. |
| **Speech Recognition** | Bhashini ASR, IndicWav2Vec | Indian dialect speech recognition across regional craft clusters. |
| **Translation & LLM** | IndicTrans2, Gemini 2.5 Flash | 22-language translation and structured JSON entity parsing. |
| **Pricing Regressor** | XGBoost 2.0, LightGBM, CLIP | Multimodal valuation combining visual features and raw input costs. |
| **Backend Framework** | Python 3.11, FastAPI, Uvicorn | Asynchronous REST endpoints and background job processing. |
| **Cache & Message Broker** | Redis, Celery | Queueing heavy ML tasks and managing inference request state. |
| **Database & GIS** | PostgreSQL 16, PostGIS | Spatial demand mapping and artisan cluster metadata tracking. |
| **Decentralized Commerce** | Beckn Protocol SDK, ONDC Gateway | Seller node integration for multi-platform catalog visibility. |

## Edge Cases, System Failures & Mitigation

- **Blurry or Underexposed Photography:** An on-device Laplacian variance check ($Var<100$) detects motion blur, while an ambient luminance check ($Y<40$) identifies low-light conditions. The app automatically triggers the flashlight and issues an audio warning: *"Photo saaf nahi hai. Kripya roshni me jaakar dobara khinchein"*.  
- **Acoustic Noise in Weaving Clusters:** Looms and workshops introduce ambient clatter. If speech confidence drops below 0.55, the waveform glows amber, prompting via audio: *"Aawaz theek se sunai nahi di. Kripya phone ke thoda paas aakar boliye"*.  
- **Network Connectivity Drops:** When rural artisans operate in zero-connectivity zones, raw images and audio recordings are stored locally in an encrypted SQLite store-and-forward queue. Listings upload and process automatically once connection is re-established.  

## Feasibility, Viability & Business Model

### Technical & Operational Feasibility
- **Compute Cost Efficiency:** Compressing the segmentation model into ONNX INT8 and relying on targeted LLM calls limits the compute pipeline cost to under ₹0.07 per generated catalog (Groq Whisper ₹0.039 + Gemini 2.5 Flash ₹0.023 at paid rates; ₹0 on free tiers).  
- **Zero Barrier to Adoption:** The app features zero typing, zero English requirement, and zero manual cropping grids, removing the key friction points that cause an 80%+ digital drop-off.  

### Business Model & Sustainable Monetization
- **Core Application Access:** 100% free for marginalized artisans, weavers, and self-help groups (SHGs).  
- **B2B Order Convenience Fee:** A nominal 1.5% transaction commission applied strictly on bulk corporate, institutional, and GeM procurement contracts executed through the network.  
- **Open Rail Efficiency:** Operates over open 3%–5% ONDC rails, completely bypassing the 30%–50% margins claimed by physical intermediaries and traditional e-commerce platforms.  
- **Credit Linkage via OCEN:** Catalogs, order fulfillment milestones, and sales histories create a verified ledger, enabling artisans to qualify for collateral-free micro-loans through the Open Credit Enablement Network (OCEN) and MoSJE schemes.  

## Competitive Differentiation

| Feature / Capability | KalaKriti AI | Amazon Karigar | Traditional ONDC Apps | Generic Photo Apps |
| :--- | :--- | :--- | :--- | :--- |
| **Voice Dialect Cataloging** | Yes (Bhashini) | No | No | No |
| **Bilingual Auto-Descriptions** | Yes (IndicTrans2) | No | No | No |
| **Edge Craft Matting** | Yes (BiRefNet INT8) | No | No | Yes (Basic) |
| **Multimodal Fair Pricing** | Yes (CLIP + XGBoost) | No | No | No |
| **Decentralized ONDC Sync** | Yes (1-Tap Beckn) | No (Walled Garden) | Yes (Manual Forms) | No |
| **Zero-Typing Visual UI** | Yes (Audio-First) | No | No | No |
| **Passive Credit Ledger (OCEN)** | Yes | No | No | No |

## Implementation Roadmap

### Phase 1: Prototype Validation (Current Internal Hackathon Baseline)
- Complete Flutter client implementation of the 4-step wizard (Camera viewfinder, audio recorder, loading shimmer, catalog card preview).  
- Deployment of FastAPI mock endpoints with structured Indian handicraft payloads (Chanderi silk, terracotta, brass filigree).  
- Verification of on-device camera framing, audio capture buffers, and audio readback simulation.  

### Phase 2: Core AI Integration (National Screening Phase)
- Package BiRefNet INT8 with ONNX Runtime Mobile for on-device/edge studio segmentation.  
- Connect Bhashini ASR endpoints and configure IndicTrans2 inference for the top 5 craft cluster languages.  
- Train the baseline XGBoost pricing regressor using scraped public handicraft catalogs.  

### Phase 3: Network Rails & Field Pilot (Grand Finale Phase)
- Deploy the Beckn Protocol Provider Platform adapter to establish live transactions across the ONDC staging sandbox.  
- Integrate automated waybill QR generation via 3PL staging APIs.  
- Pilot user testing across target artisan clusters to optimize ASR noise tolerance and dial in UX accessibility.  

## Key References

- **Ministry of Social Justice and Empowerment (MoSJE):** Problem Statement Guidelines for SIH26090.  
- **Sattva Knowledge Institute & ONDC (2022):** Ecosystem Study on Unlocking Digital Commerce for Indian Artisans and Weavers.  
- **Ministry of Textiles (MoT):** Fourth All-India Handloom Census (2019–2020).  
- **Digital Empowerment Foundation (DEF):** Enhancing Livelihood of Artisans and Weavers in Knowledge Economy.  
- **Gala et al. (TMLR 2023):** IndicTrans2: Towards High-Quality Machine Translation for All 22 Scheduled Indian Languages.  
- **Zheng et al. (CVPR 2024):** Bilateral Reference Network (BiRefNet) for High-Resolution Dichotomous Image Segmentation.  
- **Beckn Protocol Specifications:** Open Protocol for Decentralized Digital Commerce Networks.
