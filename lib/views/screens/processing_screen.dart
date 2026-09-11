import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/capture_controller.dart';
import '../../controllers/catalog_controller.dart';
import '../../controllers/voice_controller.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  bool _started = false;
  late final AnimationController _pulse;
  StreamSubscription<int>? _msgTimer;
  StreamSubscription<int>? _elapsedTimer;

  // Rotating status messages shown during the single backend call
  static const _messages = [
    ('बैकग्राउंड हटाया जा रहा है...', 'Removing background…'),
    ('आवाज़ को समझा जा रहा है...', 'Transcribing your voice…'),
    ('उत्पाद की पहचान हो रही है...', 'Identifying craft & materials…'),
    ('अंग्रेज़ी विवरण तैयार हो रहा है...', 'Writing English description…'),
    ('हिंदी विवरण तैयार हो रहा है...', 'Writing Hindi description…'),
    ('उचित दाम की गणना हो रही है...', 'Calculating fair price…'),
    ('स्टूडियो इमेज तैयार हो रही है...', 'Finishing studio photo…'),
  ];

  int _msgIndex = 0;
  int _elapsed = 0; // seconds

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Rotate messages every 3 seconds — stored so we can cancel on dispose
    _msgTimer = Stream.periodic(const Duration(seconds: 3), (i) => i).listen(
      (_) {
        if (mounted) setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
      },
    );

    // Elapsed counter every second — stored so we can cancel on dispose
    _elapsedTimer = Stream.periodic(const Duration(seconds: 1), (i) => i).listen(
      (_) {
        if (mounted) setState(() => _elapsed++);
      },
    );
  }

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

    try {
      await catalogCtrl.processCatalog(
        imagePath: captureCtrl.capturedImagePath ?? '',
        audioPath: voiceCtrl.audioPath ?? '',
      );
    } catch (e) {
      // Surface any unhandled exception as an error state so the user
      // sees the error card instead of a frozen spinner.
      debugPrint('[ProcessingScreen] unhandled exception: $e');
    }

    if (!mounted) return;

    if (catalogCtrl.stage == ProcessingStage.done) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.catalog);
    }
    // If stage == error, the error card is already shown by the Consumer build.
  }

  @override
  void dispose() {
    _msgTimer?.cancel();
    _elapsedTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogController>(
      builder: (context, ctrl, _) {
        final (hi, en) = _messages[_msgIndex];
        return Scaffold(
          backgroundColor: AppColors.surfaceLight,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.screenV,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // ── Pulsing AI orb ────────────────────────────────────
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.actionGreen.withAlpha(
                          (30 + 40 * _pulse.value).round(),
                        ),
                      ),
                      child: Shimmer.fromColors(
                        baseColor: AppColors.actionGreen.withAlpha(180),
                        highlightColor: AppColors.actionGreenLight,
                        child: Container(
                          margin: const EdgeInsets.all(16),
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
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Main title ────────────────────────────────────────
                  Text(
                    'AI काम कर रहा है...',
                    style: AppTextStyles.headline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Processing your product',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Rotating status message ───────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Column(
                      key: ValueKey(_msgIndex),
                      children: [
                        Text(
                          hi,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          en,
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Progress bar (indeterminate) ──────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor: AppColors.cardBorder,
                      color: AppColors.actionGreen,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Elapsed time ──────────────────────────────────────
                  Text(
                    '${_elapsed}s — AI server is processing…',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

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

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
