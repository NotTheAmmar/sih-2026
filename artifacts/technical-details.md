# KalaKriti AI — Prototype Technical Specification

> **Document Version:** 1.0.0-prototype  
> **Flutter SDK:** 3.47.2 (Dart SDK ^3.13.2)  
> **Architecture:** MVC (Model–View–Controller)  
> **Target Platform:** Android (primary), iOS (secondary)  
> **Min Android SDK:** 21 (Android 5.0)  

---

## 1. Architecture Overview

The prototype follows the **MVC (Model–View–Controller)** pattern for clear separation of concerns, easy testability, and a flat learning curve for the team.

```
┌─────────────────────────────────────────────────────────────────┐
│                        Views (Screens)                          │
│  CaptureScreen │ VoiceScreen │ ProcessingScreen │ CatalogScreen │
└───────┬────────┴──────┬──────┴────────┬─────────┴───────┬───────┘
        │               │               │                 │
        ▼               ▼               ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Controllers                              │
│  CaptureController │ VoiceController │ CatalogController        │
│                    │                 │ PricingController         │
└───────┬────────────┴────────┬────────┴──────────┬───────────────┘
        │                     │                   │
        ▼                     ▼                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Models                                 │
│  CatalogItem │ PricingCorridor │ VoiceRecording │ AppState      │
└───────┬────────────────────────┴────────────────┴───────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Services                                │
│  ApiService │ ImageService │ AudioService │ StorageService       │
└─────────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer          | Responsibility                                                                                  |
| -------------- | ----------------------------------------------------------------------------------------------- |
| **View**       | Pure UI widgets. Observes controller state and dispatches user events. No business logic.        |
| **Controller** | Holds mutable state, orchestrates service calls, transforms data for views. Extends `ChangeNotifier`. |
| **Model**      | Immutable data classes (using `freezed` or manual `copyWith`). No behavior, only structure.       |
| **Service**    | Encapsulates I/O: network requests, camera access, audio recording, local storage. Injected into controllers. |

---

## 2. Project Structure

```
lib/
├── main.dart                       # App entry point, provider setup
├── app.dart                        # MaterialApp configuration, routing
│
├── config/
│   ├── theme.dart                  # AppTheme — colors, typography, spacing
│   ├── constants.dart              # App-wide constants (API URLs, timeouts)
│   └── routes.dart                 # Named route definitions
│
├── models/
│   ├── catalog_item.dart           # CatalogItem data class
│   ├── pricing_corridor.dart       # PricingCorridor (floor, fair, premium)
│   ├── voice_recording.dart        # VoiceRecording metadata
│   └── craft_attributes.dart       # Extracted craft attributes
│
├── controllers/
│   ├── capture_controller.dart     # Camera/gallery image acquisition
│   ├── voice_controller.dart       # Audio recording & waveform state
│   ├── catalog_controller.dart     # Catalog creation orchestration
│   └── pricing_controller.dart     # Price corridor computation
│
├── services/
│   ├── api_service.dart            # HTTP client (mock toggle + live)
│   ├── image_service.dart          # Image picking, compression, enhancement
│   ├── audio_service.dart          # Audio capture, playback, TTS
│   └── storage_service.dart        # Local persistence (SQLite / SharedPrefs)
│
├── views/
│   ├── screens/
│   │   ├── capture_screen.dart     # Screen 1: Camera viewfinder & gallery
│   │   ├── voice_screen.dart       # Screen 2: Voice narration interface
│   │   ├── processing_screen.dart  # Screen 3: AI pipeline loading states
│   │   └── catalog_screen.dart     # Screen 4: Catalog card & pricing
│   │
│   └── widgets/
│       ├── shutter_button.dart     # Oversized camera shutter (72dp)
│       ├── mic_button.dart         # Pulsing microphone button (72dp)
│       ├── waveform_visualizer.dart # 30-bar audio amplitude visualizer
│       ├── price_gauge.dart        # 3-tier price corridor display
│       ├── before_after_toggle.dart # Raw vs studio photo toggle
│       ├── progress_stepper.dart   # 3-stage pipeline progress indicator
│       └── craft_chip.dart         # Material/category attribute chips
│
├── utils/
│   ├── haptics.dart                # Haptic feedback helpers
│   ├── validators.dart             # Image quality checks (blur, exposure)
│   └── formatters.dart             # Price formatting, date formatting
│
└── data/
    └── mock_data.dart              # Pre-configured artisan test payloads
```

---

## 3. State Management

**Provider** (via the `provider` package) is used for state management across the prototype.

- Each **Controller** extends `ChangeNotifier`.
- Controllers are provided at the app level via `MultiProvider`.
- Views consume state using `context.watch<T>()` and dispatch actions via `context.read<T>()`.

```dart
// Example: Providing controllers at app root
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => CaptureController(imageService: ImageService())),
    ChangeNotifierProvider(create: (_) => VoiceController(audioService: AudioService())),
    ChangeNotifierProvider(create: (_) => CatalogController(apiService: ApiService())),
    ChangeNotifierProvider(create: (_) => PricingController()),
  ],
  child: const KalaKritiApp(),
)
```

---

## 4. Navigation

The prototype uses a **linear wizard flow** (4 screens in sequence). Navigation is handled via Flutter's `Navigator 2.0`-style named routes or simple `Navigator.push` / `Navigator.pushReplacement`.

```
CaptureScreen  →  VoiceScreen  →  ProcessingScreen  →  CatalogScreen
     ↑                                                        │
     └────────────────── "Retake" ─────────────────────────────┘
```

Routes are defined in `config/routes.dart`:

```dart
class AppRoutes {
  static const capture = '/capture';
  static const voice = '/voice';
  static const processing = '/processing';
  static const catalog = '/catalog';
}
```

---

## 5. Data Models

### 5.1 CatalogItem

The central entity representing a product listing.

```dart
class CatalogItem {
  final String id;
  final DateTime createdAt;

  // Media
  final String rawImagePath;        // Device path to original photo
  final String? studioImagePath;    // Path to background-removed photo
  final String? audioPath;          // Path to recorded voice note

  // Bilingual descriptors
  final String? titleEn;
  final String? titleHi;
  final String? descriptionEn;
  final String? descriptionHi;

  // Craft attributes
  final String? craftCategory;      // e.g., "Handloom Silk Sarees"
  final List<String> materials;     // e.g., ["Pure Silk", "Gold Zari"]
  final int? laborDays;

  // Pricing
  final PricingCorridor? pricing;

  // Status
  final CatalogStatus status;       // draft | stored | published
}
```

### 5.2 PricingCorridor

```dart
class PricingCorridor {
  final int floorPrice;             // Breakeven (materials + labor + overhead)
  final int fairPrice;              // Recommended D2C price
  final int premiumPrice;           // B2B / institutional price (fair × 1.20)

  final int rawMaterialCost;
  final int laborDays;
  final int dailyWageRate;          // ₹450–600/day
  final double overheadPercent;     // ~10%
}
```

### 5.3 CatalogStatus

```dart
enum CatalogStatus {
  draft,          // Still in creation wizard
  storedLocally,  // Saved offline, pending upload
  published,      // Phase 2: Sent to ONDC / marketplace
}
```

---

## 6. API Contract (Prototype)

The prototype uses a **mock toggle** pattern. When `useMock = true`, pre-configured payloads are returned after a simulated delay. When `useMock = false`, real HTTP calls are made.

### 6.1 Process Catalog — `POST /api/v1/catalog/process`

**Request** (multipart/form-data):

| Field       | Type   | Description                          |
| ----------- | ------ | ------------------------------------ |
| `image`     | File   | Raw product photo (JPEG/PNG)         |
| `audio`     | File   | 15-second voice recording (WAV/M4A) |
| `language`  | String | Source dialect code (e.g., `hi-IN`)  |

**Response** (JSON):

```json
{
  "id": "cat_abc123",
  "studio_image_url": "https://api.example.com/studio/cat_abc123.jpg",
  "title_en": "Handwoven Chanderi Silk Dupatta with Gold Zari Border",
  "title_hi": "हाथ से बुनी चंदेरी सिल्क दुपट्टा सोने की ज़री बॉर्डर के साथ",
  "description_en": "Exquisite handwoven Chanderi silk dupatta...",
  "description_hi": "उत्कृष्ट हाथ से बुनी चंदेरी सिल्क दुपट्टा...",
  "craft_category": "Handloom Silk",
  "materials": ["Pure Mulberry Silk", "Gold Zari"],
  "labor_days": 5,
  "pricing": {
    "floor_price": 2750,
    "fair_price": 4200,
    "premium_price": 5040,
    "raw_material_cost": 1100,
    "daily_wage_rate": 500,
    "overhead_percent": 10
  },
  "audio_readback_url": "https://api.example.com/tts/cat_abc123.mp3"
}
```

### 6.2 Mock Data Payloads

The prototype ships with 3 pre-configured mock payloads for demonstration:

1. **Chanderi Silk Dupatta** — Handloom cluster, Madhya Pradesh
2. **Terracotta Flower Pot** — Pottery cluster, West Bengal
3. **Brass Filigree Lamp** — Metalwork cluster, Odisha

---

## 7. Packages & Dependencies

### 7.1 Core Dependencies

| Package                | Version    | Purpose                                       |
| ---------------------- | ---------- | --------------------------------------------- |
| `provider`             | ^6.1.5     | State management (ChangeNotifier + Provider)  |
| `camera`               | ^0.12.1    | Live CameraX viewfinder on Android            |
| `image_picker`         | ^1.1.2     | Gallery photo selection                       |
| `image`                | ^4.3.0     | Pixel-level image processing (blur/luminance) |
| `record`               | ^7.1.1     | Audio recording (16kHz mono AAC-LC)           |
| `audioplayers`         | ^6.4.0     | Audio file playback                           |
| `flutter_tts`          | ^4.2.2     | Hindi text-to-speech readback (hi-IN)         |
| `http`                 | ^1.3.0     | HTTP client for API calls (Groq, Gemini)      |
| `http_parser`          | ^4.1.2     | MIME type handling for multipart uploads       |
| `flutter_dotenv`       | ^5.2.1     | .env file loading for API keys                |
| `path_provider`        | ^2.1.5     | Device temp/app directory path resolution     |
| `permission_handler`   | ^11.4.0    | Runtime camera/mic permission requests        |
| `shared_preferences`   | ^2.5.3     | Lightweight local key-value storage           |
| `uuid`                 | ^4.5.1     | Unique catalog ID generation                  |

### 7.2 UI & Design

| Package                | Version    | Purpose                                       |
| ---------------------- | ---------- | --------------------------------------------- |
| `google_fonts`         | ^6.2.1     | Typography (Noto Sans for Hindi/Devanagari)   |
| `shimmer`              | ^3.0.0     | Skeleton loading shimmer effects              |
| `cupertino_icons`      | ^1.0.8     | iOS-style icons                               |
| `haptic_feedback`      | (native)   | Tactile feedback on button taps               |

### 7.3 Dev Dependencies

| Package                    | Version    | Purpose                                   |
| -------------------------- | ---------- | ----------------------------------------- |
| `flutter_test`             | (sdk)      | Widget and unit testing                   |
| `flutter_lints`            | ^6.0.0     | Recommended lint rules                    |
| `mockito`                  | ^5.4.5     | Service mocking in tests                  |
| `build_runner`             | ^2.4.15    | Code generation for mockito               |
| `flutter_launcher_icons`   | ^0.14.4    | App icon generation from source image     |

---

## 8. Design System & Theming

### 8.1 Color Palette (WCAG AAA Sunlight Contrast)

| Token              | Hex         | Usage                                              |
| ------------------ | ----------- | -------------------------------------------------- |
| **Action Green**   | `#16A34A`   | Forward actions: confirm, publish, proceed          |
| **Warning Amber**  | `#D97706`   | Audio underexposure, processing states, cautions    |
| **Alert Red**      | `#DC2626`   | Cancel, retake, destructive actions                 |
| **Surface Light**  | `#F9FAFB`   | Light mode canvas background                       |
| **Surface Dark**   | `#111827`   | Dark mode canvas background                        |
| **Text Primary**   | `#111827`   | Primary text (light mode)                           |
| **Text Secondary** | `#6B7280`   | Secondary / caption text                            |

### 8.2 Typography

| Style       | Font             | Size | Weight   | Usage                        |
| ----------- | ---------------- | ---- | -------- | ---------------------------- |
| Headline    | Noto Sans        | 24sp | Bold     | Screen titles                |
| Subhead     | Noto Sans        | 18sp | SemiBold | Section headers              |
| Body        | Noto Sans        | 16sp | Regular  | Body text, descriptions      |
| Caption     | Noto Sans        | 14sp | Regular  | Labels, chip text            |
| Price Large | Noto Sans        | 28sp | Bold     | Fair price display           |
| Price Small | Noto Sans        | 18sp | Medium   | Floor / premium price labels |

> **Why Noto Sans?** Full coverage for Devanagari (Hindi), Latin (English), and all 22 scheduled Indian language scripts — critical for a multilingual artisan app.

### 8.3 Spacing & Touch Targets

- **Base unit:** 8dp grid system
- **Minimum touch target:** 64dp × 64dp (exceeds Material's 48dp minimum)
- **Primary action buttons:** 72dp diameter (camera shutter, microphone)
- **Screen padding:** 16dp horizontal, 24dp vertical
- **Card border radius:** 16dp

### 8.4 Triple-Feedback Law

Every interactive button tap simultaneously triggers:

1. **Visual** — UI state transition (color change, animation)
2. **Haptic** — Distinct vibration pattern via `HapticFeedback`
3. **Audible** — Confirmation chime or click sound

---

## 9. Asset Organization

```
assets/
├── icons/
│   ├── shutter.svg
│   ├── gallery.svg
│   ├── mic.svg
│   ├── speaker.svg
│   ├── retake.svg
│   └── publish.svg
│
├── images/
│   ├── bg.avif                     # App background
│   └── onboarding/                 # Onboarding illustrations (if needed)
│
├── audio/
│   ├── shutter_click.mp3           # Camera capture sound
│   ├── recording_start.mp3         # Mic activation chime
│   ├── recording_stop.mp3          # Mic deactivation chime
│   └── success_chime.mp3           # Catalog creation success
│
└── mock/
    ├── chanderi_silk.json           # Mock payload: Chanderi silk dupatta
    ├── terracotta_pot.json          # Mock payload: Terracotta pot
    └── brass_lamp.json             # Mock payload: Brass filigree lamp
```

---

## 10. Image Processing Pipeline (Prototype)

For the prototype, image processing is **simulated** on the client side:

1. **Capture** — `image_picker` captures a raw photo or picks from gallery
2. **Quality Check** — Laplacian variance check for blur detection (threshold: Var < 100)
3. **Background Substitution (Simulated)** — The prototype overlays the original image onto a white canvas with a subtle drop-shadow to simulate studio output. In production, this will be replaced by on-device BiRefNet INT8 matting.
4. **Before/After Toggle** — The catalog screen shows both the raw and "studio" versions

---

## 11. Audio Pipeline (Prototype)

1. **Capture** — `record` package captures 16kHz mono audio, max 15 seconds
2. **Waveform Visualization** — Real-time amplitude data displayed as a 30-bar visualizer
3. **Auto-Cutoff** — Recording stops automatically at 15 seconds
4. **Silence Detection** — If peak amplitude stays below threshold, amber warning + audio prompt
5. **Playback** — `audioplayers` plays back the recording for the artisan to verify
6. **TTS Readback** — `flutter_tts` with `hi-IN` locale speaks the generated catalog summary (title, category, recommended price) at 0.45 speech rate for artisan comprehension. In production (Path 1), this can be upgraded to AI4Bharat Indic-Parler-TTS for natural voice synthesis.

---

## 12. Pricing Engine (Prototype)

The prototype implements a **deterministic pricing calculator** (no ML model):

$$C_{floor} = M_{raw} + (T_{days} \times W_{artisan}) + O_{overhead}$$

Where:
- $M_{raw}$ = Raw material cost (extracted from voice or manually adjusted)
- $T_{days}$ = Labor days (extracted from voice or manually adjusted)
- $W_{artisan}$ = Daily wage rate (₹450–600, configurable)
- $O_{overhead}$ = Fixed overhead (10% of subtotal)

Price tiers:
- **Floor Price:** $C_{floor}$ (breakeven)
- **Fair Price:** $C_{floor} \times 1.50$ (50% margin for D2C)
- **Premium Price:** $P_{fair} \times 1.20$ (20% uplift for B2B/institutional)

> In production, the fair price will be predicted by an XGBoost regressor trained on 45,000+ scraped listings, augmented with CLIP visual complexity embeddings.

---

## 13. Error Handling & Edge Cases

| Scenario                  | Detection                           | Response                                                                               |
| ------------------------- | ----------------------------------- | -------------------------------------------------------------------------------------- |
| **Blurry photo**          | Laplacian variance < 100            | Warning icon + audio prompt: *"Photo saaf nahi hai. Kripya roshni me jaakar dobara khinchein."* |
| **Low-light photo**       | Average luminance (Y channel) < 40  | Auto-trigger flashlight + audio warning                                                |
| **Silent recording**      | Peak amplitude below threshold      | Amber visualizer + audio prompt: *"Aawaz theek se sunai nahi di."*                     |
| **Network disconnection** | Connectivity check fails            | Save to local queue, show sync badge, auto-upload on reconnection                      |
| **API timeout**           | Response > 30 seconds               | Show retry button, fallback to mock data for demo                                      |

---

## 14. Testing Strategy

### 14.1 Unit Tests

- **Models:** Serialization/deserialization, `copyWith`, equality
- **Controllers:** State transitions, service call orchestration
- **Pricing:** Verify floor/fair/premium calculations against known inputs

### 14.2 Widget Tests

- **Each screen:** Renders correctly, buttons trigger correct controller methods
- **Waveform visualizer:** Responds to mock amplitude data
- **Price gauge:** Displays correct tier values

### 14.3 Manual Testing Checklist

- [ ] Camera capture works on budget Android device (4GB RAM)
- [ ] Gallery picking selects image correctly
- [ ] Audio recording captures 15 seconds and auto-stops
- [ ] Waveform visualizer animates during recording
- [ ] Processing screen shows 3-stage stepper
- [ ] Catalog card displays all fields correctly
- [ ] Before/after toggle switches images
- [ ] Haptic feedback fires on all buttons
- [ ] App works in landscape and portrait
- [ ] Hindi text renders correctly (Devanagari script)

---

## 15. Build & Run

### Prerequisites

- Flutter 3.47.2 (`flutter --version` to verify)
- Android Studio / VS Code with Flutter plugin
- Android device or emulator (API 21+)

### Commands

```bash
# Get dependencies
flutter pub get

# Run in debug mode
flutter run

# Run on specific device
flutter run -d <device_id>

# Build release APK
flutter build apk --release

# Run tests
flutter test
```

---

## 16. Environment Configuration

All configuration is loaded from `.env` at runtime via `flutter_dotenv`. See [`artifacts/env-setup.md`](file:///home/ammar/Programs/Flutter/sih_26_kalakriti/artifacts/env-setup.md) for the full setup guide.

**Key file:** [`lib/config/constants.dart`](file:///home/ammar/Programs/Flutter/sih_26_kalakriti/lib/config/constants.dart) — reads from `dotenv.env[]` with sensible defaults.

```env
# Core toggle
USE_MOCK_DATA=true          # false = enable live AI (Groq + Gemini)
VOICE_PIPELINE=auto         # "groq" | "bhashini" | "ai4bharat" | "auto"

# Path 3: Groq + Gemini (jury demo)
GROQ_API_KEY=gsk_...        # console.groq.com (free)
GEMINI_API_KEY=AIzaSy...    # aistudio.google.com (free)
GEMINI_MODEL=gemini-2.5-flash

# Path 2: Bhashini (govt endpoints)
BHASHINI_API_KEY=...
BHASHINI_ULCA_KEY=...

# Path 1: AI4Bharat backend
BACKEND_URL=http://localhost:8000
```

---

## 17. Git Conventions

| Type       | Branch Name              | Example                         |
| ---------- | ------------------------ | ------------------------------- |
| Feature    | `feature/<name>`         | `feature/voice-recording`       |
| Bug fix    | `fix/<name>`             | `fix/camera-permissions`        |
| UI work    | `ui/<name>`              | `ui/catalog-card-layout`        |
| Docs       | `docs/<name>`            | `docs/update-readme`            |

**Commit message format:** `type: short description`

Examples:
- `feat: add camera capture screen with image picker`
- `fix: handle null audio path on catalog screen`
- `ui: implement 3-tier price gauge widget`
- `docs: update technical specification`

---

## 18. Complete Technology Stack

A single-glance reference of every technology used across the client and backend.

### 18.1 Client (Flutter Mobile)

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| Framework | Flutter | 3.47.2 | Cross-platform mobile UI |
| Language | Dart | 3.13.2 | App logic and type safety |
| Architecture | MVC + Provider | — | State management pattern |
| Camera | `camera` (CameraX) | 0.12.1 | Live viewfinder with CameraX |
| Gallery | `image_picker` | 1.1.2 | Photo gallery selection |
| Image Processing | `image` | 4.3.0 | Blur/luminance quality checks |
| Audio Recording | `record` | 7.1.1 | 16 kHz mono AAC-LC capture |
| Audio Playback | `audioplayers` | 6.4.0 | Audio file playback |
| TTS | `flutter_tts` | 4.2.2 | Hindi text-to-speech readback |
| HTTP Client | `http` | 1.3.0 | REST API calls (Groq, Gemini) |
| MIME Handling | `http_parser` | 4.1.2 | Multipart content-type headers |
| Config | `flutter_dotenv` | 5.2.1 | .env file loading |
| Typography | `google_fonts` | 6.2.1 | Noto Sans (Devanagari support) |
| UI Effects | `shimmer` | 3.0.0 | Skeleton loading animations |
| IDs | `uuid` | 4.5.1 | Unique catalog IDs |
| File Paths | `path_provider` | 2.1.5 | Temp/app directory access |
| Permissions | `permission_handler` | 11.4.0 | Camera/mic permission requests |
| Storage | `shared_preferences` | 2.5.3 | Local key-value persistence |
| Icons | `cupertino_icons` | 1.0.8 | iOS-style icon set |

### 18.2 AI / ML Services

| Layer | Technology | Deployment | Purpose |
|---|---|---|---|
| ASR (Path 3) | Groq Whisper-Large-v3 | Cloud API | Hindi speech-to-text (~0.5s for 15s audio) |
| LLM (Path 3) | Google Gemini 2.5 Flash | Cloud API | Structured entity extraction from transcripts |
| ASR (Path 1) | AI4Bharat IndicConformer 600M | Self-hosted GPU | 22-language Indic speech recognition |
| Translation (Path 1) | AI4Bharat IndicTrans2-Dist 200M | Self-hosted GPU | Indic↔English translation |
| TTS (Path 1) | AI4Bharat Indic-Parler-TTS | Self-hosted GPU | Natural Indian voice synthesis |
| ASR (Path 2) | Bhashini / MeitY Dhruva | Cloud API (govt) | Managed ASR/NMT/TTS endpoints |
| Vision AI | BiRefNet (ONNX INT8) | Edge / Server | Background removal for studio compositing |
| Pricing (Phase 2) | XGBoost + CLIP ViT-B/32 | Server | Multimodal fair-price regression |

### 18.3 Backend (Phase 2)

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| API Framework | FastAPI | Latest | Async REST endpoints |
| Runtime | Python | 3.11+ | Backend language |
| ML Framework | PyTorch + Transformers | Latest | Model inference |
| Audio Processing | scipy + soundfile | Latest | Bandpass filter preprocessing |
| Deployment | Uvicorn | Latest | ASGI server |

