import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
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
    late final List<int> bytes;
    if (kIsWeb) {
      final res = await http.get(Uri.parse(audioPath));
      bytes = res.bodyBytes;
    } else {
      bytes = await File(audioPath).readAsBytes();
    }

    // Determine content-type from extension
    final ext = kIsWeb ? 'webm' : audioPath.split('.').last.toLowerCase();
    final mimeType = ext == 'wav' ? MediaType('audio', 'wav')
        : ext == 'webm' ? MediaType('audio', 'webm')
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
      ..headers['bypass-tunnel-reminder'] = 'true';

    if (kIsWeb) {
      final imgRes = await http.get(Uri.parse(imagePath));
      final audioRes = await http.get(Uri.parse(audioPath));
      request.files.add(http.MultipartFile.fromBytes('image', imgRes.bodyBytes, filename: 'image.jpg'));
      request.files.add(http.MultipartFile.fromBytes('audio', audioRes.bodyBytes, filename: 'audio.webm'));
    } else {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
    }

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

    String? getTagValue(String groupCode, String code) {
      final tags = j['tags'] as List?;
      if (tags == null) return null;
      for (final tagGroup in tags) {
        if (tagGroup is Map && tagGroup['code'] == groupCode) {
          final list = tagGroup['list'] as List?;
          if (list != null) {
            for (final item in list) {
              if (item is Map && item['code'] == code) {
                return item['value']?.toString();
              }
            }
          }
        }
      }
      return null;
    }

    final materialsStr = getTagValue('craft_attributes', 'materials') ?? '';
    final materialsList = materialsStr
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final titleEn = j['descriptor']?['name'] as String?;
    final titleHi = getTagValue('translation_hi', 'name');
    final descriptionEn = j['descriptor']?['long_desc'] as String?;
    final descriptionHi = getTagValue('translation_hi', 'long_desc');
    
    final laborDays = _parseInt(getTagValue('pricing_inputs', 'labor_days')) ?? 0;

    final images = j['descriptor']?['images'] as List?;
    final rawStudioUrl = (images != null && images.isNotEmpty) ? images.first as String? : null;
    final fullStudioUrl = rawStudioUrl != null ? '${AppConstants.backendUrl}$rawStudioUrl' : null;

    final pricing = PricingCorridor(
      rawMaterialCost: _parseInt(getTagValue('pricing_inputs', 'raw_material_cost')) ?? 0,
      laborDays: laborDays,
      itemsProduced: _parseInt(getTagValue('pricing_inputs', 'items_produced')) ?? 1,
      sellerProposedPrice: _parseInt(getTagValue('pricing_inputs', 'seller_proposed_price')) ?? 0,
      dailyWageRate: AppConstants.defaultDailyWageRate,
      overheadPercent: AppConstants.overheadPercent,
      floorPrice: _parseInt(j['price']?['value']) ?? 0,
      fairPrice: 0,
      premiumPrice: _parseInt(j['price']?['maximum_value']) ?? 0,
    );

    return CatalogProcessResult(
      titleEn: titleEn,
      titleHi: titleHi,
      descriptionEn: descriptionEn,
      descriptionHi: descriptionHi,
      craftAttributes: CraftAttributes(
        category: getTagValue('craft_attributes', 'category'),
        materials: materialsList,
        laborDays: laborDays,
        clusterLocation: getTagValue('craft_attributes', 'cluster_location'),
        categoryId: j['category_id'] as String?,
        fulfillmentId: j['fulfillment_id'] as String?,
        locationId: j['location_id'] as String?,
        quantity: j['quantity']?['available']?['count'] as int? ?? 1,
        timeToShip: j['@ondc/org/time_to_ship'] as String?,
        returnable: j['@ondc/org/returnable'] as bool? ?? true,
        cancellable: j['@ondc/org/cancellable'] as bool? ?? true,
        availableOnCod: j['@ondc/org/available_on_cod'] as bool? ?? true,
        returnWindow: j['@ondc/org/return_window'] as String?,
        countryOfOrigin: getTagValue('statutory_info', 'country_of_origin'),
        netQuantity: getTagValue('statutory_info', 'net_quantity'),
        genericName: getTagValue('statutory_info', 'generic_name'),
        artisanName: getTagValue('statutory_info', 'manufacturer_name'),
      ),
      pricing: pricing,
      studioImagePath: fullStudioUrl,
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

An artisan has described their handmade product in Hindi or a regional Indian language (possibly code-switched with English). Extract the following structured information from their voice transcript and return ONLY a valid JSON object matching the ONDC Beckn Item schema — no markdown, no explanation.

JSON schema:
{
  "id": "item_generated",
  "category_id": "RET16",
  "fulfillment_id": "F1",
  "location_id": "L1",
  "descriptor": {
    "name": "string — SEO-friendly English product title, max 80 chars",
    "short_desc": "string — short description",
    "long_desc": "string — SEO-optimized English description, 150–250 words"
  },
  "price": {
    "currency": "INR",
    "value": "0",
    "maximum_value": "0"
  },
  "quantity": {
    "available": {
      "count": 1
    }
  },
  "@ondc/org/time_to_ship": "PT48H",
  "@ondc/org/returnable": true,
  "@ondc/org/cancellable": true,
  "@ondc/org/available_on_cod": true,
  "@ondc/org/return_window": "P7D",
  "tags": [
    {
      "code": "translation_hi",
      "list": [
        { "code": "name", "value": "Hindi product title" },
        { "code": "long_desc", "value": "Hindi description" }
      ]
    },
    {
      "code": "craft_attributes",
      "list": [
        { "code": "category", "value": "e.g. Terracotta Pottery" },
        { "code": "materials", "value": "comma separated raw materials in English" },
        { "code": "cluster_location", "value": "city/district if mentioned" }
      ]
    },
    {
      "code": "pricing_inputs",
      "list": [
        { "code": "raw_material_cost", "value": "integer or 0 if missing" },
        { "code": "labor_days", "value": "integer or 0 if missing" },
        { "code": "items_produced", "value": "integer or 1 if missing" },
        { "code": "seller_proposed_price", "value": "integer or 0 if missing" }
      ]
    },
    {
      "code": "statutory_info",
      "list": [
        { "code": "country_of_origin", "value": "IND" },
        { "code": "manufacturer_name", "value": "Artisan or brand name, else Unknown" },
        { "code": "net_quantity", "value": "e.g. 1 unit" },
        { "code": "generic_name", "value": "Commodity name" }
      ]
    }
  ]
}

Rules:
- If the artisan mentions a price, it is likely raw_material_cost (not selling price) unless they say "I want to sell for X" (which is seller_proposed_price).
- Return ONLY the JSON object. No markdown fences.
''';
