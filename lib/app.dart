import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'views/screens/capture_screen.dart';
import 'views/screens/catalog_screen.dart';
import 'views/screens/processing_screen.dart';
import 'views/screens/voice_screen.dart';

class KalaKritiApp extends StatelessWidget {
  const KalaKritiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KalaKriti AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.capture,
      routes: {
        AppRoutes.capture: (_) => const CaptureScreen(),
        AppRoutes.voice: (_) => const VoiceScreen(),
        AppRoutes.processing: (_) => const ProcessingScreen(),
        AppRoutes.catalog: (_) => const CatalogScreen(),
      },
    );
  }
}
