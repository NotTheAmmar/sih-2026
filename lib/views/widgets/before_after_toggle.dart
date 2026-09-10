import 'dart:io';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class BeforeAfterToggle extends StatelessWidget {
  final String? rawImagePath;
  final String? studioImagePath;
  final bool showStudio;
  final VoidCallback onToggle;

  const BeforeAfterToggle({
    super.key,
    required this.rawImagePath,
    required this.studioImagePath,
    required this.showStudio,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image display with crossfade
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _buildImage(showStudio),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Toggle pill
        GestureDetector(
          onTap: onToggle,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToggleChip(
                  label: 'कच्चा फोटो',
                  sublabel: 'Raw',
                  isSelected: !showStudio,
                ),
                _ToggleChip(
                  label: 'स्टूडियो फोटो',
                  sublabel: 'Studio',
                  isSelected: showStudio,
                  activeColor: AppColors.actionGreen,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(bool studio) {
    final path = studio ? studioImagePath : rawImagePath;
    if (path == null) {
      return Container(
        color: AppColors.cardBorder,
        child: const Center(child: Icon(Icons.image_outlined, size: 48)),
      );
    }
    return Image.file(
      File(path),
      key: ValueKey(path),
      fit: BoxFit.cover,
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isSelected;
  final Color activeColor;

  const _ToggleChip({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    this.activeColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isSelected ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.chipText.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            sublabel,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? Colors.white70 : AppColors.textHint,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
