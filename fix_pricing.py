import re

with open('lib/models/pricing_corridor.dart', 'r') as f:
    text = f.read()

merged = """    // Base Labor = T_days * W_statutory * K_skill
    final double baseLabor = laborDays * dailyWageRate * skillMultiplier;
    
    // Base Cost = M_raw + Base Labor
    final double baseCost = rawMaterialCost + baseLabor;
    
    // Overhead (O_overhead) = 10%
    final double overhead = baseCost * overheadPercent;
    
    // Total floor before qty division
    final double totalFloor = baseCost + overhead;
    
    // Divide by items produced (ensure no divide-by-zero)
    final qty = itemsProduced > 0 ? itemsProduced : 1;
    final int floor = (totalFloor / qty).round();
    
    // P_fair (Market-Aware fallback until XGBoost is connected)
    final int fair = (floor * AppConstants.fairPriceMultiplier).round();
    
    // P_prem (1.20 * P_fair)
    final int premium = (fair * AppConstants.premiumPriceMultiplier).round();"""

text = re.sub(
    r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> origin/main',
    merged,
    text,
    flags=re.DOTALL
)

with open('lib/models/pricing_corridor.dart', 'w') as f:
    f.write(text)

