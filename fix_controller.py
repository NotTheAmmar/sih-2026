import re

with open('lib/controllers/pricing_controller.dart', 'r') as f:
    text = f.read()

# Fix the constructor
constructor_fix = """    int initialItemsProduced = 1,
    int initialSellerProposedPrice = 0,
    int dailyWageRate = AppConstants.defaultDailyWageRate,
    double skillMultiplier = 1.0,
    int initialQuantity = 1,
  })  : _rawMaterialCost = initialRawMaterialCost,
        _laborDays = initialLaborDays,
        _itemsProduced = initialItemsProduced,
        _sellerProposedPrice = initialSellerProposedPrice,
        _dailyWageRate = dailyWageRate,
        _skillMultiplier = skillMultiplier,
        _availableQuantity = initialQuantity {"""

text = re.sub(
    r'<<<<<<< HEAD\n=======\n    int initialItemsProduced = 1,\n    int initialSellerProposedPrice = 0,\n>>>>>>> origin/main\n    int dailyWageRate = AppConstants.defaultDailyWageRate,\n    double skillMultiplier = 1\.0,\n    int initialQuantity = 1,\n  \)  : _rawMaterialCost = initialRawMaterialCost,\n        _laborDays = initialLaborDays,\n<<<<<<< HEAD\n        _dailyWageRate = dailyWageRate,\n        _skillMultiplier = skillMultiplier,\n        _availableQuantity = initialQuantity \{\n=======\n        _itemsProduced = initialItemsProduced,\n        _sellerProposedPrice = initialSellerProposedPrice,\n        _dailyWageRate = dailyWageRate \{\n>>>>>>> origin/main',
    constructor_fix,
    text,
    flags=re.DOTALL
)

# Fix the block with setFinalPrice and setItemsProduced
methods_fix = """  // ── Final price manual override ───────────────────────────────────────────

  /// Set a manual final price entered by the artisan.
  /// Returns an error string if the price violates the statutory minimum.
  String? setFinalPrice(int value) {
    if (value < _corridor.floorPrice) {
      return 'मूल्य वैधानिक न्यूनतम (₹${_corridor.floorPrice}) से कम नहीं हो सकता';
    }
    _manualFinalPrice = value.clamp(0, 9999999);
    notifyListeners();
    return null; // success
  }

  /// Clear the override and revert to computed fair price.
  void clearFinalPriceOverride() {
    _manualFinalPrice = null;
    notifyListeners();
  }

  // ── Items Produced & Proposed Price ───────────────────────────────────────

  void setItemsProduced(int value) {
    _itemsProduced = value.clamp(1, 9999);
    _recalculate();
    notifyListeners();
  }

  void incrementItemsProduced() {
    setItemsProduced(_itemsProduced + 1);
  }

  void decrementItemsProduced() {
    setItemsProduced(_itemsProduced - 1);
  }

  void setSellerProposedPrice(int value) {
    _sellerProposedPrice = value.clamp(0, 999999);
    _recalculate();
    notifyListeners();
  }

  // ── Seed from AI extraction ───────────────────────────────────────────────

  void seedFromExtracted({
    required int rawMaterialCost, 
    required int laborDays,
    required int itemsProduced,
    required int sellerProposedPrice,
  }) {
    _rawMaterialCost = rawMaterialCost;
    _laborDays = laborDays;
    _itemsProduced = itemsProduced > 0 ? itemsProduced : 1;
    _sellerProposedPrice = sellerProposedPrice;
    _manualFinalPrice = null; // clear any previous manual override"""

text = re.sub(
    r'<<<<<<< HEAD\n  // ── Final price manual override(.*?)\n=======\n  void setItemsProduced\((.*?)\n>>>>>>> origin/main',
    methods_fix,
    text,
    flags=re.DOTALL
)

with open('lib/controllers/pricing_controller.dart', 'w') as f:
    f.write(text)

