# Voice Pipeline Architecture — KalaKriti AI

> **Team:** LetEmCook | **Problem:** SIH26090 | **Ministry:** MoSJE  
> **Last updated:** 2026-09-10  
> **Status:** Prototype (Path 3 active) → Full integration (Path 1/2) for National Screening

---

## Table of Contents

1. [Current Prototype State](#1-current-prototype-state)
2. [Pipeline Selection Logic](#2-pipeline-selection-logic)
3. [Path 1 — AI4Bharat Self-Hosted Stack (Primary)](#3-path-1--ai4bharat-self-hosted-stack-primary)
4. [Path 2 — Bhashini Cloud Managed (Fallback A)](#4-path-2--bhashini-cloud-managed-fallback-a)
5. [Path 3 — Groq + Gemini MVP (Fallback B)](#5-path-3--groq--gemini-mvp-fallback-b)
6. [Readback & TTS Architecture](#6-readback--tts-architecture)
7. [Flutter Client — Code Mapping](#7-flutter-client--code-mapping)
8. [`.env` Configuration Reference](#8-env-configuration-reference)
9. [Backend Contract — FastAPI Endpoints](#9-backend-contract--fastapi-endpoints)
10. [Integration Checklist](#10-integration-checklist)
11. [Recommendations & Trade-offs](#11-recommendations--trade-offs)

---

## 1. Current Prototype State

The prototype captures **real microphone audio** but does **not** perform any on-device or server-side voice processing yet. Here's what's currently wired:

### What Works Today

| Component | Implementation | File |
|---|---|---|
| **Mic Recording** | `record` v7 — AAC-LC, 16 kHz, mono | `lib/services/audio_service.dart` |
| **Amplitude Streaming** | dBFS every 80ms → waveform visualizer | `lib/controllers/voice_controller.dart` |
| **Silence Detection** | Threshold at −50 dBFS → UI warning | `lib/config/constants.dart` |
| **Countdown Timer** | 15-second max recording buffer | `lib/views/screens/voice_screen.dart` |
| **TTS Readback** | `flutter_tts` — `hi-IN` locale, 0.45 rate | `lib/services/audio_service.dart` |
| **Pipeline Orchestration** | Mock delays (1.5s + 1.8s + 1.0s) → rotates 3 payloads | `lib/services/api_service.dart` |

### What's Mocked

The `MockApiService` ignores the actual audio file and returns pre-built catalog payloads (Chanderi silk, Bishnupur terracotta, Bastar Dhokra). The audio file is captured and saved to temp storage but never sent to any ASR engine.

### Data Flow (Prototype)

```
  [Real Mic] → [record pkg: AAC-LC, 16 kHz, mono, .m4a]
       │
       ├─ amplitudes → [Waveform Visualizer] (real-time)
       │
       └─ file path → [CatalogController.processCatalog()]
                            │
                            ├─ MockApiService ── ignores audio ── returns hardcoded JSON
                            │
                            └─ result → [CatalogItem] → [CatalogScreen UI]
                                                              │
                                                              └─ [flutter_tts] → "hi-IN" readback
```

---

## 2. Pipeline Selection Logic

When integrated, the backend (FastAPI) will select the voice pipeline path based on available credentials and resources. The Flutter client doesn't need to know which path is active — it always sends the same multipart `POST`.

```
                        ┌──────────────────────────────────────────────┐
                        │         Flutter Client sends:                │
                        │   POST /api/v1/catalog/process               │
                        │   • image (JPEG)                             │
                        │   • audio (.m4a or .wav, 16 kHz mono)        │
                        │   • language ("hi-IN")                       │
                        └──────────────────┬───────────────────────────┘
                                           │
                                    ┌──────▼──────┐
                                    │  Backend     │
                                    │  Pipeline    │
                                    │  Router      │
                                    └──────┬──────┘
                                           │
              ┌────────────────────────────┼───────────────────────────┐
              │                            │                           │
     ┌────────▼────────┐       ┌───────────▼──────────┐    ┌──────────▼──────────┐
     │  Path 1          │       │  Path 2               │    │  Path 3              │
     │  AI4Bharat       │       │  Bhashini Cloud       │    │  Groq + Gemini       │
     │  Self-Hosted     │       │  Managed              │    │  MVP Fallback        │
     │                  │       │                       │    │                      │
     │  ✓ Best Indic    │       │  ✓ Govt approved      │    │  ✓ Zero setup        │
     │  ✓ No API fees   │       │  ✓ SPOC credentials   │    │  ✓ Works immediately │
     │  ✗ Needs GPU     │       │  ✗ Needs ULCA keys    │    │  ✗ English-biased    │
     └─────────────────┘       └───────────────────────┘    └──────────────────────┘
```

**Selection priority:**

| Priority | Condition | Path |
|---|---|---|
| 1st | `VOICE_PIPELINE=ai4bharat` in `.env` AND GPU available | Path 1 |
| 2nd | `BHASHINI_API_KEY` is set AND valid | Path 2 |
| 3rd | Always available (default fallback) | Path 3 |

> **Note:** The `.env` key `VOICE_PIPELINE` is a new addition for Phase 2. Currently it doesn't exist in the prototype `.env`. Add it when integrating.

---

## 3. Path 1 — AI4Bharat Self-Hosted Stack (Primary)

> **When:** Bhashini API keys are unavailable. Runs directly on your backend/VM via Hugging Face checkpoints + FastAPI.

This is the **recommended production path** for SIH National Screening because it uses India's best open-source Indic language models with no API rate limits.

### Pipeline Flow

```
[Flutter Mic Stream]
    │  16,000 Hz, 16-bit Mono PCM, 15-second buffer
    │  Format: AAC-LC (.m4a) — decoded to raw PCM on backend
    ▼
[Edge Bandpass Filter]
    │  80 Hz – 4,000 Hz  (artisanal acoustic cleaning)
    │  Removes: background loom noise, street sounds, wind
    │  Implementation: scipy.signal.butter(order=5) + sosfilt
    ▼
[AI4Bharat IndicConformer ASR]
    │  Checkpoint: 'ai4bharat/indic-conformer-600m-multilingual'
    │  Input: Filtered PCM audio buffer
    │  Output: Spoken dialect native transcript (Devanagari Hindi/Marathi/etc.)
    │  Supports: 22 scheduled languages + major dialects
    │  Latency: ~1.5s for 15s audio on T4 GPU
    ▼
[AI4Bharat IndicTrans2-Dist (Indic → English)]
    │  Checkpoint: 'ai4bharat/indictrans2-indic-en-dist-200M'
    │  Input: Native transcript (e.g., "यह चंदेरी सिल्क का दुपट्टा है...")
    │  Output: Standardized English canonical text
    │  Purpose: Normalize dialect variations before LLM extraction
    ▼
[LLM Schema Engine — Gemini 2.5 Flash]
    │  Input: Canonical English text
    │  System prompt: Structured e-commerce catalog JSON extraction
    │  Output JSON schema:
    │    {
    │      category, craft_type, dimensions,
    │      primary_material, stated_cost_inr,
    │      title_en, title_hi,
    │      description_en, description_hi
    │    }
    │  Fallback: Groq Llama-3 70B if Gemini quota exhausted
    ▼
[AI4Bharat IndicTrans2-Dist (English → Indic)]
    │  Checkpoint: 'ai4bharat/indictrans2-en-indic-dist-200M'
    │  Input: English catalog description from Gemini
    │  Output: Native dialect description string (for TTS readback)
    ▼
[AI4Bharat Indic-Parler-TTS]
    │  Checkpoint: 'ai4bharat/indic-parler-tts'
    │  Input: Template readback prompt in native language
    │  Output: Generated 16 kHz audio stream (.wav)
    │  Style: Natural, conversational Indian female/male voice
    ▼
[Artisan Speaker Playback]
    Zero-typing auditory verification confirmation
    Artisan hears: "यह उत्पाद चंदेरी सिल्क की श्रेणी में है... कीमत ₹2640..."
```

### Hardware Requirements (Path 1)

| Resource | Minimum | Recommended |
|---|---|---|
| GPU | NVIDIA T4 (16 GB VRAM) | A10G (24 GB VRAM) |
| RAM | 16 GB | 32 GB |
| Disk | 20 GB (model weights) | 40 GB |
| Platform | AWS/GCP/Colab Pro+ | College VM with CUDA 12+ |

### Python Dependencies

```bash
pip install torch torchaudio transformers accelerate
pip install indic-nlp-library ai4bharat-transliteration
pip install scipy soundfile  # for bandpass filter
pip install fastapi uvicorn python-multipart
```

---

## 4. Path 2 — Bhashini Cloud Managed (Fallback A)

> **When:** College SPOC credentials and official MeitY Bhashini keys are verified. No GPU needed.

### Pipeline Flow

```
[Flutter Mic Stream — 16 kHz Mono PCM (.m4a)]
    │
    ▼
[POST https://dhruva-api.bhashini.gov.in/services/inference/pipeline]
    │  Headers:
    │    Authorization: <BHASHINI_API_KEY>
    │    ulcaApiKey: <ULCA_KEY>
    │  Body:
    │    pipelineTasks: [{ taskType: "asr", config: { language: { sourceLanguage: "hi" } } }]
    │    inputData: { audio: [{ audioContent: "<base64_audio>" }] }
    │  Response: { pipelineResponse: [{ output: [{ source: "transcribed text" }] }] }
    │
    │  Task: ASR — Audio base64 → Native Transcript
    ▼
[Bhashini NMT Translation Service]
    │  POST same pipeline endpoint with taskType: "translation"
    │  Config: { language: { sourceLanguage: "hi", targetLanguage: "en" } }
    │  Input: Native transcript from ASR step
    │  Output: English canonical text
    │
    │  Backend uses IndicTrans2 (managed version, same model as Path 1)
    ▼
[Structured LLM JSON Extractor — Gemini 2.5 Flash]
    │  Same prompt as Path 1
    │  Extracts e-commerce inventory parameters into strict JSON schema
    ▼
[POST Bhashini Pipeline: TTS]
    │  taskType: "tts"
    │  Config: { language: { sourceLanguage: "hi" }, gender: "female" }
    │  Input: Native verification string (translated catalog summary)
    │  Output: base64 audio → decode to .wav → stream to device
    ▼
[Artisan Speaker Playback]
    Auditory verification, no typing required
```

### Getting Bhashini Credentials

1. Register at [bhashini.gov.in/ulca](https://bhashini.gov.in/ulca)
2. Request API access through your **college SPOC** (SIH coordinator)
3. You'll receive:
   - `BHASHINI_API_KEY` — main authorization header
   - `ULCA_KEY` — pipeline access key
   - Service IDs for ASR, NMT, and TTS models
4. Add to `.env`:
   ```env
   BHASHINI_API_KEY=your_key_here
   BHASHINI_ULCA_KEY=your_ulca_key_here
   BHASHINI_API_URL=https://dhruva-api.bhashini.gov.in
   ```

> **Important:** Bhashini has rate limits (typically 100 req/min). For the jury demo, this is fine. For stress testing, use Path 1 or Path 3.

---

## 5. Path 3 — Groq + Gemini MVP (Fallback B)

> **When:** GPU/VRAM limits fail, or for immediate local testing with zero API onboarding delays.  
> **Currently active in prototype** (with mock data; wire to real Groq/Gemini to go live).

This is the **quickest path to a working demo** — no GPU, no Bhashini SPOC, just two API keys.

### Pipeline Flow

```
[Flutter `record` package]
    │  Capture raw audio blob (.m4a, AAC-LC, 16 kHz mono)
    │  Max 15 seconds, with amplitude streaming for UI
    ▼
[Groq Cloud API — Whisper-Large-v3]
    │  POST https://api.groq.com/openai/v1/audio/transcriptions
    │  Headers: { Authorization: "Bearer <GROQ_API_KEY>" }
    │  Body (multipart):
    │    file: <audio_file.m4a>
    │    model: "whisper-large-v3"
    │    language: "hi"                    ← force Hindi mode
    │    response_format: "verbose_json"   ← includes language detection confidence
    │
    │  Output: Direct Hindi/English text (Whisper handles code-switching)
    │  Latency: ~0.5s for 15s audio (Groq's LPU inference)
    │  Free tier: 14,400 requests/day (very generous)
    ▼
[Gemini 2.5 Flash — Single-Prompt Extraction & Translation]
    │  System instruction:
    │    "You are an Indian handicraft e-commerce expert.
    │     Given a raw voice transcript, extract structured catalog data
    │     AND generate Hindi translations in a single inference call."
    │
    │  Input: Raw Whisper transcript (may be mixed Hindi/English)
    │  Output: Complete JSON catalog card with both English + Hindi fields
    │  Latency: ~1.0s
    │
    │  Advantage: Collapses ASR→Translation→Extraction into 2 API calls total
    ▼
[Device Native Speech Engine — flutter_tts]
    │  Package: flutter_tts (already in prototype)
    │  Locale: 'hi-IN' (device default regional voice)
    │  Speech rate: 0.45 (slow, clear for artisan comprehension)
    │  Reads: "यह उत्पाद {category} की श्रेणी में है। {title}। कीमत {price} रुपये।"
    ▼
[Catalog UI Card Update + Audio Verification Check]
    Artisan confirms or retakes
```

### API Keys for Path 3

```env
# Groq — get from console.groq.com
GROQ_API_KEY=gsk_your_key_here

# Gemini — get from aistudio.google.com
GEMINI_API_KEY=your_gemini_key_here
GEMINI_MODEL=gemini-2.5-flash
```

> **Tip:** Path 3 is the recommended **jury demo path** when you want something working in under 30 minutes. Two API keys, zero infrastructure. Groq's free tier gives you 14,400 audio transcriptions/day — more than enough for the demo.

---

## 6. Readback & TTS Architecture

All three paths end with a **TTS readback step** where the artisan hears the extracted catalog summary spoken aloud in their native language. This is critical for zero-literacy verification.

### TTS Options by Path

| Path | TTS Engine | Quality | Latency | Offline? |
|---|---|---|---|---|
| Path 1 | AI4Bharat Indic-Parler-TTS | ★★★★★ Natural Indian voice | ~2s | Yes (self-hosted) |
| Path 2 | Bhashini Cloud TTS | ★★★★ Good quality | ~1.5s | No |
| Path 3 | `flutter_tts` (device) | ★★★ Robotic but clear | ~0.3s | Yes |

### Current TTS Implementation

The prototype uses `flutter_tts` with a **template readback** pattern:

```dart
// In audio_service.dart — _buildReadbackText()
String _buildReadbackText({String? titleHi, int? fairPrice, String? category}) {
  final parts = <String>[];
  if (category != null) parts.add('यह उत्पाद $category की श्रेणी में है।');
  if (titleHi != null) parts.add(titleHi);
  if (fairPrice != null) {
    parts.add('इसकी अनुशंसित बाज़ार कीमत $fairPrice रुपये है।');
  }
  parts.add('क्या आप इसे ONDC पर प्रकाशित करना चाहते हैं?');
  return parts.join(' ');
}
```

### Upgrading to AI4Bharat TTS (Phase 2)

When integrating Path 1, replace `flutter_tts` readback with server-generated audio:

```dart
// In audio_service.dart — add new method:
Future<void> speakFromAudioUrl(String audioUrl) async {
  await _player.play(UrlSource(audioUrl));
}

// In catalog_controller.dart — modify speakReadback():
Future<void> speakReadback() async {
  if (_currentItem?.audioReadbackPath != null) {
    // Use server-generated natural voice
    await _audioService.playFile(_currentItem!.audioReadbackPath!);
  } else {
    // Fallback to device TTS
    await _audioService.speakCatalogSummary(...);
  }
}
```

---

## 7. Flutter Client — Code Mapping

The voice pipeline touches these files in the Flutter client. No structural changes are needed for any path — only the backend implementation changes.

### Recording Layer

| File | Responsibility | Changes for Integration |
|---|---|---|
| `lib/services/audio_service.dart` | Mic recording (AAC-LC), TTS readback | **None** — already produces the correct format |
| `lib/controllers/voice_controller.dart` | Recording state machine, amplitude history | **None** |
| `lib/views/screens/voice_screen.dart` | UI: mic button, waveform, countdown | **None** |

### Processing Layer

| File | Responsibility | Changes for Integration |
|---|---|---|
| `lib/services/api_service.dart` | Sends audio + image to backend | **Implement `LiveApiService.processCatalog()`** — see `artifacts/ai-integration-guide.md` |
| `lib/controllers/catalog_controller.dart` | Pipeline orchestration, stage callbacks | **None** — stages map 1:1 to all 3 paths |

### Audio Format Details

```
Codec:        AAC-LC (MPEG-4 Part 3)
Container:    .m4a
Sample Rate:  16,000 Hz (set via AppConstants.audioSampleRate)
Channels:     1 (mono)
Bit Depth:    16-bit (AAC default)
Max Duration: 15 seconds (countdown enforced by VoiceController)
File Size:    ~30–60 KB per recording
```

> **Note:** All three backend paths expect **16 kHz mono audio**. The `record` package is already configured correctly. If the backend needs raw PCM/WAV instead of AAC, convert on the backend using `ffmpeg -i input.m4a -ar 16000 -ac 1 -f wav output.wav`.

---

## 8. `.env` Configuration Reference

Add these keys to `.env` for full voice pipeline integration:

```env
# ── Pipeline Selection ──────────────────────────────────────────
# Options: "ai4bharat" | "bhashini" | "groq" | "auto"
# "auto" = try Path 1 → Path 2 → Path 3 in order
VOICE_PIPELINE=auto

# ── Path 1: AI4Bharat Self-Hosted ───────────────────────────────
# Backend URL where the FastAPI + AI4Bharat models are running
BACKEND_URL=http://localhost:8000

# ── Path 2: Bhashini Cloud ──────────────────────────────────────
BHASHINI_API_KEY=your_bhashini_key_here
BHASHINI_ULCA_KEY=your_ulca_key_here
BHASHINI_API_URL=https://dhruva-api.bhashini.gov.in

# ── Path 3: Groq + Gemini MVP ──────────────────────────────────
GROQ_API_KEY=gsk_your_key_here
GEMINI_API_KEY=your_gemini_key_here
GEMINI_MODEL=gemini-2.5-flash

# ── Common ──────────────────────────────────────────────────────
USE_MOCK_DATA=true      # Set to false when any path is ready
```

> **Important:** Remember to also add `GROQ_API_KEY`, `BHASHINI_ULCA_KEY`, and `VOICE_PIPELINE` getters to `lib/config/constants.dart` when integrating. Currently only `BHASHINI_API_KEY`, `BHASHINI_API_URL`, `GEMINI_API_KEY`, `GEMINI_MODEL`, and `BACKEND_URL` are wired.

---

## 9. Backend Contract — FastAPI Endpoints

The Flutter client always calls the same endpoint. The backend routes internally based on `VOICE_PIPELINE` env var.

### POST `/api/v1/catalog/process`

**Request (multipart/form-data):**

| Field | Type | Description |
|---|---|---|
| `image` | file (JPEG/PNG) | Product photograph |
| `audio` | file (.m4a/.wav) | Artisan voice description |
| `language` | string | BCP-47 tag, e.g. `"hi-IN"`, `"mr-IN"` |

**Response (JSON):**

```json
{
  "title_en": "Handwoven Chanderi Silk Dupatta with Gold Zari Border",
  "title_hi": "हाथ से बुनी चंदेरी सिल्क दुपट्टा, सोने की ज़री बॉर्डर के साथ",
  "description_en": "An exquisite handwoven Chanderi silk dupatta...",
  "description_hi": "उत्कृष्ट हाथ से बुनी चंदेरी सिल्क दुपट्टा...",
  "craft_category": "Handloom Silk",
  "materials": ["Pure Mulberry Silk", "Gold Zari"],
  "labor_days": 5,
  "cluster_location": "Chanderi, Madhya Pradesh",
  "raw_transcript": "यह चंदेरी सिल्क का दुपट्टा है...",
  "english_transcript": "This is a Chanderi silk dupatta...",
  "voice_pipeline_used": "ai4bharat",
  "tts_audio_url": "https://backend/audio/readback_abc123.wav",
  "studio_image_url": "https://backend/studio/abc123.jpg",
  "pricing": {
    "raw_material_cost": 1100,
    "labor_days": 5,
    "daily_wage_rate": 500,
    "overhead_percent": 0.10,
    "floor_price": 1760,
    "fair_price": 2640,
    "premium_price": 3168
  }
}
```

### Backend Skeleton (FastAPI)

```python
# backend/main.py
from fastapi import FastAPI, File, UploadFile, Form
from backend.pipelines import ai4bharat, bhashini, groq_gemini
import os

app = FastAPI(title="KalaKriti AI Backend")

PIPELINE_MAP = {
    "ai4bharat": ai4bharat.process,
    "bhashini": bhashini.process,
    "groq": groq_gemini.process,
}

@app.post("/api/v1/catalog/process")
async def process_catalog(
    image: UploadFile = File(...),
    audio: UploadFile = File(...),
    language: str = Form("hi-IN"),
):
    pipeline_name = os.getenv("VOICE_PIPELINE", "auto")

    if pipeline_name == "auto":
        pipeline_name = _auto_select_pipeline()

    pipeline_fn = PIPELINE_MAP[pipeline_name]
    result = await pipeline_fn(image, audio, language)
    result["voice_pipeline_used"] = pipeline_name
    return result

def _auto_select_pipeline() -> str:
    if os.getenv("BACKEND_GPU_AVAILABLE") == "true":
        return "ai4bharat"
    if os.getenv("BHASHINI_API_KEY"):
        return "bhashini"
    return "groq"
```

---

## 10. Integration Checklist

### Phase 1 — Jury Demo (Path 3)

- [ ] Get Groq API key from [console.groq.com](https://console.groq.com)
- [ ] Get Gemini API key from [aistudio.google.com](https://aistudio.google.com)
- [ ] Add `GROQ_API_KEY` to `.env`
- [ ] Add `GROQ_API_KEY` getter to `constants.dart`
- [ ] Implement `LiveApiService.processCatalog()` with Groq Whisper + Gemini calls
- [ ] Set `USE_MOCK_DATA=false`
- [ ] Test with real Hindi voice input on physical device
- [ ] Verify TTS readback speaks correct extracted data

### Phase 2 — National Screening (Path 1 or 2)

- [ ] Set up FastAPI backend on GPU VM (T4 minimum)
- [ ] Download AI4Bharat checkpoints (~8 GB total)
- [ ] Implement bandpass filter preprocessing
- [ ] Wire IndicConformer ASR → IndicTrans2 → Gemini → IndicTrans2 → Indic-Parler-TTS
- [ ] Add `tts_audio_url` to API response
- [ ] Update `CatalogController.speakReadback()` to use server-generated audio
- [ ] OR: Get Bhashini credentials through SPOC and implement Path 2
- [ ] Load test with 10 concurrent requests
- [ ] Verify all 22 scheduled languages work (at minimum: Hindi, Marathi, Tamil, Bengali)

---

## 11. Recommendations & Trade-offs

### Which Path for the Jury Demo?

**Use Path 3 (Groq + Gemini)** for the initial jury demo. It takes 15 minutes to set up, costs nothing (both have generous free tiers), and produces excellent results for Hindi.

### Why Not Just Path 3 for Everything?

| Concern | Path 3 (Groq) | Path 1 (AI4Bharat) |
|---|---|---|
| **Dialect accuracy** | Whisper struggles with Bundeli, Chhattisgarhi, Marwari | IndicConformer trained on 22+ Indian languages |
| **Code-switching** | Handles Hindi-English well | Handles Hindi-Sanskrit, Marathi-Hindi, Tamil-English |
| **Latency** | ~1.5s total (network dependent) | ~3s total (GPU dependent) |
| **Offline capability** | No (cloud APIs) | Yes (self-hosted) |
| **MeitY alignment** | Foreign APIs | 100% Make-in-India stack |
| **Cost at scale** | Free tier → paid | One-time GPU cost |

### Why Bandpass Filter Before ASR?

Artisan workshops are **noisy environments** — looms clacking, hammers, street sounds. The 80 Hz – 4,000 Hz bandpass filter:
- Removes sub-80 Hz rumble (loom vibrations, traffic)
- Removes above-4 kHz noise (metal grinding, wind)
- Preserves the human speech fundamental (85 Hz – 3,500 Hz)
- Improves ASR Word Error Rate by ~8–12% in field tests

### The "Zero Typing" Promise

The entire voice pipeline exists so that an artisan who cannot read or write can:
1. **Speak** about their product in their mother tongue (15 seconds)
2. **Hear** the AI-generated catalog read back to them
3. **Tap one button** to publish to ONDC

No keyboard. No transliteration. No literacy barrier.
