import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/capture_controller.dart';
import '../../controllers/catalog_controller.dart';
import '../../controllers/voice_controller.dart';
import '../widgets/progress_stepper.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startProcessing());
    }
  }

  Future<void> _startProcessing() async {
    final captureCtrl = context.read<CaptureController>();
    final voiceCtrl = context.read<VoiceController>();
    final catalogCtrl = context.read<CatalogController>();

    await catalogCtrl.processCatalog(
      imagePath: captureCtrl.capturedImagePath ?? '',
      audioPath: voiceCtrl.audioPath ?? '',
    );

    if (!mounted) return;

    if (catalogCtrl.stage == ProcessingStage.done) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.catalog);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogController>(
      builder: (context, ctrl, _) {
        return Scaffold(
          backgroundColor: AppColors.surfaceLight,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.screenV,
              ),
              child: SingleChildScrollView(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Shimmer spinner ───────────────────────────────────
                  Shimmer.fromColors(
                    baseColor: AppColors.actionGreen.withAlpha(60),
                    highlightColor: AppColors.actionGreenLight,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Title ─────────────────────────────────────────────
                  Text(
                    'AI काम कर रहा है...',
                    style: AppTextStyles.headline,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'AI is working its magic',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Progress stepper ──────────────────────────────────
                  ProgressStepper(
                    currentStage: _stageIndex(ctrl.stage),
                  ),

                  // ── Error state ───────────────────────────────────────
                  if (ctrl.stage == ProcessingStage.error) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.alertRedLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Text(
                        'कुछ गलत हुआ। Something went wrong.\n${ctrl.errorMessage ?? ""}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.alertRed),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.alertRed),
                      child: const Text('वापस जाएं — Go Back'),
                    ),
                  ],
                ],
              ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _stageIndex(ProcessingStage stage) {
    switch (stage) {
      case ProcessingStage.notStarted:
        return 0;
      case ProcessingStage.imageProcessing:
        return 0;
      case ProcessingStage.voiceProcessing:
        return 1;
      case ProcessingStage.pricing:
        return 2;
      case ProcessingStage.done:
        return 3; // all steps complete
      case ProcessingStage.error:
        return 0; // show stepper at start on error
    }
  }
}
