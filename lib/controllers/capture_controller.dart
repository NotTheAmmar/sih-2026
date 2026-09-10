import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/image_service.dart';

enum CaptureState { idle, previewing, confirmed }

class CaptureController extends ChangeNotifier {
  final ImageService _imageService;

  CaptureController({required ImageService imageService})
      : _imageService = imageService;

  CaptureState _state = CaptureState.idle;
  String? _capturedImagePath;
  bool _isQualityWarningBlur = false;
  bool _isQualityWarningLight = false;
  bool _isBusy = false;

  CaptureState get state => _state;
  String? get capturedImagePath => _capturedImagePath;
  bool get isQualityWarningBlur => _isQualityWarningBlur;
  bool get isQualityWarningLight => _isQualityWarningLight;
  bool get isBusy => _isBusy;
  bool get isCameraReady => _imageService.isInitialized;
  CameraController? get cameraController => _imageService.controller;

  Future<void> initCamera() async {
    await _imageService.initCamera();
    notifyListeners();
  }

  Future<void> capturePhoto() async {
    if (_isBusy) return;
    _isBusy = true;
    _clearWarnings();
    notifyListeners();

    HapticFeedback.mediumImpact();

    final path = await _imageService.capturePhoto();
    if (path != null) {
      await _handleImagePath(path);
    }

    _isBusy = false;
    notifyListeners();
  }

  Future<void> pickFromGallery() async {
    if (_isBusy) return;
    _isBusy = true;
    _clearWarnings();
    notifyListeners();

    final path = await _imageService.pickFromGallery();
    if (path != null) {
      await _handleImagePath(path);
    }

    _isBusy = false;
    notifyListeners();
  }

  void confirmImage() {
    if (_capturedImagePath != null) {
      _state = CaptureState.confirmed;
      HapticFeedback.lightImpact();
      notifyListeners();
    }
  }

  void retake() {
    _state = CaptureState.idle;
    _capturedImagePath = null;
    _clearWarnings();
    notifyListeners();
  }

  Future<void> _handleImagePath(String path) async {
    final quality = await _imageService.checkQuality(path);
    _isQualityWarningBlur = quality.isBlurry;
    _isQualityWarningLight = quality.isLowLight;

    _capturedImagePath = path;
    _state = CaptureState.previewing;
  }

  void _clearWarnings() {
    _isQualityWarningBlur = false;
    _isQualityWarningLight = false;
  }

  @override
  void dispose() {
    _imageService.dispose();
    super.dispose();
  }
}
