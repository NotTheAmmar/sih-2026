import '../config/constants.dart';

class PricingCorridor {
  final int rawMaterialCost; // ₹ — Mraw
  final int laborDays; // Tdays
  final int itemsProduced;
  final int sellerProposedPrice;
  final int dailyWageRate; // ₹/day — Wartisan (₹450–600)
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
    int itemsProduced = 1,
    int sellerProposedPrice = 0,
    int dailyWageRate = AppConstants.defaultDailyWageRate,
    double overheadPercent = AppConstants.overheadPercent,
  }) {
    final laborCost = laborDays * dailyWageRate;
    final subtotal = rawMaterialCost + laborCost;
    final overhead = (subtotal * overheadPercent).round();
    final totalFloor = subtotal + overhead;
    
    // Divide by items produced (ensure no divide-by-zero)
    final qty = itemsProduced > 0 ? itemsProduced : 1;
    final floor = (totalFloor / qty).round();
    final fair = (floor * AppConstants.fairPriceMultiplier).round();
    final premium = (fair * AppConstants.premiumPriceMultiplier).round();

    return PricingCorridor(
      rawMaterialCost: rawMaterialCost,
      laborDays: laborDays,
      itemsProduced: itemsProduced,
      sellerProposedPrice: sellerProposedPrice,
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
    int? itemsProduced,
    int? sellerProposedPrice,
    int? dailyWageRate,
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
        overheadPercent: (json['overheadPercent'] as num).toDouble(),
        floorPrice: json['floorPrice'] as int,
        fairPrice: json['fairPrice'] as int,
        premiumPrice: json['premiumPrice'] as int,
      );
}
