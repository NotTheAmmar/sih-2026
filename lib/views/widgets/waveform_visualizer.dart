import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class WaveformVisualizer extends StatelessWidget {
  final List<double> amplitudes; // 30 values, each 0.0–1.0
  final bool isActive;

  const WaveformVisualizer({
    super.key,
    required this.amplitudes,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: CustomPaint(
        painter: _WaveformPainter(
          amplitudes: amplitudes,
          isActive: isActive,
        ),
        size: const Size(double.infinity, 56),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final bool isActive;

  _WaveformPainter({required this.amplitudes, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = amplitudes.length;
    final barWidth = (size.width / barCount) * 0.6;
    final gap = (size.width / barCount) * 0.4;
    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.9;
    final minBarHeight = 4.0;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < barCount; i++) {
      final amp = amplitudes[i].clamp(0.0, 1.0);
      final barHeight = math.max(minBarHeight, amp * maxBarHeight);
      final x = i * (barWidth + gap) + gap / 2;

      // Color gradient: green for active, gray for idle
      final alpha = isActive ? (0.4 + amp * 0.6) : 0.3;
      paint.color = isActive
          ? AppColors.actionGreen.withValues(alpha: alpha)
          : AppColors.textHint.withValues(alpha: 0.5);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: barHeight,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.amplitudes != amplitudes || old.isActive != isActive;
}
