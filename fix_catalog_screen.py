import re

with open('lib/views/screens/catalog_screen.dart', 'r') as f:
    text = f.read()

# Conflict 1: seedFromExtracted
conflict1 = r'<<<<<<< HEAD\n              rawMaterialCost: 0,\n              laborDays: 0,\n=======\n              rawMaterialCost: item.pricing\?\.rawMaterialCost \?\? 0,\n              laborDays: item.pricing\?\.laborDays \?\? 0,\n              itemsProduced: item.pricing\?\.itemsProduced \?\? 1,\n              sellerProposedPrice: item.pricing\?\.sellerProposedPrice \?\? 0,\n>>>>>>> origin/main'

resolution1 = """              rawMaterialCost: item.pricing?.rawMaterialCost ?? 0,
              laborDays: item.pricing?.laborDays ?? 0,
              itemsProduced: item.pricing?.itemsProduced ?? 1,
              sellerProposedPrice: item.pricing?.sellerProposedPrice ?? 0,"""

text = re.sub(conflict1, resolution1, text)

# Conflict 2: Extra UI block (ONDC Market Comparison)
conflict2 = r'<<<<<<< HEAD\n=======\n                        if \(pricingCtrl.sellerProposedPrice > 0\)\n(.*?)>>>>>>> origin/main'

def repl(m):
    return "                        if (pricingCtrl.sellerProposedPrice > 0)\n" + m.group(1)

text = re.sub(conflict2, repl, text, flags=re.DOTALL)

with open('lib/views/screens/catalog_screen.dart', 'w') as f:
    f.write(text)

