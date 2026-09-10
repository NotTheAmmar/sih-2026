import 'package:flutter/material.dart';
import '../../config/theme.dart';

enum StepStatus { waiting, active, done }

class ProgressStepper extends StatelessWidget {
  final int currentStage; // 0, 1, 2

  const ProgressStepper({super.key, required this.currentStage});

  static const _steps = [
    _StepData(
      icon: Icons.auto_fix_high_rounded,
      labelHi: 'स्टूडियो सफाई',
      labelEn: 'Studio Safai',
    ),
    _StepData(
      icon: Icons.mic_rounded,
      labelHi: 'आवाज़ की पहचान',
      labelEn: 'Aawaz ki Pehchan',
    ),
    _StepData(
      icon: Icons.currency_rupee_rounded,
      labelHi: 'सही दाम गणना',
      labelEn: 'Sahi Daam Ganana',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_steps.length, (i) {
        final status = i < currentStage
            ? StepStatus.done
            : i == currentStage
                ? StepStatus.active
                : StepStatus.waiting;
        return _StepTile(step: _steps[i], status: status, index: i);
      }),
    );
  }
}

class _StepData {
  final IconData icon;
  final String labelHi;
  final String labelEn;
  const _StepData({required this.icon, required this.labelHi, required this.labelEn});
}

class _StepTile extends StatefulWidget {
  final _StepData step;
  final StepStatus status;
  final int index;

  const _StepTile({required this.step, required this.status, required this.index});

  @override
  State<_StepTile> createState() => _StepTileState();
}

class _StepTileState extends State<_StepTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.status == StepStatus.active) {
      _shimmer.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StepTile old) {
    super.didUpdateWidget(old);
    if (widget.status == StepStatus.active) {
      _shimmer.repeat(reverse: true);
    } else {
      _shimmer.stop();
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.status == StepStatus.done;
    final isActive = widget.status == StepStatus.active;
    final isWaiting = widget.status == StepStatus.waiting;

    final iconColor = isDone
        ? AppColors.actionGreen
        : isActive
            ? AppColors.warningAmber
            : AppColors.textHint;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              // Status indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppColors.actionGreenLight
                      : isActive
                          ? AppColors.warningAmberLight.withValues(
                              alpha: 0.5 + 0.5 * _shimmer.value)
                          : AppColors.divider,
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : widget.step.icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.step.labelHi,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isWaiting ? AppColors.textHint : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.step.labelEn,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              // Right indicator
              if (isDone)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.actionGreen, size: 20)
              else if (isActive)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.warningAmber,
                  ),
                )
              else
                Icon(Icons.radio_button_unchecked_rounded,
                    color: AppColors.textHint, size: 20),
            ],
          ),
        );
      },
    );
  }
}
