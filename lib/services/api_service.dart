import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/constants.dart';
import '../models/craft_attributes.dart';
import '../models/pricing_corridor.dart';
import '../data/mock_data.dart';

/// Response from the catalog processing pipeline.
class CatalogProcessResult {
  final String? titleEn;
  final String? titleHi;
  final String? descriptionEn;
  final String? descriptionHi;
  final CraftAttributes? craftAttributes;
  final PricingCorridor? pricing;
  final String? studioImagePath;
  final String? audioReadbackPath;

  const CatalogProcessResult({
    this.titleEn,
    this.titleHi,
    this.descriptionEn,
    this.descriptionHi,
    this.craftAttributes,
    this.pricing,
    this.studioImagePath,
    this.audioReadbackPath,
  });
}

/// Callback to report processing stage progress.
/// stage: 0 = image processing, 1 = voice/NLP, 2 = pricing
typedef StageCallback = void Function(int stage);

/// Abstract service contract.
/// Swap MockApiService → LiveApiService by setting USE_MOCK_DATA=false in .env.
abstract class ApiService {
  Future<CatalogProcessResult> processCatalog({
    required String imagePath,
    required String audioPath,
    StageCallback? onStageComplete,
  });

  /// Factory — reads USE_MOCK_DATA from .env
  factory ApiService() {
    if (AppConstants.useMockData) {
      return MockApiService();
    }
    return LiveApiService();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCK IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────

class MockApiService implements ApiService {
  int _mockIndex = 0;

  @override
  Future<CatalogProcessResult> processCatalog({
    required String imagePath,
    required String audioPath,
    StageCallback? onStageComplete,
  }) async {
    // Rotate through mock payloads so each demo shows something different
    final payload = MockData.catalogs[_mockIndex % MockData.catalogs.length];
    _mockIndex++;

    // Stage 0: Image processing (studio matting)
    await Future.delayed(AppConstants.mockStage1Delay);
    onStageComplete?.call(0);

    // Stage 1: Voice transcription + NLP
    await Future.delayed(AppConstants.mockStage2Delay);
    onStageComplete?.call(1);

    // Stage 2: Pricing calculation
    await Future.delayed(AppConstants.mockStage3Delay);
    onStageComplete?.call(2);

    return CatalogProcessResult(
      titleEn: payload.titleEn,
      titleHi: payload.titleHi,
      descriptionEn: payload.descriptionEn,
      descriptionHi: payload.descriptionHi,
      craftAttributes: payload.craftAttributes,
      pricing: payload.pricing,
      studioImagePath: null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIVE IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────

class LiveApiService implements ApiService {
  @override
  Future<CatalogProcessResult> processCatalog({
    required String imagePath,
    required String audioPath,
    StageCallback? onStageComplete,
  }) async {
    final pipeline = _resolvePipeline();

    switch (pipeline) {
      case 'ai4bharat':
      case 'bhashini':
        // Path 1 & 2: delegate to self-hosted FastAPI backend
        return _processViaBackend(
          imagePath: imagePath,
          audioPath: audioPath,
          onStageComplete: onStageComplete,
        );

      case 'groq':
      default:
        // Path 3: Groq Whisper → Gemini (direct from Flutter client)
        return _processViaGroqGemini(
          imagePath: imagePath,
          audioPath: audioPath,
          onStageComplete: onStageComplete,
        );
    }
  }

  // ── Pipeline selector ───────────────────────────────────────────────────

  String _resolvePipeline() {
    final pref = AppConstants.voicePipeline;
    if (pref == 'auto') {
      // Auto: use Groq if key is available, else try backend
      return AppConstants.groqApiKey.isNotEmpty ? 'groq' : 'ai4bharat';
    }
    return pref;
  }

  // ── Path 3: Groq Whisper + Gemini (direct client-side calls) ───────────

  Future<CatalogProcessResult> _processViaGroqGemini({
    required String imagePath,
    required String audioPath,
    StageCallback? onStageComplete,
  }) async {
    _assertKey('GROQ_API_KEY', AppConstants.groqApiKey);
    _assertKey('GEMINI_API_KEY', AppConstants.geminiApiKey);

    // Stage 0: mark image processing started (studio compositing runs in
    // parallel inside CatalogController; we just advance the stepper)
    onStageComplete?.call(0);

    // ── Step 1: Transcribe audio via Groq Whisper ──
    final transcript = await _transcribeWithGroq(audioPath);

    // Stage 1: voice transcription done
    onStageComplete?.call(1);

    // ── Step 2: Extract catalog JSON + Hindi translation via Gemini ──
    final extracted = await _extractWithGemini(transcript);

    // Stage 2: entity extraction / pricing done
    onStageComplete?.call(2);

    return _resultFromGeminiJson(extracted);
  }

  /// POST audio to Groq Whisper-Large-v3 → returns Hindi transcript string.
  Future<String> _transcribeWithGroq(String audioPath) async {
    final bytes = await File(audioPath).readAsBytes();

    // Determine content-type from extension
    final ext = audioPath.split('.').last.toLowerCase();
    final mimeType = ext == 'wav' ? MediaType('audio', 'wav')
        : ext == 'mp4' ? MediaType('audio', 'mp4')
        : MediaType('audio', 'm4a'); // default AAC

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions'),
    );
    request.headers['Authorization'] = 'Bearer ${AppConstants.groqApiKey}';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'audio.$ext',
        contentType: mimeType,
      ),
    );
    request.fields['model'] = 'whisper-large-v3';
    request.fields['language'] = 'hi'; // force Hindi; handles Hinglish
    request.fields['response_format'] = 'text'; // plain string, no JSON wrapper

    final streamed = await request.send().timeout(AppConstants.apiTimeout);
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('Groq ASR failed (${streamed.statusCode}): $body');
    }
    return body.trim();
  }

  /// POST transcript to Gemini for structured extraction → returns JSON map.
  Future<Map<String, dynamic>> _extractWithGemini(String transcript) async {
    final model = AppConstants.geminiModel;
    final key = AppConstants.geminiApiKey;
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
    );

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'system_instruction': {
              'parts': [{'text': _geminiSystemInstruction}],
            },
            'contents': [
              {
                'role': 'user',
                'parts': [{'text': transcript}],
              }
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
              'temperature': 0.2, // low temp for consistent structured output
            },
          }),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini extraction failed (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    // Navigate Gemini response envelope
    final text = (body['candidates'] as List?)
        ?.first['content']['parts']?.first['text'] as String?;

    if (text == null || text.isEmpty) {
      throw Exception('Gemini returned empty extraction response.');
    }

    return jsonDecode(text) as Map<String, dynamic>;
  }

  CatalogProcessResult _resultFromGeminiJson(Map<String, dynamic> j) {
    final materialsList = (j['materials'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final rawCost = _parseInt(j['raw_material_cost_inr']) ?? 500;
    final laborDays = _parseInt(j['labor_days']) ?? 3;

    final pricing = PricingCorridor.compute(
      rawMaterialCost: rawCost,
      laborDays: laborDays,
    );

    return CatalogProcessResult(
      titleEn: j['title_en'] as String?,
      titleHi: j['title_hi'] as String?,
      descriptionEn: j['description_en'] as String?,
      descriptionHi: j['description_hi'] as String?,
      craftAttributes: CraftAttributes(
        category: j['craft_category'] as String?,
        materials: materialsList,
        laborDays: laborDays,
        clusterLocation: j['cluster_location'] as String?,
      ),
      pricing: pricing,
    );
  }

  // ── Path 1 & 2: Backend passthrough ────────────────────────────────────

  Future<CatalogProcessResult> _processViaBackend({
    required String imagePath,
    required String audioPath,
    StageCallback? onStageComplete,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.backendUrl}/api/v1/catalog/process',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['language'] = 'hi-IN'
      ..files.add(await http.MultipartFile.fromPath('image', imagePath))
      ..files.add(await http.MultipartFile.fromPath('audio', audioPath));

    // Optional Bhashini auth header for Path 2
    if (AppConstants.bhashiniApiKey.isNotEmpty) {
      request.headers['X-Bhashini-Key'] = AppConstants.bhashiniApiKey;
    }

    onStageComplete?.call(0);

    final streamed = await request.send().timeout(AppConstants.apiTimeout);
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('Backend failed (${streamed.statusCode}): $body');
    }

    final j = jsonDecode(body) as Map<String, dynamic>;

    onStageComplete?.call(1);
    onStageComplete?.call(2);

    final materialsList = (j['materials'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final pricingMap = j['pricing'] as Map<String, dynamic>? ?? {};

    return CatalogProcessResult(
      titleEn: j['title_en'] as String?,
      titleHi: j['title_hi'] as String?,
      descriptionEn: j['description_en'] as String?,
      descriptionHi: j['description_hi'] as String?,
      craftAttributes: CraftAttributes(
        category: j['craft_category'] as String?,
        materials: materialsList,
        laborDays: _parseInt(pricingMap['labor_days']),
        clusterLocation: j['cluster_location'] as String?,
      ),
      pricing: pricingMap.isNotEmpty
          ? PricingCorridor(
              rawMaterialCost: _parseInt(pricingMap['raw_material_cost']) ?? 500,
              laborDays: _parseInt(pricingMap['labor_days']) ?? 3,
              dailyWageRate:
                  _parseInt(pricingMap['daily_wage_rate']) ??
                  AppConstants.defaultDailyWageRate,
              overheadPercent: (pricingMap['overhead_percent'] as num?)
                      ?.toDouble() ??
                  AppConstants.overheadPercent,
              floorPrice: _parseInt(pricingMap['floor_price']) ?? 0,
              fairPrice: _parseInt(pricingMap['fair_price']) ?? 0,
              premiumPrice: _parseInt(pricingMap['premium_price']) ?? 0,
            )
          : null,
      studioImagePath: j['studio_image_url'] as String?,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _assertKey(String name, String value) {
    if (value.isEmpty) {
      throw Exception(
        '$name is not set in .env. '
        'Add it and set USE_MOCK_DATA=false to enable live mode.',
      );
    }
  }

  int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GEMINI SYSTEM INSTRUCTION (Path 3)
// ─────────────────────────────────────────────────────────────────────────────

const String _geminiSystemInstruction = '''
You are an expert in Indian handicrafts and artisan products.

An artisan has described their handmade product in Hindi or a regional Indian language (possibly code-switched with English). Extract the following structured information from their voice transcript and return ONLY a valid JSON object — no markdown, no explanation.

JSON schema (all fields optional unless noted):
{
  "title_en": "string — SEO-friendly English product title, max 80 chars (REQUIRED)",
  "title_hi": "string — Professional Hindi product title, max 80 chars (REQUIRED)",
  "description_en": "string — SEO-optimized English description, 150–250 words (REQUIRED)",
  "description_hi": "string — Professional Hindi description, 100–200 words (REQUIRED)",
  "craft_category": "string — e.g. Handloom Silk, Terracotta Pottery, Dhokra Metal Craft, Block Print Fabric",
  "materials": ["array of raw materials mentioned, in English"],
  "labor_days": integer or null — days taken to make one unit,
  "raw_material_cost_inr": integer or null — cost of raw materials in Indian Rupees,
  "cluster_location": "string — city/district and state if mentioned, e.g. Chanderi, Madhya Pradesh"
}

Rules:
- If the artisan mentions a price, that is likely raw_material_cost_inr (not the selling price).
- Convert all material names to standard English equivalents (e.g. "resham" → "silk thread").
- If labor_days or raw_material_cost_inr are not mentioned, set them to null.
- Descriptions must be written in an e-commerce catalog tone — professional, evocative, factual.
- Hindi text must use Devanagari script.
- Return ONLY the JSON object. No markdown fences.
''';
