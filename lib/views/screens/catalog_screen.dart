import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/catalog_controller.dart';
import '../../controllers/capture_controller.dart';
import '../../controllers/voice_controller.dart';
import '../../controllers/pricing_controller.dart';
import '../widgets/before_after_toggle.dart';
import '../widgets/craft_chip.dart';
import '../widgets/price_gauge.dart';
import '../widgets/stepper_input.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set _seeded synchronously so this block never runs twice,
    // but defer the actual notifyListeners() call to after the frame —
    // calling seedFromExtracted directly here causes "setState during build"
    // because didChangeDependencies fires inside _firstBuild.
    if (!_seeded) {
      final item = context.read<CatalogController>().currentItem;
      if (item != null) {
        _seeded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Start at 0 so the artisan enters their actual costs
            context.read<PricingController>().seedFromExtracted(
              rawMaterialCost: item.pricing?.rawMaterialCost ?? 0,
              laborDays: item.pricing?.laborDays ?? 0,
              itemsProduced: item.pricing?.itemsProduced ?? 1,
              sellerProposedPrice: item.pricing?.sellerProposedPrice ?? 0,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CatalogController, PricingController>(
      builder: (context, catalogCtrl, pricingCtrl, _) {
        final item = catalogCtrl.currentItem;
        if (item == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final attrs = item.craftAttributes;
        final pricing = pricingCtrl.corridor;

        return Scaffold(
          backgroundColor: AppColors.surfaceLight,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top bar ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      Text('Catalog Card', style: AppTextStyles.subhead),
                      const Spacer(),
                      // TTS speaker button
                      IconButton(
                        icon: Icon(
                          catalogCtrl.isSpeaking
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: AppColors.actionGreen,
                        ),
                        iconSize: 28,
                        onPressed: catalogCtrl.isSpeaking
                            ? catalogCtrl.stopReadback
                            : catalogCtrl.speakReadback,
                        tooltip: 'सुनें / Listen',
                      ),
                    ],
                  ),
                ),

                // ── Scrollable content ───────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenH,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Before/After photo toggle
                        BeforeAfterToggle(
                          rawImagePath: item.rawImagePath,
                          studioImagePath: item.studioImagePath,
                          showStudio: catalogCtrl.showStudioImage,
                          onToggle: catalogCtrl.togglePhotoView,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Product title (Hindi + English)
                        if (item.titleHi != null) ...[
                          Text(item.titleHi!, style: AppTextStyles.headline),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        if (item.titleEn != null) ...[
                          Text(item.titleEn!,
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // ── Description — full, both languages ──────────
                        if (item.descriptionHi != null ||
                            item.descriptionEn != null) ...[
                          Text('विवरण / Description',
                              style: AppTextStyles.label),
                          const SizedBox(height: AppSpacing.sm),
                          if (item.descriptionHi != null) ...[
                            Text(
                              item.descriptionHi!,
                              style: AppTextStyles.body,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          if (item.descriptionEn != null) ...[
                            Text(
                              item.descriptionEn!,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Craft attribute chips
                        if (attrs != null) ...[
                          if (attrs.category != null)
                            CraftChip(
                              icon: Icons.category_rounded,
                              label: 'Category / श्रेणी',
                              value: attrs.category!,
                            ),
                          const SizedBox(height: AppSpacing.xs),
                          if (attrs.dimensions != null) ...[
                            CraftChip(
                              icon: Icons.straighten_rounded,
                              label: 'Dimensions / माप',
                              value: attrs.dimensions!,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                          ],
                          if (attrs.materials.isNotEmpty)
                            CraftChip(
                              icon: Icons.fiber_manual_record_rounded,
                              label: 'Materials / सामग्री',
                              value: attrs.materials.join(', '),
                              color: AppColors.warningAmber,
                            ),
                          const SizedBox(height: AppSpacing.xs),
                          if (attrs.laborDays != null)
                            CraftChip(
                              icon: Icons.schedule_rounded,
                              label: 'Labour / कार्य दिवस',
                              value: '${attrs.laborDays} days',
                              color: AppColors.pricePremium,
                            ),
                          if (attrs.clusterLocation != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            CraftChip(
                              icon: Icons.location_on_rounded,
                              label: 'Cluster / क्लस्टर',
                              value: attrs.clusterLocation!,
                              color: AppColors.priceFloor,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),

                          // ── ONDC Fulfillment & Logistics ────────────────
                          Text('ONDC Logistics & Statutory', style: AppTextStyles.label),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              if (attrs.timeToShip != null)
                                CraftChip(
                                  icon: Icons.local_shipping_rounded,
                                  label: 'Ready to Ship',
                                  value: attrs.timeToShip!.replaceAll('PT', '').replaceAll('H', ' Hours'),
                                  color: AppColors.actionGreen,
                                ),
                              if (attrs.returnable)
                                CraftChip(
                                  icon: Icons.assignment_return_rounded,
                                  label: 'Returns',
                                  value: attrs.returnWindow?.replaceAll('P', '').replaceAll('D', ' Days') ?? 'Yes',
                                  color: AppColors.actionGreen,
                                ),
                              if (attrs.quantity > 0)
                                CraftChip(
                                  icon: Icons.inventory_2_rounded,
                                  label: 'In Stock',
                                  value: '${attrs.quantity} units',
                                ),
                              if (attrs.countryOfOrigin != null)
                                CraftChip(
                                  icon: Icons.public_rounded,
                                  label: 'Origin',
                                  value: attrs.countryOfOrigin!,
                                ),
                              if (attrs.genericName != null)
                                CraftChip(
                                  icon: Icons.label_rounded,
                                  label: 'Commodity',
                                  value: attrs.genericName!,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // ── Pricing adjustment inputs ──────────────────
                        Text('मूल्य समायोजन / Adjust Pricing',
                            style: AppTextStyles.label),
                        const SizedBox(height: AppSpacing.sm),
                        StepperInput(
                          label: 'Raw Material Cost / कच्चा माल',
                          unit: '₹',
                          value: pricingCtrl.rawMaterialCost,
                          step: 50,
                          onIncrement: () =>
                              pricingCtrl.incrementRawMaterial(step: 50),
                          onDecrement: () =>
                              pricingCtrl.decrementRawMaterial(step: 50),
                          onDirectEdit: (v) => pricingCtrl.setRawMaterialCost(v),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        StepperInput(
                          label: 'Available Quantity / उपलब्ध मात्रा',
                          unit: 'pcs',
                          value: pricingCtrl.availableQuantity,
                          onIncrement: pricingCtrl.incrementQuantity,
                          onDecrement: pricingCtrl.decrementQuantity,
                          onDirectEdit: (v) => pricingCtrl.setAvailableQuantity(v),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        StepperInput(
                          label: 'Labour Days / कार्य दिवस',
                          unit: 'days',
                          value: pricingCtrl.laborDays,
                          onIncrement: pricingCtrl.incrementLaborDays,
                          onDecrement: pricingCtrl.decrementLaborDays,
                          onDirectEdit: (v) => pricingCtrl.setLaborDays(v),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        StepperInput(
                          label: 'Items in Set / कुल मात्रा',
                          unit: 'items',
                          value: pricingCtrl.itemsProduced,
                          onIncrement: pricingCtrl.incrementItemsProduced,
                          onDecrement: pricingCtrl.decrementItemsProduced,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // ── Price corridor gauge ────────────────────────
                        PriceGauge(
                          floorPrice: pricing.floorPrice,
                          fairPrice: pricing.fairPrice,
                          premiumPrice: pricing.premiumPrice,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (pricingCtrl.sellerProposedPrice > 0)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: pricingCtrl.sellerProposedPrice < pricing.floorPrice
                                  ? AppColors.priceFloor.withOpacity(0.1)
                                  : AppColors.actionGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: pricingCtrl.sellerProposedPrice < pricing.floorPrice
                                    ? AppColors.priceFloor
                                    : AppColors.actionGreen,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  pricingCtrl.sellerProposedPrice < pricing.floorPrice
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle_outline_rounded,
                                  color: pricingCtrl.sellerProposedPrice < pricing.floorPrice
                                      ? AppColors.priceFloor
                                      : AppColors.actionGreen,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '⚡ ONDC Market Comparison',
                                        style: AppTextStyles.label,
                                      ),
                                      Text(
                                        pricingCtrl.sellerProposedPrice < pricing.floorPrice
                                            ? 'Your price (₹${pricingCtrl.sellerProposedPrice}) is below market floor! You may be underpricing your work.'
                                            : 'Your price (₹${pricingCtrl.sellerProposedPrice}) is highly competitive in the current ONDC market.',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xl),


                        // ── Final / Selling price (editable) ────────────
                        GestureDetector(
                          onTap: () async {
                            final ctrl = TextEditingController(
                              text: pricingCtrl.finalPrice == 0
                                  ? ''
                                  : '${pricingCtrl.finalPrice}',
                            );
                            final result = await showDialog<int>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(
                                  'अंतिम कीमत / Final Price',
                                  style: AppTextStyles.label,
                                ),
                                content: TextField(
                                  controller: ctrl,
                                  autofocus: true,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: const InputDecoration(
                                    prefixText: '₹ ',
                                    hintText: '0',
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (v) => Navigator.of(ctx)
                                      .pop(int.tryParse(v) ?? 0),
                                ),
                                actions: [
                                  if (pricingCtrl.hasFinalPriceOverride)
                                    TextButton(
                                      onPressed: () {
                                        pricingCtrl.clearFinalPriceOverride();
                                        Navigator.of(ctx).pop();
                                      },
                                      child: const Text('Reset to Auto'),
                                    ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('रद्द / Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(ctx).pop(
                                      int.tryParse(ctrl.text) ?? 0,
                                    ),
                                    child: const Text('सेट करें / Set'),
                                  ),
                                ],
                              ),
                            );
                            if (result != null && result > 0) {
                              final errorMsg = pricingCtrl.setFinalPrice(result);
                              if (errorMsg != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMsg),
                                    backgroundColor: AppColors.errorRed,
                                  ),
                                );
                              }
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm + 2,
                            ),
                            decoration: BoxDecoration(
                              color: pricingCtrl.hasFinalPriceOverride
                                  ? AppColors.actionGreen.withAlpha(18)
                                  : AppColors.cardBackground,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                color: pricingCtrl.hasFinalPriceOverride
                                    ? AppColors.actionGreen
                                    : AppColors.cardBorder,
                                width: pricingCtrl.hasFinalPriceOverride ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sell_rounded,
                                  color: pricingCtrl.hasFinalPriceOverride
                                      ? AppColors.actionGreen
                                      : AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Final Price / अंतिम कीमत',
                                        style: AppTextStyles.label.copyWith(
                                          color: pricingCtrl
                                                  .hasFinalPriceOverride
                                              ? AppColors.actionGreen
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        pricingCtrl.hasFinalPriceOverride
                                            ? 'Manually set'
                                            : 'Tap to set selling price',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${pricingCtrl.finalPrice}',
                                  style: AppTextStyles.priceLarge.copyWith(
                                    color: pricingCtrl.hasFinalPriceOverride
                                        ? AppColors.actionGreen
                                        : AppColors.textHint,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: AppColors.textHint,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),

                // ── Bottom action dock ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      // Publish Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (catalogCtrl.isPublishing || catalogCtrl.publishSuccess)
                              ? null
                              : () async {
                                  await catalogCtrl.publishToOndc(pricingCtrl);
                                  if (catalogCtrl.errorMessage != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(catalogCtrl.errorMessage!),
                                        backgroundColor: AppColors.errorRed,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.actionGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, AppSpacing.touchTargetMin),
                            disabledBackgroundColor: catalogCtrl.publishSuccess 
                                ? AppColors.actionGreen 
                                : null,
                            disabledForegroundColor: Colors.white,
                          ),
                          child: catalogCtrl.isPublishing
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : catalogCtrl.publishSuccess
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_rounded),
                                        SizedBox(width: 8),
                                        Text('ONDC पर प्रकाशित / Published'),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.rocket_launch_rounded),
                                        SizedBox(width: 8),
                                        Text('ONDC पर प्रकाशन / Publish to ONDC'),
                                      ],
                                    ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Retake Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            catalogCtrl.reset();
                            context.read<CaptureController>().retake();
                            context.read<VoiceController>().reset();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.capture, (r) => false);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize:
                                const Size(0, AppSpacing.touchTargetMin),
                            side: const BorderSide(
                                color: AppColors.textSecondary),
                          ),
                          child: Column(
                            children: [
                              const Text('फिर से करें'),
                              Text('Retake', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }
}
