import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/catalog_item.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/image_service.dart';
import '../services/storage_service.dart';

enum ProcessingStage { notStarted, imageProcessing, voiceProcessing, pricing, done, error }

class CatalogController extends ChangeNotifier {
  final ApiService _apiService;
  final ImageService _imageService;
  final AudioService _audioService;
  final StorageService _storageService;

  CatalogController({
    required ApiService apiService,
    required ImageService imageService,
    required AudioService audioService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _imageService = imageService,
        _audioService = audioService,
        _storageService = storageService;

  ProcessingStage _stage = ProcessingStage.notStarted;
  CatalogItem? _currentItem;
  bool _showStudioImage = false;
  bool _isSpeaking = false;
  bool _isPublishing = false;
  bool _publishSuccess = false;
  String? _errorMessage;

  ProcessingStage get stage => _stage;
  CatalogItem? get currentItem => _currentItem;
  bool get showStudioImage => _showStudioImage;
  bool get isSpeaking => _isSpeaking;
  bool get isPublishing => _isPublishing;
  bool get publishSuccess => _publishSuccess;
  String? get errorMessage => _errorMessage;

  /// Main pipeline: takes captured image + recorded audio → produces CatalogItem
  Future<void> processCatalog({
    required String imagePath,
    required String audioPath,
  }) async {
    _stage = ProcessingStage.imageProcessing;
    _errorMessage = null;
    _publishSuccess = false;
    notifyListeners();

    try {
      final result = await _apiService.processCatalog(
        imagePath: imagePath,
        audioPath: audioPath,
        onStageComplete: (stage) {
          switch (stage) {
            case 0:
              _stage = ProcessingStage.imageProcessing;
            case 1:
              _stage = ProcessingStage.voiceProcessing;
            case 2:
              _stage = ProcessingStage.pricing;
          }
          notifyListeners();
        },
      );

      _currentItem = CatalogItem(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        rawImagePath: imagePath,
        studioImagePath: result.studioImagePath,
        audioPath: audioPath,
        titleEn: result.titleEn,
        titleHi: result.titleHi,
        descriptionEn: result.descriptionEn,
        descriptionHi: result.descriptionHi,
        craftAttributes: result.craftAttributes,
        pricing: result.pricing,
        status: CatalogStatus.draft,
      );

      // Persist locally
      await _storageService.saveCatalog(_currentItem!);

      _stage = ProcessingStage.done;
      notifyListeners();
    } catch (e) {
      _stage = ProcessingStage.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void togglePhotoView() {
    _showStudioImage = !_showStudioImage;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  Future<void> speakReadback() async {
    if (_currentItem == null || _isSpeaking) return;
    _isSpeaking = true;
    notifyListeners();

    await _audioService.speakCatalogSummary(
      titleHi: _currentItem!.titleHi,
      fairPrice: _currentItem!.pricing?.fairPrice,
      category: _currentItem!.craftAttributes?.category,
    );

    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> stopReadback() async {
    await _audioService.stopTts();
    _isSpeaking = false;
    notifyListeners();
  }

  /// Simulate ONDC publish (Phase 2: wire to Beckn BPP)
  Future<void> publishToOndc() async {
    if (_currentItem == null || _isPublishing) return;
    _isPublishing = true;
    notifyListeners();

    // Simulate network call
    await Future.delayed(const Duration(seconds: 2));

    _currentItem = _currentItem!.copyWith(status: CatalogStatus.published);
    await _storageService.saveCatalog(_currentItem!);

    _isPublishing = false;
    _publishSuccess = true;
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  void reset() {
    _stage = ProcessingStage.notStarted;
    _currentItem = null;
    _showStudioImage = false;
    _isSpeaking = false;
    _isPublishing = false;
    _publishSuccess = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.stopTts();
    super.dispose();
  }
}
