import 'package:flutter/material.dart';
import '../../config/theme.dart';

class PriceGauge extends StatelessWidget {
  final int floorPrice;
  final int fairPrice;
  final int premiumPrice;

  const PriceGauge({
    super.key,
    required this.floorPrice,
    required this.fairPrice,
    required this.premiumPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'मूल्य श्रेणी / Price Corridor',
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PriceTile(
          label: 'Floor',
          sublabel: 'न्यूनतम — Breakeven',
          price: floorPrice,
          color: AppColors.priceFloor,
          icon: Icons.arrow_downward_rounded,
        ),
        const SizedBox(height: AppSpacing.xs),
        _PriceTile(
          label: 'Fair Market',
          sublabel: 'अनुशंसित — Recommended D2C',
          price: fairPrice,
          color: AppColors.priceFair,
          icon: Icons.check_circle_rounded,
          isHighlighted: true,
        ),
        const SizedBox(height: AppSpacing.xs),
        _PriceTile(
          label: 'Premium / B2B',
          sublabel: 'थोक / GeM — Institutional',
          price: premiumPrice,
          color: AppColors.pricePremium,
          icon: Icons.stars_rounded,
        ),
      ],
    );
  }
}

class _PriceTile extends StatelessWidget {
  final String label;
  final String sublabel;
  final int price;
  final Color color;
  final IconData icon;
  final bool isHighlighted;

  const _PriceTile({
    required this.label,
    required this.sublabel,
    required this.price,
    required this.color,
    required this.icon,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: isHighlighted
            ? color.withAlpha(20)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isHighlighted ? color : AppColors.cardBorder,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label.copyWith(color: color)),
                Text(sublabel, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(
            '₹$price',
            style: (isHighlighted ? AppTextStyles.priceLarge : AppTextStyles.priceSmall)
                .copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
