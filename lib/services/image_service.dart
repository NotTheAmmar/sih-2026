import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../config/constants.dart';

class ImageQualityResult {
  final bool isBlurry;
  final bool isLowLight;

  const ImageQualityResult({
    required this.isBlurry,
    required this.isLowLight,
  });

  bool get isAcceptable => !isBlurry && !isLowLight;
}

class ImageService {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _cameraController;

  /// Initialize the camera (front camera for selfie, back for product shots)
  Future<void> initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Use back camera for product photography
    final backCamera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    _isInitialized = true;
  }

  Future<void> dispose() async {
    await _cameraController?.dispose();
    _cameraController = null;
    _isInitialized = false;
  }

  /// Capture a photo from the live viewfinder
  Future<String?> capturePhoto() async {
    if (_cameraController == null || !_isInitialized) return null;
    try {
      final xFile = await _cameraController!.takePicture();
      return xFile.path;
    } catch (e) {
      return null;
    }
  }

  /// Pick an image from the gallery
  Future<String?> pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    return xFile?.path;
  }

  /// Quick quality check: blur + low-light detection (runs in a background isolate)
  Future<ImageQualityResult> checkQuality(String imagePath) async {
    try {
      return await compute(_checkQualityIsolate, imagePath);
    } catch (_) {
      return const ImageQualityResult(isBlurry: false, isLowLight: false);
    }
  }

  /// Simple studio simulation: composite image onto a white canvas with shadow.
  /// ── Integration point for teammate's BiRefNet model ──
  /// Replace this method body with the model's output path.
  Future<String?> createStudioImage(String rawImagePath) async {
    try {
      final bytes = await File(rawImagePath).readAsBytes();
      final source = img.decodeImage(bytes);
      if (source == null) return null;

      // Create a square white canvas (1:1 aspect ratio)
      final size = source.width > source.height ? source.width : source.height;
      final canvas = img.Image(width: size, height: size);
      img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

      // Center the product image on the canvas
      final offsetX = (size - source.width) ~/ 2;
      final offsetY = (size - source.height) ~/ 2;
      img.compositeImage(canvas, source, dstX: offsetX, dstY: offsetY);

      // Save composite to temp file
      final tempDir = await getTemporaryDirectory();
      final studioPath =
          '${tempDir.path}/studio_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(studioPath).writeAsBytes(img.encodeJpg(canvas, quality: 90));
      return studioPath;
    } catch (_) {
      return null;
    }
  }

}

// ── Top-level function required by compute() — isolates cannot use closures ──
ImageQualityResult _checkQualityIsolate(String imagePath) {
  try {
    final bytes = File(imagePath).readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const ImageQualityResult(isBlurry: false, isLowLight: false);
    }

    final gray = img.grayscale(decoded);

    // Blur: Laplacian variance — low variance = blurry
    double sum = 0, sumSq = 0;
    int count = 0;
    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        final c = gray.getPixel(x, y).r.toDouble();
        final t = gray.getPixel(x, y - 1).r.toDouble();
        final b = gray.getPixel(x, y + 1).r.toDouble();
        final l = gray.getPixel(x - 1, y).r.toDouble();
        final r = gray.getPixel(x + 1, y).r.toDouble();
        final lap = (4 * c - t - b - l - r).abs();
        sum += lap;
        sumSq += lap * lap;
        count++;
      }
    }
    final variance = count > 0
        ? (sumSq / count) - (sum / count) * (sum / count)
        : 0.0;
    final isBlurry = variance < AppConstants.blurVarianceThreshold;

    // Low-light: average luminance
    double total = 0;
    final pixelCount = gray.width * gray.height;
    for (final pixel in gray) {
      total += pixel.r.toDouble();
    }
    final avgLuminance = pixelCount > 0 ? total / pixelCount : 0.0;
    final isLowLight = avgLuminance < AppConstants.lowLightLuminanceThreshold;

    return ImageQualityResult(isBlurry: isBlurry, isLowLight: isLowLight);
  } catch (_) {
    return const ImageQualityResult(isBlurry: false, isLowLight: false);
  }
}
