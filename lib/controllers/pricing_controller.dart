import 'package:flutter/foundation.dart';
import '../config/constants.dart';
import '../models/pricing_corridor.dart';

class PricingController extends ChangeNotifier {
  int _rawMaterialCost;
  int _laborDays;
  int _itemsProduced;
  int _sellerProposedPrice;
  int _dailyWageRate;

  late PricingCorridor _corridor;

  PricingController({
    int initialRawMaterialCost = 0,
    int initialLaborDays = 0,
    int initialItemsProduced = 1,
    int initialSellerProposedPrice = 0,
    int dailyWageRate = AppConstants.defaultDailyWageRate,
  })  : _rawMaterialCost = initialRawMaterialCost,
        _laborDays = initialLaborDays,
        _itemsProduced = initialItemsProduced,
        _sellerProposedPrice = initialSellerProposedPrice,
        _dailyWageRate = dailyWageRate {
    _recalculate();
  }

  int get rawMaterialCost => _rawMaterialCost;
  int get laborDays => _laborDays;
  int get itemsProduced => _itemsProduced;
  int get sellerProposedPrice => _sellerProposedPrice;
  int get dailyWageRate => _dailyWageRate;
  PricingCorridor get corridor => _corridor;

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

  void setLaborDays(int value) {
    _laborDays = value.clamp(1, 365);
    _recalculate();
    notifyListeners();
  }

  void incrementLaborDays() {
    setLaborDays(_laborDays + 1);
  }

  void decrementLaborDays() {
    setLaborDays(_laborDays - 1);
  }

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
    _recalculate();
    notifyListeners();
  }

  void _recalculate() {
    _corridor = PricingCorridor.compute(
      rawMaterialCost: _rawMaterialCost,
      laborDays: _laborDays,
      itemsProduced: _itemsProduced,
      sellerProposedPrice: _sellerProposedPrice,
      dailyWageRate: _dailyWageRate,
    );
  }
}
