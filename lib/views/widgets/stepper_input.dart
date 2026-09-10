import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

class StepperInput extends StatelessWidget {
  final String label;
  final String unit;
  final int value;
  final int step;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const StepperInput({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(
                  '$value $unit',
                  style: AppTextStyles.subhead,
                ),
              ],
            ),
          ),
          // Decrement
          _StepBtn(
            icon: Icons.remove_rounded,
            onPressed: onDecrement,
          ),
          const SizedBox(width: AppSpacing.sm),
          // Increment
          _StepBtn(
            icon: Icons.add_rounded,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _StepBtn({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: Container(
        width: AppSpacing.touchTargetMin,
        height: AppSpacing.touchTargetMin,
        decoration: BoxDecoration(
          color: AppColors.actionGreen.withAlpha(15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.actionGreen.withAlpha(60)),
        ),
        child: Icon(icon, color: AppColors.actionGreen, size: 24),
      ),
    );
  }
}
