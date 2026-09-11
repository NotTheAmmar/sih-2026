import 'package:flutter/foundation.dart';
import '../config/constants.dart';
import '../models/pricing_corridor.dart';

class PricingController extends ChangeNotifier {
  int _rawMaterialCost;
  int _laborDays;
  int _itemsProduced;
  int _sellerProposedPrice;
  int _dailyWageRate;
  double _skillMultiplier;
  int _availableQuantity;

  /// When non-null, the user has manually overridden the final (fair) price.
  int? _manualFinalPrice;

  late PricingCorridor _corridor;

  PricingController({
    int initialRawMaterialCost = 0,
    int initialLaborDays = 0,
    int initialItemsProduced = 1,
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
        _availableQuantity = initialQuantity {
    _recalculate();
  }

  int get rawMaterialCost => _rawMaterialCost;
  int get laborDays => _laborDays;
  int get itemsProduced => _itemsProduced;
  int get sellerProposedPrice => _sellerProposedPrice;
  int get dailyWageRate => _dailyWageRate;
  double get skillMultiplier => _skillMultiplier;
  int get availableQuantity => _availableQuantity;
  PricingCorridor get corridor => _corridor;

  /// The final price shown to the user — either manual override or computed fair.
  int get finalPrice => _manualFinalPrice ?? _corridor.fairPrice;
  bool get hasFinalPriceOverride => _manualFinalPrice != null;

  // ── Inventory / Quantity ──────────────────────────────────────────────────

  void setAvailableQuantity(int value) {
    _availableQuantity = value.clamp(1, 9999);
    notifyListeners();
  }

  void incrementQuantity({int step = 1}) {
    setAvailableQuantity(_availableQuantity + step);
  }

  void decrementQuantity({int step = 1}) {
    setAvailableQuantity(_availableQuantity - step);
  }

  // ── Raw material cost ─────────────────────────────────────────────────────

  void setRawMaterialCost(int value) {
    _rawMaterialCost = value.clamp(0, 999999);
    _recalculate();
    notifyListeners();
  }

  void incrementRawMaterial({int step = 50}) {
    setRawMaterialCost(_rawMaterialCost + step);
  }

  void decrementRawMaterial({int step = 50}) {
    setRawMaterialCost(_rawMaterialCost - step);
  }

  // ── Labour days ───────────────────────────────────────────────────────────

  void setLaborDays(int value) {
    _laborDays = value.clamp(0, 365);
    _recalculate();
    notifyListeners();
  }

  void incrementLaborDays() {
    setLaborDays(_laborDays + 1);
  }

  void decrementLaborDays() {
    setLaborDays(_laborDays - 1);
  }

  // ── Final price manual override ───────────────────────────────────────────

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
    _manualFinalPrice = null; // clear any previous manual override
    _recalculate();
    notifyListeners();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _recalculate() {
    _corridor = PricingCorridor.compute(
      rawMaterialCost: _rawMaterialCost,
      laborDays: _laborDays,
      itemsProduced: _itemsProduced,
      sellerProposedPrice: _sellerProposedPrice,
      dailyWageRate: _dailyWageRate,
      skillMultiplier: _skillMultiplier,
    );
    // If the floor rose above the manual override, clear the override
    if (_manualFinalPrice != null && _manualFinalPrice! < _corridor.floorPrice) {
      _manualFinalPrice = null;
    }
  }
}
