import 'package:flutter/foundation.dart';
import '../config/constants.dart';
import '../models/pricing_corridor.dart';

class PricingController extends ChangeNotifier {
  int _rawMaterialCost;
  int _laborDays;
  int _dailyWageRate;

  late PricingCorridor _corridor;

  PricingController({
    int initialRawMaterialCost = 500,
    int initialLaborDays = 3,
    int dailyWageRate = AppConstants.defaultDailyWageRate,
  })  : _rawMaterialCost = initialRawMaterialCost,
        _laborDays = initialLaborDays,
        _dailyWageRate = dailyWageRate {
    _recalculate();
  }

  int get rawMaterialCost => _rawMaterialCost;
  int get laborDays => _laborDays;
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

  void seedFromExtracted({required int rawMaterialCost, required int laborDays}) {
    _rawMaterialCost = rawMaterialCost;
    _laborDays = laborDays;
    _recalculate();
    notifyListeners();
  }

  void _recalculate() {
    _corridor = PricingCorridor.compute(
      rawMaterialCost: _rawMaterialCost,
      laborDays: _laborDays,
      dailyWageRate: _dailyWageRate,
    );
  }
}
