import '../config/constants.dart';

class PricingCorridor {
  final int rawMaterialCost; // ₹ — Mraw
  final int laborDays; // Tdays
  final int itemsProduced;
  final int sellerProposedPrice;
  final int dailyWageRate; // ₹/day — Wartisan (₹450–600)
  final double skillMultiplier; // Kskill
  final double overheadPercent; // e.g. 0.10 for 10%

  // Computed tiers (set after calculation)
  final int floorPrice;
  final int fairPrice;
  final int premiumPrice;

  const PricingCorridor({
    required this.rawMaterialCost,
    required this.laborDays,
    required this.itemsProduced,
    required this.sellerProposedPrice,
    required this.dailyWageRate,
    this.skillMultiplier = 1.0,
    required this.overheadPercent,
    required this.floorPrice,
    required this.fairPrice,
    required this.premiumPrice,
  });

  /// Factory: compute corridor from inputs using the MoSJE deterministic formula.
  ///
  /// Cfloor = Mraw + (Tdays * Wstatutory * Kskill) + Ooverhead
  /// Pfair  = Cfloor * 1.50 (Phase 1 fallback)
  /// Pprem  = Pfair * 1.20
  factory PricingCorridor.compute({
    required int rawMaterialCost,
    required int laborDays,
    int itemsProduced = 1,
    int sellerProposedPrice = 0,
    int dailyWageRate = AppConstants.defaultDailyWageRate,
    double skillMultiplier = 1.0,
    double overheadPercent = AppConstants.overheadPercent,
  }) {
    // Base Labor = T_days * W_statutory * K_skill
    final double baseLabor = laborDays * dailyWageRate * skillMultiplier;
    
    // Base Cost = M_raw + Base Labor
    final double baseCost = rawMaterialCost + baseLabor;
    
    // Overhead (O_overhead) = 10%
    final double overhead = baseCost * overheadPercent;
    
    // Total floor before qty division
    final double totalFloor = baseCost + overhead;
    
    // Divide by items produced (ensure no divide-by-zero)
    final qty = itemsProduced > 0 ? itemsProduced : 1;
    final int floor = (totalFloor / qty).round();
    
    // P_fair (Market-Aware fallback until XGBoost is connected)
    final int fair = (floor * AppConstants.fairPriceMultiplier).round();
    
    // P_prem (1.20 * P_fair)
    final int premium = (fair * AppConstants.premiumPriceMultiplier).round();

    return PricingCorridor(
      rawMaterialCost: rawMaterialCost,
      laborDays: laborDays,
      itemsProduced: itemsProduced,
      sellerProposedPrice: sellerProposedPrice,
      dailyWageRate: dailyWageRate,
      skillMultiplier: skillMultiplier,
      overheadPercent: overheadPercent,
      floorPrice: floor,
      fairPrice: fair,
      premiumPrice: premium,
    );
  }

  PricingCorridor copyWith({
    int? rawMaterialCost,
    int? laborDays,
    int? itemsProduced,
    int? sellerProposedPrice,
    int? dailyWageRate,
    double? skillMultiplier,
    double? overheadPercent,
    int? floorPrice,
    int? fairPrice,
    int? premiumPrice,
  }) {
    return PricingCorridor(
      rawMaterialCost: rawMaterialCost ?? this.rawMaterialCost,
      laborDays: laborDays ?? this.laborDays,
      itemsProduced: itemsProduced ?? this.itemsProduced,
      sellerProposedPrice: sellerProposedPrice ?? this.sellerProposedPrice,
      dailyWageRate: dailyWageRate ?? this.dailyWageRate,
      skillMultiplier: skillMultiplier ?? this.skillMultiplier,
      overheadPercent: overheadPercent ?? this.overheadPercent,
      floorPrice: floorPrice ?? this.floorPrice,
      fairPrice: fairPrice ?? this.fairPrice,
      premiumPrice: premiumPrice ?? this.premiumPrice,
    );
  }

  Map<String, dynamic> toJson() => {
        'rawMaterialCost': rawMaterialCost,
        'laborDays': laborDays,
        'itemsProduced': itemsProduced,
        'sellerProposedPrice': sellerProposedPrice,
        'dailyWageRate': dailyWageRate,
        'skillMultiplier': skillMultiplier,
        'overheadPercent': overheadPercent,
        'floorPrice': floorPrice,
        'fairPrice': fairPrice,
        'premiumPrice': premiumPrice,
      };

  factory PricingCorridor.fromJson(Map<String, dynamic> json) =>
      PricingCorridor(
        rawMaterialCost: json['rawMaterialCost'] as int,
        laborDays: json['laborDays'] as int,
        itemsProduced: json['itemsProduced'] as int? ?? 1,
        sellerProposedPrice: json['sellerProposedPrice'] as int? ?? 0,
        dailyWageRate: json['dailyWageRate'] as int,
        skillMultiplier: (json['skillMultiplier'] as num?)?.toDouble() ?? 1.0,
        overheadPercent: (json['overheadPercent'] as num).toDouble(),
        floorPrice: json['floorPrice'] as int,
        fairPrice: json['fairPrice'] as int,
        premiumPrice: json['premiumPrice'] as int,
      );
}
