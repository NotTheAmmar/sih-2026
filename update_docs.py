import re

# --- 1. flutter-ondc-integration.md ---
with open('artifacts/flutter-ondc-integration.md', 'r') as f:
    text = f.read()

text = text.replace('Status:** 🔜 Phase 3 (Post-hackathon prototype, pre-grand-finale)', 'Status:** ✅ Implemented in Prototype')
text = text.replace('- `[ ]` Add `BPP_BACKEND_URL`', '- `[x]` Add `BPP_BACKEND_URL`')
text = text.replace('- `[ ]` Add `bppBackendUrl` getter', '- `[x]` Add `bppBackendUrl` getter')
text = text.replace('- `[ ]` Add `publishToOndc(CatalogItem item)`', '- `[x]` Add `publishToOndc`')
text = text.replace('- `[ ]` Add the same method stub', '- `[x]` Add the same method stub')
text = text.replace('- `[ ]` Add `publishToOndc()` method to', '- `[x]` Add `publishToOndc()` method to')
text = text.replace('- `[ ]` Update `lib/views/screens/catalog_screen.dart`', '- `[x]` Update `lib/views/screens/catalog_screen.dart`')
text = text.replace('- `[ ]` Update `lib/services/storage_service.dart`', '- `[x]` Update `lib/services/storage_service.dart`')

text = text.replace('"available_qty": 5,', '"dimensions": item.craftAttributes?.dimensions ?? "1 unit",\n    "available_qty": availableQuantity,')
text = text.replace('"available_qty": 5\n}', '"available_qty": 5\n}') # already 5 in example, keep it 5 for json

with open('artifacts/flutter-ondc-integration.md', 'w') as f:
    f.write(text)

# --- 2. prototype-details.md ---
with open('artifacts/prototype-details.md', 'r') as f:
    text = f.read()

old_screen4_chips = """  * **Craft Category:** Identified heritage category (e.g., Chanderi Weave, Terracotta).
  * **Detected Materials:** Extracted primary fibers or elements (e.g., Pure Silk, Zari).
  * **Crafting Duration:** Dedication time parsed from voice (e.g., 5 Days)."""
new_screen4_chips = """  * **Craft Category:** Identified heritage category (e.g., Chanderi Weave, Terracotta).
  * **Dimensions / Map:** Extracted physical size (e.g., 6.2 meters).
  * **Detected Materials:** Extracted primary fibers or elements (e.g., Pure Silk, Zari).
  * **Crafting Duration:** Dedication time parsed from voice (e.g., 5 Days).
  * **Quantity (Stock):** Artisan can step up/down the available pieces."""

text = text.replace(old_screen4_chips, new_screen4_chips)

old_screen4_price = """* **3-Tier Fair-Pricing Corridor:** A tripartite visual price gauge:
  * **Floor Price (Base Clearance):** Breakeven threshold covering materials and minimum daily wage.
  * **Fair Market Price (Recommended D2C):** Algorithmically optimized price for open commerce.
  * **Premium Price (Institutional/B2B):** Suggested quote for bulk government or corporate procurement.
* **Primary Action Bar:** A full-width "Phir Se Karein" (Retake Voice/Photo) button in a muted outlined style, allowing the artisan to restart the capture cycle. ONDC publishing integration is deferred to Phase 2."""

new_screen4_price = """* **3-Tier Fair-Pricing Corridor:** A tripartite visual price gauge:
  * **Floor Price (Statutory Minimum):** Strict deterministic threshold covering raw materials + (labor days × statutory wage × skill multiplier) + 10% overhead. Manual pricing below this floor is blocked by the UI.
  * **Fair Market Price (Recommended D2C):** Algorithmically optimized price for open commerce.
  * **Premium Price (Institutional/B2B):** Suggested quote for bulk government or corporate procurement.
* **Primary Action Bar:** 
  * **Publish to ONDC (Primary Green):** Instantly POSTs the structured catalog via the backend BPP to the ONDC Network. Displays loading spinner, success badge, and triggers Hindi TTS confirmation on success.
  * **Retake (Secondary Outlined):** Allows the artisan to discard and restart the capture cycle."""

text = text.replace(old_screen4_price, new_screen4_price)

with open('artifacts/prototype-details.md', 'w') as f:
    f.write(text)

# --- 3. technical-details.md ---
with open('artifacts/technical-details.md', 'r') as f:
    text = f.read()

text = text.replace(
    '  final String? craftCategory;      // e.g., "Handloom Silk Sarees"\n  final List<String> materials;     // e.g., ["Pure Silk", "Gold Zari"]\n  final int? laborDays;',
    '  final CraftAttributes? craftAttributes;\n  final int availableQuantity;'
)

text = text.replace(
    'class PricingCorridor {\n  final int floorPrice;             // Breakeven (materials + labor + overhead)\n  final int fairPrice;              // Recommended D2C price\n  final int premiumPrice;           // B2B / institutional price (fair × 1.20)\n\n  final int rawMaterialCost;\n  final int laborDays;\n  final int dailyWageRate;          // ₹450–600/day\n  final double overheadPercent;     // ~10%\n}',
    'class PricingCorridor {\n  final int floorPrice;             // Breakeven (materials + labor + overhead)\n  final int fairPrice;              // Recommended D2C price\n  final int premiumPrice;           // B2B / institutional price (fair × 1.20)\n\n  final int rawMaterialCost;\n  final int laborDays;\n  final int dailyWageRate;          // ₹450–600/day\n  final double skillMultiplier;     // 1.0 to 1.5 based on artisan mastery\n  final double overheadPercent;     // ~10%\n}'
)

old_pricing = """## 12. Pricing Engine (Prototype)

The prototype implements a **deterministic pricing calculator** (no ML model):

$$C_{floor} = M_{raw} + (T_{days} \times W_{artisan}) + O_{overhead}$$

Where:
- $M_{raw}$ = Raw material cost (extracted from voice or manually adjusted)
- $T_{days}$ = Labor days (extracted from voice or manually adjusted)
- $W_{artisan}$ = Daily wage rate (₹450–600, configurable)
- $O_{overhead}$ = Fixed overhead (10% of subtotal)"""

new_pricing = """## 12. Pricing Engine (Prototype)

The prototype implements a **deterministic pricing calculator** (no ML model) establishing a strict Statutory Cost Floor:

$$C_{floor} = M_{raw} + (T_{days} \times W_{artisan} \times K_{skill}) + O_{overhead}$$

Where:
- $M_{raw}$ = Raw material cost (extracted from voice or manually adjusted)
- $T_{days}$ = Labor days (extracted from voice or manually adjusted)
- $W_{artisan}$ = Daily statutory wage rate (₹450–600, configurable)
- $K_{skill}$ = Skill level multiplier (1.0 for basic, 1.25 for GI-cluster, 1.5 for master weaver)
- $O_{overhead}$ = Fixed overhead (10% of subtotal)"""

text = text.replace(old_pricing, new_pricing)

with open('artifacts/technical-details.md', 'w') as f:
    f.write(text)

