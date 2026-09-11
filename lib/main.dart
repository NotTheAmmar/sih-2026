import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'controllers/capture_controller.dart';
import 'controllers/catalog_controller.dart';
import 'controllers/pricing_controller.dart';
import 'controllers/voice_controller.dart';
import 'services/api_service.dart';
import 'services/audio_service.dart';
import 'services/image_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final imageService = ImageService();
  final audioService = AudioService();
  final storageService = StorageService();
  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CaptureController(imageService: imageService),
        ),
        ChangeNotifierProvider(
          create: (_) => VoiceController(audioService: audioService),
        ),
        ChangeNotifierProvider(
          create: (_) => CatalogController(
            apiService: apiService,
            audioService: audioService,
            storageService: storageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PricingController(),
        ),
      ],
      child: const KalaKritiApp(),
    ),
  );
}
