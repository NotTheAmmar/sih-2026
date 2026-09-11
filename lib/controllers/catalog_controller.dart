import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/catalog_item.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import 'pricing_controller.dart';

enum ProcessingStage { notStarted, imageProcessing, voiceProcessing, pricing, done, error }

class CatalogController extends ChangeNotifier {
  final ApiService _apiService;
  final AudioService _audioService;
  final StorageService _storageService;

  CatalogController({
    required ApiService apiService,
    required AudioService audioService,
    required StorageService storageService,
  })  : _apiService = apiService,
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

      // Warm the image cache now so the studio photo is ready by the time
      // the user reaches the catalog screen (avoids visible load flash).
      if (result.studioImagePath != null &&
          result.studioImagePath!.startsWith('http')) {
        _precacheStudioImage(result.studioImagePath!);
      }

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

  /// Publish to ONDC via the BPP backend.
  Future<void> publishToOndc(PricingController pricingCtrl) async {
    if (_currentItem == null || _isPublishing) return;
    _isPublishing = true;
    _publishSuccess = false;
    _errorMessage = null;
    notifyListeners();

    if (pricingCtrl.corridor.floorPrice <= 0 || pricingCtrl.corridor.fairPrice <= 0 || pricingCtrl.corridor.premiumPrice <= 0) {
      _errorMessage = 'मूल्य 0 से अधिक होना चाहिए / Price must be greater than ₹0 before publishing';
      _isPublishing = false;
      notifyListeners();
      return;
    }

    try {
      final response = await _apiService.publishToOndc(
        item: _currentItem!,
        pricing: pricingCtrl.corridor,
        availableQuantity: pricingCtrl.availableQuantity,
      );

      if (response['status'] == 'PUBLISHED') {
        _currentItem = _currentItem!.copyWith(status: CatalogStatus.published);
        await _storageService.saveCatalog(_currentItem!);
        _publishSuccess = true;
        HapticFeedback.heavyImpact();

        // TTS confirmation in Hindi
        await _audioService.speakText(
          'आपका उत्पाद ओ.एन.डी.सी. पर प्रकाशित हो गया है।',
        );
      } else {
        _errorMessage = response['message'] ?? 'Publish failed';
      }
    } catch (e) {
      _errorMessage = 'Publish failed: ${e.toString()}';
    }

    _isPublishing = false;
    notifyListeners();
  }

  /// Warms the Flutter image cache for [url] in the background.
  /// Uses [NetworkImage] directly — no BuildContext needed.
  void _precacheStudioImage(String url) {
    final provider = NetworkImage(
      url,
      headers: const {'ngrok-skip-browser-warning': 'true'},
    );
    provider.resolve(ImageConfiguration.empty).addListener(
      ImageStreamListener(
        (info, _) {}, // success — image is now in cache
        onError: (e, _) {}, // ignore cache-warm errors silently
      ),
    );
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
