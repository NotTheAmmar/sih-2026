import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/capture_controller.dart';
import '../widgets/shutter_button.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  bool _cameraInitStarted = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback so the context is fully available.
    // _cameraInitStarted ensures this never fires twice on hot-restart.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_cameraInitStarted && mounted) {
        _cameraInitStarted = true;
        context.read<CaptureController>().initCamera();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CaptureController>(
      builder: (context, ctrl, _) {
        if (ctrl.state == CaptureState.previewing ||
            ctrl.state == CaptureState.confirmed) {
          return _PreviewOverlay(ctrl: ctrl);
        }
        return _ViewfinderScreen(ctrl: ctrl);
      },
    );
  }
}

// ── Live Viewfinder ──────────────────────────────────────────────────────────

class _ViewfinderScreen extends StatelessWidget {
  final CaptureController ctrl;
  const _ViewfinderScreen({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (ctrl.isCameraReady && ctrl.cameraController != null)
            CameraPreview(ctrl.cameraController!)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // 1:1 framing overlay
          Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white60, width: 2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _CircleIconBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  Text(
                    'कलाकृती AI',
                    style: AppTextStyles.subhead.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // Quality warning banner
          if (ctrl.isQualityWarningBlur || ctrl.isQualityWarningLight)
            Positioned(
              top: 90,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: _QualityWarning(
                isBlur: ctrl.isQualityWarningBlur,
              ),
            ),

          // Instruction label
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'उत्पाद को फ्रेम में रखें  •  Place product in frame',
                  style:
                      AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
              ),
            ),
          ),

          // Bottom action dock
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xl,
                  horizontal: AppSpacing.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery picker
                    _CircleIconBtn(
                      icon: Icons.photo_library_rounded,
                      onTap: () => ctrl.pickFromGallery(),
                      size: AppSpacing.touchTargetMin,
                    ),
                    // Shutter
                    ShutterButton(
                      onPressed: ctrl.capturePhoto,
                      enabled: ctrl.isCameraReady && !ctrl.isBusy,
                    ),
                    // Placeholder for symmetry
                    const SizedBox(width: AppSpacing.touchTargetMin),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preview after capture ────────────────────────────────────────────────────

class _PreviewOverlay extends StatelessWidget {
  final CaptureController ctrl;
  const _PreviewOverlay({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Captured image
          if (ctrl.capturedImagePath != null)
            kIsWeb 
                ? Image.network(
                    ctrl.capturedImagePath!, 
                    fit: BoxFit.cover,
                    headers: const {'ngrok-skip-browser-warning': 'true'},
                  )
                : Image.file(File(ctrl.capturedImagePath!), fit: BoxFit.cover),

          // Bottom action row
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'फिर से लें',
                        sublabel: 'Retake ↺',
                        color: AppColors.alertRed,
                        onTap: ctrl.retake,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ActionButton(
                        label: 'आगे बढ़ें',
                        sublabel: 'Proceed ✔',
                        color: AppColors.actionGreen,
                        onTap: () {
                          ctrl.confirmImage();
                          Navigator.of(context)
                              .pushNamed(AppRoutes.voice);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ───────────────────────────────────────────────────────

class _QualityWarning extends StatelessWidget {
  final bool isBlur;
  const _QualityWarning({required this.isBlur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withAlpha(220),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isBlur
                  ? 'फोटो साफ नहीं। Photo blurry — hold the camera steady.'
                  : 'रोशनी कम है। Low light — move to a brighter spot.',
              style: AppTextStyles.caption.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CircleIconBtn({
    required this.icon,
    required this.onTap,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.55),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          children: [
            Text(label,
                style:
                    AppTextStyles.buttonLabel.copyWith(color: Colors.white),
                textAlign: TextAlign.center),
            Text(sublabel,
                style:
                    AppTextStyles.caption.copyWith(color: Colors.white70),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
