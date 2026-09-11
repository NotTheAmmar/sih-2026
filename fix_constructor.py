import re

with open('lib/controllers/pricing_controller.dart', 'r') as f:
    text = f.read()

bad_constructor = r"""  PricingController\(\{
    int initialRawMaterialCost = 0,
    int initialLaborDays = 0,
<<<<<<< HEAD
=======
    int initialItemsProduced = 1,
    int initialSellerProposedPrice = 0,
>>>>>>> origin/main
    int dailyWageRate = AppConstants\.defaultDailyWageRate,
    double skillMultiplier = 1\.0,
    int initialQuantity = 1,
  \}\)  : _rawMaterialCost = initialRawMaterialCost,
        _laborDays = initialLaborDays,
<<<<<<< HEAD
        _dailyWageRate = dailyWageRate,
        _skillMultiplier = skillMultiplier,
        _availableQuantity = initialQuantity \{
=======
        _itemsProduced = initialItemsProduced,
        _sellerProposedPrice = initialSellerProposedPrice,
        _dailyWageRate = dailyWageRate \{
>>>>>>> origin/main"""

good_constructor = """  PricingController({
    int initialRawMaterialCost = 0,
    int initialLaborDays = 0,
    int initialItemsProduced = 1,
    int initialSellerProposedPrice = 0,
    int dailyWageRate = AppConstants.defaultDailyWageRate,
    double skillMultiplier = 1.0,
    int initialQuantity = 1,
  })  : _rawMaterialCost = initialRawMaterialCost,
        _laborDays = initialLaborDays,
        _itemsProduced = initialItemsProduced,
        _sellerProposedPrice = initialSellerProposedPrice,
        _dailyWageRate = dailyWageRate,
        _skillMultiplier = skillMultiplier,
        _availableQuantity = initialQuantity {"""

text = text.replace(bad_constructor, good_constructor)
text = re.sub(bad_constructor, good_constructor, text, flags=re.DOTALL) # in case

# try without regex just exact string match with some tolerance if needed
with open('lib/controllers/pricing_controller.dart', 'w') as f:
    f.write(text)

