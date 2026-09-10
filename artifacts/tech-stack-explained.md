# Technology Choices Explained — KalaKriti AI

> **Audience:** Jury, team members, anyone who asks "why did you use X?"  
> **Format:** Every technology → What it is, How we use it, Why we chose it  
> **Last updated:** 2026-09-10

---

## Table of Contents

1. [Framework & Architecture](#1-framework--architecture)
2. [Flutter Packages — Client](#2-flutter-packages--client)
3. [AI & ML Services — Backend](#3-ai--ml-services--backend)
4. [Why Our Solution is Faster, Cheaper, and Better](#4-why-our-solution-is-faster-cheaper-and-better)

---

## 1. Framework & Architecture

### Flutter 3.47.2 (Dart SDK 3.13.2)

| | |
|---|---|
| **What** | Google's open-source UI framework for building natively compiled mobile apps from a single codebase. Dart is the programming language Flutter uses. |
| **How we use it** | Our entire mobile app — all 4 screens (Capture, Voice, Processing, Catalog), all widgets, all services — is written in Flutter/Dart. One codebase compiles to both Android APK and iOS IPA. |
| **Why we chose it** | **Cross-platform from day one.** Writing separate Android (Kotlin) and iOS (Swift) apps would double our development time. Flutter gives us native performance (60 FPS) with a single team. It also has excellent Hindi/Devanagari text rendering via the Skia engine, which is critical for our bilingual artisan UI. React Native was the alternative, but Flutter's widget system gives us pixel-perfect control over our oversized 72dp buttons and custom waveform visualizer — things that are harder to achieve with React Native's bridge-to-native approach. |

### MVC + Provider (Architecture Pattern)

| | |
|---|---|
| **What** | MVC (Model-View-Controller) separates data (Models), UI (Views), and logic (Controllers). Provider is Flutter's recommended lightweight state management solution. |
| **How we use it** | Each screen has a corresponding Controller (e.g., `CaptureController`, `VoiceController`). Controllers extend `ChangeNotifier` and are provided via `MultiProvider` at the app root. Views observe state via `context.watch<T>()` and call methods via `context.read<T>()`. |
| **Why we chose it** | **Simplicity for a hackathon team.** Alternatives like BLoC or Riverpod have steeper learning curves. MVC + Provider is the simplest pattern that still gives us clean separation — our 4-person team could onboard in 30 minutes. Provider is also officially recommended by the Flutter team. |

---

## 2. Flutter Packages — Client

### `camera: ^0.12.1` — Live Camera Viewfinder

| | |
|---|---|
| **What** | Official Flutter plugin that provides a live camera viewfinder using CameraX on Android and AVFoundation on iOS. |
| **How** | Powers Screen 1 — the artisan sees a live camera preview and taps a shutter button to capture a product photo. |
| **Why** | We need a real viewfinder, not just a gallery picker. CameraX handles focus locking, auto-exposure, and flash on budget ₹7,000 phones. `image_picker`'s camera mode delegates to the system camera app (no custom UI), but we need our oversized 72dp shutter button inside our own UI. |

### `image_picker: ^1.1.2` — Gallery Selection

| | |
|---|---|
| **What** | Flutter plugin to pick images from the device gallery or take a photo using the system camera. |
| **How** | Alternative to the live viewfinder — artisans can select a pre-existing photo from their gallery. |
| **Why** | Some artisans may have already photographed their product. This lets them skip the camera step. |

### `image: ^4.3.0` — Image Quality Checks

| | |
|---|---|
| **What** | Pure Dart image processing library. Works at the pixel level — no native code needed. |
| **How** | We use it to check photo quality before sending to AI: Laplacian variance for blur detection, and average luminance for low-light detection. Runs in a background isolate via `compute()`. |
| **Why** | Catching blurry or dark photos *before* the AI pipeline saves API costs and gives instant feedback to the artisan. |

### `record: ^7.1.1` — Microphone Audio Recording

| | |
|---|---|
| **What** | Cross-platform audio recording plugin. Records from the device microphone to a file. |
| **How** | Powers Screen 2 — records the artisan's 15-second Hindi voice description. Configured for AAC-LC codec, 16,000 Hz sample rate, mono channel. Also streams real-time amplitude data (dBFS) every 80ms for the waveform visualizer. |
| **Why** | We need real microphone access with precise control over codec, sample rate, and amplitude streaming. The `record` package (v7) is the most actively maintained option, supports all platforms, and gives us the amplitude stream that powers the waveform UI. |

### `audioplayers: ^6.4.0` — Audio Playback

| | |
|---|---|
| **What** | Plugin for playing audio files from device storage or URLs. |
| **How** | Plays back the artisan's recorded voice clip so they can verify what they said before proceeding. Also plays server-generated TTS audio in Path 1 (AI4Bharat Indic-Parler-TTS). |
| **Why** | We need to play local `.m4a` files. `audioplayers` is the standard solution with broad codec support. |

### `flutter_tts: ^4.2.2` — Hindi Text-to-Speech

| | |
|---|---|
| **What** | Plugin that uses the device's built-in speech synthesis engine (Android TTS / iOS AVSpeech). |
| **How** | On the Catalog screen, the speaker button reads the generated catalog summary aloud in Hindi: "यह उत्पाद {category} की श्रेणी में है... कीमत {price} रुपये..." at 0.45 speech rate for clarity. |
| **Why** | Zero-literacy verification — the artisan **hears** the AI-generated listing instead of reading it. Uses `hi-IN` locale. Works offline, zero API cost. |

### `http: ^1.3.0` + `http_parser: ^4.1.2` — HTTP Client

| | |
|---|---|
| **What** | Dart's standard HTTP client library. `http_parser` provides MIME type handling for multipart form uploads. |
| **How** | `LiveApiService` uses these to POST audio files to Groq Whisper (multipart), POST transcripts to Gemini (JSON), and POST image+audio to the backend (multipart). |
| **Why** | Lightweight, no dependencies, dart-team maintained. We don't need Dio's interceptor complexity for our 2-3 API calls. |

### `flutter_dotenv: ^5.2.1` — Environment Config

| | |
|---|---|
| **What** | Loads key-value pairs from a `.env` file at runtime. |
| **How** | All API keys (`GROQ_API_KEY`, `GEMINI_API_KEY`, `BHASHINI_API_KEY`), pipeline selection (`VOICE_PIPELINE`), and feature flags (`USE_MOCK_DATA`) are read from `.env`. |
| **Why** | API keys must never be hardcoded. `.env` is in `.gitignore` so keys don't leak into git. Each team member can have their own keys. |

### `google_fonts: ^6.2.1` — Typography

| | |
|---|---|
| **What** | Loads fonts from the Google Fonts catalog at runtime. |
| **How** | We use Noto Sans throughout the app. It renders correctly in Devanagari (Hindi), Latin (English), and all 22 scheduled Indian language scripts. |
| **Why** | Our artisan UI shows Hindi text everywhere. System fonts vary wildly across Android devices — some budget phones don't have good Devanagari fonts. Noto Sans guarantees consistent, beautiful Hindi rendering on every device. |

### `provider: ^6.1.5` — State Management

| | |
|---|---|
| **What** | Flutter's recommended dependency injection and state management solution, built on `InheritedWidget`. |
| **How** | We provide 4 controllers (`CaptureController`, `VoiceController`, `CatalogController`, `PricingController`) at the app root via `MultiProvider`. Screens observe state via `Consumer` widgets. |
| **Why** | Official Flutter recommendation. Simpler than BLoC/Riverpod. Perfect for our 4-screen linear flow with no complex state dependencies. |

### `shimmer: ^3.0.0` — Loading Effects

| | |
|---|---|
| **What** | Adds shimmering skeleton loading effects to widgets. |
| **How** | On the Processing screen, while the AI pipeline runs (~4 seconds), the UI shows shimmering placeholder elements with traditional craft motifs. |
| **Why** | Builds trust with the artisan. A blank loading spinner looks broken. A shimmer effect says "something is being built for you." |

### `permission_handler: ^11.4.0` — Permissions

| | |
|---|---|
| **What** | Cross-platform plugin for requesting runtime permissions (camera, microphone, storage). |
| **How** | Before opening the camera or starting a recording, we check and request the required permissions. |
| **Why** | Android requires runtime permission requests since API 23. This plugin handles the platform-specific dialogs. |

### Other Packages

| Package | Purpose |
|---|---|
| `uuid: ^4.5.1` | Generates unique IDs for each catalog item (e.g., `cat_a7f3b2...`) |
| `path_provider: ^2.1.5` | Gets the device's temp directory for storing recorded audio files |
| `shared_preferences: ^2.5.3` | Stores simple settings locally (key-value pairs) |
| `cupertino_icons: ^1.0.8` | iOS-style icons for the UI |

---

## 3. AI & ML Services — Backend

### Groq Cloud API — Whisper-Large-v3 (Path 3 ASR)

| | |
|---|---|
| **What** | Groq runs OpenAI's Whisper-Large-v3 speech recognition model on their custom LPU (Language Processing Unit) hardware, making it the fastest Whisper API available. |
| **How** | The artisan's 15-second `.m4a` recording is POST-ed to Groq. It returns a Hindi text transcript in ~0.5 seconds. |
| **Why** | **14,400 free requests/day** — enough for months of demos. Fastest inference available (LPU hardware). Handles Hindi and Hinglish code-switching well. |

### Google Gemini 2.5 Flash (Path 3 LLM)

| | |
|---|---|
| **What** | Google's latest fast multimodal LLM. Supports structured JSON output mode (`responseMimeType: application/json`). |
| **How** | Takes the Whisper transcript and extracts structured catalog data (title, description, materials, labor days, cost) in both English and Hindi in a single API call. |
| **Why** | **JSON mode guarantees valid output** — no parsing failures. 2.5 Flash is the sweet spot of speed/quality/cost. Free tier gives 1,500 requests/day. Collapses what would be 3 separate API calls (entity extraction + Hindi generation + English SEO copy) into 1. |

### AI4Bharat Stack (Path 1 — Production)

| Model | Purpose |
|---|---|
| **IndicConformer 600M** | Best-in-class Indic ASR. Trained on 22 Indian languages + dialects. Self-hosted on GPU. |
| **IndicTrans2-Dist 200M** | Translate Hindi/regional → English and back. 200M distilled = fast + accurate. |
| **Indic-Parler-TTS** | Generate natural-sounding Hindi speech for readback. Much better than device TTS. |

**Why AI4Bharat?** 100% Make-in-India, open-source, trained specifically on Indian languages. Whisper struggles with Bundeli, Chhattisgarhi, Marwari — IndicConformer handles these natively.

### Bhashini / MeitY Dhruva (Path 2)

| | |
|---|---|
| **What** | Government-managed ASR/NMT/TTS cloud endpoints by MeitY (Ministry of Electronics & IT). Uses the same AI4Bharat models internally. |
| **How** | Single pipeline API call: send audio → get transcript + translation + TTS audio back. |
| **Why** | **Government-approved for SIH.** Shows alignment with India's Digital India initiative. Uses SPOC credentials from the college. |

### BiRefNet — Background Removal

| | |
|---|---|
| **What** | Bilateral Reference Network — a neural network for high-resolution image segmentation (removing backgrounds). |
| **How** | Takes the raw product photo → removes the cluttered workshop background → composites on clean white canvas with drop shadow. |
| **Why** | Traditional background removal fails on intricate textiles (loose threads, translucent fabrics). BiRefNet handles craft textures specifically. ONNX INT8 quantization makes it run on budget hardware. |

---

## 4. Why Our Solution is Faster, Cheaper, and Better

### 4.1 Cost Per Catalog: ₹0.062 (or ₹0 on free tiers)

Here's the actual cost breakdown for generating one complete catalog card using Path 3 (Groq + Gemini):

| Step | Service | Calculation | Cost |
|---|---|---|---|
| 1. Transcribe 15s audio | Groq Whisper-Large-v3 | \$0.111/hour × (15s ÷ 3600s) = \$0.000463 | **₹0.039** |
| 2. Extract catalog JSON | Gemini 2.5 Flash | ~500 input + ~800 output tokens × (\$0.075 + \$0.30)/M | **₹0.023** |
| 3. TTS readback | flutter_tts (on-device) | Device engine, no API | **₹0.000** |
| | | **Total per catalog** | **₹0.062** |

> **Sources:** [Groq pricing](https://groq.com/pricing/) (as of Sept 2026), [Gemini pricing](https://ai.google.dev/pricing) (as of Sept 2026). Exchange rate: 1 USD = ₹84.

**Both services have generous free tiers:**
- Groq: 14,400 requests/day free → that's **~200 days of 72 catalogs/day** before paying anything
- Gemini 2.5 Flash: 1,500 requests/day free → that's **~20 catalogs/hour**, plenty for demos

### 4.2 Cost Comparison with Alternatives

| Method | Cost Per Product | Notes |
|---|---|---|
| **KalaKriti AI (Path 3)** | **₹0.062** (or ₹0 on free tier) | Groq + Gemini, fully automated |
| **KalaKriti AI (Path 1)** | **~₹0.50** (GPU amortized) | Self-hosted, no API fees, one-time GPU cost |
| Professional photographer | ₹500 – ₹2,000 | Per product, manual, requires travel |
| Catalog copywriter | ₹200 – ₹500 | Per product, English-only, 30-min turnaround |
| Amazon Karigar listing | ₹0 upfront | But **27–50% commission** on every sale |
| Trade fair booth | ₹5,000 – ₹15,000 | Per fair + travel + accommodation, seasonal only |
| Manual e-commerce onboarding | ₹0 upfront | But 30-45 minutes per product, requires literacy |

> **Reference:** Sattva Knowledge Institute & ONDC (2022) — 90% of rural weavers tied to traders extracting 30–50% margins.

### 4.3 Speed Comparison

| Method | Time Per Product |
|---|---|
| **KalaKriti AI** | **~30 seconds** (tap photo + 15s voice + 2s AI) |
| Manual e-commerce listing | 30 – 45 minutes (photograph, write description, set price, upload) |
| Amazon Karigar onboarding | 2 – 3 hours (account setup, forms, category selection, photography) |
| Professional catalog service | 1 – 2 days (photography → editing → copywriting → upload) |

**That's a 60× to 240× speedup** over traditional methods.

### 4.4 Why Better — Feature Comparison

| Feature | KalaKriti AI | Amazon Karigar | Traditional ONDC Apps | Manual Process |
|---|---|---|---|---|
| **Zero typing required** | ✅ Voice-only | ❌ Forms | ❌ Forms | ❌ Keyboard |
| **Native dialect input** | ✅ Hindi/22 languages | ❌ English only | ❌ English/Hindi text | ❌ English |
| **Automated fair pricing** | ✅ 3-tier corridor | ❌ Artisan guesses | ❌ Manual | ❌ Manual |
| **Studio photo generation** | ✅ BiRefNet AI | ❌ No | ❌ No | ❌ Photographer needed |
| **Works on ₹7K phone** | ✅ 4GB RAM sufficient | ⚠️ Needs good phone | ⚠️ Needs good phone | ✅ Any phone |
| **Bilingual output** | ✅ Hindi + English auto | ❌ English only | ❌ Manual | ❌ One language |
| **Audio verification** | ✅ TTS readback | ❌ Read-only | ❌ Read-only | ❌ None |
| **Make-in-India AI** | ✅ AI4Bharat available | ❌ Foreign APIs | ❌ No AI | ❌ No AI |
| **Cost per listing** | ₹0.062 | ₹0 + 27-50% commission | ₹0 + manual labor | ₹500-2000 |

### 4.5 Why This Matters for Artisans

> *"Over 80% of artisans abandon digital onboarding when confronted with complex desktop web forms and English-only interfaces."*  
> — Digital Empowerment Foundation (DEF) survey, 2,000+ handicraft workers

Our solution eliminates every friction point:
- **No English needed** → voice input in mother tongue
- **No typing needed** → zero keyboard, only taps
- **No photography skill needed** → auto background removal
- **No pricing knowledge needed** → algorithmic fair pricing based on materials + labor
- **No e-commerce knowledge needed** → one-tap ONDC publish (Phase 2)

The result: an illiterate artisan earning ₹5,000/month can create a professional, bilingual, correctly-priced e-commerce listing in 30 seconds flat.

---

## References

1. **Groq Pricing** — https://groq.com/pricing/ — Whisper-Large-v3: $0.111/audio-hour, 14,400 free req/day
2. **Google Gemini Pricing** — https://ai.google.dev/pricing — 2.5 Flash: $0.075/M input, $0.30/M output tokens, 1,500 free req/day
3. **Amazon Seller Fees** — Amazon Karigar seller central — 27% referral fee (handicrafts category)
4. **Sattva Knowledge Institute & ONDC (2022)** — "Ecosystem Study on Unlocking Digital Commerce for Indian Artisans and Weavers" — 30–50% intermediary margins
5. **4th All-India Handloom Census (2019-2020)** — Ministry of Textiles — 66% of artisan households below ₹5,000/month, e-commerce = 0.2% of weaver sales
6. **Digital Empowerment Foundation (DEF)** — "Enhancing Livelihood of Artisans and Weavers in Knowledge Economy" — 80%+ onboarding drop-off rate
7. **AI4Bharat (IIT Madras)** — IndicConformer, IndicTrans2, Indic-Parler-TTS — open-source Make-in-India AI models
8. **Zheng et al. (CVPR 2024)** — "BiRefNet: Bilateral Reference Network for High-Resolution Dichotomous Image Segmentation"
