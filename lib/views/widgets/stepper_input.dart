import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

/// A stepper row with +/- buttons. Tapping the value label opens a keyboard
/// dialog so the user can type a number directly.
class StepperInput extends StatelessWidget {
  final String label;
  final String unit;
  final int value;
  final int step;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  /// Called when the user types a value directly. Defaults to null (no direct edit).
  final ValueChanged<int>? onDirectEdit;

  const StepperInput({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.step = 1,
    this.onDirectEdit,
  });

  Future<void> _showEditDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: value == 0 ? '' : '$value');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label, style: AppTextStyles.label),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            suffixText: unit,
            hintText: '0',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) =>
              Navigator.of(ctx).pop(int.tryParse(v) ?? 0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('रद्द / Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(int.tryParse(ctrl.text) ?? 0),
            child: const Text('ठीक है / OK'),
          ),
        ],
      ),
    );
    if (result != null && onDirectEdit != null) {
      onDirectEdit!(result);
    }
  }

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
            child: GestureDetector(
              onTap: onDirectEdit != null
                  ? () => _showEditDialog(context)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption),
                  Row(
                    children: [
                      Text(
                        '$value $unit',
                        style: AppTextStyles.subhead,
                      ),
                      if (onDirectEdit != null) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
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
