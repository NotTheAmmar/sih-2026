import '../config/constants.dart';

class PricingCorridor {
  final int rawMaterialCost; // ₹ — Mraw
  final int laborDays; // Tdays
  final int dailyWageRate; // ₹/day — Wartisan (₹450–600)
  final double overheadPercent; // e.g. 0.10 for 10%

  // Computed tiers (set after calculation)
  final int floorPrice;
  final int fairPrice;
  final int premiumPrice;

  const PricingCorridor({
    required this.rawMaterialCost,
    required this.laborDays,
    required this.dailyWageRate,
    required this.overheadPercent,
    required this.floorPrice,
    required this.fairPrice,
    required this.premiumPrice,
  });

  /// Factory: compute corridor from inputs using the deterministic formula.
  ///
  /// Cfloor = Mraw + (Tdays × Wartisan) + Ooverhead
  /// Pfair  = Cfloor × 1.50
  /// Pprem  = Pfair  × 1.20
  factory PricingCorridor.compute({
    required int rawMaterialCost,
    required int laborDays,
    int dailyWageRate = AppConstants.defaultDailyWageRate,
    double overheadPercent = AppConstants.overheadPercent,
  }) {
    final laborCost = laborDays * dailyWageRate;
    final subtotal = rawMaterialCost + laborCost;
    final overhead = (subtotal * overheadPercent).round();
    final floor = subtotal + overhead;
    final fair = (floor * AppConstants.fairPriceMultiplier).round();
    final premium = (fair * AppConstants.premiumPriceMultiplier).round();

    return PricingCorridor(
      rawMaterialCost: rawMaterialCost,
      laborDays: laborDays,
      dailyWageRate: dailyWageRate,
      overheadPercent: overheadPercent,
      floorPrice: floor,
      fairPrice: fair,
      premiumPrice: premium,
    );
  }

  PricingCorridor copyWith({
    int? rawMaterialCost,
    int? laborDays,
    int? dailyWageRate,
    double? overheadPercent,
    int? floorPrice,
    int? fairPrice,
    int? premiumPrice,
  }) {
    return PricingCorridor(
      rawMaterialCost: rawMaterialCost ?? this.rawMaterialCost,
      laborDays: laborDays ?? this.laborDays,
      dailyWageRate: dailyWageRate ?? this.dailyWageRate,
      overheadPercent: overheadPercent ?? this.overheadPercent,
      floorPrice: floorPrice ?? this.floorPrice,
      fairPrice: fairPrice ?? this.fairPrice,
      premiumPrice: premiumPrice ?? this.premiumPrice,
    );
  }

  Map<String, dynamic> toJson() => {
        'rawMaterialCost': rawMaterialCost,
        'laborDays': laborDays,
        'dailyWageRate': dailyWageRate,
        'overheadPercent': overheadPercent,
        'floorPrice': floorPrice,
        'fairPrice': fairPrice,
        'premiumPrice': premiumPrice,
      };

  factory PricingCorridor.fromJson(Map<String, dynamic> json) =>
      PricingCorridor(
        rawMaterialCost: json['rawMaterialCost'] as int,
        laborDays: json['laborDays'] as int,
        dailyWageRate: json['dailyWageRate'] as int,
        overheadPercent: (json['overheadPercent'] as num).toDouble(),
        floorPrice: json['floorPrice'] as int,
        fairPrice: json['fairPrice'] as int,
        premiumPrice: json['premiumPrice'] as int,
      );
}
