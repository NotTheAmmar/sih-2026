# KalaKriti AI (कलाकृति AI): Prototype Technical Specification

**Document Version:** 1.0.0-MVP  
**Smart India Hackathon 2026 \| Problem Statement ID:** SIH26090  
**Target Ministry:** Ministry of Social Justice and Empowerment (MoSJE)  
**Platform Architecture:** Cross-Platform Mobile Client (Flutter) + Headless REST Engine  

---

## Prototype Scope vs. Final Production Scope
The prototype isolates and validates the core user ingestion journey—the Magic Ingestion Loop—proving that an unschooled artisan can produce an e-commerce-ready listing without typing a single character.

### Scope Comparison

| Functional Domain | Hackathon Prototype Scope (Internal MVP) | Final Target System (SIH Finale) |
|---|---|---|
| **Visual Capture & Matting** | Camera capture & gallery picking; studio background substitution simulation with before/after comparison. | Real-time on-device BiRefNet INT8 neural matting, shadow synthesis, and illumination normalization. |
| **Voice Processing** | Local 15-second audio capture; waveform visualization; Groq Whisper-Large-v3 transcription → Gemini 2.5 Flash structured extraction → `flutter_tts` Hindi readback. | Dialect-level Bhashini ASR / AI4Bharat IndicConformer across 22 scheduled languages with automated background loom-noise suppression and Indic-Parler-TTS natural voice readback. |
| **Valuation Engine** | Calculation of the 3-tier price corridor (Floor, Fair, Premium) using extracted labor days and raw material inputs. | Full multimodal pricing fusion combining visual CLIP complexity embeddings and live web-scraped market telemetry. |
| **Network Rails** | Local catalog card rendering with simulated 1-tap dispatch trigger. | Live Beckn Provider Platform (BPP) injection into the ONDC staging gateway and GeM procurement API. |
| **Data Persistence** | In-memory session state with a local fallback data contract. | Encrypted offline SQLite store-and-forward architecture paired with PostgreSQL/PostGIS telemetry. |

---

## Screen-by-Screen User Experience & Interface Specifications

### Screen 1: Direct Visual Ingestion (Camera Viewfinder & Picker)
**Objective:** Enable the artisan to capture or select a raw handicraft photograph on a cluttered workshop surface without needing to navigate complex menus.

**Layout Hierarchy:**
* **Primary Viewport:** Full-screen 1:1 camera framing guide featuring a high-contrast boundary overlay to indicate proper placement.
* **Controls Overlay:** A persistent bottom action dock holding two oversized, tactile buttons: a primary shutter icon for direct camera snap and a secondary gallery folder icon for pre-shot files.
* **Image Review Overlay:** Once an image is captured or selected, the viewfinder pauses to display the full image preview with two primary options: a red "Retake" button (↺) and a green "Proceed to Voice" button (✔).

**Interaction Rules:**
* No manual crop sliders, boundary pull-handles, or pinch-to-zoom requirements.
* Haptic buzz feedback fires upon image acquisition to confirm the frame capture without requiring the artisan to read an on-screen prompt.

### Screen 2: Tactile Voice Narration Interface
**Objective:** Capture 15 seconds of regional spoken narration detailing raw materials, creation time, and craft history with zero text entry.

**Layout Hierarchy:**
* **Top Context Area:** A rounded thumbnail card of the captured handicraft image for visual continuity.
* **Central Audio Node:** A single, centered, pulsing microphone target measuring 72 dp in diameter. The outer halo pulsates rhythmically during recording.
* **Audio Visualizer:** A dynamic 30-bar amplitude waveform positioned beneath the mic button that reflects sound waves in real time to visually confirm that speech is being registered.
* **Countdown Meter:** A high-contrast circular or bar timer counting down from 15 to 0 seconds, indicating elapsed recording time.

**Interaction Rules:**
* **One-Tap Initiation:** Tapping the microphone starts recording; tapping it a second time halts the buffer immediately.
* **Auto-Cutoff:** If the artisan speaks continuously, the recorder automatically stops and locks the buffer at the 15-second mark to prevent file bloat.
* **Audio Confirmation:** If zero audio amplitude is registered, the interface prompts with an amber visual pulse and an audible chime prompting the user to speak again.

### Screen 3: Inference & Multimodal Pipeline State
**Objective:** Mask backend computation latencies while visually explaining AI actions to build trust with the artisan.

**Layout Hierarchy:**
* **Central Element:** A shimmering, progressive status spinner styled with traditional craft motifs.
* **Visual Stepper Indicators:** Three clear progress checkpoints that illuminate sequentially:
  1. **Stage 1:** "Studio Safai" (Eliminating background clutter and balancing lighting).
  2. **Stage 2:** "Aawaz ki Pehchan" (Transcribing dialect voice and parsing materials).
  3. **Stage 3:** "Sahi Daam Ganana" (Calculating statutory costs and fair price corridor).

**Interaction Rules:**
* No numerical progress percentages (e.g., "67%"); transitions rely strictly on pictorial checkmarks and accessible status lights.

### Screen 4: Interactive Bilingual Catalog Card & Valuation
**Objective:** Present the generated e-commerce listing for auditory and visual verification, giving the artisan final approval before publication.

**Layout Hierarchy:**
* **Interactive Studio Preview:** A centered visual container featuring a toggle control to switch between "Kaccha Photo" (Raw photo on the floor) and "Studio Photo" (Clean white backdrop with natural contact drop-shadow).
* **Audio Readback Control:** A prominent speaker button that plays a generated voice readout of the listing in the artisan's dialect (e.g., verifying item name, material, and calculated price).
* **Structured Attribute Chips:** A vertical grid of pictorial chips:
  * **Craft Category:** Identified heritage category (e.g., Chanderi Weave, Terracotta).
  * **Detected Materials:** Extracted primary fibers or elements (e.g., Pure Silk, Zari).
  * **Crafting Duration:** Dedication time parsed from voice (e.g., 5 Days).
* **3-Tier Fair-Pricing Corridor:** A tripartite visual price gauge:
  * **Floor Price (Base Clearance):** Breakeven threshold covering materials and minimum daily wage.
  * **Fair Market Price (Recommended D2C):** Algorithmically optimized price for open commerce.
  * **Premium Price (Institutional/B2B):** Suggested quote for bulk government or corporate procurement.
* **Primary Action Bar:** A full-width "Phir Se Karein" (Retake Voice/Photo) button in a muted outlined style, allowing the artisan to restart the capture cycle. ONDC publishing integration is deferred to Phase 2.

---

## Design System & Rural Accessibility Tokens
To ensure operational viability for weavers and rural artisans who may have calloused hands, low formal literacy, or operate outdoors in direct sunlight, the prototype implements the following accessibility constraints:

* **Oversized Hit Geometry:** All interactive buttons (camera shutter, mic trigger, confirmation marks) are standardized between 64 dp and 72 dp, significantly exceeding standard 48 dp requirements to prevent missed taps.
* **Triple-Feedback Law:** Every button tap simultaneously triggers an interface transition, a distinct tactile vibration, and an audible confirmation chime.
* **Absolute Zero-Typing Mandate:** The prototype does not call up the operating system keyboard at any point in the workflow. Adjustments to figures are performed exclusively via tactile stepping buttons (+ / -).

### WCAG AAA Sunlight Contrast Palette

| Color Token | Hex Code | Usage |
|---|---|---|
| **Action Green** | `#16A34A` | Dedicated to forward actions, price confirmation, and publishing. |
| **Warning Amber** | `#D97706` | Flags audio underexposure, quiet speaking volume, or processing states. |
| **Alert Red** | `#DC2626` | Reserved for recording cancellation, resetting the canvas, or retaking assets. |
| **Canvas Background** | `#F9FAFB` / `#111827` | High-contrast neutral bases (Light/Dark) that prevent glare reflections in outdoor craft yards. |

---

## Data Models & Service Architecture
The prototype decouples the frontend client from the heavy AI microservice via a clean abstraction layer, supporting immediate hackathon demonstration via a mock toggle while permitting seamless backend API integration.

### Unified Catalog Entity Schema
The data exchanged between the ingestion interface and the catalog storage layer contains:
* **Identification:** Unique listing identifier and session timestamp.
* **Media Assets:** Device path to the raw input photo, URL to the studio-enhanced output photo, and path to the recorded audio file.
* **Bilingual Descriptors:** Dual string representations for product titles and descriptions (both in English and standardized Hindi).
* **Extracted Craft Attributes:** String category name, array of detected materials, and numerical labor duration measured in days or hours.
* **Algorithmic Pricing Corridor:** Numerical integer fields for the floor price, recommended fair price, and premium quote (in INR).
* **Network Status:** Lifecycle state marker (e.g., Draft, Stored Locally, Published to ONDC).

### Decoupled Service Contract
* **State Management Strategy:** The mobile client maintains a central catalog creation controller that tracks current ingestion steps: idle, media picked, recording, processing, and finalized.
* **Mock Toggle Mode:** When enabled, the network service bypasses external calls, injecting pre-configured artisan test payloads representing authentic craft clusters (such as Chanderi silk dupattas or terracotta pots) after a timed delay to simulate inference latencies.
* **Live Integration Mode:** When disabled, the network service packages the local image and audio files into a standard multipart payload, transmitting them to the team's backend for model inference.

---

## Edge Cases, Guardrails & Fallback Mechanisms
* **Acoustic Noise Interference:** Rural craft clusters present ambient mechanical clatter (such as handloom shuttles, hammer strikes, or outdoor street noise). If incoming audio amplitude fluctuates erratically without clear speech formants, the recording visualizer turns amber, and the app prompts the artisan with an audio message: *"Aawaz theek se sunai nahi di. Kripya phone ke thoda paas aakar boliye"*.
* **Blurry or Dim Photography:** If an artisan captures a photo in low-light conditions or with camera shake, an edge variance check flags the image before submission. The UI displays a warning icon alongside an automated voice prompt: *"Photo saaf nahi hai. Kripya roshni me jaakar dobara khinchein"*.
* **Network Disconnection (Offline Resilience):** If internet access drops during capture, the prototype writes the image and audio payloads directly to local device storage, marking the listing as locally cached. A persistent visual sync badge informs the user that catalog creation will conclude automatically as soon as connectivity resumes.

---

## Internal Hackathon Evaluation & Live Demonstration Walkthrough
This step-by-step demonstration script is structured to highlight design feasibility, technical depth, and alignment with the MoSJE brief within a standard 3-minute pitch window:

### Step 1: The Context & Problem Hook (0:00 – 0:30)
* Introduce the team and open the app on an Android device.
* Explain the core friction: Traditional e-commerce platforms demand desktop dashboards, product descriptions written in English, and professional photography, creating an 80%+ drop-off rate for marginalized artisans.
* State the mission: KalaKriti AI provides a complete, zero-typing "Virtual Business Manager" operated purely by voice and camera.

### Step 2: The Visual Ingestion Demo (0:30 – 1:15)
* Mount a handcrafted item (or textured textile sample) against an uneven, cluttered table surface.
* Tap the camera shutter button. Show the immediate, automated boundary acquisition without dragging manual crop handles.
* Highlight that the prototype requires zero manual cropping or pinch-to-zoom actions.

### Step 3: Dialect Voice Narration (1:15 – 2:00)
* Tap the oversized microphone button.
* Speak a 10-second Hindi craft narrative into the phone (e.g., describing a Chanderi saree, pure silk yarn, gold zari borders, and 5 days of weaving labor).
* Point out the live audio visualizer responding to voice dynamics. Tap to finalize the recording.

### Step 4: AI Output Showcase & Verification (2:00 – 2:45)
* Display the transition state as background studio segmentation and entity extraction occur.
* Reveal the final Catalog Card:
  * Slide the Before/After toggle to demonstrate the cluttered table background replaced by a pristine white studio background with a realistic contact shadow.
  * Tap the Speaker icon: Demonstrate the app reading back the generated title, material breakdown, and recommended price out loud in Hindi.
  * Showcase the 3-Tier Fair-Price Corridor, explaining to the judges how statutory daily artisan wages are guaranteed against intermediary price exploitation.

### Step 5: Judging Alignment & Hackathon Rubric Close (2:45 – 3:00)
* Conclude with the scalable system architecture: Emphasize that the client is built using Flutter for cross-platform availability, ready to syndicate listings across the decentralized ONDC network using open Beckn protocols.
* Summarize total computational efficiency: Low inferencing overhead designed to keep per-catalog operational costs under ₹0.07 (Groq Whisper ₹0.039 + Gemini Flash ₹0.023, or ₹0 on free tiers).
