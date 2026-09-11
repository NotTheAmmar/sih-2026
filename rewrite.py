import os

with open('lib/views/screens/catalog_screen.dart', 'r') as f:
    content = f.read()

# 1. Add dimensions to Craft attributes
old_materials_chip = """                          if (attrs.materials.isNotEmpty)
                            CraftChip(
                              icon: Icons.fiber_manual_record_rounded,
                              label: 'Materials / सामग्री',
                              value: attrs.materials.join(', '),
                              color: AppColors.warningAmber,
                            ),
                          const SizedBox(height: AppSpacing.xs),"""

new_materials_chip = """                          if (attrs.dimensions != null) ...[
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
                          const SizedBox(height: AppSpacing.xs),"""

content = content.replace(old_materials_chip, new_materials_chip)


# 2. Add StepperInput for Quantity
old_stepper = """                        StepperInput(
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
                        const SizedBox(height: AppSpacing.sm),"""

new_stepper = """                        StepperInput(
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
                        const SizedBox(height: AppSpacing.sm),"""

content = content.replace(old_stepper, new_stepper)


# 3. Add Snackbar logic to price editor
old_price = """                            if (result != null && result > 0) {
                              pricingCtrl.setFinalPrice(result);
                            }"""

new_price = """                            if (result != null && result > 0) {
                              final errorMsg = pricingCtrl.setFinalPrice(result);
                              if (errorMsg != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMsg),
                                    backgroundColor: AppColors.errorRed,
                                  ),
                                );
                              }
                            }"""

content = content.replace(old_price, new_price)


# 4. Replace Action Dock
old_dock = """                // ── Bottom action dock ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: SizedBox(
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
                ),"""

new_dock = """                // ── Bottom action dock ────────────────────────────────────
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
                ),"""

content = content.replace(old_dock, new_dock)

with open('lib/views/screens/catalog_screen.dart', 'w') as f:
    f.write(content)

