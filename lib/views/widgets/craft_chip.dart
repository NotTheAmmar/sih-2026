import 'package:flutter/material.dart';
import '../../config/theme.dart';

class CraftChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const CraftChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.actionGreen;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: chipColor.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: chipColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: chipColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
