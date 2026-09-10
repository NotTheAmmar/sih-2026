import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // API
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.kalakriti.dev/v1';
  static bool get useMockData =>
      (dotenv.env['USE_MOCK_DATA'] ?? 'true').toLowerCase() == 'true';
  static Duration get apiTimeout => const Duration(seconds: 120);

  // Gemini
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get geminiModel =>
      dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';

  // Groq (Whisper-Large-v3, Path 3 ASR)
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  // Bhashini (Path 2)
  static String get bhashiniApiKey => dotenv.env['BHASHINI_API_KEY'] ?? '';
  static String get bhashiniUlcaKey => dotenv.env['BHASHINI_ULCA_KEY'] ?? '';
  static String get bhashiniApiUrl =>
      dotenv.env['BHASHINI_API_URL'] ??
      'https://dhruva-api.bhashini.gov.in';

  // Voice pipeline selector: "groq" | "bhashini" | "ai4bharat" | "auto"
  // "auto" = groq if key present, else backend
  static String get voicePipeline =>
      dotenv.env['VOICE_PIPELINE']?.toLowerCase() ?? 'auto';

  // Backend (Path 1 & 2 — FastAPI)
  static String get backendUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';

  // Audio
  static const int maxRecordingSeconds = 15;
  static const int audioSampleRate = 16000;
  static const double silenceAmplitudeThreshold = -50.0; // dBFS

  // Image quality thresholds
  static const double blurVarianceThreshold = 100.0;
  static const double lowLightLuminanceThreshold = 40.0;

  // Pricing defaults
  static const int defaultDailyWageRate = 500; // ₹/day
  static const double overheadPercent = 0.10;
  static const double fairPriceMultiplier = 1.50;
  static const double premiumPriceMultiplier = 1.20;

  // Mock data delay (simulates inference latency)
  static const Duration mockStage1Delay = Duration(milliseconds: 1500);
  static const Duration mockStage2Delay = Duration(milliseconds: 1800);
  static const Duration mockStage3Delay = Duration(milliseconds: 1000);
}
