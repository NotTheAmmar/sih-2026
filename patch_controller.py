import re

with open('lib/controllers/catalog_controller.dart', 'r') as f:
    content = f.read()

# Add import for PricingController
content = content.replace(
    "import '../services/storage_service.dart';",
    "import '../services/storage_service.dart';\nimport 'pricing_controller.dart';"
)

# Replace the publishToOndc method
old_method = """  /// Simulate ONDC publish (Phase 2: wire to Beckn BPP)
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
  }"""

new_method = """  /// Publish to ONDC via the BPP backend.
  Future<void> publishToOndc(PricingController pricingCtrl) async {
    if (_currentItem == null || _isPublishing) return;
    _isPublishing = true;
    _publishSuccess = false;
    _errorMessage = null;
    notifyListeners();

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
  }"""

content = content.replace(old_method, new_method)

with open('lib/controllers/catalog_controller.dart', 'w') as f:
    f.write(content)
