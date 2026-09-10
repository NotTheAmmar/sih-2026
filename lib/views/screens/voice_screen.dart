import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/capture_controller.dart';
import '../../controllers/voice_controller.dart';
import '../widgets/mic_button.dart';
import '../widgets/waveform_visualizer.dart';

class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CaptureController, VoiceController>(
      builder: (context, captureCtrl, voiceCtrl, _) {
        return Scaffold(
          backgroundColor: AppColors.surfaceLight,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.screenV,
              ),
              child: Column(
                children: [
                  // ── Top bar ───────────────────────────────────────────
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () {
                          voiceCtrl.reset();
                          Navigator.of(context).pop();
                        },
                      ),
                      const Spacer(),
                      Text('आवाज़ रिकॉर्ड करें',
                          style: AppTextStyles.subhead),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Captured image thumbnail ──────────────────────────
                  if (captureCtrl.capturedImagePath != null)
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      child: Image.file(
                        File(captureCtrl.capturedImagePath!),
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Instruction ───────────────────────────────────────
                  Text(
                    'अपने उत्पाद के बारे में बताएं',
                    style: AppTextStyles.headline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'सामग्री, बनाने में लगे दिन, और कीमत बताएं\n'
                    'Describe materials, days of work, and price',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Countdown timer ───────────────────────────────────
                  _CountdownTimer(seconds: voiceCtrl.secondsRemaining),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Mic button ────────────────────────────────────────
                  MicButton(
                    isRecording:
                        voiceCtrl.state == VoiceState.recording,
                    onTap: voiceCtrl.toggleRecording,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Waveform ──────────────────────────────────────────
                  WaveformVisualizer(
                    amplitudes: voiceCtrl.amplitudeHistory,
                    isActive: voiceCtrl.state == VoiceState.recording,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Silence warning ───────────────────────────────────
                  AnimatedOpacity(
                    opacity: voiceCtrl.isSilent &&
                            voiceCtrl.state == VoiceState.recording
                        ? 1.0
                        : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningAmberLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(color: AppColors.warningAmber),
                      ),
                      child: Text(
                        '🔔 आवाज़ ठीक से नहीं आई — phone पास लाएं',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.warningAmber),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── Proceed button (after recording stops) ────────────
                  AnimatedOpacity(
                    opacity: voiceCtrl.hasRecording ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: voiceCtrl.hasRecording
                            ? () => Navigator.of(context)
                                .pushNamed(AppRoutes.processing)
                            : null,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('AI से catalog बनाएं'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CountdownTimer extends StatelessWidget {
  final int seconds;
  const _CountdownTimer({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final color = seconds <= 5 ? AppColors.alertRed : AppColors.textPrimary;
    return Column(
      children: [
        Text(
          '$seconds',
          style: AppTextStyles.headlineLarge.copyWith(
            color: color,
            fontSize: 48,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'seconds remaining',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
