# AI Model Integration Guide

> **For:** Teammate integrating BiRefNet, Bhashini ASR, and Gemini 2.5 Flash  
> **Prototype state:** Mock mode (`USE_MOCK_DATA=true` in `.env`)  
> **Goal:** Swap mock implementations with real model outputs — no UI or controller changes needed

---

## Architecture Overview

The prototype is built with a clean **service abstraction layer**. All AI model integration happens in exactly **3 places**:

```
lib/services/
├── image_service.dart    ← BiRefNet background removal
├── audio_service.dart    ← Bhashini ASR (future)
└── api_service.dart      ← Gemini 2.5 Flash entity extraction + full pipeline
```

---

## 1. Switching from Mock to Live Mode

Open `.env` and change one line:

```env
USE_MOCK_DATA=false
```

That's it — `ApiService()` factory will now use `LiveApiService` instead of `MockApiService`.

---

## 2. Integrating the Image Background Removal Model (BiRefNet)

**File:** [`lib/services/image_service.dart`](file:///home/ammar/Programs/Flutter/sih_26_kalakriti/lib/services/image_service.dart)

**Method to replace:**
```dart
Future<String?> createStudioImage(String rawImagePath) async { ... }
```

**Current behavior:** Simple white-canvas compositing (placeholder).

### Option A: On-Device (ONNX Runtime Mobile)
If the model is packaged as an ONNX INT8 model:

```dart
// Add to pubspec.yaml:
// onnxruntime: ^1.x.x

Future<String?> createStudioImage(String rawImagePath) async {
  final session = OrtSession.fromFile('assets/models/birefnet_int8.onnx');
  final inputBytes = await File(rawImagePath).readAsBytes();

  // Preprocess: resize to 1024x1024, normalize to [-1, 1]
  final inputTensor = _preprocess(inputBytes);

  // Run inference
  final outputs = await session.run({'input': inputTensor});
  final alphaMask = outputs['output']; // Shape: [1, 1, H, W]

  // Composite: apply alpha mask on white background
  final studioPath = await _compositeMask(rawImagePath, alphaMask);
  return studioPath;
}
```

### Option B: Backend API (recommended for demo)
If the model runs on the FastAPI backend:

```dart
Future<String?> createStudioImage(String rawImagePath) async {
  final uri = Uri.parse('${AppConstants.backendUrl}/api/v1/image/studio');
  final request = http.MultipartRequest('POST', uri)
    ..files.add(await http.MultipartFile.fromPath('image', rawImagePath));

  final response = await request.send();
  final body = await response.stream.bytesToString();
  final json = jsonDecode(body);

  // Download and save the studio image locally
  final studioUrl = json['studio_image_url'] as String;
  final studioBytes = await http.get(Uri.parse(studioUrl));
  final tempDir = await getTemporaryDirectory();
  final path = '${tempDir.path}/studio_${DateTime.now().millisecondsSinceEpoch}.jpg';
  await File(path).writeAsBytes(studioBytes.bodyBytes);
  return path;
}
```

---

## 3. Voice Pipeline — Already Implemented (ApiService)

**File:** [`lib/services/api_service.dart`](file:///home/ammar/Programs/Flutter/sih_26_kalakriti/lib/services/api_service.dart)

> **Status: ✅ Fully implemented.** `LiveApiService` is wired and ready. Set `USE_MOCK_DATA=false` in `.env` to activate.

### How It Works

`LiveApiService.processCatalog()` reads the `VOICE_PIPELINE` env var and auto-routes:

| Pipeline Value | What Happens |
|---|---|
| `groq` or `auto` (with `GROQ_API_KEY` set) | **Path 3:** Groq Whisper-Large-v3 transcribes audio → Gemini 2.5 Flash extracts structured JSON → `PricingCorridor.compute()` calculates pricing tiers |
| `ai4bharat` or `bhashini` | **Path 1 & 2:** Multipart POST to `BACKEND_URL/api/v1/catalog/process` — your FastAPI backend handles all AI |

### Path 3 Flow (Groq + Gemini, direct from Flutter)

```
[.m4a audio file] → POST Groq Whisper API → Hindi transcript (string)
                                                    │
                                                    ▼
                              POST Gemini 2.5 Flash (responseMimeType: application/json)
                                                    │
                                                    ▼
                              Structured JSON → PricingCorridor.compute() → CatalogProcessResult
```

### Path 1 & 2 Flow (Backend Passthrough)

The Flutter client sends the same multipart POST regardless of which backend pipeline is active:

```dart
POST {BACKEND_URL}/api/v1/catalog/process
  fields: { language: "hi-IN" }
  files:  { image: <photo.jpg>, audio: <voice.m4a> }
```

The backend returns the same JSON schema documented in Section 4 below.


---

## 4. Expected Backend API Response Format

```json
{
  "id": "cat_abc123",
  "title_en": "Handwoven Chanderi Silk Dupatta with Gold Zari Border",
  "title_hi": "हाथ से बुनी चंदेरी सिल्क दुपट्टा, सोने की ज़री बॉर्डर के साथ",
  "description_en": "An exquisite handwoven Chanderi silk dupatta...",
  "description_hi": "उत्कृष्ट हाथ से बुनी चंदेरी सिल्क दुपट्टा...",
  "craft_category": "Handloom Silk",
  "materials": ["Pure Mulberry Silk", "Gold Zari"],
  "labor_days": 5,
  "cluster_location": "Chanderi, Madhya Pradesh",
  "studio_image_url": "https://api.example.com/studio/abc123.jpg",
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

---

## 5. Gemini 2.5 Flash — Entity Extraction Prompt

Use this prompt template on the backend when calling Gemini:

```python
ENTITY_EXTRACTION_PROMPT = """
You are an expert in Indian handicrafts and artisan products.

The following is a transcription of a voice note from an artisan describing their product in Hindi/regional dialect:
<transcription>
{transcription}
</transcription>

Extract the following structured information and return a JSON object:
{
  "craft_category": "string — e.g. Handloom Silk, Terracotta Pottery, Dhokra Metal Craft",
  "materials": ["list of raw materials mentioned"],
  "labor_days": integer or null,
  "raw_material_cost_inr": integer or null,
  "cluster_location": "city, state if mentioned",
  "artisan_name": "name if mentioned",
  "title_en": "SEO-friendly English product title (max 80 chars)",
  "title_hi": "Professional Hindi product title (max 80 chars)",
  "description_en": "SEO-optimized English product description (150-250 words)",
  "description_hi": "Professional Hindi product description (100-200 words)"
}

Model: {model}  (use gemini-2.5-flash)
"""
```

---

## 6. `.env` Keys Needed Before Demo

```env
USE_MOCK_DATA=false

# Required for full AI pipeline
GEMINI_API_KEY=<get from Google AI Studio — aistudio.google.com>
GEMINI_MODEL=gemini-2.5-flash

BHASHINI_API_KEY=<get from bhashini.gov.in>
BHASHINI_API_URL=https://dhruva-api.bhashini.gov.in

BACKEND_URL=http://<your-machine-ip>:8000
```

---

## 7. Testing the Integration

After integrating, run through the manual checklist:

- [ ] Set `USE_MOCK_DATA=false` in `.env`
- [ ] Start the FastAPI backend on the same network as the phone
- [ ] Set `BACKEND_URL=http://<laptop-ip>:8000`
- [ ] Capture a real product photo
- [ ] Record a real 10-second Hindi voice note
- [ ] Verify the catalog card shows real extracted data
- [ ] Verify the studio image shows proper background removal
- [ ] Verify the TTS readback speaks the correct Hindi title
- [ ] Verify pricing reflects the extracted raw material cost

---

## 8. Key Files Reference

| File | Purpose | Your integration point |
|---|---|---|
| [`image_service.dart`](file:///home/ammar/Programs/Flutter/sih_26_kalakriti/lib/services/image_service.dart) | Image capture & studio compositing | Replace `createStudioImage()` with BiRefNet |
| [`api_service.dart`](file:///home/ammar/Programs/Flutter/sih_26_kalakriti/lib/services/api_service.dart) | Full pipeline orchestration | Implement `LiveApiService.processCatalog()` |
| [`audio_service.dart`](file:///home/ammar/Programs/Flutter/sih_26_kalakriti/lib/services/audio_service.dart) | Recording & TTS | Optionally replace TTS with Bhashini TTS |
| [`mock_data.dart`](file:///home/ammar/Programs/Flutter/sih_26_kalakriti/lib/data/mock_data.dart) | Demo payloads | Reference for expected data shapes |
| [`.env`](file:///home/ammar/Programs/Flutter/sih_26_kalakriti/.env) | All API keys & flags | Set `USE_MOCK_DATA=false` + add keys |
